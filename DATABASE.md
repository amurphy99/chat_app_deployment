# Database Backups, Restoration, and Migrations

This guide explains how to back up a deployed database, download a saved backup, initialize a new deployment from it, and apply application migrations.

A **checkpoint** in this guide means a saved database backup archive and its matching checksum file.

## 1. What this feature does

The application uses two PostgreSQL services:

| Service | Purpose |
|---|---|
| `db` | Main application data, including users and conversations. |
| `db_vector` | Vector/RAG data, including embeddings. |

The backup utility saves both databases. The restore utility imports both into a new deployment before the backend starts.

There are two initialization modes:

| `DB_INIT_MODE` | Behavior |
|---|---|
| `fresh` | Normal startup. Docker creates missing database volumes or reuses existing ones. |
| `restore` | First initialization from a saved backup. Refuses to proceed if either database volume already exists. |

**`fresh` does not erase existing data.** To create an empty deployment, use a new VM without existing application database volumes.

Use a separate VM for each sandbox. Changing `TARGET_PREFIX` changes the hostname and storage labels; it does not create separate database volumes or resolve container and port conflicts on the same VM.

## 2. Related files

Paths below are relative to this deployment repository unless stated otherwise.

| File | Purpose |
|---|---|
| `.env.example` | Documents the deployment settings, including backup destinations and restore sources. |
| `deploy.sh` | Loads the uploaded deployment configuration and starts the deployment process. |
| `utils/controller.sh` | Runs the deployment steps in order. |
| `utils/env_config.sh` | Validates the initialization mode and selects the database image-pin file. |
| `utils/project_env.sh` | Writes the application’s database credentials and audio settings into its generated environment files. |
| `utils/database_common.sh` | Shared configuration, Docker, checksum, and archive functions. |
| `utils/backup_databases.sh` | Creates local backups of both databases and migration history, then uploads the archive and checksum to GCS. |
| `utils/restore_databases.sh` | Downloads and verifies a checkpoint, restores migration history, starts the database services, and imports both databases. |
| `utils/launch_containers.sh` | Runs restoration when requested, then starts the complete application. |
| `utils/docker_utils/reset_docker.sh` | Stops existing application containers during deployment. Keeps database volumes. |
| `utils/reset_databases.sh` | Destructive helper for disposable development databases. Deletes both database volumes and numbered `chat_app` migration files after confirmation. |

The application repository also contains:

| Application file | Purpose |
|---|---|
| `backend/docker-compose.backend.yaml` | Defines the databases and backend startup commands, including migration execution. |
| `backend/chat_app/migrations/` | Historical migrations for the main application. These are currently ignored by Git and therefore included in new backups. |
| `backend/rag_vectorstore/migrations/` | Vector application migrations distributed with the application code. |

## 3. Configuration

Use the deployment `.env` uploaded beside `deploy.sh`, normally `~/.env` on the VM.

The standalone database utilities accept an explicit configuration path:

```bash
bash utils/backup_databases.sh "$HOME/.env"
```

Without an argument, they look for `.env` above the deployment checkout, then inside the checkout.

Use the configuration belonging to the VM being backed up. The backup’s instance label comes from this configuration.

**Do not pass the generated application or backend `.env` files.** The utilities expect the deployment configuration containing variables such as `REPO_NAME` and `DEPLOYMENT_TARGET`.

### Database operation settings

| Setting | Meaning |
|---|---|
| `DB_INIT_MODE` | `fresh` for normal startup or `restore` for first initialization from a checkpoint. Defaults to `fresh`. |
| `DB_RESTORE_GCS_URI` | Exact GCS URI of the checkpoint `.tar` file. Required in restore mode. |
| `DB_RESTORE_MIGRATIONS_GCS_URI` | Separate migration archive for older checkpoints without embedded migration history. |
| `DB_RESTORE_POSTGRES_IMAGE` | Optional source-compatible main database image when the checkpoint metadata has no usable image digest. |
| `DB_RESTORE_VECTOR_IMAGE` | Optional source-compatible vector database image when the checkpoint metadata has no usable image digest. |
| `DB_BACKUP_GCS_PREFIX` | Base GCS location for new backups. The utility appends the instance folder and filename. |
| `DB_BACKUP_LOCAL_ROOT` | Optional local backup directory. Defaults to `~/database-backups`. |
| `DEPLOYMENT_TARGET` | `sandbox` or `main`. |
| `TARGET_PREFIX` | Sandbox label, such as `sandbox2`. Ignored for the main deployment’s storage label. |

Example settings for normal sandbox operation:

```bash
DEPLOYMENT_TARGET=sandbox
TARGET_PREFIX=sandbox2

DB_INIT_MODE=fresh
DB_RESTORE_GCS_URI=
DB_RESTORE_MIGRATIONS_GCS_URI=
DB_RESTORE_POSTGRES_IMAGE=
DB_RESTORE_VECTOR_IMAGE=

DB_BACKUP_GCS_PREFIX=gs://v2-deployment-files/deployment-files/db_backup
DB_BACKUP_LOCAL_ROOT=
```

The main deployment uses `main` as its backup label.

These utilities support the local Compose database services: `db:5432` and `db_vector:5432`. They refuse configurations pointing to external database hosts or ports.

## 4. Requirements and permissions

The VM needs:

- Bash and standard Linux utilities, including `tar` and `sha256sum`.
- Docker and Docker Compose V2.
- Google Cloud CLI with `gcloud storage` support.
- Python 3 for restoration.
- Enough disk space for backup files or restored database contents.
- Access to the required container registry images.

The existing deployment process also uses `gsutil`.

Check the tools with:

```bash
docker --version
sudo docker compose version
gcloud --version
gsutil version
python3 --version
```

Run the database utilities as the VM login user. They elevate Docker commands with `sudo` when needed while keeping `gcloud` under the login user’s credentials.

### GCS access

The identity used by `gcloud` needs:

- Read access to checkpoints for restoration.
- Create access for new backups.
- Get and list permissions used by the CLI.

Bucket-level **Storage Object Viewer + Storage Object Creator** is one suitable combination for backup and restore operations. VM access scopes must also permit the requested operations.

The backend may use a different identity through `google-stt-key.json`. Granting permissions to the VM identity does not automatically grant them to that key’s service account. Keep backup buckets private. 

## 5. Back up current data

### Step 1: Connect to the correct VM

Confirm that both database services are running:

```bash
sudo docker ps
df -h "$HOME"
```

Choose a quiet period and avoid deploying schema changes while the backup runs.

### Step 2: Run the backup utility

```bash
cd "$HOME/chat_app_deployment"
bash utils/backup_databases.sh "$HOME/.env"
```

The utility:

1. Loads the deployment configuration.
2. Checks that numbered `chat_app` migration files exist.
3. Estimates the required local disk space.
4. Dumps both databases using read-only connections.
5. Checks that each dump’s archive inventory can be read.
6. Saves database image and extension information.
7. Includes the `chat_app` migration history.
8. Creates and checks file checksums.
9. Packages the backup.
10. Uploads the archive and then its checksum.

A successful run ends with:

```text
BACKUP AND UPLOAD COMPLETED
```

Do not treat a run without that message as a completed remote backup.

### Backup names and locations

For `sandbox2`, a checkpoint looks like:

```text
gs://v2-deployment-files/deployment-files/db_backup/sandbox2/
  sandbox2-database-2026-10-26_19-30-00_UTC-AbCd12.tar
  sandbox2-database-2026-10-26_19-30-00_UTC-AbCd12.tar.sha256
```

The filename contains the instance name, a readable UTC timestamp, and a random suffix.

Local copies remain under `~/database-backups`, or the configured `DB_BACKUP_LOCAL_ROOT`.

### What the archive contains

| File | Contents |
|---|---|
| `db.dump` | Main application database schema and data. |
| `db_vector.dump` | Vector database schema and data. |
| `db.globals.sql` | Main server role/global definitions, excluding PostgreSQL role passwords. |
| `db_vector.globals.sql` | Vector server role/global definitions, excluding PostgreSQL role passwords. |
| `db.metadata.txt` | Main database image digests, PostgreSQL version, and installed extensions. |
| `db_vector.metadata.txt` | Vector database image digests, PostgreSQL version, and installed extensions. |
| `chat_app_migrations.tar` | Historical `chat_app` migration files. |
| `SHA256SUMS` | Checksums for the files inside the archive. |

The separate `.tar.sha256` file verifies the complete archive.

### Effect on the running application

The utility reads database contents and leaves the application running. It can increase CPU and disk activity.

Each database dump has its own consistent snapshot. The two databases are dumped separately, so they do not share one snapshot time. Pause all relevant writers during both dumps when a coordinated pair is required.

The disk-space check requires approximately three times the combined database size plus 2 GiB. It is an estimate, not a reserved limit; other processes can still consume disk space.

## 6. Find, download, and inspect checkpoints

### Find a checkpoint

Browse the bucket in Google Cloud Console, or list an instance’s backups:

```bash
gcloud storage ls \
    "gs://v2-deployment-files/deployment-files/db_backup/sandbox2/"
```

Older manually uploaded backups may be directly inside `db_backup/`, without an instance subfolder.

Select an exact filename. The restore utility does not automatically select the latest checkpoint.

### Download and verify

On a Linux machine with the Google Cloud CLI:

```bash
umask 077
mkdir -p "$HOME/database-backup-downloads"
cd "$HOME/database-backup-downloads"

BACKUP_URI="gs://v2-deployment-files/deployment-files/db_backup/sandbox2/ACTUAL_BACKUP_NAME.tar"
BACKUP_NAME="${BACKUP_URI##*/}"

gcloud storage cp "$BACKUP_URI" .
gcloud storage cp "$BACKUP_URI.sha256" .

sha256sum --check "$BACKUP_NAME.sha256"
```

Replace `ACTUAL_BACKUP_NAME.tar` with the real object filename.

Expected output ends with:

```text
ACTUAL_BACKUP_NAME.tar: OK
```

For files downloaded manually to a Mac, keep the archive and checksum together and run:

```bash
shasum -a 256 -c "ACTUAL_BACKUP_NAME.tar.sha256"
```

### Inspect without restoring

List archive contents:

```bash
tar -tf "$BACKUP_NAME"
```

Read the saved version information:

```bash
tar -xOf "$BACKUP_NAME" ./db.metadata.txt
tar -xOf "$BACKUP_NAME" ./db_vector.metadata.txt
```

To browse application records, restore the checkpoint into a separate sandbox and inspect the restored application or database there.

Checksums confirm file integrity. They do not prove that every application feature will work after recovery. A successful test restore is the recovery check.

Only restore trusted checkpoints; database dumps and migration files can execute code during recovery.

## 7. Restore a checkpoint into a new deployment

### Step 1: Prepare a new VM

Use a separate VM without existing application database volumes.

Configure its static IP, sandbox DNS records, HTTP/HTTPS access, and required GCS permissions.

Do not start `db` or `db_vector` manually first. The restore utility creates their volumes after its initial checks.

The normal deployment process stops existing application containers on its target VM before reaching the restore stage. Always confirm that you are connected to the intended new VM.

### Step 2: Configure restoration

Fill in the usual deployment settings and set:

```bash
DEPLOYMENT_TARGET=sandbox
TARGET_PREFIX=sandbox2

DB_INIT_MODE=restore
DB_RESTORE_GCS_URI="gs://v2-deployment-files/deployment-files/db_backup/ACTUAL_BACKUP_NAME.tar"
```

The archive must have its matching object at:

```text
ACTUAL_BACKUP_NAME.tar.sha256
```

For a checkpoint created by the new backup utility:

```bash
DB_RESTORE_MIGRATIONS_GCS_URI=
```

For an older checkpoint, prepare the separate migration archive described in the next section.

Choose an application branch compatible with the saved migration history. Record the application commit used with each checkpoint; the backup utility does not capture the application source or Git revision.

### Step 3: Isolate recording storage

Use a separate audio bucket for the restored sandbox.

Restored recording rows retain their object keys. If the restored app shares the original bucket, deleting a restored recording can delete the original audio object.

Example configuration:

```bash
SESSION_AUDIO_STORAGE=gcs
SESSION_AUDIO_GCS_BUCKET=YOUR_SEPARATE_SANDBOX_AUDIO_BUCKET
SESSION_AUDIO_OBJECT_PREFIX=recordings
```

The deployment adds the instance prefix, producing new keys under `sandbox2/recordings/`.

Historical audio files must be copied separately. For existing GCS recording rows, preserve their full object keys when copying into the new bucket. Existing local recording rows still require the corresponding local files.

### Step 4: Deploy

Upload `deploy.sh` and the configured `.env` into the new VM’s home directory:

```bash
cd "$HOME"
bash deploy.sh
```

The restore utility:

1. Refuses a running backend or existing database volumes.
2. Downloads the checkpoint and checksum.
3. Verifies the archive and required files.
4. Restores historical migration files.
5. Pins database images using the saved image digests.
6. Starts only the database services.
7. Checks database versions and empty targets.
8. Restores each database in its own transaction.
9. Checks that applied `chat_app` migration names have corresponding files.
10. Runs `ANALYZE`.

The launcher then starts the complete application.

Image pins are saved outside the app checkout:

```text
~/deployment-files/database-images/sandbox2.yaml
```

Normal launches and deployment teardown use this file. Keep it when retaining the associated database volumes.

This workflow restores source-compatible database versions. It is not an automatic PostgreSQL or pgvector upgrade process.

### Step 5: Verify the application

```bash
sudo docker ps
sudo docker logs --tail 200 backend
```

Check representative users, conversations, vector searches, and new recording upload/playback.

A deployment command returning successfully does not by itself prove that backend startup migrations completed. Check the backend’s status and logs.

### Step 6: Return to normal startup mode

After successful restoration and verification, change this in both the VM’s uploaded `.env` and your local deployment configuration:

```bash
DB_INIT_MODE=fresh
```

Keep the database credentials consistent with the deployed database.

Later deployments reuse the restored volumes. Leaving `restore` enabled causes another initialization attempt to refuse those volumes.

If the restore itself failed, do not switch to `fresh` merely to bypass the failure.

## 8. Restore older backups without migration files

Older database archives may contain all database dumps and metadata but lack `chat_app_migrations.tar`.

Because `chat_app` migrations are currently ignored by Git, preserve the history from the original VM that produced the checkpoint.

On that source VM:

```bash
umask 077

MIGRATIONS_BACKUP="source-chat-app-migrations-$(date -u +%Y-%m-%d_%H-%M-%S_UTC).tar.gz"

tar -C "$HOME/v2_benchmarking/backend" \
    --exclude='__pycache__' \
    -czf "$HOME/$MIGRATIONS_BACKUP" \
    chat_app/migrations

(
    cd "$HOME"
    sha256sum "$MIGRATIONS_BACKUP" > "$MIGRATIONS_BACKUP.sha256"
)

printf '%s\n' \
    "$HOME/$MIGRATIONS_BACKUP" \
    "$HOME/$MIGRATIONS_BACKUP.sha256"
```

These commands read migration files and create an archive; they do not modify database contents.

Download both files and upload them to the backup bucket. Then configure:

```bash
DB_RESTORE_MIGRATIONS_GCS_URI="gs://v2-deployment-files/deployment-files/db_backup/ACTUAL_MIGRATION_HISTORY.tar.gz"
```

The matching `.sha256` object must be alongside it.

Use migration files corresponding to the saved database. If the original history was deleted or regenerated after the checkpoint, current files with the same names may not represent that checkpoint correctly.

Do not invent replacement initial migrations or use fake migration flags to bypass missing history. Recover the matching files or investigate the schema and history first.

## 9. How migrations work

A backup restores the schema and records saved at backup time. Migrations update that restored schema to the version expected by newer application code.

The current backend startup command runs:

```bash
python manage.py makemigrations --noinput
python manage.py migrate --database=default --noinput
python manage.py migrate --database=vector --noinput
```

These commands run sequentially; a failure stops the later backend startup commands.

- `makemigrations` generates migration files from differences between the models and existing migration history.
- `migrate --database=default` applies pending operations routed to the main database.
- `migrate --database=vector` applies pending operations routed to the vector database.

The application’s database router controls where model operations belong.

### Before deploying model changes

1. Create a checkpoint before changing a valuable deployment.
2. Preserve the existing migration history.
3. Review generated migrations, especially field removals, data transformations, and new required fields.
4. Test the new application branch against a restored checkpoint in a separate sandbox.
5. Verify the application after migration.
6. Create another checkpoint after successful verification.

For repeatable releases, migration files should eventually be tracked and reviewed with application code. Their inclusion in backups currently preserves the ignored history; it does not replace a version-controlled migration workflow.

### Inspect migration status

When the backend is running:

```bash
sudo docker exec backend \
    python manage.py showmigrations --database=default

sudo docker exec backend \
    python manage.py showmigrations --database=vector
```

Inspect the plan for existing pending migration files:

```bash
sudo docker exec backend \
    python manage.py migrate --plan --database=default

sudo docker exec backend \
    python manage.py migrate --plan --database=vector
```

If the backend has exited, inspect its logs first. `docker exec` requires a running container. One-off maintenance containers must use the same Compose configuration, including the saved database image-pin file.

### What startup may change after restoration

After migrations, startup also runs `close_stale_sessions` and `seed_demo`.

Consequently:

- Previously active chat sessions may be marked closed.
- Configured accounts may be created or refreshed.
- Environment-managed account passwords may be updated.
- Optional fixture data may be created when its seed flags are enabled.

Disabling optional seed flags does not disable all account setup.

Restoration followed by normal application startup is therefore not a promise that every database row remains identical to the saved checkpoint.

## 10. Failure handling

| Problem | Meaning and next step |
|---|---|
| Missing deployment `.env` | Pass the correct deployment configuration path explicitly. |
| External database host or port | These utilities support the two local Compose database services only. |
| Insufficient backup disk space | Use a larger writable location through `DB_BACKUP_LOCAL_ROOT`. |
| Missing numbered migration files | Recover the source application’s migration history before backing up or restoring. |
| GCS permission or scope error | Check the host CLI identity, bucket IAM permissions, and VM access scopes. |
| Missing archive checksum | The checkpoint pair is incomplete. Locate the matching checksum before restoring. |
| Checksum mismatch | Stop and obtain a verified copy. Do not bypass the check. |
| Existing database volume | Restore mode will not overwrite it. Use a new VM for a separate restore. |
| Conflicting migration file | The destination checkout contains different history with the same filename. Investigate the mismatch. |
| Conflicting image-pin file | The stored database image selection differs from the checkpoint. Investigate compatibility before changing it. |
| PostgreSQL or pgvector mismatch | Use source-compatible images; these scripts do not perform database engine upgrades. |
| Missing applied migration | A migration recorded in the database has no corresponding restored file. Recover the correct history. |
| Backend migration failure | Read the backend logs and fix the application migration. Do not reset valuable data to hide the error. |

### Backup failure

The utility retains local files. If upload fails, the local archive may still be usable.

The archive is uploaded before its checksum. An upload failure can leave an archive object without a checksum; do not count that as a complete remote checkpoint.

After fixing permissions or connectivity, rerunning the utility creates a new checkpoint with a new filename.

### Restore failure

Restore errors stop the launcher before it starts the complete application.

Each database restore has its own transaction. There is no transaction covering both databases: the main database may have restored successfully before the vector restore fails.

Once database services have started, their volumes exist. A retry may therefore be refused even after the original problem is fixed.

Preserve the logs and downloaded files. For an isolated sandbox recovery attempt, using another new VM is the simplest way to retain the failed attempt for investigation.

Do not switch to `fresh` after a failed restore just to start a partially restored database pair.

## 11. Destructive resets

`utils/reset_databases.sh` is reserved for disposable development data.

It requires a command-line confirmation flag and a typed confirmation, then deletes:

- The main database volume.
- The vector database volume.
- Numbered `chat_app` migration files.

It does not create a backup first.

Do not use it for routine schema changes or as the normal restore procedure. Databases containing data to retain should be migrated.

`utils/docker_utils/reset_docker.sh` is different: ordinary deployment teardown preserves named database volumes.

## 12. Scope and limitations

This feature provides checkpoint creation, GCS upload, and first initialization of a new deployment from a supported checkpoint.

It does not currently provide:

- Scheduled backups; backups run when the utility is invoked.
- Automatic retention, rotation, or cleanup of local or GCS copies.
- Continuous WAL archiving or recovery to an arbitrary time between checkpoints.
- Automatic replacement or merging of an existing database.
- One atomic snapshot or restore across both databases.
- Automatic rollback of an unsuccessful application release.
- Automatic PostgreSQL or pgvector upgrades.
- Guaranteed compatibility between unrelated application branches and schemas.

The database archive does not include:

- Audio files stored locally or in GCS.
- Other uploaded files stored outside PostgreSQL.
- Deployment `.env` files or credentials.
- TLS certificates.
- Application source code or its Git revision.
- Model downloads.
- Container image contents; only image identifiers are recorded.
- Ignored migration histories from apps other than `chat_app`.

Application source, tracked migrations, configuration, credentials, external files, and required registry images must remain available separately.

Restore uses the destination database users and skips restoration of original ownership and grants. Saved global SQL files are retained for reference and are not applied automatically. Custom PostgreSQL roles, role-dependent policies, or tablespaces may require additional recovery work.

The restore utility accepts the archive layout produced by this backup workflow and the supported earlier local backup script. Arbitrary SQL dumps and raw Docker volume archives are not accepted by this automated path.

Keep archives and credentials outside Git. Preserve a verified checkpoint until its replacement has passed a real restore test.