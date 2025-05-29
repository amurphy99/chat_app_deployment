echo "Current working directory: $(pwd)"

# ====================================================================
# Logging
# ====================================================================
RESET='\033[0m'

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'

# Bold Colors
BOLD_BLUE="\033[1;34m"
BOLD_GREE="\033[1;32m"
BOLD_YELL="\033[1;33m"

# Horizontal Lines
HR_1="--------------------------------------------------------------------"
HR_2="===================================================================="

CYAN_H_LINE="${CYAN}${HR_1}${RESET}"
BLUE_H_LINE="${BOLD_BLUE}${HR_1}${RESET}"

# --------------------------------------------------------------------
# Specific Formatting
# --------------------------------------------------------------------
# Progress formatting
PROG_HR_1="\n${BLUE_H_LINE}"
PROG_TEXT=$BOLD_BLUE
PROG_HR_2="${BLUE_H_LINE}"

# Info formatting
INFO_T0=$BOLD_YELL
INFO_T1=$CYAN
INFO_T2=$CYAN

