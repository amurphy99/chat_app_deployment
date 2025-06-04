STEP_NUM=6 #"${1:-6}"
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

# We could cd into the repo directory earlier here and save a few lines...
echo "APP_ENVIRONMENT=${APP_ENVIRONMENT}" > "$REPO_NAME/.env.deploy"
echo "BACKEND_DOCKERFILE=${BACKEND_DOCKERFILE}" >> "$REPO_NAME/.env.deploy"
echo "DEV_APP_ROUTE=${DEV_APP_ROUTE}" >> "$REPO_NAME/.env.deploy"
echo "LLM_COMPOSE_FILE=${LLM_COMPOSE_FILE}" >> "$REPO_NAME/.env.deploy"

# Check that the new .env.deploy file got properly created
ls -a "$REPO_NAME"


# --------------------------------------------------------------------
# Launch docker compose in headless mode
# --------------------------------------------------------------------
echo -e "${INFO_T1}Launch docker compose in headless mode...${RESET}"

# Adding "-d" to the end puts it in headless mode (sudo docker-compose up --build -d)
cd "$REPO_NAME"
export BACKEND_DOCKERFILE="$BACKEND_DOCKERFILE"
#sudo --preserve-env=BACKEND_DOCKERFILE --gpus all docker-compose up --build -d
#sudo docker compose up --gpus all --build -d
#sudo docker compose --profile gpu up --build -d

echo -e "\n"
ls -lah .
echo -e "\n"
ls -lah ..
echo -e "\n"
ls -lah ../deployment-files
echo -e "\n"
ls -lah ../deployment-files/models
echo -e "\n"

sudo --preserve-env=BACKEND_DOCKERFILE docker compose up --build -d
