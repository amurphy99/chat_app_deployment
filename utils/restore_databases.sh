#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/database_common.sh"
database_load_config "${1:-}"

[ "${DB_INIT_MODE:-fresh}" = restore ] || {
    database_error "This utility requires DB_INIT_MODE=restore"
    exit 1
}

URI="${DB_RESTORE_GCS_URI:?Set DB_RESTORE_GCS_URI to the exact backup .tar object}"
[[ "$URI" == gs://?*.tar ]] || {
    database_error "Expected a gs://.../backup.tar URI"
    exit 1
}

command -v gcloud >/dev/null
command -v python3 >/dev/null

# Refuse a running application and any existing database volumes.
# Restore is deliberately limited to first initialization on a new VM.
[ -z "$(database_compose ps --status running -q backend)" ] || {
    database_error "The backend must be stopped before restoring"
    exit 1
}

VOLUMES="$(database_compose config --format json | python3 -c '
import json, sys
config = json.load(sys.stdin)
for name in ("db_data", "vector_db_data"):
    print(config["volumes"][name]["name"])
')"

while IFS= read -r VOLUME; do
    if "${DATABASE_DOCKER[@]}" volume inspect "$VOLUME" >/dev/null 2>&1; then
        database_error "Volume '$VOLUME' already exists. Restore will not overwrite it. Use DB_INIT_MODE=fresh to reuse it."
        exit 1
    fi
done <<< "$VOLUMES"

RESTORE_ROOT="$HOME/database-restores"
mkdir -p "$RESTORE_ROOT"
RESTORE_DIR="$(mktemp -d "$RESTORE_ROOT/${DATABASE_INSTANCE}-restore-XXXXXX")"

trap 'echo "Restore incomplete; application startup stopped. Files retained in: $RESTORE_DIR" >&2' ERR

ARCHIVE="$RESTORE_DIR/backup.tar"
gcloud storage cp "$URI" "$ARCHIVE"
gcloud storage cp "$URI.sha256" "$ARCHIVE.sha256"

database_verify_checksum "$ARCHIVE" "$ARCHIVE.sha256"
database_unpack_backup "$ARCHIVE" "$RESTORE_DIR"

# Older backups lack migration files; require a separate verified history archive.
MIGRATIONS_ARCHIVE="$RESTORE_DIR/chat_app_migrations.tar"

if [ ! -f "$MIGRATIONS_ARCHIVE" ]; then
    MIGRATIONS_URI="${DB_RESTORE_MIGRATIONS_GCS_URI:?This legacy backup requires DB_RESTORE_MIGRATIONS_GCS_URI}"

    [[ "$MIGRATIONS_URI" == gs://?* ]] || {
        database_error "Invalid migrations URI"
        exit 1
    }

    gcloud storage cp "$MIGRATIONS_URI" "$MIGRATIONS_ARCHIVE"
    gcloud storage cp "$MIGRATIONS_URI.sha256" "$MIGRATIONS_ARCHIVE.sha256"

    database_verify_checksum "$MIGRATIONS_ARCHIVE" "$MIGRATIONS_ARCHIVE.sha256"
fi

# Install only migration Python files, and pin the source database images.
# JSON-quoted image strings are valid YAML and cannot inject extra Compose fields.
python3 - "$RESTORE_DIR" "$APP_DIR" \
    "${DB_RESTORE_POSTGRES_IMAGE:-}" \
    "${DB_RESTORE_VECTOR_IMAGE:-}" \
    "$DATABASE_IMAGE_OVERRIDE" <<'PY'
import json
import pathlib
import re
import sys
import tarfile

work, app = map(pathlib.Path, sys.argv[1:3])
destination = app / "backend/chat_app/migrations"
files = {}

with tarfile.open(work / "chat_app_migrations.tar", "r:*") as archive:
    for member in archive.getmembers():
        path = pathlib.PurePosixPath(member.name)

        if path.is_absolute() or ".." in path.parts:
            raise SystemExit("Unsafe path in migration archive")

        if len(path.parts) != 3 or path.parts[:2] != ("chat_app", "migrations"):
            continue

        name = path.name
        if not re.fullmatch(r"(?:__init__|[0-9]{4}_[A-Za-z0-9_]+)\.py", name):
            continue

        if not member.isfile() or name in files:
            raise SystemExit("Invalid/duplicate migration file")

        files[name] = archive.extractfile(member).read()

if not any(re.match(r"[0-9]{4}_", name) for name in files):
    raise SystemExit("Migration archive contains no numbered chat_app migrations")

destination.mkdir(parents=True, exist_ok=True)

for name, content in files.items():
    target = destination / name
    if target.is_symlink() or (target.exists() and target.read_bytes() != content):
        raise SystemExit(f"Conflicting migration file: {target}")

for name, content in files.items():
    (destination / name).write_bytes(content)

images = []

for service, override in zip(("db", "db_vector"), sys.argv[3:5]):
    metadata = (work / f"{service}.metadata.txt").read_text()
    digests = json.loads(metadata.splitlines()[0])
    image = override or (digests[0] if digests else "")

    if not image or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_./:@-]*", image):
        raise SystemExit(
            f"No usable image digest for {service}; set its DB_RESTORE_*_IMAGE"
        )

    images.append(image)

override_file = pathlib.Path(sys.argv[5])
override_file.parent.mkdir(parents=True, exist_ok=True)

content = "services:\n" + "".join(
    f"  {service}:\n    image: {json.dumps(image)}\n"
    for service, image in zip(("db", "db_vector"), images)
)

if override_file.exists() and override_file.read_text() != content:
    raise SystemExit(f"Conflicting database image override: {override_file}")

override_file.write_text(content)
PY

database_compose up -d --wait --wait-timeout 180 db db_vector

# Validate both targets before importing either database.
for SERVICE in db db_vector; do
    CONTAINER="$(database_container "$SERVICE")"

    "${DATABASE_DOCKER[@]}" exec -i "$CONTAINER" pg_restore --list \
        < "$RESTORE_DIR/$SERVICE.dump" \
        > "$RESTORE_DIR/$SERVICE.contents.txt"

    SOURCE_VERSION="$(awk '/Dumped from database version:/ {print $6}' "$RESTORE_DIR/$SERVICE.contents.txt")"

    TARGET_VERSION="$(database_pg "$CONTAINER" on psql -XAt --no-password \
        --set=ON_ERROR_STOP=1 -c 'SHOW server_version;')"

    [ -n "$SOURCE_VERSION" ] &&
    [ "${SOURCE_VERSION%%.*}" = "${TARGET_VERSION%%.*}" ] || {
        database_error "PostgreSQL major version mismatch for $SERVICE: source=$SOURCE_VERSION target=$TARGET_VERSION"
        exit 1
    }

    HAS_TABLES="$(database_pg "$CONTAINER" on psql -XAt --no-password \
        --set=ON_ERROR_STOP=1 -c "SELECT EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE n.nspname NOT LIKE 'pg_%'
              AND n.nspname <> 'information_schema'
              AND c.relkind IN ('r', 'p', 'v', 'm', 'S', 'f')
        );")"

    [ "$HAS_TABLES" = f ] || {
        database_error "$SERVICE is not empty"
        exit 1
    }
done

SOURCE_VECTOR_VERSION="$(awk '$1 == "vector" && $2 == "|" {print $3}' "$RESTORE_DIR/db_vector.metadata.txt")"

if [ -n "$SOURCE_VECTOR_VERSION" ]; then
    CONTAINER="$(database_container db_vector)"

    TARGET_VECTOR_VERSION="$(database_pg "$CONTAINER" on psql -XAt --no-password \
        --set=ON_ERROR_STOP=1 \
        -c "SELECT default_version FROM pg_available_extensions WHERE name = 'vector';")"

    [ "$SOURCE_VECTOR_VERSION" = "$TARGET_VECTOR_VERSION" ] || {
        database_error "pgvector version mismatch: source=$SOURCE_VECTOR_VERSION target=$TARGET_VECTOR_VERSION"
        exit 1
    }
fi

for SERVICE in db db_vector; do
    CONTAINER="$(database_container "$SERVICE")"
    echo "Restoring $SERVICE..."

    # The database name comes from the destination container, not from the archive.
    database_pg "$CONTAINER" off sh -eu -c '
        exec pg_restore --no-password --no-owner --no-privileges \
            --exit-on-error --single-transaction --dbname="$PGDATABASE"
    ' < "$RESTORE_DIR/$SERVICE.dump"
done

# Every already-applied chat_app migration must exist before Django can migrate.
CONTAINER="$(database_container db)"

APPLIED="$(database_pg "$CONTAINER" on psql -XAt --no-password \
    --set=ON_ERROR_STOP=1 \
    -c "SELECT name FROM django_migrations WHERE app = 'chat_app' ORDER BY name;")"

while IFS= read -r MIGRATION; do
    [ -n "$MIGRATION" ] || continue

    [[ "$MIGRATION" =~ ^[0-9]{4}_[A-Za-z0-9_]+$ ]] &&
    [ -f "$APP_DIR/backend/chat_app/migrations/$MIGRATION.py" ] || {
        database_error "Missing restored migration: $MIGRATION"
        exit 1
    }
done <<< "$APPLIED"

for SERVICE in db db_vector; do
    CONTAINER="$(database_container "$SERVICE")"

    database_pg "$CONTAINER" off psql -X --no-password \
        --set=ON_ERROR_STOP=1 -c 'ANALYZE;'
done

echo "Database restore completed. Django can now apply subsequent migrations."
echo "Set DB_INIT_MODE=fresh in the uploaded .env before future deployments; existing data is retained."