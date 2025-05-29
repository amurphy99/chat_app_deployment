STEP_NUM=4 #"${1:-4}"
# ====================================================================
# Clone/Pull Repo & Download deployment files from GCS Bucket
# ====================================================================
echo -e "$PROG_HR_1"
echo -e "${PROG_TEXT}${STEP_NUM}. Cloning Repo & Downloading deployment-files from GCS Bucket... ${RESET}"
echo -e "$PROG_HR_2"
echo "download_files.sh current working directory: $(pwd)"

# --------------------------------------------------------------------
# a) Clone or pull from the main app repository
# --------------------------------------------------------------------
echo -e "${INFO_T1}Clone or update the repository...${RESET}"

# Check if the repository directory already exists
# ---- some of this stuff might need to happen in different directories, 
# ---- but we will cross that bridge when we come to it i guess... ----
if [ -d "$REPO_NAME" ]; then
    # If it already exists, pull from the given origin branch
    echo -e "${INFO_T2}Repo exists, pulling latest changes...${RESET}"
    cd "$REPO_NAME"
    git checkout $REPO_BRANCH
    git pull origin $REPO_BRANCH
    cd ..
else
    # If it doesn't exist at all yet, clone it
    echo -e "${INFO_T2}Cloning repo...${RESET}"
    git clone -b $REPO_BRANCH $REPO_URL
fi

# --------------------------------------------------------------------
# b) Download files from the GCS bucket
# --------------------------------------------------------------------
echo -e "${INFO_T1}Download files from the GCS bucket...${RESET}"

# Check if this has already been done by checking for an .env file
#if [ ! -f "$DPL_DIR/.env" ]; then
if [ ! -f "$MDL_DIR/new_LSA.csv" ]; then
    mkdir -p "$DPL_DIR"
    gsutil -m cp -r "$GCS_BUCKET/deployment-files/*" "$DPL_DIR/"
else
    echo -e "${GREEN}Deployment files already exist locally, skipping download${RESET}"
fi

# Make a logs folder in deployment-files for persistence
mkdir -p "$LOG_DIR"

# --------------------------------------------------------------------
# c) Copy Deployment Files (.env, models)
# --------------------------------------------------------------------
echo -e "${INFO_T1}Copy deployment files into the repository (.env, models)...${RESET}"

# Copy .env into the repo
echo -e "${INFO_T2}Copying .env into the repo...${RESET}"
cp "$DPL_DIR/.env" "$REPO_NAME/.env"

# Copy model files into the repo
echo -e "${INFO_T2}Copying model files into the repo...${RESET}"
cp "$MDL_DIR/new_LSA.csv"                      "$BIO_DIR/new_LSA.csv"
cp "$MDL_DIR/stanford-parser-4.2.0-models.jar" "$BIO_DIR/stanford-parser-full-2020-11-17/stanford-parser-4.2.0-models.jar"



# ---- This goes somewhere else now ----
#cp "$MDL_DIR/Phi-3_finetuned.gguf"             "$REPO_NAME/backend/chat_app/services/Phi-3_finetuned.gguf"

