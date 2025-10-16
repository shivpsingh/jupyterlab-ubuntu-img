FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH="/root/miniconda3/bin:${PATH}"
# Auto-accept Conda plugin terms
ENV CONDA_PLUGINS_AUTO_ACCEPT_TOS=true

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y build-essential curl file git wget openjdk-11-jdk && \
    rm -rf /var/lib/apt/lists/*

# (Optional) Install Homebrew — skip if not required
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /root/.profile && \
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && \
    brew install libomp

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /root/miniconda3 && \
    rm /tmp/miniconda.sh && \
    /root/miniconda3/bin/conda init bash

# Install JupyterLab (auto-accept terms)
RUN conda config --set always_yes yes --set changeps1 no && \
    conda install -y jupyterlab && \
    conda clean -afy

ENV JUPYTER_PASSWORD="LO(ki8ju7hy6gt5"

# Generate Jupyter configuration with password
RUN mkdir -p /root/.jupyter && \
    python -c "from jupyter_server.auth import passwd; \
               print(f'c.ServerApp.password = \"{passwd(\"${JUPYTER_PASSWORD}\")}\"')" \
               > /root/.jupyter/jupyter_lab_config.py && \
    echo 'c.ServerApp.ip = "0.0.0.0"' >> /root/.jupyter/jupyter_lab_config.py && \
    echo 'c.ServerApp.port = 8888' >> /root/.jupyter/jupyter_lab_config.py && \
    echo 'c.ServerApp.open_browser = False' >> /root/.jupyter/jupyter_lab_config.py && \
    echo 'c.ServerApp.allow_root = True' >> /root/.jupyter/jupyter_lab_config.py

# Expose Jupyter port
EXPOSE 8888

# Start JupyterLab
CMD ["conda", "run", "-n", "base", "jupyter-lab", "--config=/root/.jupyter/jupyter_lab_config.py"]
