#!/bin/bash
set -Eeuo pipefail

RESET='\033[0m'
YELL='\033[0;33m'
CYAN='\033[0;36m'
BOLD_YELL="\033[1;33m"
BOLD_CYAN="\033[1;36m"
H0="================================================================================${RESET}"
H1="--------------------------------------------------------------------------------${RESET}"
H2="${BOLD_YELL}${H0}"
H3="${BOLD_CYAN}${H1}"

# ================================================================================
# Main Deployment Controller File
# ================================================================================
# To deploy the entire speech system project, manually upload this file and the 
# .env file and run with `bash deploy.sh`. It will first install Git and download
# the rest of this deployment repository before proceeding with downloading and 
# installing the full app.
echo -e " "
echo -e "${H2}"
echo -e "${BOLD_YELL}                           Beginning Deployment... ${RESET}"
echo -e "${H2}"

# --------------------------------------------------------------------------------
# Define some "secret" keys here (pull from the .env file)
# --------------------------------------------------------------------------------
source .env

echo "Loaded deployment config from .env"
echo "Sample environment variable: ${GITHUB_USER}/${GITHUB_REPO}"

# If we do make the repo private at some point and need a token...
#SETUP_REPO_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${GITHUB_REPO}.git"

# --------------------------------------------------------------------------------
# Define Locations
# --------------------------------------------------------------------------------
SETUP_REPO_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git"

# These will be loaded from .env (GITHUB_USER, GITHUB_REPO, SETUP_REPO_BRANCH)
SETUP_PRJ_DIR="$HOME"
SETUP_REPO_DIR="$SETUP_PRJ_DIR/$GITHUB_REPO"

# Check our location
echo "Current working directory: $(pwd)"
cd "$SETUP_PRJ_DIR"
echo "Current working directory: $(pwd) (moved into project setup directory)"

# --------------------------------------------------------------------------------
# Install Git (if it isn't installed already)
# --------------------------------------------------------------------------------
echo -e "\n${H3}"
echo -e "${BOLD_CYAN}Installing Git... ${RESET}"
echo -e "${H3}"

# Only install git if the "git" command doesn't already work
if ! command -v git &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y git
else
    echo -e "Git already installed, skipping..."
fi

# --------------------------------------------------------------------------------
# Clone or pull from the project repository
# --------------------------------------------------------------------------------
echo -e "\n${H3}"
echo -e "${BOLD_CYAN}Download the repository... ${RESET}"
echo -e "${H3}"

# Check if the remote branch exists
if ! git ls-remote --exit-code --heads "$SETUP_REPO_URL" "$SETUP_REPO_BRANCH" >/dev/null; then
    echo "ERROR: Remote branch '$SETUP_REPO_BRANCH' not found at $SETUP_REPO_URL"
    echo "       Did you create & push it? Try: git push -u origin $SETUP_REPO_BRANCH"
    exit 1
fi

# Check if the repository directory already exists
if [ -d "$GITHUB_REPO" ]; then
    # If it already exists, pull from the given origin branch
    echo "Repo exists. Updating..."
    cd "$GITHUB_REPO"
    
    # Fetch from the repository
    git fetch origin --prune

    # Switch / checkout the specified branch
    git switch "$SETUP_REPO_BRANCH" || git checkout "$SETUP_REPO_BRANCH"
    git pull origin "$SETUP_REPO_BRANCH"

else
    # If it doesn't exist at all yet, clone it
    echo "Cloning branch '$SETUP_REPO_BRANCH'..."
    git clone --branch "$SETUP_REPO_BRANCH" --single-branch "$SETUP_REPO_URL" "$GITHUB_REPO"
    cd "$GITHUB_REPO"
fi

# --------------------------------------------------------------------------------
# Run the setup script
# --------------------------------------------------------------------------------
# bash controller.sh --env=sandbox
source "$SETUP_REPO_DIR/utils/controller.sh" "$@"
