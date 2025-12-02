# ================================================================================
# Launch Containers
# ================================================================================
echo -e "${PROG_HR_1}"
echo -e "${PROG_TEXT}6. Starting Docker Compose in headless mode... ${RESET}"
echo -e "${PROG_HR_2}"

echo "launch_containers.sh current working directory: $(pwd)"

# --------------------------------------------------------------------------------
# Export Environment Variables
# --------------------------------------------------------------------------------
echo -e "${INFO_T1}Export some extra environment variables... ${RESET}"

# Only keeping this here for if we want to pass a variable this way in the future
SAMPLE_VAR="SAMPLE_VAR"

# Check that the new .env.deploy file got properly created
ls -a "$REPO_NAME"

# --------------------------------------------------------------------------------
# Launch docker compose in headless mode
# --------------------------------------------------------------------------------
echo -e "${INFO_T1}Launch docker compose in headless mode... ${RESET}"

# Check to make sure we can see all of the files where we expect them
echo -e "\n"
ls -lah .
echo -e "\n"
ls -lah ..
echo -e "\n"
ls -lah ../deployment-files
echo -e "\n"
ls -lah ../deployment-files/models
echo -e "\n"

# Start the containers
echo " " 
echo -e "launch_containers.sh current working directory: $(pwd)"
cd "$REPO_NAME"
echo -e "launch_containers.sh current working directory: $(pwd)"

# Adding "-d" to the end puts it in headless mode (sudo docker-compose up --build -d)
sudo --preserve-env=SAMPLE_VAR docker compose up --build -d
