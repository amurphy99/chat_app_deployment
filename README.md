# Shell scripts for deploying the chat app. 

ToDo:
* Move the target deployment branch in `utils/env_config.sh` to another exported variable in `deploy_app.sh` (that way we don't need a new branch of this repo every time we want to use a different backend branch)
* Maybe combine the two env steps
* MAYBE could change the image location as a variable here if you wanted to run the CPU version (no idea what I meant by this)

<br>

# How to deploy (deployment)
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

# How to deploy (sandbox)
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
    1) Remove the old `deploy_app.sh` from the VM: `rm deploy_app.sh`
    2) Use the web-SSH console to upload your version of `deploy_app.sh`
* To run the app after the `deploy_app.sh` script is uploaded:
    - GPU: `bash deploy_app.sh`
    - CPU: `bash deploy_app.sh --env=sandbox` 
* Check logs of the containers (replace backend with other container names):
    - `sudo docker logs --tail 200 backend`
* To check if the containers are up and responding to requests from inside of the VM:
    - `sudo docker exec nginx curl -s http://frontend:5173`
    - `sudo docker exec nginx curl -s http://backend:8000/api/health/`


<br>

<details closed> <summary>Need to look into...</summary>

- [ ] I do "sudo apt update" a lot, is that needed more than once if I know I already did it early on?
- [ ] Is the Nvidia/more updated Docker installation fine for the CPU/sandbox version too?
- [ ] What is the difference between apt and apt-get ?
- [ ] The app repo cloning is wonky right now...

</details>
<br>


# Project Architecture
```diff
chat_app_deployment/
 ├── deploy.sh                    # Calls all of the other shell files inside utils
 ├── utils/
 │   ├── logging.sh               # Defines logging helpers (colors, etc.)
 │   ├── env_config.sh            # Set mode for "sandbox" or "development"
 │   ├── docker_utils/
 │   │   ├── reset_docker.sh      # 0) --- Not setup at the moment... ---
 │   │   └── install_docker.sh    # 1) Install Docker (Engine + Compose V2 Plugin)
 │   ├── nvidia_gpu_setup.sh      # 2) NVIDIA Setup (skipped for "sandbox" deployment) 
 │   ├── download_files.sh        # 3) Clone main project repo & download from GCS bucket
 │   ├── project_env.sh           # 4) Step 4a, more detailed .env configuration   
 │   └── launch_containers.sh     # 5) Launch docker compose in headless mode
 │
 └── ...
```
