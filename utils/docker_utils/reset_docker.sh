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

    # Find old containers by Compose project name (the repo folder's name), so this still
    # works after the repo folder was deleted (`down` keeps named volumes and their data)
    # Use the app's Compose file when available; a new VM has no app checkout yet.
    # `down` keeps named volumes and their data.
    if [ -f "$APP_DIR/docker-compose.yaml" ]; then
        echo -e "Bringing down existing containers in ${INFO_T3}${REPO_NAME}${RESET}..."
        COMPOSE_FILES=(-f "$APP_DIR/docker-compose.yaml")
        if [ -f "$DATABASE_IMAGE_OVERRIDE" ]; then
            COMPOSE_FILES+=(-f "$DATABASE_IMAGE_OVERRIDE")
        fi
        sudo docker compose -p "$REPO_NAME" "${COMPOSE_FILES[@]}" down
    else
        echo "No existing app Compose file; skipping container teardown."
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
