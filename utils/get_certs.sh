# ================================================================================
# Request the initial certificates for nginx (the main app will refresh them)
# ================================================================================
echo -e "${PROG_HR_1}"
echo -e "${PROG_TEXT}6. Requesting the initial certificates for nginx... ${RESET}"
echo -e "${PROG_HR_2}"

echo -e "get_certs.sh current working directory: $(pwd)"

# --------------------------------------------------------------------------------
# Set up the Volume
# --------------------------------------------------------------------------------
# Volume name
LETSENCRYPT_VOL="${REPO_NAME}_letsencrypt"

# Create the volumes here (they are about to get created anyways)
sudo docker volume create $LETSENCRYPT_VOL

# Common arguments
COMMON_DOCKER_ARGS=(
  --rm
  -p 80:80
  -v "$LETSENCRYPT_VOL:/etc/letsencrypt"
)

COMMON_CERTBOT_ARGS=(
  certonly
  --standalone
  --preferred-challenges http
  --email "$CERT_EMAIL"
  --agree-tos
  --no-eff-email
  --non-interactive
  --expand
)

# --------------------------------------------------------------------------------
# Get the Certificats
# --------------------------------------------------------------------------------
# The domain pair (DOMAIN and DOMAIN_WWW) were already selected by `env_config.sh`
# based on sandbox or deployment mode (from APP_ENVIRONMENT)
echo -e "${INFO_T2}Getting certificates for ${INFO_T0}${DOMAIN}${RESET}${INFO_T2}... ${RESET}"

# Run the certificate retrieval task in a docker container
sudo docker run "${COMMON_DOCKER_ARGS[@]}" certbot/certbot \
    "${COMMON_CERTBOT_ARGS[@]}" \
    -d "$DOMAIN" -d "$DOMAIN_WWW"
