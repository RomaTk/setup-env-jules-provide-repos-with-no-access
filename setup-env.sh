#!/usr/bin/env bash
set -euo pipefail

# 1. Verify token existence
if [ -z "${FINE_GRAINED_PERSONAL_TOKEN_TO_READ_REPOS:-}" ]; then
  echo "Error: FINE_GRAINED_PERSONAL_TOKEN_TO_READ_REPOS environment variable is not set." >&2
  exit 1
fi

# 2. Verify JSON mapping existence
if [ -z "${FOLDER_TO_GITHUB:-}" ]; then
  echo "Error: FOLDER_TO_GITHUB environment variable is not set." >&2
  echo 'Example: FOLDER_TO_GITHUB='\''{"engineering-blueprint":"github.com/RomaTk/engineering-blueprint.git"}'\''' >&2
  exit 1
fi

# Helper function to parse JSON using jq or python3
parse_json() {
  if command -v jq >/dev/null 2>&1; then
    jq -r 'to_entries[] | "\(.key) \(.value)"' <<< "$FOLDER_TO_GITHUB"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import json, os; [print(f'{k} {v}') for k, v in json.loads(os.environ['FOLDER_TO_GITHUB']).items()]"
  else
    echo "Error: Either 'jq' or 'python3' must be installed to parse JSON." >&2
    exit 1
  fi
}

# 3. Ignore .deps globally in local git configuration without touching tracked files
BASE_DIR=".deps"

if [ -d .git ]; then
  mkdir -p .git/info
  EXCLUDE_ENTRY="/${BASE_DIR}"
  if ! grep -qs "^${EXCLUDE_ENTRY}$" .git/info/exclude 2>/dev/null; then
    echo "${EXCLUDE_ENTRY}" >> .git/info/exclude
    echo "Added ${EXCLUDE_ENTRY} to .git/info/exclude"
  fi
fi

# 4. Iterate over repos and clone/pull each one into .deps/<folder>
while read -r folder repo_url; do
  [ -z "$folder" ] && continue

  # Sanitize repository URL (strips protocol if included)
  CLEAN_REPO_URL=$(echo "$repo_url" | sed -E 's|^https?://||')
  TARGET_DIR="${BASE_DIR}/${folder}"
  AUTH_URL="https://x-access-token:${FINE_GRAINED_PERSONAL_TOKEN_TO_READ_REPOS}@${CLEAN_REPO_URL}"

  if [ -d "$TARGET_DIR/.git" ]; then
    echo "Repository '$folder' already exists at $TARGET_DIR. Fetching latest changes..."
    git -C "$TARGET_DIR" pull origin main || git -C "$TARGET_DIR" pull origin master
  else
    echo "Cloning '$folder' into $TARGET_DIR..."
    git clone "$AUTH_URL" "$TARGET_DIR"
  fi
done < <(parse_json)

echo "Setup completed successfully."
