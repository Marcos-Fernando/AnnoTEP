<div align="center"> 
    <img src="www/static/assets/Logo2.svg" alt="Logo2">
</div><br>

![Linux version](https://img.shields.io/badge/Platform-Linux_64-orange)


# AnnoTEP
AnnoTEP é uma plataforma dedicada à anotação de elementos transponíveis (TEs) em genomas de plantas. Construída com base no pipeline [Plant genome Annotation](https://github.com/amvarani/Plant_Annotation_TEs), combina ferramentas de anotação sofisticadas integrada com recursos HTML para oferecer uma experiência aprimorada aos pesquisadores durante o processo de anotação. Ao integrar essas ferramentas com uma interface amigável, AnnoTEP visa facilitar e otimizar o trabalho de anotação de TEs, fornecendo uma solução eficaz para a análise genômica de plantas.

Atualmente, o AnnoTEP está disponível em três formatos: Web Server, Home Server com Interface e Home Server Terminal. Clicando em cada formato abaixo, você será direcionado para o sistema de acesso ou instalação da plataforma:
- [Web Server](http://150.230.81.111:5000/) 
- [Home server with interface](##home-server-interface)
- [Home server in terminal](##home-server-terminal)

## Funções da ferramenta
* Identificação, validação e anotação dos elementos SINE e LINE
* Mascaramento dos genomas (mode home server)
* Geração de relatório sobre TEs
* Geração de gráficos ilustrando os elementos repetidos
* Geração de gráficos de idade dos elementos Gypsy e Copia
* Geração de gráfico da filogenia e densidade dos TEs

# Conteúdo

[Installation with Docker](#installation-with-docker)

[Example](#example-of-results)

[Git Install](#git-intall)


# Installation with Docker
AnnoTEP pode ser instalado na máquina de diferentes forma, e uma delas é utilizando o Docker. A ferramenta está disponível em dois formatos: com interface gráfica e sem interface (modo terminal). Para seguir com as etapas abaixo, é necessário ter o Docker instalado na sua máquina. Você pode baixá-lo diretamente do site oficial do [Docker](https://docs.docker.com/engine/install/)

## Home server with interface
Abra o terminal e execute os seguintes comandos:
1. Baixe a imagem do AnnoTEP:
```sh
    docker pull annotep-local-interface:v1
```

2. Em seguida, execute o contêiner com o comando abaixo, substituindo ``caminho/diretorio/results`` pelo diretório onde você deseja armazenar os resultados gerados pela anotação:
```sh
     docker run -it -v /caminho/diretorio/results:/root/TEs/www/results --name local-interface -dp 0.0.0.0:5000:5000 annotep-local-interface:v1
```

Exemplo diretorio de resultados:
```sh
     docker run -it -v $HOME/Documents/results:/root/TEs/www/results --name local-interface -dp 0.0.0.0:5000:5000 annotep-local-interface:v1
```

#### Description:
- ``-v $HOME/Documents/results:/root/TEs/www/results``: This creates a volume between the host and the container to store data. You can replace ``-v $HOME/results`` with any path on your machine. This is where your result data will be saved.
- ``--name local-interface``: Sets the name of the container to "local-interface".
- ``-dp 0.0.0.0:5000:5000``: Maps the container's port 5000 to the host's port 5000.
- ``annotep-local-interface:v1``: Specifies the image to be used.

3. Depois de executar o contêiner com o comando anterior, acesse a interface do AnnoTEP digitando o seguinte endereço no seu navegador web: 
``127.0.0.1:5000``

4. Ao acessar 127.0.0.1:5000 você irá visualizar uma versão da plataforma AnnoTEP similar a versão WEB. 

Se você deseja acessar o contêiner enquanto ele está em execução para fins de depuração ou configuração, você pode usar o seguinte comando Docker:
```sh
    docker run --name flask-container -it -p 0.0.0.0:5000:5000 "nome-da-image" /bin/bash
```
Substitua ``nome-da-image`` pelo nome da imagem do AnnoTEP que você está usando. Este comando executará um novo contêiner Docker com uma shell interativa /bin/bash, permitindo que você acesse o interior do contêiner enquanto ele está em execução.


## Home server in terminal
1. Baixe a imagem do AnnoTEP:
```sh
    docker pull annotep-local-terminal:v1
```

2. Em seguida, execute o contêiner com o comando abaixo, substituindo ``caminho/diretorio/results`` pelo diretório onde você deseja armazenar os resultados gerados pela anotação, e ``caminho/diretorio/genome`` pelo diretório onde está localizado seu genoma:
```sh
    sudo docker run -it -v /caminho/diretorio/results:/root/TEs/local/results -v /home/user/TEs:/caminho/diretorio/genome "nome_da_imagem" python run_annotep.py --file {/caminho/diretorio/genome/genome.fasta} --type {type-annotation}
```

No parâmetro ``--file``, você precisa adicionar o mesmo diretório do genoma seguido pelo nome do genoma a ser utilizado no formato .fasta.
No parâmetro ``--type``, você deve adicionar o número correspondente ao tipo de anotação que deseja realizar: 
[1] SINE Annotation 
[2] LINE Annotation
[3] SINE and LINE annotation
[4] Complete Annotation.

Exemplo:
```sh
    sudo docker run -it -v $HOME/results:/root/TEs/local/results -v $HOME/TEs:$HOME/TEs annotep-local-terminal:v1 python run_annotep.py --file $HOME/TEs/Athaliana.fasta --type 2
```

3. Agora aguarde a finalização na anotação do genoma
 




# Instalação com github
Important: This pipeline was tested only on Ubuntu 20.20 and 22.04

## Prerequisitos
[Python 3.7+](https://www.python.org/)

[Miniconda3](https://docs.conda.io/projects/miniconda/en/latest/)

[MongoDB Compass](https://www.mongodb.com/docs/compass/current/install/)


## Baixe o repositório
```sh
git clone https://github.com/Marcos-Fernando/TEP.git $HOME/TEs
```

Acesse o local do repositório na máquina:
```sh
cd $HOME/TEs
```
### Configurando o repositório local
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

Dentro da pasta copia os scripts para local/bin de sua máquina:
```sh
sudo cp Scripts/irf /usr/local/bin
sudo cp Scripts/break_fasta.pl /usr/local/bin
```
Agora configure o TEsorter
```sh
cd $HOME/TEs/TEsorter
sudo python3 setup.py install
```
Verifique a versão do python existente na máquina para prosseguir com a configuração

* Python 3.6
```sh
# Hmmpress the databases (The path may be different depending on the python version - see the two examples below)
cd /usr/local/lib/python3.6/dist-packages/TEsorter-1.4.1-py3.6.egg/TEsorter/database/
```

* Python 3.7
```sh
# Hmmpress the databases (The path may be different depending on the python version - see the two examples below)
cd /usr/local/lib/python3.7/dist-packages/TEsorter-1.4.1-py3.6.egg/TEsorter/database/
```

* Python 3.10
```sh
# Hmmpress the databases (The path may be different depending on the python version - see the two examples below)
cd /usr/local/lib/python3.10/dist-packages/TEsorter-1.4.1-py3.6.egg/TEsorter/database/
```
...

```sh
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
### Baixando genomas para testes
* Theobrama cacao
```sh
wget https://cocoa-genome-hub.southgreen.fr/sites/cocoa-genome-hub.southgreen.fr/files/download/Theobroma_cacao_pseudochromosome_v1.0_tot.fna.tar.gz
tar xvfz Theobroma_cacao_pseudochromosome_v1.0_tot.fna.tar.gz
mv Theobroma_cacao_pseudochromosome_v1.0_tot.fna Tcacao.fasta
```

* Arabidopsis thaliana 
```sh
wget https://www.arabidopsis.org/download_files/Genes/TAIR10_genome_release/TAIR10_chromosome_files/TAIR10_chr_all.fas.gz
gzip -d TAIR10_chr_all.fas.gz
cat TAIR10_chr_all.fas | cut -f 1 -d" " > At.fasta
rm TAIR10_chr_all.fas
```
* Chromossomo 4 A. thaliana
```sh
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

cd ..
```

Copie o Seed_SINE.fa para o diretório inicial do pipeline:
```sh
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
Uma janela com instruções irá abrir, arreste até a ultima linha e aperte a letra ``i`` para digitar o comando PATH:
```sh
export PATH="$HOME/miniconda3/envs/AnnoSINE/bin:$PATH";
export PATH="$HOME/miniconda3/envs/EDTA/bin:$PATH";
export PATH="$HOME/TEs/non-LTR/hmmer-3.2/src/:$PATH";
```
Ao finalizar aperte o botão ``ESC`` e digite ``:wq`` para salva as alterações.

----

<b>Dica para usar o vim:</b> aperte a tecla ``i`` para inserir informações e ir até o final do documento, ``ctrl+shift+v`` para colar,  ``esc`` para sair da edição, digite ``:wq`` e depois clique ``enter``para salvar e sair

----

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

Processando os resultados MGEScan-não-LTR: removendo falsos positivos com TEsorter e gerando a biblioteca LINE não redundante pré-final mostrando entrada compatível para o pipeline EDTA modificado:

Primeiro, entre na pasta que contém os resultados
```sh
cd ..

cd Atch4-LINE-results
```
Em seguida, na janela do seu terminal, copie e cole o código abaixo e execute. Isso irá gerar o arquivo LINE-lib.fa não redundante:
```sh
cat info/full/*/*.dna > temp.fa
cat temp.fa | grep \>  | sed 's#>#cat ./info/nonltr.gff3 | grep "#g'  | sed 's#$#" | cut -f 1,4,5#g'  > ver.sh
bash ver.sh  | sed 's#\t#:#' | sed 's#\t#\.\.#'   > list.txt
#
mkdir TMP
break_fasta.pl < temp.fa TMP/
cat temp.fa | grep \> | sed 's#>#cat ./TMP/#g' | sed 's#$#.fasta#g' > A.txt
cat temp.fa | grep \> > list2.txt
paste list2.txt list.txt | sed 's/>/ sed "s#/g'  | sed 's/\t/#/g' | sed 's/$/#g"/g'   > B.txt
paste A.txt B.txt  -d"|"  > rename.sh
bash rename.sh > candidates.fa
#
#/usr/local/bin/TEsorter -db rexdb-plant --hmm-database rexdb-plant -pre LINE -p 22 -cov 60 candidates.fa
/usr/local/bin/TEsorter -db rexdb-plant --hmm-database rexdb-plant -pre LINE -p 22 -cov 80 -eval 0.0001 -rule 80-80-80 candidates.fa
more LINE.cls.lib  | sed 's/#/__/g'  | sed 's#.fa##g' | cut -f 1 -d" " | sed 's#/#-#g'  > pre1.fa
mkdir pre1
break_fasta.pl < pre1.fa pre1
cat pre1/*LINE.fasta  | sed 's#__#\t#g' | cut -f 1  > pre2.fa
#/usr/local/bin/TEsorter -db rexdb-line --hmm-database rexdb-line -pre LINE2 -p 22 -cov 60 pre2.fa
/usr/local/bin/TEsorter -db rexdb-line --hmm-database rexdb-line -pre LINE2 -p 22 -cov 60 -eval 0.0001 -rule 80-80-80 pre2.fa
more LINE2.cls.lib  | sed 's/#/__/g'  | sed 's#.fa##g' | cut -f 1 -d" " | sed 's#/#-#g'  > pre-final.fa
mkdir pre-final
break_fasta.pl < pre-final.fa pre-final
cat pre-final/*LINE*.fasta  > pre-final2.fa
cdhit-est -i pre-final2.fa -o clustered -c 0.8 -G 1 -T 22 -d 100 -s 0.6 -aL 0.6 -aS 0.6
cat clustered | sed 's/__/#/g' | sed 's#-#/#g'  > LINE-lib.fa
#
rm -rf pre1/ pre-final/ TMP/
rm LINE2*
rm LINE.cls.*
rm A.txt B.txt clustered.clstr clustered LINE.dom* list2.txt list.txt pre1.fa pre2.fa pre-final2.fa pre-final.fa rename.sh temp.fa ver.sh candidates.fa
cp LINE-lib.fa $HOME/TEs/Atch4-LINE-lib.fa
```

Finalize desativando o ambiente de desenvolvimento e retornando ao diretório inicial do pipeline:
```sh
deactivate
cd $HOME/TEs
```

### Configurando EDTA versão modificada
Instale e ative o ambiente EDTA conda (necessário apenas executar uma vez)
```sh
cd EDTA
# Re-start the conda enviroment 
bash

conda env create -f EDTA.yml
conda activate EDTA

perl EDTA.pl
```

Agora execute EDTA, utilizaremos AtChr4.fasta
```sh
cd ..
mkdir AtCh4
cd AtCh4
```

Com nohup:
```sh
# Run EDTA in the backgroup
nohup $HOME/TEs/EDTA/EDTA.pl --genome ../AtChr4.fasta --species others --step all --line ../Atch4-LINE-lib.fa --sine ../AtCh4-Seed_SINE.fa --sensitive 1 --anno 1 --threads 10 > EDTA.log 2>&1 &
```

Acomapnhe o progresso por:
```sh
tail -f EDTA.log
```

sem nohup (para acompanhar o progresso)
```sh
$HOME/TEs/EDTA/EDTA.pl --genome ../AtChr4.fasta --species others --step all --line ../Atch4-LINE-lib.fa --sine ../AtCh4-Seed_SINE.fa --sensitive 1 --anno 1 --threads 10
```

Lembre-se de configurar as threads de acordo com suas máquina (neste estamos utilizando apenas 10) sua máquina pode conter menos ou mais em comparação ao código apresentado.

###Gerando o relatório completo
```sh
cd $HOME/TEs
cd AtCh4
mkdir TE-REPORT
cd TE-REPORT
ln -s ../AtChr4.fasta.mod.EDTA.anno/AtChr4.fasta.mod.cat.gz .

perl $HOME/TEs/ProcessRepeats/ProcessRepeats-complete.pl -species viridiplantae -nolow -noint AtChr4.fasta.mod.cat.gz

mv AtChr4.fasta.mod.tbl ../TEs-Report-Complete.txt
```
Gerando relatório simples
```sh
perl $HOME/TEs/ProcessRepeats/ProcessRepeats-lite.pl -species viridiplantae -nolow -noint -a AtChr4.fasta.mod.cat.gz

mv AtChr4.fasta.mod.tbl ../TEs-Report-lite.txt
```

### Gráficos de paisagem repetidos
Os gráficos de paisagem repetidos ilustram a quantidade relativa de cada classe TE associada à distância Kimura no eixo x como um proxy para o tempo. Em contraste, o eixo y fornece a cobertura comparável de cada classe de repetição com base no tamanho do genoma. Portanto, o gráfico de repetição da paisagem é uma inferência razoável das idades relativas de cada elemento identificado em um determinado genoma.

Na janela do seu terminal, execute:
```sh
cd $HOME/TEs
cd AtCh4
cd TE-REPORT

cat AtChr4.fasta.mod.align  | sed 's#TIR/.\+ #TIR &#g'  | sed 's#DNA/Helitron.\+ #Helitron &#g' | sed 's#LTR/Copia.\+ #LTR/Copia &#g' | sed 's#LTR/Gypsy.\+ #LTR/Gypsy &#g'  | sed 's#LINE-like#LINE#g' | sed 's#TR_GAG/Copia.\+ #LTR/Copia &#g' | sed 's#TR_GAG/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#TRBARE-2/Copia.\+ #LTR/Copia &#g' | sed 's#BARE-2/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#LINE/.\+ #LINE &#g' > tmp.txt
#

cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "LTR/Copia" -A 5 |  grep -v "\-\-"  > align2.txt
cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "LTR/Gypsy" -A 5 |  grep -v "\-\-"  >> align2.txt
cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "TIR" -A 5 |  grep -v "\-\-"  >> align2.txt
cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "LINE" -A 5 |  grep -v "\-\-"  >> align2.txt
cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "LARD" -A 5 |  grep -v "\-\-"  >> align2.txt
cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "TRIM" -A 5 |  grep -v "\-\-"  >> align2.txt
cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "Helitron" -A 5 |  grep -v "\-\-"  >> align2.txt
cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "SINE" -A 5 |  grep -v "\-\-"  >> align2.txt
cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "Unknown" -A 5 |  grep -v "\-\-"  >> align2.txt
#

perl $HOME/TEs/ProcessRepeats/calcDivergenceFromAlign.pl -s AtChr4.divsum align2.txt

genome_size="`perl $HOME/TEs/EDTA/util/count_base.pl ../AtChr4.fasta.mod | cut -f 2`" 
perl $HOME/TEs/ProcessRepeats/createRepeatLandscape.pl -g $genome_size -div AtChr4.divsum > ../RepeatLandscape.html
#
tail -n 72 AtChr4.divsum > divsum.txt
#
cat $HOME/TEs/Rscripts/plotKimura.R | sed "s#_SIZE_GEN_#$genome_size#g" > plotKimura.R
#
Rscript plotKimura.R
mv Rplots.pdf ../RepeatLandScape.pdf
#
rm align2.txt
rm tmp.txt
```
<img src="https://i.ibb.co/ScrCSqP/Repeat-Land-Scape.jpg" alt="Repeat-Land-Scape" border="0" />

### Plotagem de idade LTR (Gypsy e Copia)

Para traçar as idades dos elementos LTR Gypsy e LTR Copia, usaremos um Rscript ggplot2.
```sh
cd $HOME/TEs
cd AtCh4
mkdir LTR-AGE
cd LTR-AGE
ln -s ../AtChr4.fasta.mod.EDTA.raw/AtChr4.fasta.mod.LTR-AGE.pass.list .

ln -s $HOME/TEs/Rscripts/plot-AGE-Gypsy.R .
ln -s $HOME/TEs/Rscripts/plot-AGE-Copia.R .


cat -n AtChr4.fasta.mod.LTR-AGE.pass.list  | grep Gypsy  | cut -f 1,13 | sed 's# ##g'  | sed 's#^#Cluster_#g' | awk '{if ($2 > 0) print $n}'   > AGE-Gypsy.txt
cat -n AtChr4.fasta.mod.LTR-AGE.pass.list  | grep Copia  | cut -f 1,13 | sed 's# ##g'  | sed 's#^#Cluster_#g' | awk '{if ($2 > 0) print $n}'   > AGE-Copia.txt
#
# Generating the plots
Rscript plot-AGE-Gypsy.R
Rscript plot-AGE-Copia.R
```
Os arquivos finais são: AGE-Copia.pdf e AGE-Gypsys.pdf

<img src="https://i.ibb.co/s1MNPXT/AGE-Copia.jpg" alt="AGE-Copia" border="0">
<img src="https://i.ibb.co/b2bjRBx/AGE-Gypsy.jpg" alt="AGE-Gypsy" border="0">

### Plotar elementos LTR Filogenia e Densidade
Iremos traçar a filogenia dos alinhamentos de todos os domínios do LTR-RT.

```sh
cd $HOME/TEs
cd AtCh4
mkdir TREE
cd TREE


ln -s ../AtChr4.fasta.mod.EDTA.TElib.fa .
cat AtChr4.fasta.mod.EDTA.TElib.fa | sed 's/#/_CERC_/g'  | sed 's#/#_BARRA_#g'  > tmp.txt

mkdir tmp
break_fasta.pl < tmp.txt ./tmp
cat tmp/*LTR* | sed 's#_CERC_#\t#g' | cut -f 1 > TE.fasta
rm -f tmp.txt ; rm -f At.fasta.mod.EDTA.TElib.fa ; rm -Rf tmp


/usr/local/bin/TEsorter -db rexdb-plant --hmm-database rexdb-plant -pre TE -dp2 -p 40 TE.fasta

concatenate_domains.py TE.cls.pep GAG > GAG.aln
concatenate_domains.py TE.cls.pep PROT > PROT.aln
concatenate_domains.py TE.cls.pep RH > RH.aln
concatenate_domains.py TE.cls.pep RT > RT.aln
concatenate_domains.py TE.cls.pep INT > INT.aln
#
cat GAG.aln | cut -f 1 -d" " > GAG.fas
cat PROT.aln | cut -f 1 -d" " > PROT.fas
cat RH.aln | cut -f 1 -d" " > RH.fas
cat RT.aln | cut -f 1 -d" " > RT.fas
cat INT.aln | cut -f 1 -d" " > INT.fas


perl $HOME/TEs/Scripts/catfasta2phyml.pl -c -f *.fas > all.fas
iqtree2 -s all.fas -alrt 1000 -bb 1000 -nt AUTO 


cat TE.cls.tsv | cut -f 1 | sed "s#^#cat ../AtChr4.fasta.mod.EDTA.TEanno.sum | grep -w \"#g"  | sed 's#$#"#g'   > pick-occur.sh
bash pick-occur.sh  > occur.txt

cat occur.txt  | sed 's#^      TE_#TE_#g'  | awk '{print $1,$2,$3}' | sed 's# #\t#g' |  sort -k 2 -V  > sort_occur.txt
cat occur.txt  | sed 's#^      TE_#TE_#g'  | awk '{print $1,$2,$3}' | sed 's# #\t#g' |  sort -k 3 -V  > sort_size.txt

cat all.fas  | grep \> | sed 's#^>##g'   > ids.txt

cat sort_occur.txt | cut -f 1,2 | sed 's#^#id="#g' | sed 's#\t#" ; data="#g' | sed 's#$#" ; ver="`cat ids.txt | grep $id`" ; echo -e "$ver\\t$data" #g'   > pick.sh
bash pick.sh  | grep "^TE" | grep "^TE"  | sed 's/#/_/g' | sed 's#/#_#g'  > occurrences.tsv

cat sort_size.txt | cut -f 1,3 | sed 's#^#id="#g' | sed 's#\t#" ; data="#g' | sed 's#$#" ; ver="`cat ids.txt | grep $id`" ; echo -e "$ver\\t$data" #g'   > pick.sh
bash pick.sh  | grep "^TE" | grep "^TE"  | sed 's/#/_/g' | sed 's#/#_#g'  > size.tsv

rm -f pick-occur.sh sort_occur.txt sort_size.txt ids.txt pick.sh

ln -s $HOME/TEs/Rscripts/LTR_tree.R .
ln -s $HOME/TEs/Rscripts/LTR_tree-density.R .

Rscript LTR_tree.R all.fas.contree TE.cls.tsv LTR_RT-Tree1.pdf
Rscript LTR_tree-density.R all.fas.contree TE.cls.tsv occurrences.tsv size.tsv LTR_RT-Tree2.pdf
```
Os arquivos finais são: LTR_RT-Tree1.pdf e LTR_RT-Tree2.pdf

<img src="https://i.ibb.co/vVyqRfs/LTR-RT-Tree1.jpg" alt="LTR-RT-Tree1" border="0">

O círculo externo (roxo) representa o comprimento (em bp) ocupado por cada elemento, enquanto o círculo interno (vermelho) representa o número de ocorrências de cada elemento.

<img src="https://i.ibb.co/yfFgLCk/LTR-RT-Tree2.jpg" alt="LTR-RT-Tree2" border="0">

------
O guia de intslação foi resumido do [Plant genome Annotation](https://github.com/amvarani/Plant_Annotation_TEs)
Foi utilizado um arquivo contendo o cromossomo da A. thaliana para facilitar o processo de instalação e teste. Porém pode se feitos utilizando genomas maiores como A. thaliana completa ou T. cacao

------

## Executando a plataforma web
Acesse a pasta www para ter acesso aos conteudos da plataforma e crie a variavel de ambiente para se trabalhar com flask e suas aplicações
```sh
python3 -m venv .venv
..venv/bin/activate
```

Instale alguns pacotes pip para funcionamento da aplicação (sendo utilizado somente uma vez):
```sh
pip install -r ../required.txt 
```
Dentro do required.txt encontrasse os paoctes fundamenteis como Flask e python-dotenv.

Caso algum pacote apresentar erro, será necessários realizar ainstalação manualmente.

Após esse comando você pode está criando o arquivo <b> .flaskenv </b> e configurando as váriaveis, exemplo:
```sh
FLASK_APP = "main.py"
FLASK_DEBUG = True
FLASK_ENV = development
```
----
A primeira,<b>FLASK_APP</b> pode ser deixada vazia e então ele procurará por "app" ou "wsgi" (com ou sem o ".py" no final, ou seja, pode ser um arquivo ou um módulo) mas você pode usar:
* Um módulo a ser importado, como FLASK_APP=hello.web;
* Um arquivo/módulo no diretório atual, por exemplo FLASK_APP=src/hello;
* Uma instância específica dentro do módulo, algo como FLASK_APP=hello:app2 ou
* Executar diretamente a factory create_app() e até com passagem de parâmetros, tipo FLASK_APP=hello:create_app('dev')".
* 
A váriavel <b>FLASK_DEBUG</b> ativá a depuração do código

E por último, a variável <b>FLASK_ENV</b> definirá o tipo de ambiente projeto, os valores reconhecidos são dois, "production" e "development", se nenhum valor for definido "production" é utilizado por padrão.

Outras informações sobre as váriaveis de desenvolvimento poderá ser encontrado no site do [Flask](https://flask.palletsprojects.com/en/2.3.x/cli/#dotenv)

----

Com o flask configurado. Configure o mongodb compass (também pode optarpor mongodb container)

No MongoDB Compass configure uma nova conexão (New Connection) com o  endereço:
```sh
mongodb://localhost:27017
```
E aperte conectar (connect)

Agora dentro da pasta www e no ambiente criado, execute:
```sh
flask run
```
Se todas as configurações estiverem corretas, a mensagem deverá aparecer:
```sh
 * Serving Flask app 'main.py' (lazy loading)
 * Environment: development
 * Debug mode: on
 * Running on http://127.0.0.1:5000/ (Press CTRL+C to quit)
 * Restarting with stat
 * Debugger is active!
 * Debugger PIN: 264-075-516
```
Click sobre  http://127.0.0.1:5000/ ou copie e cole no navegador e comece a testa a platafroma.
