# Prepare Reachy assets before building the frontend Docker image.
# Sourced by controller.sh after project_env.sh.

prepare_reachy_demo() {
    case "${ENABLE_REACHY_DEMO:-false}" in
        false)
            echo "Reachy demo disabled; skipping asset preparation."
            return 0
            ;;
        true) ;;
        *)
            echo "ERROR: ENABLE_REACHY_DEMO must be true or false." >&2
            return 1
            ;;
    esac

    # Keep the experimental demo limited to sandbox deployments.
    if [ "$DEPLOYMENT_TARGET" != "sandbox" ]; then
        echo "ERROR: Enable the Reachy demo only on a sandbox deployment." >&2
        return 1
    fi

    # Persist downloads beside the other deployment files, outside the app
    # checkout and Docker containers.
    local reachy_cache_dir="$DPL_DIR/reachy-demo-cache"
    mkdir -p "$reachy_cache_dir"

    echo "Preparing Reachy assets for the frontend build..."

    # Node runs temporarily in Docker; the VM does not need Node installed.
    # Bind mounts write generated assets directly into the frontend checkout.
    # Matching the host UID/GID avoids creating root-owned generated files.
    sudo docker run --rm \
        --user "$(id -u):$(id -g)" \
        --mount "type=bind,src=$APP_DIR/frontend,dst=/app" \
        --mount "type=bind,src=$reachy_cache_dir,dst=/reachy-cache" \
        --env REACHY_ASSET_CACHE_DIR=/reachy-cache \
        --workdir /app \
        node:22-alpine \
        node src/pages/reachy_demo/download-assets.mjs
}

prepare_reachy_demo