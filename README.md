# Shell scripts for deploying the chat app. 

ToDo:
* Maybe combine the two env steps


<br>

# [OUTDATED] How to deploy (deployment)
1. Clone this repo
2. Make a branch of this repo and name it
3. In chat_app_deployment/blob/main/utils/env_config.sh, change line 47 to point at the branch you want to deploy from the v2_benchmarking repo
4. Modify deploy_app.sh line 9 to the branch you made in step 2
5. Add any new env variables necessary
6. Go to Google Cloud Console > Compute Engine > VM Instances and SSH into the v2-testing-06-gpu instance
7. Upload your copy of deploy_app.sh
8. Run `bash deploy_app.sh`
    * May need to run twice
    * Installs docker & updates other dependencies
    * Downloads required, non-tracked files from cloud storage
    * Clones the repo & copies the non-tracked files (model files) into their proper locations 
    * Builds the Docker containers & starts the app
9. Go to cognibot.org/ once the deployment finishes

# [OUTDATED] How to deploy (sandbox)
1. Clone this repository
2. Make a branch of this repository and name it
3. In chat_app_deployment/blob/main/utils/env_config.sh, change line 47 to point at the branch you want to deploy from the v2_benchmarking repo
4. Modify deploy_app.sh line 9 to the branch you made in step 2
5. Add any new env variables necessary
6. Go to Google Cloud Console > Compute Engine > VM Instances and SSH into the v2-testing-05-cpu instance
7. Upload your copy of deploy_app.sh
8. Run `bash deploy_app.sh --env=sandbox`
    * May need to run twice
    * Installs docker & updates other dependencies
    * Downloads required, non-tracked files from cloud storage
    * Clones the repo & copies the non-tracked files (model files) into their proper locations 
    * Builds the Docker containers & starts the app
9. Go to sandbox.cognibot.org/ once the deployment finishes
    * May have security errors--just ignore these

</details>

# Helpful Console Commands
* If re-running/updating the deployed app (CPU or GPU instance):
    1) Remove the old `deploy.sh` from the VM: `rm deploy.sh` (also use this with `.env`)
    2) Use the web-SSH console to upload your version of `deploy.sh` and `.env`
* To run the app after the `deploy.sh` script and `.env` are uploaded:
    - GPU: `bash deploy.sh`
    - CPU: `bash deploy.sh --env=sandbox` 
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
-│   ├── nginx_setup.sh           # 3) Install & Setup Nginx (not currently active yet)
 │   ├── download_files.sh        # 4) Clone main project repo & download from GCS bucket
 │   ├── project_env.sh           # 5) More detailed .env configuration 
 │   └── launch_containers.sh     # 6) Launch docker compose in headless mode
 │
 └── ...
```
