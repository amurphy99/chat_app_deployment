#!/bin/bash
set -e

# ====================================================================
# Initial Setup
# ====================================================================
echo "Current working directory: $(pwd)"

# Get the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Script is located at: $SCRIPT_DIR"

# Go one level up 
cd "$SCRIPT_DIR/.."
echo "Now running from: $(pwd)"

# Define path to the utils directory
UTILS_DIR="$SCRIPT_DIR/utils"
echo "Looking for logging helpers in: $UTILS_DIR"

# Load logging helpers
source "$UTILS_DIR/logging.sh"

# First console output
echo -e "${BOLD_BLUE}$HR_2${RESET}"
echo -e "${BOLD_BLUE} Starting Deployment of Speech System... ${RESET}"
echo -e "${BOLD_BLUE}$HR_2${RESET}"

# --------------------------------------------------------------------
# Check "secret" keys set in the startup script
# --------------------------------------------------------------------
echo -e "${INFO_T0}SPEECH_KEY        = $__SPEECH_KEY ${RESET}"
echo -e "${INFO_T0}POSTGRES_USER     = $__POSTGRES_USER ${RESET}"
echo -e "${INFO_T0}POSTGRES_PASSWORD = $__POSTGRES_PASSWORD ${RESET}"
echo -e "${HR_1}"

# --------------------------------------------------------------------
# Load env config logic and pass args along
# --------------------------------------------------------------------
# This also does the basic config with github, log directories, etc...
source "$UTILS_DIR/env_config.sh" "$@" 

# Echo the environment setup
echo -e "${INFO_T0}ENV             = $ENV             ${RESET}"
echo -e "${INFO_T0}DOMAIN          = $DOMAIN          ${RESET}"
echo -e "${INFO_T0}DOMAIN_WWW      = $DOMAIN_WWW      ${RESET}"
echo -e "${INFO_T0}NGINX_CONF      = $NGINX_CONF      ${RESET}"
echo -e "${INFO_T0}APP_ENVIRONMENT = $APP_ENVIRONMENT ${RESET}"


# ====================================================================
# Setup Steps
# ====================================================================
# 1) Install Docker (Engine + Compose V2 Plugin)
#source "$UTILS_DIR/docker_utils/reset_docker.sh" --step_num=0
source "$UTILS_DIR/docker_utils/install_docker.sh" --step_num=1

# 2) NVIDIA Setup (GPU Drivers, Container Toolkit)
source "$UTILS_DIR/nvidia_gpu_setup.sh" --step_num=2

# 3) Install System Dependencies (Git, Nginx, Certbot)
source "$UTILS_DIR/install_dependencies.sh" --step_num=3

# 4) Clone/Pull Repo & Download deployment files from GCS Bucket
source "$UTILS_DIR/download_files.sh" --step_num=4

# 4a) Configure project environment variables
source "$UTILS_DIR/project_env.sh" 

# 5) Launch docker compose in headless mode
source "$UTILS_DIR/launch_containers.sh" --step_num=5



# Print the target URLs
echo -e "${INFO_T0}Domain:     $DOMAIN     ${RESET}"
echo -e "${INFO_T0}Domain WWW: $DOMAIN_WWW ${RESET}"


# ====================================================================
# Done
# ====================================================================
echo -e "\n${GREEN}$HR_2${RESET}"
echo -e "${GREEN} Deployment complete! Visit: https://$DOMAIN ${RESET}"
echo -e "${GREEN}$HR_2${RESET}\n"

