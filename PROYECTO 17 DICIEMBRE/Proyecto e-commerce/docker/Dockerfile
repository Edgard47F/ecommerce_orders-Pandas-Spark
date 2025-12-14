FROM jupyter/pyspark-notebook:python-3.11

USER root

# Instalar dependencias adicionales
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}

# Instalar librerías Python adicionales para generar datos sintéticos
RUN pip install --no-cache-dir \
    faker \
    matplotlib \
    pandas \
    numpy

WORKDIR /home/jovyan/work
