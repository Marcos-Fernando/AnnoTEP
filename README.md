# AnnoTEP - Annotation Transposable Element for Plant
<i> Plataforma destinada a anotação de elementos transponíveis em genomas de plantas </i>

## Introdução 
AnnoTEP é uma plataforma destinada a anotação de elementos transponíveis em genomas de plantas. A plataforma tem como base o pipeline [Plant genome Annotation](https://github.com/amvarani/Plant_Annotation_TEs) e abrange diferentes características relacionadas ás classes dos TES, como: SINE, LINE, TRIM, LARD, TR_GAG, BARE-2, MITES, Gelitron, Familía Gypsy e Familia Copia.
  
O AnnoTEP encontra-se em sua fase de prototipagem e oferecerá uma versão baseado na web, contando com uma interface simples de fácil utilização, para auxiliar pesquisadores, com diferentes níveis de conhecimentos, a estarem conduzido suas anotações de forma eficiente, apresentando diferentes relatórios e gráficos como resultado. Assim como, contará com uma versão local, voltada para pesquisadores que desejam trabalhar com a plataforma em suas proprias máquinas, podendo escolher utilizar interfcae ou trabalhar com linhas de comando.

## Funções
* Identificação, validação e anotação dos elementos SINE e LINE
* Mascaramento dos genomas
* Geração de relatório sobre TEs
* Geração de gráficos ilustrando os elementos repetidos
* Geração de gráficos apresentando a idade dos elementos Gypsy e Copia
* Geração de gráfico da filogenia e densidade dos TEs

## Instalação local
## Prerequisitos
[Python 3.7+](https://www.python.org/)

[Miniconda3](https://docs.conda.io/projects/miniconda/en/latest/)

### Bibliotecas
Abra o terminal e baixe as seguintes bibliotecas:
```sh
sudo apt-get install lib32z1 python-is-python3 python3-setuptools python3-biopython python3-xopen trf hmmer2 seqtk
sudo apt-get install hmmer emboss python3-virtualenv python2 python2-setuptools-whl python2-pip-whl cd-hit iqtree
sudo apt-get install python2-dev build-essential linux-generic libmpich-dev libopenmpi-dev bedtools pullseq bioperl

# R dependencies
sudo apt-get install r-cran-ggplot2 r-cran-tidyr r-cran-reshape2 r-cran-reshape rs r-cran-viridis r-cran-tidyverse r-cran-gridextra r-cran-gdtools r-cran-phangorn r-cran-phytools r-cran-ggrepel

```
Acesse o programa R pelo teminal e instale bibliotecas por dentro dele:

```sh
#program acess
R

install.packages("hrbrthemes")

if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("ggtree")
BiocManager::install("ggtreeExtra")
```
## Baixe o repositório
```sh
https://github.com/Marcos-Fernando/TEP.git $HOME/TEs
```

Acesse o local do repositório na máquina:
```sh
cd $HOME/TEs
```
### Configurando o repositório local
Dentro da pasta copia os scripts para local/bin de sua máquina:
```sh
sudo cp Scripts/irf /usr/local/bin
sudo cp Scripts/break_fasta.pl /usr/local/bin
```
Agora configure o TEsorter (recomenda-se verificar a versão de python existente na máquina para continuar a configuração):
```sh
cd $HOME/TEs/TEsorter
sudo python3 setup.py install

# Hmmpress the databases (The path may be different depending on the python version - see the two examples below)
cd /usr/local/lib/python3.6/dist-packages/TEsorter-1.4.1-py3.6.egg/TEsorter/database/
or
cd /usr/local/lib/python3.10/dist-packages/TEsorter-1.4.1-py3.10.egg/TEsorter/database/

sudo hmmpress REXdb_v3_TIR.hmm
sudo hmmpress Yuan_and_Wessler.PNAS.TIR.hmm
sudo hmmpress REXdb_protein_database_viridiplantae_v3.0_plus_metazoa_v3.hmm
sudo hmmpress REXdb_protein_database_viridiplantae_v3.0.hmm
sudo hmmpress REXdb_protein_database_metazoa_v3.hmm
sudo hmmpress Kapitonov_et_al.GENE.LINE.hmm
sudo hmmpress GyDB2.hmm
sudo hmmpress AnnoSINE.hmm
cd $HOME/TEs 
```
###Baixando genomas para testes
Theobrama cacao
```sh
wget https://cocoa-genome-hub.southgreen.fr/sites/cocoa-genome-hub.southgreen.fr/files/download/Theobroma_cacao_pseudochromosome_v1.0_tot.fna.tar.gz
tar xvfz Theobroma_cacao_pseudochromosome_v1.0_tot.fna.tar.gz
mv Theobroma_cacao_pseudochromosome_v1.0_tot.fna Tcacao.fasta
```

Arabidopsis thaliana 
```sh
wget https://www.arabidopsis.org/download_files/Genes/TAIR10_genome_release/TAIR10_chromosome_files/TAIR10_chr_all.fas.gz
gzip -d TAIR10_chr_all.fas.gz
cat TAIR10_chr_all.fas | cut -f 1 -d" " > At.fasta
rm TAIR10_chr_all.fas
```

```sh
# Chromossomo $ A. thaliana
sudo cp SINE/AnnoSINE/Testing/A.thaliana_Chr4.fasta AtChr4.fasta
```

## Organizando o ambiente
### Configurando AnnoSINE versão modificada
Crie e ative o ambiente conda AnnoSINE:
```sh
cd SINE/AnnoSINE/
conda env create -f AnnoSINE.conda.yaml

cd bin
conda activate AnnoSINE
```

Execute os dados de teste ( cromossomo 4 de A. thaliana ) para verificar a instalação:
```sh
python3 AnnoSINE.py 3 ../Testing/A.thaliana_Chr4.fasta ../Output_Files
```

Dentro da pasta www crie o ambiente de desenvolvimento:
```sh
python3 -m venv .venv
```
Um arquivo 'Seed_SINE.fa' será criado em '../Output_Files'. Este arquivo contém todos os elementos SINE previstos e será usado posteriormente nas próximas etapas.

Você pode fazer o teste com a A. thaliana ou T. cacao:
```sh
cd bin
python3 AnnoSINE.py 3 $HOME/TEs/At.fasta At
#
```

Copie o Seed_SINE.fa para o diretório inicial do pipeline:
```sh
#Saia da pasta bin
cd ..

cp ./Output_Files/Seed_SINE.fa $HOME/TEs/AtCh4-Seed_SINE.fa
```

Desative o ambiente
```sh
conda deactivate
cd $HOME/TEs
```
### Configurando MGEScan-non-LTR e validação primária com TEsorter
Entre na pasta Non-LTR e crie um ambinete virtual
```sh
cd non-LTR/mgescan/

virtualenv -p /usr/bin/python2 mgescan-virtualenv
source mgescan-virtualenv/bin/activate
pip2 install biopython==1.76
pip2 install bcbio-gff==0.6.6
pip2 install docopt==0.6.1
python setup.py install
```

Siga as instruções nas telas do instalador.
Se não tiver certeza sobre alguma configuração, aceite os padrões.

Agora o mgescan está instalado e pronto para funcionar. Teste a instalação:
```sh
mgescan --help
```
### Configurando variáveis de ambiente:
No terminal digite:
```sh
vim ~/.bashrc
```
Uma janela com instruções irá abrir, arreste até a ultima linha e aperte a letra "i" para digitar o comando PATH:
```sh
export PATH="$HOME/miniconda3/envs/AnnoSINE/bin:$PATH";
export PATH="$HOME/miniconda3/envs/EDTA/bin:$PATH";
export PATH="$HOME/TEs/non-LTR/hmmer-3.2/src/:$PATH";
```
Ao finalizar aperte o botão ESC e digite ":wq" para salva as alterações.

Voltando ao terminal, execute (apenas uma vez):
```sh
cd ..
cd hmmer-3.2
make clean
./configure
make -j
```
Agora podemos executar o MGEScan-non-LTR, no terminal configure os diretórios:
```sh
cd $HOME/TEs/non-LTR

# Create a project dir and link your genome file to this folder
mkdir Atch4-LINE
cd Atch4-LINE
ln -s $HOME/TEs/At.fasta At.fasta
cd ..

# Set the ulimit higher value - See below
ulimit -n 8192
```

Execute MGEScan-non-LTR
```sh
mgescan nonltr $HOME/TEs/non-LTR/Atch4-LINE --output=$HOME/TEs/non-LTR/Atch4-LINE-results --mpi=4
```

-------------------




Agora instale o flask:
```sh
pip install flask
```

Instalando o Flask você poderá configurar variáveis de ambiente para ajudar durante a execução projeto.
Primeira instale dontenv por meio do comando:
```sh
pip install python-dotenv
```

Após esse comando você pode está criando o arquivo <b> .flaskenv </b> e configurando as váriaveis, exemplo:
```sh
FLASK_APP = "main.py"
FLASK_DEBUG = True
FLASK_ENV = development
```

A primeira,<b>FLASK_APP</b> pode ser deixada vazia e então ele procurará por "app" ou "wsgi" (com ou sem o ".py" no final, ou seja, pode ser um arquivo ou um módulo) mas você pode usar:
* Um módulo a ser importado, como FLASK_APP=hello.web;
* Um arquivo/módulo no diretório atual, por exemplo FLASK_APP=src/hello;
* Uma instância específica dentro do módulo, algo como FLASK_APP=hello:app2 ou
* Executar diretamente a factory create_app() e até com passagem de parâmetros, tipo FLASK_APP=hello:create_app('dev')".
* 
A váriavel <b>FLASK_DEBUG</b> ativá a depuração do código

E por último, a variável <b>FLASK_ENV</b> definirá o tipo de ambiente projeto, os valores reconhecidos são dois, "production" e "development", se nenhum valor for definido "production" é utilizado por padrão.

Outras informações sobre as váriaveis de desenvolvimento poderá ser encontrado no site do [Flask](https://flask.palletsprojects.com/en/2.3.x/cli/#dotenv)


<b>Dica para usar o vim:</b> aperte a tecla ``i`` para inserir informações e ir até o final do documento, ``ctrl+shift+v`` para colar,  ``esc`` para sair da edição, digite ``:wq`` e depois clique ``enter``para salvar e sair
