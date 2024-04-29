FROM ubuntu:22.04

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y curl gnupg wget python3-pip python3.6 git vim lib32z1 python-is-python3 python3-setuptools python3-biopython python3-xopen \
    trf hmmer2 seqtk hmmer emboss python3-virtualenv python2 python2-setuptools-whl python2-pip-whl pdf2svg cd-hit iqtree python2-dev build-essential \
    linux-generic libmpich-dev libopenmpi-dev bedtools pullseq bioperl \
    libgdal-dev


# Install R
RUN apt-get update -y \
    && apt-get upgrade -y\
    && apt-get install -y --no-install-recommends software-properties-common dirmngr wget \
    && wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc \
    && add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends r-base \
    && apt-get install -y r-cran-ggplot2 r-cran-tidyr r-cran-reshape2 r-cran-reshape r-cran-viridis r-cran-tidyverse r-cran-gridextra r-cran-gdtools r-cran-phangorn r-cran-phytools r-cran-ggrepel \
    && R -e "install.packages('hrbrthemes')" \
    && R -e "if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager')" \
    && R -e "BiocManager::install(version = '3.19')" \
    && R -e "BiocManager::install('ggtree', dependencies = TRUE, ask = FALSE)" \
    && R -e "BiocManager::install('ggtreeExtra', dependencies = TRUE, ask = FALSE)"