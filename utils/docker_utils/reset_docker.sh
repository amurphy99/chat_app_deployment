# ================================================================================
# 1a) Clear old, unused Docker resources
# ================================================================================
# Right now the more serious commands are commented out, only clearing unused stuff
echo -e "${PROG_HR_1}"
echo -e "${PROG_TEXT}1a. Stopping and removing any existing Docker containers...${RESET}"
echo -e "${PROG_HR_2}"

# Check if Docker is actually installed first
if ! command -v docker &>/dev/null; then
    echo -e "${GREEN}Docker not installed yet, nothing to clean up...${RESET}"
else
    # --------------------------------------------------------------------------------
    # Shut down existing Docker containers from previous deployments
    # --------------------------------------------------------------------------------
    # This prevents old containers blocking ports needed for a new deployment
    echo -e "${INFO_T1}Shutting down for existing Docker resources...${RESET}"

    # Check if the `docker-compose` file exists yet (no need for this on the first install)
    if [ -f "$REPO_NAME/docker-compose.yaml" ]; then
        echo -e "Bringing down existing containers in ${INFO_T3}${REPO_NAME}${RESET}..."
        sudo docker compose -f "$REPO_NAME/docker-compose.yaml" down || true
    else
        echo -e "No existing ${INFO_T3}${REPO_NAME}/docker-compose.yaml${RESET} found, skipping container teardown..."
    fi

    # --------------------------------------------------------------------------------
    # Prune unused Docker resources (dangling containers and/or images)
    # --------------------------------------------------------------------------------
    echo -e "${INFO_T1}Pruning unused Docker resources...${RESET}"

    # Containers
    echo -e "Pruning exited containers..."
    sudo docker container prune -f

    # Images
    echo -e "Pruning dangling images..."
    sudo docker image prune -f
fi
