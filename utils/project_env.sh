# ================================================================================
# Configure Project Environment Variables
# ================================================================================
# NOTE: All files we create with environment variables are made private
#       automatically for added security.
echo -e "${PROG_HR_1}"
echo -e "${PROG_TEXT}3. Detailed project environment variable configuration... ${RESET}"
echo -e "${PROG_HR_2}"

echo "project_env.sh current working directory: $(pwd)"

# --------------------------------------------------------------------------------
# a) Root .env
# --------------------------------------------------------------------------------
echo -e "\n${INFO_T2}Preparing root .env file... ${RESET}"

# File location
ROOT_ENV_PATH="${APP_DIR}/.env"
echo -e "${INFO_T3}ROOT_ENV_PATH = $ROOT_ENV_PATH ${RESET}"

# Create the Compose interpolation file
cat <<EOF > "$ROOT_ENV_PATH"
# Nginx & Certbot
DOMAIN     = ${DOMAIN}
DOMAIN_WWW = ${DOMAIN_WWW}
CERT_EMAIL = ${CERT_EMAIL}

# --------------------------------------------------------------------------------
# Database
# --------------------------------------------------------------------------------
POSTGRES_DB            = ${__POSTGRES_DB}
POSTGRES_USER          = ${__POSTGRES_USER}
POSTGRES_PASSWORD      = ${__POSTGRES_PASSWORD}

VECTOR_DB_NAME         = ${__VECTOR_DB_NAME}
VECTOR_DB_USER         = ${__VECTOR_DB_USER}
VECTOR_DB_PASSWORD     = ${__VECTOR_DB_PASSWORD}
EOF

chmod 600 "$ROOT_ENV_PATH"

echo -e "${GREEN}.env file created successfully ${RESET}"

# --------------------------------------------------------------------------------
# b) frontend/.env 
# --------------------------------------------------------------------------------
echo -e "\n${INFO_T2}Preparing frontend .env file... ${RESET}"

# File location
FRONTEND_ENV_PATH="${APP_DIR}/frontend/.env"
echo -e "${INFO_T3}FRONTEND_ENV_PATH = $FRONTEND_ENV_PATH ${RESET}"

# Create the build-time Vite configuration
cat <<EOF > "$FRONTEND_ENV_PATH"
VITE_API_URL = "/api"
EOF

chmod 600 "$FRONTEND_ENV_PATH"

echo -e "${GREEN}frontend/.env file created successfully ${RESET}"

# ================================================================================
# c) Backend Environment Variables -- `backend/.env`
# ================================================================================
echo -e "\n${INFO_T2}Preparing backend .env file... ${RESET}"

# File location
BACKEND_ENV_PATH="${APP_DIR}/backend/.env"
echo -e "${INFO_T3}BACKEND_ENV_PATH = $BACKEND_ENV_PATH ${RESET}"

# Create the Django environment file
cat <<EOF > "$BACKEND_ENV_PATH"
# --------------------------------------------------------------------------------
# Django
# --------------------------------------------------------------------------------
DJANGO_SETTINGS_MODULE = ${DJANGO_SETTINGS_MODULE}
DJANGO_DEBUG           = ${DJANGO_DEBUG}
DJANGO_SECRET_KEY      = ${DJANGO_SECRET_KEY}
TZ                     = ${TZ}

# --------------------------------------------------------------------------------
# Database
# --------------------------------------------------------------------------------
POSTGRES_DB            = ${__POSTGRES_DB}
POSTGRES_USER          = ${__POSTGRES_USER}
POSTGRES_PASSWORD      = ${__POSTGRES_PASSWORD}
POSTGRES_HOST          = ${__POSTGRES_HOST}
POSTGRES_PORT          = ${__POSTGRES_PORT}

VECTOR_DB_NAME         = ${__VECTOR_DB_NAME}
VECTOR_DB_USER         = ${__VECTOR_DB_USER}
VECTOR_DB_PASSWORD     = ${__VECTOR_DB_PASSWORD}
VECTOR_DB_HOST         = ${__VECTOR_DB_HOST}
VECTOR_DB_PORT         = ${__VECTOR_DB_PORT}

# --------------------------------------------------------------------------------
# Google Cloud
# --------------------------------------------------------------------------------
GOOGLE_APPLICATION_CREDENTIALS = ${GOOGLE_APPLICATION_CREDENTIALS}
GOOGLE_API_KEY                 = ${GOOGLE_API_KEY}
GOOGLE_GENAI_USE_VERTEXAI      = ${GOOGLE_GENAI_USE_VERTEXAI}

# --------------------------------------------------------------------------------
# Session Audio
# --------------------------------------------------------------------------------
SESSION_AUDIO_STORAGE              = ${SESSION_AUDIO_STORAGE}
SESSION_AUDIO_LOCAL_ROOT           = ${SESSION_AUDIO_LOCAL_ROOT}
SESSION_AUDIO_TEMP_ROOT            = ${SESSION_AUDIO_TEMP_ROOT}
SESSION_AUDIO_GCS_BUCKET           = ${SESSION_AUDIO_GCS_BUCKET}
SESSION_AUDIO_OBJECT_PREFIX        = ${AUDIO_INSTANCE_PREFIX}/${SESSION_AUDIO_OBJECT_PREFIX}
SESSION_AUDIO_PLAYBACK_URL_TTL_SEC = ${SESSION_AUDIO_PLAYBACK_URL_TTL_SEC}

# --------------------------------------------------------------------------------
# Live-Chat LLM
# --------------------------------------------------------------------------------
LIVE_CHAT_RESPONSE_MODE = ${LIVE_CHAT_RESPONSE_MODE}
LLM_NAME                = ${LLM_NAME}

IU_URL = ${IU_URL}
IU_KEY = ${IU_KEY}

# --------------------------------------------------------------------------------
# Legacy Llama API
# --------------------------------------------------------------------------------
LLM_BASE_URL      = ${LLM_BASE_URL}
LLM_GATEWAY_TOKEN = ${LLM_GATEWAY_TOKEN}

# --------------------------------------------------------------------------------
# Misc.
# --------------------------------------------------------------------------------
PEXELS_KEY = ${__PEXELS_KEY}

# --------------------------------------------------------------------------------
# Admin & Demo user login information
# --------------------------------------------------------------------------------
# Primary admin user
ADMIN_USERNAME_0 = ${ADMIN_USERNAME_0}
ADMIN_PASSWORD_0 = ${ADMIN_PASSWORD_0}

# Protected demo data user
DEMO_USERNAME_0 = ${DEMO_USERNAME_0}
DEMO_PASSWORD_0 = ${DEMO_PASSWORD_0}
EOF

chmod 600 "$BACKEND_ENV_PATH"

echo -e "${GREEN}backend/.env file created successfully ${RESET}"
