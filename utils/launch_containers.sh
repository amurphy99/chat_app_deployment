STEP_NUM=5 
# ====================================================================
# Launch Containers
# ====================================================================
echo -e "$PROG_HR_1"
echo -e "${PROG_TEXT}${STEP_NUM}. Starting Docker Compose in headless mode... ${RESET}"
echo -e "$PROG_HR_2"
echo "launch_containers.sh current working directory: $(pwd)"


# --------------------------------------------------------------------
# a) Export Environment Variables
# --------------------------------------------------------------------
echo -e "${INFO_T1}Export some extra environment variables...${RESET}"

# Define some new environment variables
DEV_APP_ROUTE="" # "" Empty string for deployment mode

# Whether or not to use the LLM GPU container or a dummy
if [ "$APP_ENVIRONMENT" = "sandbox" ]; then
    LLM_COMPOSE_FILE="llama_api/dummy-compose.yaml"
else
    LLM_COMPOSE_FILE="llama_api/compose.yaml"
fi

# Check that the new .env.deploy file got properly created
ls -a "$REPO_NAME"


# --------------------------------------------------------------------
# Launch docker compose in headless mode
# --------------------------------------------------------------------
echo -e "${INFO_T1}Launch docker compose in headless mode...${RESET}"

# Adding "-d" to the end puts it in headless mode (sudo docker-compose up --build -d)
cd "$REPO_NAME"


echo -e "\n"
ls -lah .
echo -e "\n"
ls -lah ..
echo -e "\n"
ls -lah ../deployment-files
echo -e "\n"
ls -lah ../deployment-files/models
echo -e "\n"

sudo --preserve-env=LLM_COMPOSE_FILE docker compose up --build -d
