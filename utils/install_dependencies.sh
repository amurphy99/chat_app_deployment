STEP_NUM=3 #"${1:-3}"
# ====================================================================
# Install System Dependencies (Just Git now -- Nginx and Certbot are in the main project)
# ====================================================================
echo -e "$PROG_HR_1"
echo -e "${PROG_TEXT}${STEP_NUM}. Installing System Dependencies (Just Git for now)... ${RESET}"
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
