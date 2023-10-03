#!/bin/bash

# Baixar e instalar o Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
rm Miniconda3-latest-Linux-x86_64.sh

# Atualizar pacotes e instalar dependências iniciais
sudo apt-get update
sudo apt-get install -y lib32z1 python-is-python3 python3-setuptools python3-biopython python3-xopen trf hmmer2 seqtk hmmer emboss python3-virtualenv python2 python2-setuptools-whl python2-pip-whl cd-hit iqtree python2-dev build-essential linux-generic libmpich-dev libopenmpi-dev bedtools pullseq bioperl

# Instalar dependências R
sudo apt-get install -y r-cran-ggplot2 r-cran-tidyr r-cran-reshape2 r-cran-reshape rs r-cran-viridis r-cran-tidyverse r-cran-gridextra r-cran-gdtools r-cran-phangorn r-cran-phytools r-cran-ggrepel

# Entrar no R shell e instalar pacotes
echo "install.packages('hrbrthemes')" | R --no-save
echo "if (!require('BiocManager', quietly = TRUE)) install.packages('BiocManager')" | R --no-save
echo "BiocManager::install('ggtree')" | R --no-save
echo "BiocManager::install('ggtreeExtra')" | R --no-save

# Copiar arquivos para /usr/local/bin
cd $HOME/TEs/Scripts
sudo cp irf /usr/local/bin
sudo cp break_fasta.pl /usr/local/bin

# Instalar TEsorter
cd $HOME/TEs/TEsorter
sudo python3 setup.py install

# Hmmpress das bases de dados TEsorter
python_version=$(python3 --version | awk '{print $2}')
if [[ "$python_version" == "3.6"* ]]; then
    cd /usr/local/lib/python3.6/dist-packages/TEsorter-1.4.1-py3.6.egg/TEsorter/database/
elif [[ "$python_version" == "3.10"* ]]; then
    cd /usr/local/lib/python3.10/dist-packages/TEsorter-1.4.1-py3.10.egg/TEsorter/database/
else
    echo "Versão do Python não suportada."
    exit 1
fi

sudo hmmpress REXdb_v3_TIR.hmm
sudo hmmpress Yuan_and_Wessler.PNAS.TIR.hmm
sudo hmmpress REXdb_protein_database_viridiplantae_v3.0_plus_metazoa_v3.hmm
sudo hmmpress REXdb_protein_database_viridiplantae_v3.0.hmm
sudo hmmpress REXdb_protein_database_metazoa_v3.hmm
sudo hmmpress Kapitonov_et_al.GENE.LINE.hmm
sudo hmmpress GyDB2.hmm
sudo hmmpress AnnoSINE.hmm

# Voltar para o diretório inicial
cd $HOME/TEs

# Configurar ambiente para www
cd www
python3 -m venv venv
source venv/bin/activate
./required.sh
deactivate
cd $HOME/TEs

# Configurar o ambiente Conda para AnnoSINE
cd SINE/AnnoSINE/
conda env create -f AnnoSINE.conda.yaml
cd bin
conda activate AnnoSINE

# Executar AnnoSINE
python3 AnnoSINE.py 3 ../Testing/A.thaliana_Chr4.fasta ../Output_Files
python3 AnnoSINE.py 3 $HOME/TEs/At.fasta At

# Copiar Seed_SINE.fa
cp ./At/Seed_SINE.fa $HOME/TEs/At-Seed_SINE.fa
conda deactivate

# Voltar para o diretório inicial
cd $HOME/TEs

# Configurar ambiente virtual para mgescan
cd non-LTR/mgescan
virtualenv -p /usr/bin/python2 mgescan-virtualenv
source mgescan-virtualenv/bin/activate
pip2 install biopython==1.76
pip2 install bcbio-gff==0.6.6
pip2 install docopt==0.6.1
python setup.py install

# Configurar ambiente HMMER
cd ..
cd hmmer-3.2
make clean
./configure
make -j

export PATH=$HOME/TEs/non-LTR/hmmer-3.2/src/:$PATH
deactivate

# Voltar para o diretório inicial
cd $HOME/TEs

# Configurar ambiente Conda para EDTA
cd EDTA
conda env create -f EDTA.yml
conda activate EDTA

# Executar EDTA
cd $HOME/TEs
perl EDTA.pl

# Finalizar o ambiente Conda
conda deactivate

echo "Concluído!"
