# ================================================================================
# Clone/Pull Repo & Download deployment files from GCS Bucket
# ================================================================================
# a) Clones/pulls the target repository/branch for the main app.
# b) Downloads any missing files required for deployment from the GCS bucket & 
#    copies those files into their correct places within the app repository.
echo -e "${PROG_HR_1}"
echo -e "${PROG_TEXT}4. Pulling project repo & Downloading 'deployment-files' from GCS Bucket... ${RESET}"
echo -e "${PROG_HR_2}"

echo -e "download_files.sh current working directory: $(pwd)"

# --------------------------------------------------------------------------------
# a) Clone or pull from the main app repository
# --------------------------------------------------------------------------------
echo -e "${INFO_T1}Clone or update the repository... ${RESET}"

# Check if the repository directory already exists
if [ -d "$APP_DIR" ]; then
    # If it already exists, pull from the given origin branch
    echo -e "${INFO_T2}Repo exists (${INFO_T0}${GITHUB_USER}/${REPO_NAME}/${REPO_BRANCH}${RESET}${INFO_T2}), pulling latest changes... ${RESET}"
    cd "$APP_DIR"
    echo -e "cd'ed into ${APP_DIR}; new current working directory: $(pwd)"

    # Fetch latest remote state
    #git fetch origin --prune

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

# Make a logs folder in deployment-files for persistence (I don't think this gets used anymore...)
mkdir -p "$LOG_DIR"

# ================================================================================
# b) Download files from the GCS bucket
# ================================================================================
echo -e "\n${PROG_TEXT}Downloading files from the GCS bucket... ${RESET}"

# Optional flag from the .env for skipping model redownload
SKIP_MODEL_REDOWNLOAD="${SKIP_MODEL_REDOWNLOAD:-false}"
echo -e "${INFO_T0}SKIP_MODEL_REDOWNLOAD = ${SKIP_MODEL_REDOWNLOAD}${RESET}\n"

# Creating the GCS download destination directories
mkdir -p "$DPL_DIR" "$MDL_DIR"

# --------------------------------------------------------------------------------
# Google Speech-to-Text key (always download)
# --------------------------------------------------------------------------------
# Download from GCS bucket
echo -e "${INFO_T1}Downloading Google Speech-to-Text key... ${RESET}"
gsutil cp "$GCS_BUCKET/deployment-files/google-stt-key.json" "$DPL_DIR/"

# Copy into the repository
echo -e "${INFO_T3}  cp -f $DPL_DIR/google-stt-key.json  ->  $GSK_DIR/google-stt-key.json ${RESET}"
cp -f "$DPL_DIR/google-stt-key.json" "$GSK_DIR/google-stt-key.json"


# --------------------------------------------------------------------------------
# MiniLM-L6-v2 RAG embedding model
# --------------------------------------------------------------------------------
if [ -f "$MDL_DIR/MiniLM-L6-v2/config.json" ] && [ "$SKIP_MODEL_REDOWNLOAD" = "true" ]; then
    echo -e "${INFO_T2}Skipping MiniLM-L6-v2: already staged and SKIP_MODEL_REDOWNLOAD=true ${RESET}"
else
    # Download from GCS bucket
    echo -e "${INFO_T1}Downloading MiniLM-L6-v2 RAG embedding model... ${RESET}"
    gsutil -m cp -r "$GCS_BUCKET/deployment-files/models/MiniLM-L6-v2" "$MDL_DIR/"

    # Copy into the repository
    echo -e "${INFO_T2}Copying MiniLM-L6-v2 into the repo... ${RESET}"
    mkdir -p "$APP_DIR/backend/rag_vectorstore/models"
    cp -r "$MDL_DIR/MiniLM-L6-v2" "$APP_DIR/backend/rag_vectorstore/models/"
fi

# --------------------------------------------------------------------------------
# "Prosody" biomarker models
# --------------------------------------------------------------------------------
if [ -f "$MDL_DIR/prosody/fold_0_train_preds.npy" ] && [ "$SKIP_MODEL_REDOWNLOAD" = "true" ]; then
    echo -e "${INFO_T2}Skipping prosody: already staged and SKIP_MODEL_REDOWNLOAD=true ${RESET}"
else
    # Download from GCS bucket
    echo -e "${INFO_T1}Downloading prosody biomarker models... ${RESET}"
    gsutil -m cp -r "$GCS_BUCKET/deployment-files/models/prosody" "$MDL_DIR/"
    mkdir -p "$BIO_DIR/prosody"

    # Copy into the repository
    echo -e "${INFO_T2}Copying prosody models into the repo... ${RESET}"
    echo -e "${INFO_T3}  cp -r $MDL_DIR/prosody/.  ->  $BIO_DIR/prosody/ ${RESET}"
    cp -r "$MDL_DIR/prosody/." "$BIO_DIR/prosody/"
fi

# --------------------------------------------------------------------------------
# "Altered Grammar" biomarker models
# --------------------------------------------------------------------------------
if [ -f "$MDL_DIR/altered_grammar/fold_0_train_preds.npy" ] && [ "$SKIP_MODEL_REDOWNLOAD" = "true" ]; then
    echo -e "${INFO_T2}Skipping altered_grammar: already staged and SKIP_MODEL_REDOWNLOAD=true ${RESET}"
else
    # Download from GCS bucket
    echo -e "${INFO_T1}Downloading altered_grammar biomarker models... ${RESET}"
    gsutil -m cp -r "$GCS_BUCKET/deployment-files/models/altered_grammar" "$MDL_DIR/"
    mkdir -p "$BIO_DIR/altered_grammar"

    # Copy into the repository
    echo -e "${INFO_T2}Copying altered_grammar models into the repo... ${RESET}"
    echo -e "${INFO_T3}  cp -r $MDL_DIR/altered_grammar/.  ->  $BIO_DIR/altered_grammar/ ${RESET}"
    cp -r "$MDL_DIR/altered_grammar/." "$BIO_DIR/altered_grammar/"
fi


# ================================================================================
# Offline sample/demo data
# ================================================================================
# Re-usable function
# TODO: Maybe I should just move it rather than copying? Kind of wastes memory to have it in two places...
copy_seed_data() {
    local source_dir="$1"
    local target_dir="$2"

    # Execute the echo and the copy command
    echo -e "${INFO_T3} cp -r $source_dir/. -> $target_dir/ ${RESET}"
    cp -r "$source_dir/." "$target_dir/"
}

# --------------------------------------------------------------------------------
# Check if we should do the download
# --------------------------------------------------------------------------------
if [ -f "$SEED_DIR/test_03/IU_03.csv" ] && [ "$SKIP_SEED_DATA_REDOWNLOAD" = "true" ]; then
    echo -e "${INFO_T2}Skipping seed data download: already downloaded and SKIP_SEED_DATA_REDOWNLOAD=true ${RESET}"
else
    # Download from GCS bucket
    echo -e "${INFO_T1}Downloading seed data... ${RESET}"
    gsutil -m cp -r "$GCS_BUCKET/deployment-files/demo_data" "$SEED_GCS/"

    # --------------------------------------------------------------------------------
    # Copy into the repository (4 times currently; once for each chat)
    # --------------------------------------------------------------------------------
    echo -e "${INFO_T2}Copying demo data into the repo... ${RESET}"

    # Copy the seed data into the proper location for each chat
    copy_seed_data "$SEED_GCS/test_02" "$SEED_DIR/test_02"
    copy_seed_data "$SEED_GCS/test_03" "$SEED_DIR/test_03"
    copy_seed_data "$SEED_GCS/test_04" "$SEED_DIR/test_04"
    copy_seed_data "$SEED_GCS/test_05" "$SEED_DIR/test_05"

fi