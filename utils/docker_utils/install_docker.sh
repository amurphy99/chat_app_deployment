# ================================================================================
# 1b) Install Docker (Engine + Compose V2 Plugin)
# ================================================================================
echo -e "${PROG_HR_1}"
echo -e "${PROG_TEXT}1b. Install Docker (Engine + Compose V2 Plugin)... ${RESET}"
echo -e "${PROG_HR_2}"

# Install Docker only if needed (if it is not already installed)
if ! command -v docker &>/dev/null; then
    echo -e "${INFO_T1}Installing Docker Engine and the Compose V2 plugin... ${RESET}"

    # --------------------------------------------------------------------------------
    # 1) Set up the Docker repository
    # --------------------------------------------------------------------------------
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Create keyring directory
    sudo mkdir -p /etc/apt/keyrings

    # --------------------------------------------------------------------------------
    # 2) Select the Docker repository from the VM operating system
    # --------------------------------------------------------------------------------
    OS_ID="$(. /etc/os-release && echo "$ID")"
    if [ "$OS_ID" != "debian" ] && [ "$OS_ID" != "ubuntu" ]; then
        echo "ERROR: Unsupported operating system for Docker installation: $OS_ID" >&2
        exit 1
    fi

    curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" | \
        gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null

    DISTRO_CODENAME=$(lsb_release -cs)

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/${OS_ID} $DISTRO_CODENAME stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # --------------------------------------------------------------------------------
    # 3) Install Docker Engine + Compose plugin
    # --------------------------------------------------------------------------------
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   
    # Enable Docker to run at startup
    sudo systemctl enable docker
    sudo systemctl start docker

else
    echo -e "${GREEN}Docker already installed, skipping...${RESET}"
fi
