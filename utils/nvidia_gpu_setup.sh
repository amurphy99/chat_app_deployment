STEP_NUM="${1:-2}"
# ====================================================================
# NVIDIA Setup (GPU Drivers, Container Toolkit)
# ====================================================================
echo -e "$PROG_HR_1"
echo -e "${PROG_TEXT}${STEP_NUM}. NVIDIA Setup (GPU Drivers, Container Toolkit)... ${RESET}"
echo -e "$PROG_HR_2"

# Echo the mode we are running in (sandbox or development)
echo -e "${INFO_T1}Running in ${INFO_T0}$APP_ENVIRONMENT${RESET} ${INFO_T1}mode...${RESET}"


# Only do all of these steps if we are in deployment mode and need the GPU
if [ "$APP_ENVIRONMENT" = "deployment" ]; then

    # --------------------------------------------------------------------
    # a) Install GPU Drivers
    # --------------------------------------------------------------------
    echo -e "${INFO_T1}Installing NVIDIA GPU Drivers...${RESET}"

    # Install GPU drivers if "nvidia-smi" not found
    if ! command -v nvidia-smi &>/dev/null; then
        sudo apt update
        sudo apt install -y nvidia-driver-535 nvidia-utils-535
        echo -e "${INFO_T2}Reboot is recommended after this step for drivers to take effect.${RESET}"
    else
        echo -e "${GREEN}NVIDIA drivers already installed, skipping...${RESET}"
    fi


    # --------------------------------------------------------------------
    # b) Install NVIDIA Container Toolkit
    # --------------------------------------------------------------------
    echo -e "${INFO_T1}Installing NVIDIA Container Toolkit...${RESET}"

    # Install NVIDIA Container Toolkit if "nvidia-ctk " not found
    if ! command -v nvidia-ctk &>/dev/null; then
        # Get the distribution    # distribution="ubuntu22.04"  
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        echo -e "${INFO_T0}Nvidia Distribution: $distribution ${RESET}"

        # Add the repo
        curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | \
            sudo tee /etc/apt/trusted.gpg.d/nvidia-container-toolkit.asc

        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

        #curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/${distribution}/nvidia-container-toolkit.list | \
            #sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

        #curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        #    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

        # Update and install
        sudo apt update
        sudo apt install -y nvidia-container-toolkit

        # Configure runtime and restart Docker
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker

    else
        echo -e "${GREEN}NVIDIA Container Toolkit already installed, skipping...${RESET}"
    fi


    # --------------------------------------------------------------------
    # c) Test GPU access in Docker
    # --------------------------------------------------------------------
    echo -e "${INFO_T1}Testing GPU access in Docker...${RESET}"
    sudo docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi

else
    echo -e "${GREEN}In sandbox mode, skipping GPU setup... ${RESET}"
fi
