STEP_NUM=5 #"${1:-5}"
# ====================================================================
# Configure Nginx & Run Certbot for HTTPS
# ====================================================================
echo -e "$PROG_HR_1"
echo -e "${PROG_TEXT}${STEP_NUM}. Configure Nginx & Run Certbot for HTTPS... ${RESET}"
echo -e "$PROG_HR_2"

# --------------------------------------------------------------------
# a) Configure Nginx
# --------------------------------------------------------------------
echo -e "${INFO_T1}Copying the repo Nginx file to the VMs expected location...${RESET}"

# Nginx file paths
NGINX_CONF_PATH="/etc/nginx/sites-available/default"
NGINX_REPO_CONF="$REPO_NAME/$NGINX_CONF"

echo -e "${INFO_T0}Target Path: $NGINX_CONF_PATH${RESET}"
echo -e "${INFO_T0}Source Path: $NGINX_REPO_CONF${RESET}"

# Copying the repo Nginx file to the VMs expected location... if needed
if ! cmp -s "$NGINX_REPO_CONF" "$NGINX_CONF_PATH"; then
    echo -e "${INFO_T2}Updating Nginx config...${RESET}"
    sudo cp "$NGINX_REPO_CONF" "$NGINX_CONF_PATH"
    sudo nginx -t && sudo systemctl restart nginx
else
    echo -e "${GREEN}Nginx config unchanged, skipping restart...${RESET}"
fi


# --------------------------------------------------------------------
# b) Run Certbot for HTTPS
# --------------------------------------------------------------------
# Running Certbot to enable HTTPS
echo -e "${INFO_T1}Running Certbot to enable HTTPS...${RESET}"

# Print the target URLs
echo -e "${INFO_T0}Domain:     $DOMAIN     ${RESET}"
echo -e "${INFO_T0}Domain WWW: $DOMAIN_WWW ${RESET}"

# Check if Certbot was already done
# ---- honestly not sure if this actually works properly right now... ----
if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    sudo certbot --non-interactive --nginx --agree-tos \
        -d "$DOMAIN" -d "$DOMAIN_WWW" \
        -m amurphy62299@gmail.com
else
    echo -e "${GREEN}SSL certificate already exists, skipping Certbot...${RESET}"
fi


#if sudo certbot certificates | grep -q "$DOMAIN"; then
#    echo -e "${GREEN}SSL certificate already exists, skipping Certbot...${RESET}"
#else
#    sudo certbot --non-interactive --nginx --agree-tos \
#        -d "$DOMAIN" -d "$DOMAIN_WWW" \
#        -m amurphy62299@gmail.com
#fi
