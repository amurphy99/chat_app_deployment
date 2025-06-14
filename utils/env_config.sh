# ====================================================================
# Sandbox or Deployment
# ====================================================================
# Specify if this should be for the "deployment" or "sandbox" instance
# bash deploy.sh --env=sandbox
echo "env_config.sh current working directory: $(pwd)"

# Set default
ENV="deploy"
#ENV="sandbox"

# Parse optional argument
if [[ "$1" == "--env=sandbox" ]]; then
    ENV="sandbox"
fi

# --------------------------------------------------------------------
# Set variables based on environment
# --------------------------------------------------------------------
# Domains & Nginx configuration files stem from there

# Sandbox
if [ "$ENV" = "sandbox" ]; then
    DOMAIN="sandbox.cognibot.org"
    DOMAIN_WWW="www.sandbox.cognibot.org"
    NGINX_CONF="nginx/default.conf.sandbox"
    #APP_ENVIRONMENT="sandbox"
    APP_ENVIRONMENT="deployment" # right now i want a sandbox version that uses the GPU

# Deployment
else
    DOMAIN="cognibot.org"
    DOMAIN_WWW="www.cognibot.org"
    NGINX_CONF="nginx/default.conf"
    APP_ENVIRONMENT="deployment"
fi


# --------------------------------------------------------------------
# Basic Config
# --------------------------------------------------------------------
PRJ_DIR="$HOME"

GCS_BUCKET="gs://v2-deployment-files"

# App repository stuff
REPO_URL="https://github.com/amurphy99/v2_benchmarking.git" 
REPO_NAME="v2_benchmarking"
#REPO_BRANCH="gpu"
REPO_BRANCH="gpu-merge"
APP_DIR="$PRJ_DIR/$REPO_NAME"

# Deployment Files (from GCS bucket)
DPL_DIR="$PRJ_DIR/deployment-files"
MDL_DIR="$DPL_DIR/models"
LOG_DIR="$DPL_DIR/logs"

# Final location for the model files when inside the app repo
BIO_DIR="$REPO_NAME/backend/chat_app/websocket/biomarkers/biomarker_models"



