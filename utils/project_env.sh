# ================================================================================
# Configure Project Environment Variables
# ================================================================================
echo -e "${PROG_HR_1}"
echo -e "${PROG_TEXT}5. Detailed project environment variable configuration... ${RESET}"
echo -e "${PROG_HR_2}"

echo "project_env.sh current working directory: $(pwd)"

# --------------------------------------------------------------------------------
# a) .env 
# --------------------------------------------------------------------------------
echo -e "\n${INFO_T2}Preparing root .env file... ${RESET}"

# File location
ROOT_ENV_PATH="${APP_DIR}/.env"
echo -e "${INFO_T3}ROOT_ENV_PATH = $ROOT_ENV_PATH ${RESET}"

# Create the .env file
cat <<EOF > $ROOT_ENV_PATH

# Misc.
APP_ENVIRONMENT  = ${APP_ENVIRONMENT}

# Overrides (root .env file loaded second)
VITE_RUN_ENV  = ${VITE_RUN_ENV}
DEV_APP_ROUTE = ${DEV_APP_ROUTE}

# Nginx & Certbot
CONF_FILE  = ${CONF_FILE}
DOMAIN     = ${DOMAIN}
DOMAIN_WWW = ${DOMAIN_WWW}
CERT_EMAIL = ${CERT_EMAIL}

EOF

echo -e "${GREEN}.env file created successfully ${RESET}"

# --------------------------------------------------------------------------------
# b) frontend/.env 
# --------------------------------------------------------------------------------
echo -e "\n${INFO_T2}Preparing frontend .env file... ${RESET}"

# File location
FRONTEND_ENV_PATH="${APP_DIR}/frontend/.env"
echo -e "${INFO_T3}FRONTEND_ENV_PATH = $FRONTEND_ENV_PATH ${RESET}"

# Create the .env file
cat <<EOF > $FRONTEND_ENV_PATH

# The speech key is defined in the initial file of this project
VITE_SPEECH_PROVIDER = "azure"
VITE_SPEECH_KEY      = ${__SPEECH_KEY}  
VITE_SERVICE_REGION  = "eastus"

VITE_API_URL    = "/api"
VITE_RUN_ENV    = "DEV" 
VITE_API_BASE   = "http://localhost:8000/api"
VITE_WS_BASE    = "ws://localhost:8000/ws/chat/"

EOF

echo -e "${GREEN}frontend/.env file created successfully ${RESET}"

# --------------------------------------------------------------------------------
# c) backend/.env 
# --------------------------------------------------------------------------------
echo -e "\n${INFO_T2}Preparing backend .env file... ${RESET}"

# File location
BACKEND_ENV_PATH="${APP_DIR}/backend/.env"
echo -e "${INFO_T3}BACKEND_ENV_PATH = $BACKEND_ENV_PATH ${RESET}"

# Create the .env file
cat <<EOF > $BACKEND_ENV_PATH

# The postgres information is defined in the initial file of this project
POSTGRES_DB            = ${__POSTGRES_DB}
POSTGRES_USER          = ${__POSTGRES_USER}
POSTGRES_PASSWORD      = ${__POSTGRES_PASSWORD}
POSTGRES_HOST          = ${__POSTGRES_HOST}
POSTGRES_PORT          = ${__POSTGRES_PORT}
DJANGO_SETTINGS_MODULE = "backend.settings"
TZ                     = "UTC"

# Access to the external GPU VM instance
LLM_BASE_URL      = ${LLM_BASE_URL}
LLM_GATEWAY_TOKEN = ${LLM_GATEWAY_TOKEN}

GOOGLE_APPLICATION_CREDENTIALS = ${__GOOGLE_APPLICATION_CREDENTIALS}
GOOGLE_API_KEY                 = ${__GEMINI_KEY}
GOOGLE_GENAI_USE_VERTEXAI      = 0

EOF

echo -e "${GREEN}backend/.env file created successfully ${RESET}"
