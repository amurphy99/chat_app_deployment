#!/bin/bash
set -Eeuo pipefail

# ================================================================================
# Final Environmental Variable Setup
# ================================================================================
# Specify if this should be for the "deployment" or "sandbox" instance
# bash deploy.sh --env=sandbox
echo -e "env_config.sh current working directory: $(pwd)"


# CPU/GPU behavior used to depend on ENV or APP_ENVIRONMENT, hardcoding it here for now instead
VM_TYPE="CPU"

# --------------------------------------------------------------------------------
# Domains & Nginx configuration files stem from here
# --------------------------------------------------------------------------------
# Setup .env file used to configure multiple sandboxes (e.g. "sandbox.cognibot.org", "sandbox2.cognibot.org", etc.)
TARGET_PREFIX="${TARGET_PREFIX:-sandbox}"

# Sandbox
if [ "$ENV" = "sandbox" ]; then
    DOMAIN="${TARGET_PREFIX}.cognibot.org"
    DOMAIN_WWW="www.${TARGET_PREFIX}.cognibot.org"
    NGINX_CONF="nginx/default.conf.sandbox"
    APP_ENVIRONMENT="sandbox"

# Deployment
else
    DOMAIN="cognibot.org"
    DOMAIN_WWW="www.cognibot.org"
    NGINX_CONF="nginx/default.conf"
    APP_ENVIRONMENT="deployment"
fi

# --------------------------------------------------------------------------------
# Project Repository .env file variables
# --------------------------------------------------------------------------------
# Frontend
VITE_RUN_ENV="PROD"
DEV_APP_ROUTE=""                    # "" Empty string for deployment mode
CERT_EMAIL="amurphy62299@gmail.com"

# Whether or not to use the LLM GPU container or a dummy
if [ "$APP_ENVIRONMENT" = "sandbox" ]; then
    CONF_FILE="default.conf.sandbox"
else
    CONF_FILE="default.conf"
fi

# --------------------------------------------------------------------------------
# Basic Config
# --------------------------------------------------------------------------------
PRJ_DIR="$HOME"
APP_DIR="$PRJ_DIR/$REPO_NAME"

# Main app repository stuff (repo with frontend, backend, & database)
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git" 

# Location of the external files to download 
GCS_BUCKET="gs://v2-deployment-files"

# Deployment Files (from GCS bucket)
DPL_DIR="$PRJ_DIR/deployment-files"
MDL_DIR="$DPL_DIR/models"
LOG_DIR="$DPL_DIR/logs"

# Final location for the model files when inside the app repo
BIO_DIR="$REPO_NAME/backend/chat_app/websocket/biomarkers/biomarker_models"

# Final location for the Google Speech Key
GSK_DIR="$REPO_NAME/backend"

# --------------------------------------------------------------------------------
# Echo the environment setup
# --------------------------------------------------------------------------------
echo -e "${INFO_T0}ENV                = ${ENV}                  ${RESET}"
echo -e "${INFO_T0}APP_ENVIRONMENT    = ${APP_ENVIRONMENT}      ${RESET}\n"

echo -e "${INFO_T0}DOMAIN             = ${DOMAIN}               ${RESET}"
echo -e "${INFO_T0}DOMAIN_WWW         = ${DOMAIN_WWW}           ${RESET}"
echo -e "${INFO_T0}NGINX_CONF         = ${NGINX_CONF}           ${RESET}\n"

echo -e "${INFO_T0}PRJ_DIR            = ${PRJ_DIR}              ${RESET}"
echo -e "${INFO_T0}SETUP_REPO_BRANCH  = ${SETUP_REPO_BRANCH}    ${RESET}"
echo -e "${INFO_T0}SETUP_REPO_DIR     = ${SETUP_REPO_DIR}       ${RESET}"
echo -e "${INFO_T0}UTILS_DIR          = ${UTILS_DIR}            ${RESET}"
echo -e "${INFO_T0}SETUP_PRJ_DIR      = ${SETUP_PRJ_DIR}        ${RESET}\n"

echo -e "${INFO_T0}REPO_NAME          = ${REPO_NAME}            ${RESET}"
echo -e "${INFO_T0}REPO_BRANCH        = ${REPO_BRANCH}          ${RESET}\n"

echo -e "${INFO_T0}DPL_DIR            = ${DPL_DIR}              ${RESET}"
echo -e "${INFO_T0}MDL_DIR            = ${MDL_DIR}              ${RESET}"
echo -e "${INFO_T0}LOG_DIR            = ${LOG_DIR}              ${RESET}"
echo -e "${INFO_T0}GSK_DIR            = ${GSK_DIR}              ${RESET}"
