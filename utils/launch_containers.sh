STEP_NUM=6 #"${1:-6}"
# ====================================================================
# Launch Containers
# ====================================================================
echo -e "$PROG_HR_1"
echo -e "${PROG_TEXT}${STEP_NUM}. Starting Docker Compose in headless mode... ${RESET}"
echo -e "$PROG_HR_2"

# --------------------------------------------------------------------
# a) Export Environment Variables
# --------------------------------------------------------------------
echo -e "${INFO_T1}Export some extra environment variables...${RESET}"

# We could cd into the repo directory earlier here and save a few lines...
echo "APP_ENVIRONMENT=${APP_ENVIRONMENT}" > "$REPO_NAME/.env.deploy"
echo "BACKEND_DOCKERFILE=${BACKEND_DOCKERFILE}" >> "$REPO_NAME/.env.deploy"
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

ls -lah
ls -lah ../deployment-files/models

sudo --preserve-env=BACKEND_DOCKERFILE docker compose up --build -d
