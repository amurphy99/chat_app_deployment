#!/bin/bash
set -Eeuo pipefail

# ================================================================================
# Final Environmental Variable Setup
# ================================================================================
echo -e "env_config.sh current working directory: $(pwd)"

# --------------------------------------------------------------------------------
# Domains & Nginx configuration files stem from here
# --------------------------------------------------------------------------------
# Resolve the deployment target (is this the "main" deployment or a "sandbox"?),
# and apply the namespace prefix here. Prefixes are used to configure multiple
# sandboxes (e.g. "sandbox.cognibot.org", "sandbox2.cognibot.org", etc.).

# From the uploaded `.env` file
TARGET_PREFIX="${TARGET_PREFIX:-sandbox}"

# Sandbox
if [ "$DEPLOYMENT_TARGET" = "sandbox" ]; then
    DOMAIN="${TARGET_PREFIX}.cognibot.org"
    DOMAIN_WWW="www.${TARGET_PREFIX}.cognibot.org"
    AUDIO_INSTANCE_PREFIX="${TARGET_PREFIX}"

# Main (ignores `TARGET_PREFIX`)
elif [ "$DEPLOYMENT_TARGET" = "main" ]; then
    DOMAIN="cognibot.org"
    DOMAIN_WWW="www.cognibot.org"
    AUDIO_INSTANCE_PREFIX="main"

else
    echo -e "${RED}ERROR: DEPLOYMENT_TARGET='$DEPLOYMENT_TARGET' is not supported (expected sandbox or main)${RESET}" >&2
    exit 1
fi

# --------------------------------------------------------------------------------
# Database connection defaults
# --------------------------------------------------------------------------------
# Containers reach local Compose databases through their service names
__POSTGRES_HOST="${__POSTGRES_HOST:-db}"
__POSTGRES_PORT="${__POSTGRES_PORT:-5432}"
__VECTOR_DB_HOST="${__VECTOR_DB_HOST:-db_vector}"
__VECTOR_DB_PORT="${__VECTOR_DB_PORT:-5432}"

# ================================================================================
# Directory/Filepath Configs
# ================================================================================
# Overall directories
PRJ_DIR="$HOME"
APP_DIR="$PRJ_DIR/$REPO_NAME"

# Main app repository stuff (repo with frontend, backend, & database)
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git" 

# --------------------------------------------------------------------------------
# Deployment Files (downloaded from GCS bucket)
# --------------------------------------------------------------------------------
# Includes: ML models, demo data (from real chats), others...

# 1) GCS bucket URL & local directory the files get downloaded to
GCS_BUCKET="gs://v2-deployment-files"
DPL_DIR="$PRJ_DIR/deployment-files"

# 2) Machine learning Model files 
#    Location within local GCS download & where to copy them to within the project
MDL_DIR="$DPL_DIR/models"
BIO_DIR="$REPO_NAME/backend/chat_app/websocket/biomarkers/models"

# 3) Seed data
#    Location of the data within the local GCS download & within the project
SEED_GCS="$DPL_DIR/demo_data"
SEED_DIR="$REPO_NAME/backend/chat_app/management/seed_data/transcript_data/test_transcripts"

# 4) Credentials
#    Final location for the Google Speech Key (used for STT & TTS)
GSK_DIR="$REPO_NAME/backend"

# 5) Misc. 
#    TODO: I don't remember if the "logs" directory is actually used anywhere...
LOG_DIR="$DPL_DIR/logs"


# ================================================================================
# Echo the environment setup
# ================================================================================
echo -e "${INFO_T0}DEPLOYMENT_TARGET  = ${DEPLOYMENT_TARGET}    ${RESET}"
echo -e "${INFO_T0}TARGET_PREFIX      = ${TARGET_PREFIX}        ${RESET}\n"

echo -e "${INFO_T0}DOMAIN             = ${DOMAIN}               ${RESET}"
echo -e "${INFO_T0}DOMAIN_WWW         = ${DOMAIN_WWW}           ${RESET}"
echo -e "${INFO_T0}AUDIO PREFIX       = ${AUDIO_INSTANCE_PREFIX}/${SESSION_AUDIO_OBJECT_PREFIX} ${RESET}\n"

echo -e "${INFO_T0}PRJ_DIR            = ${PRJ_DIR}              ${RESET}"
echo -e "${INFO_T0}SETUP_REPO_BRANCH  = ${SETUP_REPO_BRANCH}    ${RESET}"
echo -e "${INFO_T0}SETUP_REPO_DIR     = ${SETUP_REPO_DIR}       ${RESET}"
echo -e "${INFO_T0}UTILS_DIR          = ${UTILS_DIR}            ${RESET}"
echo -e "${INFO_T0}SETUP_PRJ_DIR      = ${SETUP_PRJ_DIR}        ${RESET}\n"

echo -e "${INFO_T0}REPO_NAME          = ${REPO_NAME}            ${RESET}"
echo -e "${INFO_T0}REPO_BRANCH        = ${REPO_BRANCH}          ${RESET}\n"

# Locally downloaded GCS bucket data
echo -e "${INFO_T0}DPL_DIR            = ${DPL_DIR}              ${RESET}"

# Machine learning models
echo -e "${INFO_T0}MDL_DIR            = ${MDL_DIR}              ${RESET}"
echo -e "${INFO_T0}BIO_DIR            = ${BIO_DIR}              ${RESET}"

# Seed data
echo -e "${INFO_T0}SEED_GCS           = ${SEED_GCS}             ${RESET}"
echo -e "${INFO_T0}SEED_DIR           = ${SEED_DIR}             ${RESET}"

# Credentials/misc.
echo -e "${INFO_T0}GSK_DIR            = ${GSK_DIR}              ${RESET}"
echo -e "${INFO_T0}LOG_DIR            = ${LOG_DIR}              ${RESET}"
