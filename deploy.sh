#!/bin/bash
set -e

# ====================================================================
# Initial Setup
# ====================================================================
# Get path to the base directory (chat_app_deployment/../ = home/)
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UTILS_DIR="$SCRIPT_DIR/chat_app_deployment/utils"
echo "Current working directory: $(pwd)"

# Move up from chat_app_deployment to home
#cd "$(dirname "$0")"
#cd ..

# Define path to the shell utils directory
#SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
#UTILS_DIR="$SCRIPT_DIR/utils"

# Load logging helpers
source "$UTILS_DIR/logging.sh"

# First console output
echo -e "${BOLD_BLUE}$HR_2${RESET}"
echo -e "${BOLD_BLUE} Starting Deployment of Speech System... ${RESET}"
echo -e "${BOLD_BLUE}$HR_2${RESET}"

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

# 5) Configure Nginx & Run Certbot for HTTPS
source "$UTILS_DIR/nginx_cert_config.sh" --step_num=5

# 6) Launch docker compose in headless mode
source "$UTILS_DIR/launch_containers.sh" --step_num=6


# ====================================================================
# Done
# ====================================================================
echo -e "\n${GREEN}$HR_2${RESET}"
echo -e "${GREEN} Deployment complete! Visit: https://$DOMAIN ${RESET}"
echo -e "${GREEN}$HR_2${RESET}\n"

