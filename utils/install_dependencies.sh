STEP_NUM="${1:-3}"
# ====================================================================
# Install System Dependencies (Git, Nginx, Certbot)
# ====================================================================
echo -e "$PROG_HR_1"
echo -e "${PROG_TEXT}${STEP_NUM}. Installing System Dependencies (Git, Nginx, Certbot)... ${RESET}"
echo -e "$PROG_HR_2"

# --------------------------------------------------------------------
# a) Git
# --------------------------------------------------------------------
echo -e "${INFO_T1}Installing Git...${RESET}"

# Install git if the "git" command doesn't already work
if ! command -v git &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y git
else
    echo -e "${GREEN}Git already installed, skipping...${RESET}"
fi

# --------------------------------------------------------------------
# b) Nginx & Certbot
# --------------------------------------------------------------------
echo -e "${INFO_T1}Installing Nginx & Certbot...${RESET}"

# Install Nginx & Certbot if the "nginx" command doesn't already work
if ! command -v nginx &>/dev/null; then
    sudo apt-get install -y nginx certbot python3-certbot-nginx
    sudo systemctl enable nginx
else
    echo -e "${GREEN}Nginx already installed, skipping...${RESET}"
fi
