#!/bin/bash
set -e

# ================================================================================
# Run each setup file & start the project containers
# ================================================================================
echo " "
echo -e "Current working directory: $(pwd)"

# Get the directory this script is in
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
echo -e "Script is located at: ${SCRIPT_DIR}"

# Go one level up 
cd "${SCRIPT_DIR}/.."
echo -e "Now running from: $(pwd)"

# Define path to the utils directory
UTILS_DIR="$SCRIPT_DIR/utils"
echo -e "Looking for logging helpers in: ${UTILS_DIR}"

# Load logging helpers
source "${UTILS_DIR}/logging.sh"
echo -e " "

# --------------------------------------------------------------------------------
# Final environment variable setup before starting
# --------------------------------------------------------------------------------
# First console output
echo -e "${BOLD_BLUE}${HR_2}${RESET}"
echo -e "${BOLD_BLUE}Starting Deployment of Speech System... ${RESET}"
echo -e "${BOLD_BLUE}${HR_2}${RESET}"

# This also does the basic config with the GCS bucket, local directories, etc...
source "${UTILS_DIR}/env_config.sh" "$@" 

# --------------------------------------------------------------------------------
# Setup Steps
# --------------------------------------------------------------------------------
# 1) Reset Docker (if installed) & Setup Docker (if not installed)
source "${UTILS_DIR}/docker_utils/reset_docker.sh"
source "${UTILS_DIR}/docker_utils/install_docker.sh"

# 2) NVIDIA Setup (GPU Drivers, Container Toolkit) -- never actually fires, just leaving it in for now though
source "${UTILS_DIR}/nvidia_gpu_setup.sh"

# 3) ---- I might want to do a new nginx setup here... ----

# 4) Pull from project repo & download from GCS bucket
source "${UTILS_DIR}/download_files.sh"

# 5) More detailed .env configuration 
source "${UTILS_DIR}/project_env.sh"

# 6) Launch docker compose in headless mode
source "${UTILS_DIR}/launch_containers.sh"

# --------------------------------------------------------------------------------
# Deployment Complete
# --------------------------------------------------------------------------------
# Print the target URLs
echo -e " "
echo -e "${INFO_T0}Domain:     $DOMAIN     ${RESET}"
echo -e "${INFO_T0}Domain WWW: $DOMAIN_WWW ${RESET}"

# Final message
echo -e " "
echo -e "${BOLD_GREE}$HR_2${RESET}"
echo -e "${BOLD_GREE} Deployment complete! Visit: https://$DOMAIN ${RESET}"
echo -e "${BOLD_GREE}$HR_2${RESET}\n"
