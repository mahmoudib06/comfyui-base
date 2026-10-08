# syntax=docker/dockerfile:1

ARG UBUNTU_VERSION=24.04

ARG COMFYUI_VERSION=v0.39.0

ARG TORCH_VERSION=2.14.1+cu130
ARG TORCHVISION_VERSION=0.29.1+cu130
ARG TORCHAUDIO_VERSION=2.11.0+cu130

ARG JUPYTERLAB_VERSION=4.6.4

FROM ubuntu:${UBUNTU_VERSION}

ARG COMFYUI_VERSION
ARG TORCH_VERSION
ARG TORCHVISION_VERSION
ARG TORCHAUDIO_VERSION
ARG JUPYTERLAB_VERSION

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 \
        python3-pip \
        python3.12-venv \
        python3.12-dev \
        build-essential \
        git \
        ca-certificates \
        ffmpeg \
    && rm -rf /var/lib/apt/lists/*

RUN git clone \
        --depth 1 \
        --branch "${COMFYUI_VERSION}" \
        https://github.com/Comfy-Org/ComfyUI.git \
        /opt/comfyui-baked

RUN python3.12 -m pip install \
        --break-system-packages \
        "torch==${TORCH_VERSION}" \
        "torchvision==${TORCHVISION_VERSION}" \
        "torchaudio==${TORCHAUDIO_VERSION}" \
        --index-url https://download.pytorch.org/whl/cu130

RUN python3.12 -m pip install \
        --break-system-packages \
        -r /opt/comfyui-baked/requirements.txt \
        -r /opt/comfyui-baked/manager_requirements.txt

RUN python3.12 -m pip install \
        --break-system-packages \
        "jupyterlab==${JUPYTERLAB_VERSION}"

ENV VIRTUAL_ENV=/workspace/ComfyUI/comfyui-venv \
    PATH="/workspace/ComfyUI/comfyui-venv/bin:/usr/local/bin:${PATH}"

COPY start.sh /usr/local/bin/start.sh

WORKDIR /workspace

EXPOSE 8188 8888

ENTRYPOINT ["/bin/bash", "/usr/local/bin/start.sh"]

CMD ["sleep", "infinity"]
