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
    echo -e "${INFO_T2}Repo exists (${INFO_T0}${GITHUB_USER}/${REPO_NAME}/${REPO_BRANCH}${RESET}), pulling latest changes... ${RESET}"
    cd "$APP_DIR"
    echo -e "cd'ed into ${APP_DIR}; new current working directory: $(pwd)"

    # Fetch latest remote state
    #git fetch origin --prune

    # If the local branch exists, switch to it; otherwise create it from origin
    #if git rev-parse --verify "$REPO_BRANCH" >/dev/null 2>&1; then
    #    # Branch already exists locally
    #    echo -e "${INFO_T2}Branch exists locally, switching or checking it out... ${RESET}"
    #    git switch "$REPO_BRANCH" || git checkout "$REPO_BRANCH"
    #else
    #    # Create local branch tracking origin/REPO_BRANCH
    #    echo -e "${INFO_T2}Branch doesn't exist locally, checking it out... ${RESET}"
    #    git checkout -B "$REPO_BRANCH" "origin/$REPO_BRANCH"
    #fi

    # Hard reset to match remote exactly
    #git reset --hard "origin/$REPO_BRANCH"
    #git pull origin $REPO_BRANCH

    # Fetch latest commits and reset the working directory to match the remote
    git fetch origin
    git checkout "$REPO_BRANCH"
    #git reset --hard "origin/$REPO_BRANCH"
    git pull --ff-only origin "$REPO_BRANCH"

    cd ..
else
    # If it doesn't exist at all yet, clone it
    echo -e "${INFO_T2}Cloning repo: ${INFO_T0}${GITHUB_USER}/${REPO_NAME}/${REPO_BRANCH} ${RESET}"
    git clone -b $REPO_BRANCH $REPO_URL
fi

# --------------------------------------------------------------------------------
# Download files from the GCS bucket (right now we just need the LLM model file)
# --------------------------------------------------------------------------------
echo -e "\n${PROG_TEXT}Downloading files from the GCS bucket... ${RESET}"

# Only download if not already present
if [ ! -f "$MDL_DIR/new_LSA.csv" ]; then
    mkdir -p "$DPL_DIR" "$MDL_DIR" "$GSK_DIR"

    # Download only the files we need
    gsutil -m cp \
        "$GCS_BUCKET/deployment-files/models/new_LSA.csv" \
        "$GCS_BUCKET/deployment-files/models/stanford-parser-4.2.0-models.jar" \
        "$GCS_BUCKET/deployment-files/google-stt-key.json" \
        "$DPL_DIR/"

    # Put new_LSA + parser jar specifically under $MDL_DIR
    mv "$DPL_DIR/new_LSA.csv"                      "$MDL_DIR/new_LSA.csv"
    mv "$DPL_DIR/stanford-parser-4.2.0-models.jar" "$MDL_DIR/stanford-parser-4.2.0-models.jar"

else
    echo -e "${GREEN}Deployment files already exist locally, skipping download. ${RESET}"
fi

# Make a logs folder in deployment-files for persistence
mkdir -p "$LOG_DIR"

# --------------------------------------------------------------------------------
# Copy Deployment Files (.env, models)
# --------------------------------------------------------------------------------
echo -e "${INFO_T1}Copy deployment files into the repository (.env, models)... ${RESET}"

# Copy "new_LSA.csv" for ... ?
echo -e "${INFO_T3}  cp    $MDL_DIR/new_LSA.csv                        $BIO_DIR/new_LSA.csv                      ${RESET}"
echo -e "${INFO_T3}  cp    $MDL_DIR/stanford-parser-4.2.0-models.jar   $BIO_DIR/stanford-parser-4.2.0-models.jar ${RESET}"

cp "$MDL_DIR/new_LSA.csv"                       "$BIO_DIR/new_LSA.csv"
cp "$MDL_DIR/stanford-parser-4.2.0-models.jar"  "$BIO_DIR/stanford-parser-full-2020-11-17/stanford-parser-4.2.0-models.jar"

# copy the RAG embedding model into the repo
echo -e "${INFO_T3}Copying the RAG Embedding model into the repo...${RESET}"
mkdir -p "$APP_DIR/backend/rag_vectorstore/models"
cp -r "$MDL_DIR/MiniLM-L6-v2" "$APP_DIR/backend/rag_vectorstore/models"


# Google keys
echo -e "${INFO_T3}  cp -f $DPL_DIR/google-stt-key.json  $GSK_DIR/google-stt-key.json ${RESET}"
cp -f "$DPL_DIR/google-stt-key.json" "$GSK_DIR/google-stt-key.json"
