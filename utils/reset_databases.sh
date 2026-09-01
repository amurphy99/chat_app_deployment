#!/bin/bash
set -Eeuo pipefail

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# This should **NEVER** be ran in a production environment connected to real data.
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# This script is intentionally standalone and is never sourced by `deploy.sh`.`

# ================================================================================
# Reset Disposable Development Databases
# ================================================================================
# Because development databases never actually contain actual research data that
# we NEED to keep around, we don't actually need to migrate whatever existing data
# is in a database when we make changes. Rather than dealing with constant version
# conflicts, we can just use this script to rest the database completely (clear
# any Docker volume instances & remove auto-generated migrations files).


# --------------------------------------------------------------------------------
# 1)  Locate the deployment repository and its private configuration file
# --------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEPLOYMENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEPLOYMENT_PARENT="$(cd "${DEPLOYMENT_DIR}/.." && pwd)"
UPLOADED_ENV="${DEPLOYMENT_PARENT}/.env"
REPOSITORY_ENV="${DEPLOYMENT_DIR}/.env"

# Require an explicit flag before even loading the reset configuration
if [ "${1:-}" != "--confirm-reset" ]; then
    echo "Usage: bash utils/reset_databases.sh --confirm-reset" >&2
    exit 1
fi

# The VM keeps the uploaded bootstrap configuration beside deploy.sh, one level
# above the cloned repository. A repository-local file is supported for local use.
if [ -f "$UPLOADED_ENV" ]; then
    DEPLOYMENT_ENV="$UPLOADED_ENV"
elif [ -f "$REPOSITORY_ENV" ]; then
    DEPLOYMENT_ENV="$REPOSITORY_ENV"
else
    echo "ERROR: Missing deployment configuration. Checked:" >&2
    echo "  - $UPLOADED_ENV" >&2
    echo "  - $REPOSITORY_ENV" >&2
    exit 1
fi

source "$DEPLOYMENT_ENV"

# Prevent path traversal or malformed Docker volume names through REPO_NAME
if [[ ! "$REPO_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]; then
    echo "ERROR: Unsafe REPO_NAME in deployment configuration: $REPO_NAME" >&2
    exit 1
fi

APP_DIR="${HOME}/${REPO_NAME}"
COMPOSE_FILE="${APP_DIR}/docker-compose.yaml"
MIGRATIONS_DIR="${APP_DIR}/backend/chat_app/migrations"
DB_VOLUME="${REPO_NAME}_db_data"
VECTOR_DB_VOLUME="${REPO_NAME}_vector_db_data"
CONFIRMATION="RESET ${REPO_NAME} DATABASES"

# --------------------------------------------------------------------------------
# 2) Verify that the resolved app and migration targets exist before prompting
# --------------------------------------------------------------------------------
if [ ! -f "$COMPOSE_FILE" ] || [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "ERROR: Expected app files were not found under: $APP_DIR" >&2
    exit 1
fi

# Preview every destructive target and require the repository-specific phrase
echo "This permanently deletes:"
echo "  - Docker volume: $DB_VOLUME"
echo "  - Docker volume: $VECTOR_DB_VOLUME"
echo "  - Generated migrations in: $MIGRATIONS_DIR"
echo "It does not delete certificates, session audio, or GCS objects."
echo
read -r -p "Type '$CONFIRMATION' to continue: " response

if [ "$response" != "$CONFIRMATION" ]; then
    echo "Database reset cancelled."
    exit 1
fi

# --------------------------------------------------------------------------------
# 3) Stop containers
# --------------------------------------------------------------------------------
# Release the database volumes before trying to delete them
sudo docker compose -f "$COMPOSE_FILE" --project-directory "$APP_DIR" down

# --------------------------------------------------------------------------------
# 4) Delete database volumes only
# --------------------------------------------------------------------------------
for volume in "$DB_VOLUME" "$VECTOR_DB_VOLUME"; do
    # Checking first makes repeated resets safe when a volume is already absent
    if sudo docker volume inspect "$volume" >/dev/null 2>&1; then
        sudo docker volume rm "$volume"
    else
        echo "Volume does not exist, skipping: $volume"
    fi
done

# --------------------------------------------------------------------------------
# 5) Delete auto-generated migrations
# --------------------------------------------------------------------------------
# Preserve __init__.py and delete only numbered migration modules
sudo find "$MIGRATIONS_DIR" -maxdepth 1 -type f -name '[0-9]*_*.py' -print -delete

echo "Database reset complete. Run bash deploy.sh when you are ready to redeploy."
