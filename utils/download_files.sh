# ================================================================================
# Clone/Pull Repo & Download deployment files from GCS Bucket
# ================================================================================
echo -e "${PROG_HR_1}"
echo -e "${PROG_TEXT}4. Pulling project repo & Downloading 'deployment-files' from GCS Bucket... ${RESET}"
echo -e "${PROG_HR_2}"

echo -e "download_files.sh current working directory: $(pwd)"

# --------------------------------------------------------------------------------
# Clone or pull from the main app repository
# --------------------------------------------------------------------------------
echo -e "${INFO_T1}Clone or update the repository... ${RESET}"

# Check if the repository directory already exists
if [ -d "$APP_DIR" ]; then
    # If it already exists, pull from the given origin branch
    echo -e "${INFO_T2}Repo exists, pulling latest changes... ${RESET}"
    cd "$APP_DIR"
    echo -e "cd'ed into ${APP_DIR}; new current working directory: $(pwd)"

    # Fetch latest remote state
    git fetch origin --prune

    # If the local branch exists, switch to it; otherwise create it from origin
    if git rev-parse --verify "$REPO_BRANCH" >/dev/null 2>&1; then
        # Branch already exists locally
        echo -e "${INFO_T2}Branch exists locally, switching or checking it out... ${RESET}"
        git switch "$REPO_BRANCH" || git checkout "$REPO_BRANCH"
    else
        # Create local branch tracking origin/REPO_BRANCH
        echo -e "${INFO_T2}Branch doesn't exist locally, checking it out... ${RESET}"
        git checkout -B "$REPO_BRANCH" "origin/$REPO_BRANCH"
    fi

    # Hard reset to match remote exactly
    git reset --hard "origin/$REPO_BRANCH"
    git pull origin $REPO_BRANCH

    # Fetch latest commits and reset the working directory to match the remote
    #git fetch origin
    #git checkout "$REPO_BRANCH"
    #git reset --hard "origin/$REPO_BRANCH"
    #git pull origin $REPO_BRANCH

    cd ..
else
    # If it doesn't exist at all yet, clone it
    echo -e "${INFO_T2}Cloning repo... ${RESET}"
    git clone -b $REPO_BRANCH $REPO_URL
fi

# --------------------------------------------------------------------------------
# Download files from the GCS bucket (right now we just need the LLM model file)
# --------------------------------------------------------------------------------
echo -e "${INFO_T1}Downloading files from the GCS bucket... ${RESET}"

# Check if this has already been done by checking for one of the files
if [ ! -f "$MDL_DIR/new_LSA.csv" ]; then
    mkdir -p "$DPL_DIR"
    gsutil -m cp -r "$GCS_BUCKET/deployment-files/*" "$DPL_DIR/"
else
    echo -e "${GREEN}Deployment files already exist locally, skipping download. ${RESET}"
fi

# Make a logs folder in deployment-files for persistence
mkdir -p "$LOG_DIR"


# --------------------------------------------------------------------------------
# Copy Deployment Files (.env, models)
# --------------------------------------------------------------------------------
echo -e "${INFO_T1}Copy deployment files into the repository (.env, models)...${RESET}"

# Copy "new_LSA.csv" for ... ?
echo -e "${INFO_T3}  cp    $MDL_DIR/new_LSA.csv  $BIO_DIR/new_LSA.csv ${RESET}"
cp "$MDL_DIR/new_LSA.csv"                       "$BIO_DIR/new_LSA.csv"
cp "$MDL_DIR/stanford-parser-4.2.0-models.jar"  "$BIO_DIR/stanford-parser-full-2020-11-17/stanford-parser-4.2.0-models.jar"

# Google keys
echo -e "${INFO_T3}  cp -f $DPL_DIR/google-stt-key.json  $GSK_DIR/google-stt-key.json ${RESET}"
cp -f "$DPL_DIR/google-stt-key.json" "$GSK_DIR/google-stt-key.json"
