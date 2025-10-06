# Shell scripts for deploying the chat app. 

ToDo:
* Move the `git` installation to `deploy_app.sh` (the first time running the script in VM it uses git to pull this repo..)
* Move the target deployment branch in `utils/env_config.sh` to another exported variable in `deploy_app.sh` (that way we don't need a new branch of this repo every time we want to use a different backend branch)
* Update the "step numbers"
* Maybe combine the two env steps
* MAYBE could change the image location as a variable here if you wanted to run the CPU version (no idea what I meant by this)

<br>

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
 │   ├── install_dependencies.sh  # 3) Install system dependencies (Git, ...)
 │   ├── download_files.sh        # 4) Clone main project repo & download from GCS bucket
 │   ├── project_env.sh           # a) Step 4a, more detailed .env configuration   
 │   └── launch_containers.sh     # 5) Launch docker compose in headless mode
 │
 └── ...
```