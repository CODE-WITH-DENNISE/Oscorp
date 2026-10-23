#!/bin/bash
# Builds a small, plausible-looking git history:
#   1. initial commit (app scaffold)
#   2. "oops, hardcoded config" commit (the leak)
#   3-4. unrelated normal commits (makes it look organic)
#   5. rotation commit (removes the hardcoded key, switches to env vars)
#
# Self-contained: writes all file content itself, safe to re-run from scratch.
set -e

rm -rf .git src package.json .gitignore .env.example README.md
mkdir -p src/components

git init -q
git checkout -q -b main

cat > package.json <<'EOF'
{
  "name": "daily-tasks-web",
  "version": "0.1.0",
  "private": true
}
EOF
echo "node_modules/" > .gitignore
git add package.json .gitignore
git commit -q -m "initial scaffold"

# --- commit 2: the leak ---
cat > src/config.js <<'EOF'
// Firebase client configuration
// TODO: move this to env vars before prod launch

const firebaseConfig = {
  apiKey: "Flag{inm_deleted_secret}",
  authDomain: "ctf-project.firebaseapp.com",
  databaseURL: "https://ctf-project-default-rtdb.firebaseio.com",
  projectId: "ctf-project",
  storageBucket: "ctf-project.appspot.com",
  messagingSenderId: "000000000000",
  appId: "1:000000000000:web:0000000000000000000000"
};

export default firebaseConfig;
EOF

cat > README.md <<'EOF'
# daily-tasks-web

Small companion web dashboard for the daily-tasks mobile app. Lets users view
and sync their task list from a browser.

## Setup

\`\`\`bash
npm install
npm run dev
\`\`\`

Copy \`.env.example\` to \`.env\` and fill in your Firebase project values.

## Status

Early prototype — UI is rough, syncing works. See commit history for recent
cleanup/security pass.
EOF

git add src/config.js README.md
git commit -q -m "wire up firebase client"

# --- commit 3: unrelated normal work ---
cat > src/components/TaskList.jsx <<'EOF'
export default function TaskList({ tasks }) {
  return (
    <ul>
      {tasks.map((t) => (
        <li key={t.id}>{t.title}</li>
      ))}
    </ul>
  );
}
EOF
git add src/components/TaskList.jsx
git commit -q -m "add basic task list component"

# --- commit 4: another small unrelated change ---
cat >> README.md <<'EOF'

## Roadmap
- [ ] offline sync
- [ ] dark mode
EOF
git add README.md
git commit -q -m "update roadmap notes"

# --- commit 5: the rotation (breadcrumb commit) ---
cat > src/config.js <<'EOF'
// Firebase client configuration
// Loaded from environment — see .env.example

const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  databaseURL: process.env.FIREBASE_DB_URL,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID
};

export default firebaseConfig;
EOF

cat > .env.example <<'EOF'
FIREBASE_API_KEY=
FIREBASE_AUTH_DOMAIN=
FIREBASE_DB_URL=
FIREBASE_PROJECT_ID=
FIREBASE_STORAGE_BUCKET=
FIREBASE_SENDER_ID=
FIREBASE_APP_ID=
EOF

git add src/config.js .env.example
git commit -q -m "rotate leaked firebase config, move to env vars"

echo "Done. Review with: git log --oneline --stat"
echo "Then: git remote add origin <your-new-empty-github-repo-url>"
echo "      git push -u origin main"
