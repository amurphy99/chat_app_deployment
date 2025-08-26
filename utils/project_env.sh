# ==================================================================== ===================================
# Configure Project Environment Variables
# ==================================================================== ===================================
echo -e "$PROG_HR_1"
echo -e "${PROG_TEXT}4.5 Detailed project environment variable configuration... ${RESET}"
echo -e "$PROG_HR_2"
echo "project_env.sh current working directory: $(pwd)"

echo -e "${INFO_T1}The project expects: [.env, frontend/.env, backend/.env] ${RESET}"

# ====================================================================
# a) .env 
# ====================================================================
echo -e "${INFO_T2}Preparing root .env file...${RESET}"

# File location
ROOT_ENV_PATH="${APP_DIR}/.env"
echo -e "${INFO_T0}ROOT_ENV_PATH = $ROOT_ENV_PATH ${RESET}"

# Define some new environment variables
VITE_RUN_ENV="PROD"
DEV_APP_ROUTE=""                    # "" Empty string for deployment mode
CERT_EMAIL="amurphy62299@gmail.com"

# Whether or not to use the LLM GPU container or a dummy
if [ "$APP_ENVIRONMENT" = "sandbox" ]; then
    LLM_COMPOSE_FILE="llama_api/dummy-compose.yaml"
    CONF_FILE="default.conf.sandbox"
else
    LLM_COMPOSE_FILE="llama_api/compose.yaml"
    CONF_FILE="default.conf"
fi

# Create the .env file
cat <<EOF > $ROOT_ENV_PATH
# Misc.
APP_ENVIRONMENT=${APP_ENVIRONMENT}
LLM_COMPOSE_FILE=${LLM_COMPOSE_FILE}

# Overrides (root .env file loaded second)
VITE_RUN_ENV=${VITE_RUN_ENV}
DEV_APP_ROUTE=${DEV_APP_ROUTE}

# Nginx & Certbot
CONF_FILE=${CONF_FILE}
DOMAIN=${DOMAIN}
DOMAIN_WWW=${DOMAIN_WWW}
CERT_EMAIL=${CERT_EMAIL}
EOF

echo -e "${GREEN}.env file created successfully${RESET}"

# ====================================================================
# b) frontend/.env 
# ====================================================================
echo -e "${INFO_T2}Preparing frontend .env file...${RESET}"

# File location
FRONTEND_ENV_PATH="${APP_DIR}/frontend/.env"
echo -e "${INFO_T0}FRONTEND_ENV_PATH = $FRONTEND_ENV_PATH ${RESET}"

# --------------------------------------------------------------------
# Create the .env file
# --------------------------------------------------------------------
# The speech key is defined in the initial file of this project
cat <<EOF > $FRONTEND_ENV_PATH
VITE_SPEECH_PROVIDER = "azure"
VITE_SPEECH_KEY      = ${__SPEECH_KEY}
VITE_SERVICE_REGION  = "eastus"

VITE_API_URL    = "/api"
VITE_RUN_ENV    = "DEV" 
VITE_API_BASE   = "http://localhost:8000/api"
VITE_WS_BASE    = "ws://localhost:8000/ws/chat/"

GOOGLE_APPLICATION_CREDENTIALS = ${__GOOGLE_APPLICATION_CREDENTIALS}
GEMINI_KEY = ${__GEMINI_KEY}
EOF

echo -e "${GREEN}frontend/.env file created successfully${RESET}"


# ====================================================================
# c) backend/.env 
# ====================================================================
echo -e "${INFO_T2}Preparing backend .env file...${RESET}"

# File location
BACKEND_ENV_PATH="${APP_DIR}/backend/.env"
echo -e "${INFO_T0}BACKEND_ENV_PATH = $BACKEND_ENV_PATH ${RESET}"

# --------------------------------------------------------------------
# Create the .env file
# --------------------------------------------------------------------
# The postgres information is defined in the initial file of this project
cat <<EOF > $BACKEND_ENV_PATH
POSTGRES_DB            = "dementia_chat_db"
POSTGRES_USER          = ${__POSTGRES_USER}
POSTGRES_PASSWORD      = ${__POSTGRES_PASSWORD}
DJANGO_SETTINGS_MODULE = "backend.settings"
TZ                     = "UTC"
EOF

echo -e "${GREEN}backend/.env file created successfully${RESET}"

