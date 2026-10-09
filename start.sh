
#!/usr/bin/env bash

set -euo pipefail

COMFYUI_DIR="/workspace/ComfyUI"
BAKED_DIR="/opt/comfyui-baked"
VENV_DIR="${COMFYUI_DIR}/comfyui-venv"
BACKUP_DIR="/workspace-global/comfyui-backups"

if ! mountpoint -q /workspace-global; then
    echo "Global Storage ist nicht gemountet."
    exit 1
fi

if [ "${1:-}" = "--backup" ]; then
    if [ ! -f "${COMFYUI_DIR}/main.py" ] || \
       [ ! -x "${VENV_DIR}/bin/python" ]; then
        echo "ComfyUI oder venv fehlt."
        exit 1
    fi

    TEMP_DIR="$(mktemp -d /workspace/.comfy-backup.XXXXXX)"
    trap 'rm -rf "${TEMP_DIR}"' EXIT

    tar -C "${COMFYUI_DIR}" \
        --exclude='./comfyui-venv' \
        -cf "${TEMP_DIR}/comfyui.tar" .

    tar -C "${COMFYUI_DIR}" \
        -cf "${TEMP_DIR}/venv.tar" comfyui-venv

    TARGET="${BACKUP_DIR}/$(date -u +%Y%m%dT%H%M%S)-$$"
    mkdir -p "${TARGET}"

    cp "${TEMP_DIR}/comfyui.tar" "${TARGET}/"
    cp "${TEMP_DIR}/venv.tar" "${TARGET}/"

    tar -tf "${TARGET}/comfyui.tar" > /dev/null
    tar -tf "${TARGET}/venv.tar" > /dev/null

    sync
    echo "complete" > "${TARGET}/COMPLETE"
    sync

    echo "Backup gespeichert: ${TARGET}"
    exit 0
fi

RESET=0

if [ "${1:-}" = "--reset" ]; then
    rm -rf "${COMFYUI_DIR}"
    RESET=1
fi

LATEST_BACKUP=""

for marker in "${BACKUP_DIR}"/*/COMPLETE; do
    if [ -f "${marker}" ]; then
        candidate="${marker%/COMPLETE}"
        if [ -f "${candidate}/comfyui.tar" ] && \
           [ -f "${candidate}/venv.tar" ]; then
            LATEST_BACKUP="${candidate}"
        fi
    fi
done

if [ ! -f "${COMFYUI_DIR}/main.py" ]; then
    mkdir -p "${COMFYUI_DIR}"

    if [ -n "${LATEST_BACKUP}" ] && \
       [ "${RESET}" = "0" ]; then
        tar -xf "${LATEST_BACKUP}/comfyui.tar" \
            -C "${COMFYUI_DIR}"
    else
        cp -a "${BAKED_DIR}/." "${COMFYUI_DIR}/"
    fi
fi

if [ ! -x "${VENV_DIR}/bin/python" ] || \
   [ ! -x "${VENV_DIR}/bin/pip" ] || \
   [ ! -f "${VENV_DIR}/bin/activate" ]; then
    rm -rf "${VENV_DIR}"

    if [ -n "${LATEST_BACKUP}" ] && \
       [ "${RESET}" = "0" ]; then
        tar -xf "${LATEST_BACKUP}/venv.tar" \
            -C "${COMFYUI_DIR}"
    else
        /usr/bin/python3.12 -m venv \
            --system-site-packages \
            "${VENV_DIR}"
    fi
fi

if [ "${RESET}" = "1" ]; then
    echo "ComfyUI und venv zurückgesetzt."
    exit 0
fi

exec "$@"
