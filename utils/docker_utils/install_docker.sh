STEP_NUM=1 #"${1:-1}"
# ====================================================================
# Install Docker (Engine + Compose V2 Plugin)
# ====================================================================
echo -e "$PROG_HR_1"
echo -e "${PROG_TEXT}${STEP_NUM}. Install Docker (Engine + Compose V2 Plugin)... ${RESET}"
echo -e "$PROG_HR_2"

# --------------------------------------------------------------------
# Install Docker if needed
# --------------------------------------------------------------------
if ! command -v docker &>/dev/null; then
    echo -e "${INFO_T1}Installing Docker (Engine + Compose V2 Plugin)...${RESET}"

    # Set up the Docker repository
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Create keyring directory
    sudo mkdir -p /etc/apt/keyrings

    # --------------------------------------------------------------------
    # Depending on if we need GPU or not
    # --------------------------------------------------------------------
    # Sandbox (CPU) => debian
    if [ "$ENV" = "sandbox" ]; then
        echo -e "${INFO_T0}For sandbox (CPU) => installing debian ${RESET}"
        curl -fsSL https://download.docker.com/linux/debian/gpg | \
            gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null

        # Get Debian codename (e.g., bookworm, bullseye)
        DISTRO_CODENAME=$(lsb_release -cs)

        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/debian $DISTRO_CODENAME stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Deployment (GPU) => ubuntu
    else
        echo -e "${INFO_T0}For deployment (GPU) => installing ubuntu ${RESET}"
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
            sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    # Install Docker Engine + Compose plugin
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   
    # Enable Docker to run at startup
    sudo systemctl enable docker
    sudo systemctl start docker

else
    echo -e "${GREEN}Docker already installed, skipping...${RESET}"
fi

