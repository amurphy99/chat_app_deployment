STEP_NUM=0 #"${1:-0}"

# ====================================================================
# Clear old Docker stuff (optional safety)
# ====================================================================
echo -e "$PROG_HR_1"
echo -e "${PROG_TEXT}${STEP_NUM}. Stopping and removing any existing Docker containers...${RESET}"
echo -e "$PROG_HR_2"


# Check if Docker is actually installed first
if ! command -v docker &>/dev/null; then
    echo -e "${GREEN}Docker not installed yet, nothing to clean up...${RESET}"
else
    #sudo docker-compose -f "$REPO_NAME/docker-compose.yaml" down || true
    echo -e "${CYAN}Pruning unused Docker resources...${RESET}"
    #sudo docker system prune -af --volumes=false || true
    
    echo "Pruning exited containers..."
    sudo docker container prune -f

    echo "Pruning dangling images..."
    sudo docker image prune -f

fi

