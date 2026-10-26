#!/usr/bin/env bash
# Shared configuration and Docker helpers for the standalone database utilities.

DATABASE_UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATABASE_DEPLOYMENT_DIR="$(cd "$DATABASE_UTILS_DIR/.." && pwd)"

database_error() {
    echo "ERROR: $*" >&2
    return 1
}

database_load_config() {
    local CONFIG="${1:-}"
    if [ -z "$CONFIG" ]; then
        if [ -f "$DATABASE_DEPLOYMENT_DIR/../.env" ]; then
            CONFIG="$DATABASE_DEPLOYMENT_DIR/../.env"
        else
            CONFIG="$DATABASE_DEPLOYMENT_DIR/.env"
        fi
    fi
    [ -f "$CONFIG" ] || {
        database_error "Missing deployment .env: $CONFIG"
        return 1
    }
    source "$CONFIG"

    [[ "${REPO_NAME:-}" =~ ^[a-z0-9][a-z0-9_.-]*$ ]] || {
        database_error "Invalid REPO_NAME"
        return 1
    }

    case "${DEPLOYMENT_TARGET:-}" in
        main)
            DATABASE_INSTANCE=main
            ;;
        sandbox)
            DATABASE_INSTANCE="${TARGET_PREFIX:?Set TARGET_PREFIX}"
            ;;
        *)
            database_error "DEPLOYMENT_TARGET must be main or sandbox"
            return 1
            ;;
    esac

    [[ "$DATABASE_INSTANCE" =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
        database_error "Invalid instance prefix"
        return 1
    }

    # These utilities operate on the two local Compose database services.
    [ "${__POSTGRES_HOST:-db}" = db ] &&
    [ "${__POSTGRES_PORT:-5432}" = 5432 ] &&
    [ "${__VECTOR_DB_HOST:-db_vector}" = db_vector ] &&
    [ "${__VECTOR_DB_PORT:-5432}" = 5432 ] || {
        database_error "Database utilities require local Compose database hosts and ports"
        return 1
    }

    APP_DIR="$HOME/$REPO_NAME"
    DATABASE_IMAGE_OVERRIDE="$HOME/deployment-files/database-images/$DATABASE_INSTANCE.yaml"

    [ -f "$APP_DIR/docker-compose.yaml" ] || {
        database_error "Missing app Compose file in $APP_DIR"
        return 1
    }

    # Keep gcloud running as the login user; elevate only Docker when necessary.
    if docker info >/dev/null 2>&1; then
        DATABASE_DOCKER=(docker)
    else
        DATABASE_DOCKER=(sudo docker)
        "${DATABASE_DOCKER[@]}" info >/dev/null
    fi
}

database_compose() {
    local FILES=(-f "$APP_DIR/docker-compose.yaml")
    if [ -f "$DATABASE_IMAGE_OVERRIDE" ]; then
        FILES+=(-f "$DATABASE_IMAGE_OVERRIDE")
    fi
    "${DATABASE_DOCKER[@]}" compose -p "$REPO_NAME" "${FILES[@]}" "$@"
}

database_container() {
    local CONTAINER
    CONTAINER="$(database_compose ps -q "$1")"

    [ -n "$CONTAINER" ] || {
        database_error "Database service '$1' is not running"
        return 1
    }

    printf '%s\n' "$CONTAINER"
}

database_pg() {
    local CONTAINER="$1" READ_ONLY="$2"
    shift 2

    "${DATABASE_DOCKER[@]}" exec -i \
        -e "PGOPTIONS=-c default_transaction_read_only=$READ_ONLY" \
        "$CONTAINER" sh -eu -c '
            export PGHOST=127.0.0.1 PGPORT=5432 PGUSER="$POSTGRES_USER"
            export PGDATABASE="$POSTGRES_DB" PGPASSWORD="$POSTGRES_PASSWORD"
            export PGCONNECT_TIMEOUT=15
            exec "$@"
        ' sh "$@"
}

database_verify_checksum() {
    local FILE="$1" CHECKSUM="$2" EXPECTED ACTUAL

    EXPECTED="$(awk 'NR == 1 {print $1}' "$CHECKSUM")"
    [[ "$EXPECTED" =~ ^[[:xdigit:]]{64}$ ]] || {
        database_error "Invalid SHA256 file: $CHECKSUM"
        return 1
    }

    ACTUAL="$(sha256sum "$FILE")"
    [ "${ACTUAL%% *}" = "$EXPECTED" ] || {
        database_error "Checksum mismatch: $FILE"
        return 1
    }
}

database_unpack_backup() {
    local ARCHIVE="$1" DIRECTORY="$2" FILE EXPECTED ACTUAL
    local FILES=(
        db.dump
        db_vector.dump
        db.globals.sql
        db_vector.globals.sql
        db.metadata.txt
        db_vector.metadata.txt
    )

    if tar -tf "$ARCHIVE" ./chat_app_migrations.tar >/dev/null 2>&1; then
        FILES+=(chat_app_migrations.tar)
    fi

    # Stream only fixed filenames to fixed destinations; never extract arbitrary paths.
    tar -xOf "$ARCHIVE" ./SHA256SUMS > "$DIRECTORY/SHA256SUMS"

    for FILE in "${FILES[@]}"; do
        tar -xOf "$ARCHIVE" "./$FILE" > "$DIRECTORY/$FILE"

        EXPECTED="$(awk -v file="$FILE" '$2 == file {print $1}' "$DIRECTORY/SHA256SUMS")"
        [[ "$EXPECTED" =~ ^[[:xdigit:]]{64}$ ]] || {
            database_error "Missing/invalid checksum for $FILE"
            return 1
        }

        ACTUAL="$(sha256sum "$DIRECTORY/$FILE")"
        [ "${ACTUAL%% *}" = "$EXPECTED" ] || {
            database_error "Checksum mismatch: $FILE"
            return 1
        }
    done
}