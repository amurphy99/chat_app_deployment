# Cognibot Speech System Deployment <br> `chat_app_deployment`

Bash scripts for setting up a Linux VM into a fully running instance of the Cognibot chat application. Upload `deploy.sh` and a configured `.env` to the VM and run. The script handles everything from Docker installation and SSL certificate retrieval to cloning the app repo and downloading model files from a GCS bucket. The entry point (`deploy.sh`) installs Git, clones this deployment repository onto the VM, then hands off to `utils/controller.sh`, which orchestrates the remaining setup steps in order.

<br>


<!-- ================================================================================ -->
<!-- How to Deploy                                                                    -->
<!-- ================================================================================ -->
# How to deploy

1. Create a local copy of `.env` based on `.env.example` and fill in the fields:
    - `REPO_BRANCH`: Branch of `v2_benchmarking` to deploy
    - `DEPLOYMENT_TARGET`: Use `main` when deploying a stable version meant for "production"; use `sandbox` for development versions
    - `TARGET_PREFIX`: URL prefix for your instance (e.g. `sandbox2` -> `sandbox2.cognibot.org`); if the target is set to `main`, this is ignored (and it just goes to `cognibot.org`)
    - `SKIP_MODEL_REDOWNLOAD`: Set to `true` on re-runs to skip re-downloading model files that are already staged locally (speeds up re-deployments significantly)
2. SSH into the target VM instance
3. Upload `deploy.sh` and your `.env` to the VM (removing any old copies first)
4. Run `bash deploy.sh` and you are done (takes a **long** time, can be 35+ minutes)

The script will:
- Install Git and Docker (if not already present)
- Clone the app repo and pull the latest changes
- Download model files and credentials from the GCS bucket and copy them into the repo
- Generate project-level `.env` files
- Obtain SSL certificates via Certbot
- Build and start all Docker containers in headless mode

> **NOTE:** If your VMs instance is not already mapped to one of our sandbox URLs, you may need to contact me to do so.

<br>


<!-- ================================================================================ -->
<!-- Architecture Diagram                                                             -->
<!-- ================================================================================ -->
# Project Architecture

```diff
chat_app_deployment/
!├── deploy.sh                    # Entry point; install Git, clone this repo, then call controller.sh
!├── .env                         # Local config (not tracked); see .env.example
 ├── .env.example                 # Template for .env
 ├── utils/
 │   ├── controller.sh            # Orchestrates all setup steps below in order
 │   ├── logging.sh               # ANSI color helpers used across all scripts
 │   ├── env_config.sh            # Derives domain, paths, and env vars from .env
 │   │
 │   ├── docker_utils/            # 1) Stop existing containers & install Docker if missing
 │   │   ├── reset_docker.sh      #    Tears down running containers, prunes dangling resources
 │   │   └── install_docker.sh    #    Installs Docker Engine + Compose plugin (v2)
 │   ├── download_files.sh        # 2) Clone/pull app repo; download models & keys from GCS bucket
 │   ├── project_env.sh           # 3) Write per-service .env files (root, frontend, backend)
+│   ├── get_certs.sh             # 4) Request initial SSL certificates via Certbot/nginx
 │   ├── launch_containers.sh     # 5) Launch Docker in headless mode
 │   │
-│   └── reset_databases.sh       # Manual, guarded reset; NEVER run during deployment
 │
 └── ...
```

<br>

---

<!-- -------------------------------------------------------------------------------- -->
<!-- Console Commands                                                                 -->
<!-- -------------------------------------------------------------------------------- -->
<details closed><summary>Helpful Console Commands</summary>

<br>

**Check running containers**
```
sudo docker ps -a
```

**Check container logs** (swap `backend` for any of the container names):
```
sudo docker logs --tail 200 backend
```

**Verify containers are responding from inside the VM:**
```
sudo docker exec nginx curl -s http://frontend:5173
sudo docker exec nginx curl -s http://backend:8000/api/health/
```

**Re-running the deploy script** (remove old files from the VM first):
```
rm deploy.sh .env
```
Then re-upload and run `bash deploy.sh` again. Port conflicts from the previous run are handled automatically. The script tears down existing containers before rebuilding.

**Manual container teardown** (if you need to stop containers outside of a full re-deploy):
```
cd v2_benchmarking/
sudo docker compose down
```

**Initialize the pgvector extension** (needed only on first-ever vector DB setup):
```
sudo docker exec -it db_vector env | grep POSTGRES_USER
sudo docker exec -it db_vector env | grep POSTGRES_DB
sudo docker exec -it db_vector psql -U <actual_user> -d <actual_db_name> -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

</details>


<!-- -------------------------------------------------------------------------------- -->
<!-- Walkthrough for Resetting DB (need to do this each time the DB changes...)       -->
<!-- -------------------------------------------------------------------------------- -->
<details closed><summary>Resetting the DB</summary>

Because the current setup does not track `migrations` changes (and the existing data for the site isn't necessary to track yet), reset the volumes every time there is a DB schema change. The reset helper is deliberately separate from `deploy.sh`, requires both a command-line flag and typed confirmation, and deletes only the two database volumes and generated `chat_app` migrations.

Run it from the deployment repository:
```bash
bash utils/reset_databases.sh --confirm-reset
```

After redeploying, initialize the pgvector extension if it was not created automatically:
```bash
sudo docker exec -it db_vector env | grep POSTGRES_USER
sudo docker exec -it db_vector env | grep POSTGRES_DB
sudo docker exec -it db_vector psql -U <actual_user> -d <actual_db_name> -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

</details>


<!-- -------------------------------------------------------------------------------- -->
<!-- TODO List                                                                        -->
<!-- -------------------------------------------------------------------------------- -->
<details closed><summary>To Do</summary>

* Maybe combine the two env steps?
* Didn't realize you could do functions with this stuff... need to add more like I did with the demo data in `download_files.sh`

</details>
