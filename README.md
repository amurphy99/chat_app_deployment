# Shell scripts for deploying the chat app. 

* Could add a number as input to each module, then they know which step they are...
* MAYBE could change the image location as a variable here if you wanted to run the CPU version

<br>

- [ ] I do "sudo apt update" a lot, is that needed more than once if I know I already did it early on?
- [ ] Is the Nvidia/more updated Docker installation fine for the CPU/sandbox version too?
- [ ] What is the difference between apt and apt-get ?

<br>

chat_app_deployment/
 ├── .env                         # 
 ├── deploy.sh                    # Calls all of the other shell files inside utils
 ├── utils/
 │   ├── logging.sh               # Defines logging helpers (colors, etc.)
 │   ├── env_config.sh            # Set mode for "sandbox" or "development"
 │   ├── install_dependencies.sh  # Install system dependencies (Git, Nginx, Certbot)
 │   ├── download_files.sh        # Clone main project repository & download from GCS bucket
 │   └── docker_utils/
 │       ├── reset_docker.sh
 │       ├── install_docker.sh
 │
 └── ...
