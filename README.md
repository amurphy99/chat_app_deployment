# Shell scripts for deploying the chat app. 

ToDo:
* Maybe combine the two env steps


<br>

# How to deploy
1. Create a local copy of `.env` based on `.env.example` and change a few of the fields
    - `REPO_BRANCH=`: Change this to your desired branch of `v2_benchmarking` to deploy
    - `TARGET_PREFIX=`: This is what URL prefix your instance will use (e.g. `sandbox2.cognibot.org`)
    - `ENV=`: This determines if your instance will ALSO be hosted at the main URL (in addition to the sandbox URL)
    - You may need to update your .env file to remove Windows-style line endings (e.g. sed -i 's/\r/\n/g' .env)
2. SSH into the VM instance to deploy the app on
3. Upload `deploy.sh` and your new `.env` into the VM (deleting any old ones first)
4. Run `bash deploy.sh` and you are done
    * Installs docker & updates other dependencies
    * Downloads required, non-tracked files from cloud storage
    * Clones the repo & copies the non-tracked files into their proper locations 
    * Generates project-level `.env` files using the provided `.env` file
    * Builds all Docker containers & starts the app

If your VMs instance is not already mapped to one of our sandbox URLs, you may need to contact me to do so.


</details>

# Helpful Console Commands
* If re-running/updating the deployed app (CPU or GPU instance):
    1) Remove the old `deploy.sh` from the VM: `rm deploy.sh` (also use this with `.env`)
    2) Use the web-SSH console to upload your version of `deploy.sh` and `.env`
* Check logs of the containers (replace backend with other container names):
    - `sudo docker logs --tail 200 backend`
* To check if the containers are up and responding to requests from inside of the VM:
    - `sudo docker exec nginx curl -s http://frontend:5173`
    - `sudo docker exec nginx curl -s http://backend:8000/api/health/`


<br>


# Project Architecture
```diff
chat_app_deployment/
!├── deploy.sh                    # This and .env are involved in the overall project setup
!├── .env
 ├── utils/
 │   ├── controller.sh            # Calls all of the other shell files inside utils
 │   ├── logging.sh               # Defines logging helpers (colors, etc.)
 │   ├── env_config.sh            # Set mode for "sandbox" or "deployment"
 │   │
 │   ├── docker_utils/            # 1) Reset Docker (if installed) & Setup Docker (if not installed)
 │   │   ├── reset_docker.sh
 │   │   └── install_docker.sh 
 │   ├── nvidia_gpu_setup.sh      # 2) NVIDIA Setup (skipped for "sandbox" deployment) 
 │   ├── download_files.sh        # 3) Clone main project repo & download from GCS bucket
 │   ├── project_env.sh           # 4) More detailed .env configuration 
+│   ├── get_certs.sh             # 5) Request the initial certificates for nginx 
 │   └── launch_containers.sh     # 6) Launch docker compose in headless mode
 │
 └── ...
```
