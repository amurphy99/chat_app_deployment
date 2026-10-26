#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/database_common.sh"
database_load_config "${1:-}"

GCS_PREFIX="${DB_BACKUP_GCS_PREFIX:-gs://v2-deployment-files/deployment-files/db_backup}"

[[ "$GCS_PREFIX" == gs://?* ]] || {
    database_error "Invalid DB_BACKUP_GCS_PREFIX"
    exit 1
}

command -v gcloud >/dev/null || {
    database_error "Install the Google Cloud CLI"
    exit 1
}

# Optional deployment setting: a backup directory on a different disk.
BACKUP_ROOT="${DB_BACKUP_LOCAL_ROOT:-$HOME/database-backups}"
mkdir -p "$BACKUP_ROOT"
BACKUP_ROOT="$(cd "$BACKUP_ROOT" && pwd)"

# Save the ignored migration history as well as the SQL database contents.
MIGRATIONS_DIR="$APP_DIR/backend/chat_app/migrations"

shopt -s nullglob
MIGRATION_FILES=("$MIGRATIONS_DIR"/[0-9][0-9][0-9][0-9]_*.py)

[ "${#MIGRATION_FILES[@]}" -gt 0 ] || {
    database_error "No chat_app migration history found in $MIGRATIONS_DIR"
    exit 1
}

# Allow room for the dumps, the archive, and a 2 GiB margin.
TOTAL_BYTES=0

for SERVICE in db db_vector; do
    CONTAINER="$(database_container "$SERVICE")"

    BYTES="$(database_pg "$CONTAINER" on psql -XAt --no-password \
        --set=ON_ERROR_STOP=1 \
        -c 'SELECT pg_database_size(current_database());')"

    TOTAL_BYTES=$((TOTAL_BYTES + BYTES))
done

AVAILABLE_KB="$(df -Pk "$BACKUP_ROOT" | awk 'NR == 2 {print $4}')"
REQUIRED_KB=$((3 * ((TOTAL_BYTES + 1023) / 1024) + 2 * 1024 * 1024))

printf 'Free space: %s MiB; estimated requirement: %s MiB\n' \
    "$((AVAILABLE_KB / 1024))" "$((REQUIRED_KB / 1024))"

if (( AVAILABLE_KB < REQUIRED_KB )); then
    database_error "Insufficient free space. Set DB_BACKUP_LOCAL_ROOT to a larger disk."
    exit 1
fi

TIMESTAMP="$(date -u +%Y-%m-%d_%H-%M-%S_UTC)"
BACKUP_DIR="$(mktemp -d "$BACKUP_ROOT/${DATABASE_INSTANCE}-database-${TIMESTAMP}-XXXXXX")"
ARCHIVE="${BACKUP_DIR}.tar"

trap 'echo "Backup/upload incomplete. Local files retained in: $BACKUP_DIR" >&2' ERR

printf 'Working directory: %s\n' "$BACKUP_DIR"

for SERVICE in db db_vector; do
    CONTAINER="$(database_container "$SERVICE")"
    echo "Backing up $SERVICE..."

    database_pg "$CONTAINER" on pg_dump --format=custom --no-password \
        --lock-wait-timeout=30s > "$BACKUP_DIR/$SERVICE.dump.partial"

    # List the archive contents only. This does not restore or connect to a DB.
    "${DATABASE_DOCKER[@]}" exec -i "$CONTAINER" pg_restore --list \
        < "$BACKUP_DIR/$SERVICE.dump.partial" > /dev/null

    mv "$BACKUP_DIR/$SERVICE.dump.partial" "$BACKUP_DIR/$SERVICE.dump"

    # Save role/global definitions without PostgreSQL role passwords.
    database_pg "$CONTAINER" on pg_dumpall \
        --globals-only --no-role-passwords --no-password \
        > "$BACKUP_DIR/$SERVICE.globals.sql"

    # Record the image, PostgreSQL version, and installed extensions.
    IMAGE_ID="$("${DATABASE_DOCKER[@]}" inspect --format '{{.Image}}' "$CONTAINER")"

    "${DATABASE_DOCKER[@]}" image inspect --format '{{json .RepoDigests}}' "$IMAGE_ID" \
        > "$BACKUP_DIR/$SERVICE.metadata.txt"

    database_pg "$CONTAINER" on psql -X --no-password --set=ON_ERROR_STOP=1 \
        -c 'SELECT current_database(), version();' \
        -c 'SELECT extname, extversion FROM pg_extension ORDER BY extname;' \
        >> "$BACKUP_DIR/$SERVICE.metadata.txt"
done

tar -C "$APP_DIR/backend" --exclude='__pycache__' \
    -cf "$BACKUP_DIR/chat_app_migrations.tar" chat_app/migrations

(
    cd "$BACKUP_DIR"
    sha256sum *.dump *.globals.sql *.metadata.txt chat_app_migrations.tar > SHA256SUMS
    sha256sum --check SHA256SUMS
)

# Only give the archive its final filename after packaging succeeds.
tar -C "$BACKUP_DIR" -cf "$ARCHIVE.partial" .
mv "$ARCHIVE.partial" "$ARCHIVE"

(
    cd "$BACKUP_ROOT"
    sha256sum "$(basename "$ARCHIVE")" > "$(basename "$ARCHIVE").sha256"
)

DESTINATION="${GCS_PREFIX%/}/$DATABASE_INSTANCE/$(basename "$ARCHIVE")"

# Upload the checksum last; a usable remote backup must have both objects.
gcloud storage cp --if-generation-match=0 "$ARCHIVE" "$DESTINATION"
gcloud storage cp --if-generation-match=0 "$ARCHIVE.sha256" "$DESTINATION.sha256"

printf '\nBACKUP AND UPLOAD COMPLETED\nArchive: %s\nChecksum: %s.sha256\nLocal archive: %s\n' \
    "$DESTINATION" "$DESTINATION" "$ARCHIVE"