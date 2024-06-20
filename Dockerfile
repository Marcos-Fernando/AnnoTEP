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

# Config MGEScan root
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# Copying folder contents
COPY . /root/TEs/
COPY Scripts/break_fasta.pl /usr/local/bin/
COPY Scripts/irf /usr/local/bin/ 

# Setting environment variables
ENV PATH="/root/TEs/non-LTR/hmmer-3.2/src/:$PATH"

# Install MGEScan
RUN cd /root/TEs/non-LTR/mgescan \
    && virtualenv -p /usr/bin/python2 mgescan-virtualenv \
    && . mgescan-virtualenv/bin/activate \
    && pip2 install biopython==1.76 \
    && pip2 install bcbio-gff==0.6.6 \
    && pip2 install docopt==0.6.1 \
    && echo "" | python setup.py install \
    && mgescan --help \
    && cd /root/TEs/non-LTR/hmmer-3.2 \
    && rm -rf src/impl \
    && make clean \
    && ./configure \
    && make -j

# Install TEsorter
RUN cd /root/TEs/TEsorter \
    && python3 setup.py install

RUN cd /usr/local/lib/python3.10/dist-packages/TEsorter-1.4.1-py3.10.egg/TEsorter/database/ \
    && hmmpress REXdb_v3_TIR.hmm \
    && hmmpress Yuan_and_Wessler.PNAS.TIR.hmm \
    && hmmpress REXdb_protein_database_viridiplantae_v3.0_plus_metazoa_v3.hmm \
    && hmmpress REXdb_protein_database_viridiplantae_v3.0.hmm \
    && hmmpress REXdb_protein_database_metazoa_v3.hmm \
    && hmmpress Kapitonov_et_al.GENE.LINE.hmm \
    && hmmpress GyDB2.hmm \
    && hmmpress AnnoSINE.hmm

#Install miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && mkdir /root/.conda \
    && bash Miniconda3-latest-Linux-x86_64.sh -b \
    && rm -f Miniconda3-latest-Linux-x86_64.sh

# Setting environment variables
ENV CONDA_PREFIX=/root/miniconda3
ENV PATH="/root/miniconda3/bin:$PATH" 
ENV PATH="/root/miniconda3/envs/AnnoSINE/bin:$PATH"
ENV PATH="/root/miniconda3/envs/EDTA/bin:$PATH"
ENV PATH="/root/miniconda3/envs/EDTA/share/EDTA/bin/HelitronScanner:$PATH"
ENV PATH="/root/TEs/EDTA/share/EDTA/bin/HelitronScanner:$PATH"

#Install AnnoSINE
RUN cd /root/TEs/SINE/AnnoSINE/ \
    && conda env create -f AnnoSINE.conda.yaml

#Install EDTA
RUN cd /root/TEs/EDTA \
    && conda env create -f EDTA.yml

# EDTA can't install RunCmdsMP correctly, so we have to copy it to the folder (pay attention to the python version)
COPY Scripts/RunCmdsMP.py /root/miniconda3/envs/EDTA/lib/python3.6/site-packages/

# Config UTF-8 for Flask
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Port Flask
EXPOSE 5000

# Installing the platform's development environment and adding the requirements
RUN cd /root/TEs/homeserverinterface \
    && python3 -m venv .venv \
    && . .venv/bin/activate \
    && pip install --upgrade pip \
    && pip install -r requirements.txt

# Work directory
WORKDIR /root/TEs/homeserverinterface

# Create a volume called “results” and set it as the container's mount point
VOLUME /root/TEs/homeserverinterface/results

# Command to start Flask and synchronize the folder
CMD ["/bin/bash", "-c", "source /root/miniconda3/bin/activate && source .venv/bin/activate && export LC_ALL=C.UTF-8 && export LANG=C.UTF-8 && flask run --host=0.0.0.0"]






