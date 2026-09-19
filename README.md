# Environment Setup Script

This repository contains a script used to setup the environment in Jules. It provides access to repositories that Jules doesn't have access to by default.

## Usage

To use the setup script, you need to configure two environment variables and run the script using `bash`.

1. `FINE_GRAINED_PERSONAL_TOKEN_TO_READ_REPOS`: A GitHub fine-grained personal access token that has read access to the target repositories.
2. `FOLDER_TO_GITHUB`: A JSON string mapping the local folder name to the GitHub repository URL.

### Example

```bash
# Set the GitHub token
export FINE_GRAINED_PERSONAL_TOKEN_TO_READ_REPOS="your_github_token_here"

# Set the mapping of folders to repositories
export FOLDER_TO_GITHUB='{"engineering-blueprint":"github.com/RomaTk/engineering-blueprint.git"}'

# Run the setup script
bash setup-env.sh
```

The script will:
- Verify the environment variables.
- Configure git to locally ignore the `.deps` directory.
- Clone or pull the specified repositories into the `.deps/<folder>` directory.
