# ================================================================================
# Request the initial certificates for nginx (the main app will refresh them)
# ================================================================================
echo -e "${PROG_HR_1}"
echo -e "${PROG_TEXT}6. Requesting the initial certificates for nginx... ${RESET}"
echo -e "${PROG_HR_2}"

echo -e "get_certs.sh current working directory: $(pwd)"

# --------------------------------------------------------------------------------
# Include the cert for the main domain "cognibot.org" if ENV=deployment
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
  --email "amurphy62299@gmail.com"
  --agree-tos
  --no-eff-email
  --non-interactive
)


# Sandbox => just its own subdomain
if [ "$ENV" = "sandbox" ]; then
    echo -e "${INFO_T2}Getting certs for the subdomain only (${INFO_T0}${DOMAIN}${RESET})... ${RESET}"

    # Get certs
    sudo docker run "${COMMON_DOCKER_ARGS[@]}" certbot/certbot \
        "${COMMON_CERTBOT_ARGS[@]}" \
        -d "$DOMAIN" -d "www.$DOMAIN"

# Deployment => subdomain AND the main domain (cognibot.org)
else
    echo -e "${INFO_T2}Getting certs for the subdomain AND the main domain (${INFO_T0}${DOMAIN} & sandbox.org${RESET})... ${RESET}"

    # Get certs
    sudo docker run "${COMMON_DOCKER_ARGS[@]}" certbot/certbot \
        "${COMMON_CERTBOT_ARGS[@]}" \
        -d "$DOMAIN" -d "www.$DOMAIN" \
        -d cognibot.org -d www.cognibot.org

else
    echo -e "\n${RED}ERROR: ENV='$ENV' not supported (expected sandbox or deployment)${RESET}" >&2
    exit 1

fi
