# Shell scripts for deploying the chat app. 

* Could add a number as input to each module, then they know which step they are...
* MAYBE could change the image location as a variable here if you wanted to run the CPU version

<br>

### Console Commands
```
sudo docker logs backend

chmod +x deploy.sh
./deploy.sh
./deploy.sh > deploy_output.log

```

<br>

- [ ] I do "sudo apt update" a lot, is that needed more than once if I know I already did it early on?
- [ ] Is the Nvidia/more updated Docker installation fine for the CPU/sandbox version too?
- [ ] What is the difference between apt and apt-get ?
- [ ] The app repo cloning is wonky right now...

<br>


# Project Architecture
```diff
chat_app_deployment/
 ├── .env                         # --- nothing right now ---
 ├── deploy.sh                    # Calls all of the other shell files inside utils
 ├── utils/
 │   ├── logging.sh               #    Defines logging helpers (colors, etc.)
 │   ├── env_config.sh            #    Set mode for "sandbox" or "development"
 │   ├── nvidia_gpu_setup.sh      # 2) NVIDIA Setup (GPU Drivers, Container Toolkit)
 │   ├── install_dependencies.sh  # 3) Install system dependencies (Git, Nginx, Certbot)
 │   ├── download_files.sh        # 4) Clone main project repo & download from GCS bucket
 │   ├── nginx_cert_config.sh     # 5) Configure Nginx & Run Certbot for HTTPS
 │   ├── launch_containers.sh     # 6) Launch docker compose in headless mode
 │   └── docker_utils/
 │       ├── reset_docker.sh
 │       └── install_docker.sh
 │
 └── ...
```