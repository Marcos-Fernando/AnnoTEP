<div align="center"> 
    <img src="graphic-interface/static/assets/Logo2.svg" alt="Logo2">
</div><br>

<div align="center">

![Linux version](https://img.shields.io/badge/PLATFORM-Linux_64-orange) ![Python](https://img.shields.io/badge/LANGUAGE-Python-blue) ![Install](https://img.shields.io/badge/Container-Docker-4682B4) ![License](https://img.shields.io/badge/LICENSE-GPL_v3.0-D3D3D3)
</div>


# AnnoTEP
AnnoTEP is a platform designed for the annotation of transposable elements (TEs) in plant genomes. Developed on the basis of the [EDTA](https://github.com/oushujun/EDTA) pipeline, the tool incorporates specific modifications inspired by [Plant genome Annotation](https://github.com/amvarani/Plant_Annotation_TEs) pipeline, as well as adjustments that improve its performance and flexibility. One of AnnoTEP's great differentials is its user-friendly interface, built with HTML and Python technologies, which makes the process accessible even to researchers with little familiarity with command lines. Combining efficiency, customisation and ease of use, AnnoTEP offers a powerful solution for the analysis and annotation of TEs, contributing to significant advances in plant genomic research.

AnnoTEP is currently available in three formats: web server, container with graphic interface and container with bash interface. Clicking on each format below will take you to the system where you can access or install the platform:
- [Web Server](https://plantgenomics.ncc.unesp.br/AnnoTEP/) 
- [Graphic Interface](#graphic-interface)
- [Bash Interface](#bash-interface)

## Tool functions
* Identification of non-autonomous LTR elements, such as TRIM, LARD, TR-GAG, and BARE2;
* Identification of soloLTR;
* Identification of non-autonomous TIR elements, such as MITE;
* In-depth analysis of autonomous and non-autonomous Helitron elements.
* Genome masking (local mode)
* Report generation on TEs
* Generation of graphs illustrating repeated elements
* Generation of age graphs for Gypsy and Copia elements
* Generation of LTR phylogeny and density graphs
<br>

# Table of contents
* [Installation with Container](#installation-with-container)
    * [Graphic Interface](#graphic-interface)
    * [Bash Interface](#bash-interface)
* [Installation with Github](#installation-with-github)
    * [Organizing the environment](#organizing-the-environment)
    * [Results](#results)
    * [Running the platform with a graphical interface via github](#running-the-platform-with-a-graphical-interface-via-github)
    * [Running the platform with bash interface via github](#running-the-platform-with-bash-interface-via-github)
<br>

# Installation with Container
AnnoTEP can be installed on the machine in different ways, one of which is using Docker. The tool is available in two formats: with a graphical interface and without an interface (terminal mode). To follow the steps below, you need to have Docker installed on your machine. You can download it directly from the official [Docker website](https://docs.docker.com/engine/install/)


## Graphic Interface
<div align="center"> 
    <img src="graphic-interface/static/assets/Graphic-interface-logo.svg" alt="Logo3" width="350px">
</div><br>

**Important**: for this version your machine must have access to the internet network

Open the terminal and run the following commands:

**Step 1.** Download the AnnoTEP image:
```sh
docker pull annotep/graphic-interface:v2
```

**Step 2.** Next, run the container with the command below, specifying a folder to store the annotation results on your machine:
```sh
docker run -it -v {folder-results}:/root/TEs/graphic-interface/results -dp 0.0.0.0:5000:5000 --pids-limit {threads x 10000} --memory-swap -1 annotep/graphic-interface:v2
```

### Description:
- ``-v {folder-results}:/root/TEs/graphic-interface/results``: This creates a volume between the host and the container to store data. You can replace ``-v {folder-results}`` with any folder path on your machine, if you don't have the folder created Docker will create it. ``/root/TEs/graphic-interface/results`` is the path of the directory folder, you don't need to change it.
- ``-dp 0.0.0.0:5000:5000``: Maps the container's port 5000 to the host's port 5000.
- ``annotep/graphic-interface:v2``: Specifies the image to be used.
- ``--pids-limit {threads x 10000}``: Defines the limit of processes that the container can create. **Example:** If you use 12 threads, the value will be 120,000. This ensures that each thread can create subprocesses without exhausting the process limit, maintaining performance at high load.
- ``--memory-swap -1``: Disables the swap usage limit. This allows the container to use unlimited virtual memory, helping to avoid errors when physical RAM is insufficient.

#### Example:
```sh
docker run -it -v $HOME/results-annotep:/root/TEs/graphic-interface/results -dp 0.0.0.0:5000:5000 --pids-limit 120000 --memory-swap -1 annotep/graphic-interface:v2
```

**Step 3.** After running the container with the previous command, access the AnnoTEP interface by typing the following address into your web browser: 
``127.0.0.1:5000``

**Step 4.** When you access 127.0.0.1:5000 you will see a version of the AnnoTEP platform similar to the WEB version. 

* If you want to run tests, you can download the file _Arabidopsis thaliana_ (Chromosome 4) `AtChr4.fasta` from the repository. **The annotation process can take 1 hour if 10 threads are used.**.

* This version includes a field for the number of threads when using and it is recommended that you have at least 4 threads on your machine. **Please note that the fewer the threads, the longer it will take to analyze the element.**

**Step 5.** Within the interface you can enter your data such as: email, genome and annotation type and send it for analysis. When the work is completed without any errors, you will receive an e-mail informing you that the results are available in the directory entered in ``-v {folder-results}``.

**Step 6:** You can follow the progress of the annotation via the Docker logs.
   * In the terminal, type ``docker ps``.
   * A list of active containers will appear. Select the ``CONTAINER ID`` of the AnnoTEP image.
   * With the ID copied, type and paste: ``docker logs -f {CONTAINER ID}``.

**Important2**: Avoid shutting down the machine during the process, as this could interrupt the data analysis. Even when using the web system, processing takes place locally on your machine.

**Important3**: Bear in mind that the speed of the annotation will depend on the performance of your local machine.

Return to [Table of contents](#table-of-contents)

## Bash Interface
<div align="center"> 
    <img src="graphic-interface/static/assets/Bash-interface-logo.svg" alt="Logo4" width="350px">
</div><br>

**Step 1.** Download the AnnoTEP image:
```sh
docker pull annotep/bash-interface:v2
```

**Step 2.** Use the ``-h`` parameter to display a user guide describing how to use the script:

```sh
docker run annotep/bash-interface:v2 python run_annotep.py -h
```
- You will be introduced to:
```sh
usage: run_annotep.py [-h] --genome GENOME --threads THREADS
                      [--species {Rice,Maize,others}]
                      [--step {all,filter,final,anno}] [--sensitive {0,1}]
                      [--overwrite {0,1}] [--anno {0,1}] [--evaluate {0,1}]
                      [--force {0,1}] [--u U] [--maxdiv [0-100]] [--cds CDS]
                      [--curatedlib CURATEDLIB] [--exclude EXCLUDE]
                      [--rmlib RMLIB] [--rmout RMOUT]

Run annotep with specified parameters.

optional arguments:
  -h, --help            show this help message and exit

required arguments:
  --genome GENOME       The genome FASTA file (.fasta)
  --threads THREADS     Number of threads used to complete annotation (default threads: 4)

optional arguments:
  --species {Rice,Maize,others}
                        Specify the species for identification of TIR candidates. Default: others
  --step {all,filter,final,anno}
                        Specify which steps you want to run EDTA.
  --sensitive {0,1}     Use RepeatModeler to identify remaining TEs (1) or not (0, default). This step may help to recover some TEs.
  --overwrite {0,1}     If previous raw TE results are found, decide to overwrite (1, rerun) or not (0, default).
  --anno {0,1}          Perform (1) or not perform (0, default) whole-genome TE annotation after TE library construction.
  --evaluate {0,1}      Evaluate (1) classification consistency of the TE annotation. (--anno 1 required).
  --force {0,1}         When no confident TE candidates are found: 0, interrupt and exit (default); 1, use rice TEs to continue.
  --u U                 Neutral mutation rate to calculate the age of intact LTR elements. Intact LTR age is found in this file: *EDTA_raw/LTR/*.pass.list. Default: 1.3e-8 (per bp per year, from rice).
  --maxdiv [0-100]      Maximum divergence (0-100, default: 40) of repeat fragments comparing to library sequences.
  --cds CDS             Provide a FASTA file containing the coding sequence (no introns, UTRs, nor TEs) of this genome or its close relative.
  --curatedlib CURATEDLIB
                        Provided a curated library to keep consistant naming and classification for known TEs. TEs in this file will be trusted 100%, so please ONLY provide MANUALLY CURATED ones. This option is not mandatory. It is totally OK if no file is provided (default).
  --exclude EXCLUDE     Exclude regions (bed format) from TE masking in the MAKER.masked output. Default: undef. (--anno 1 required).
  --rmlib RMLIB         Provide the RepeatModeler library containing classified TEs to enhance the sensitivity especially for LINEs. If no file is provided (default), EDTA will generate such file for you.
  --rmout RMOUT         Provide your own homology-based TE annotation instead of using the EDTA library for masking. File is in RepeatMasker .out format. This file will be merged with the structural-based TE annotation. (--anno 1 required). Default: use the EDTA library for annotation.
```
<br>

**Your options maintain similar parameters to the EDTA pipeline**
<br>

**Step 3.** To simplify this step, we recommend creating a folder to insert your genomic data in FASTA format. Once created, run the container using the command below as a guide. Make sure you provide the full path to the folder where you want to save the results, as well as the full path to the genomes folder:

```sh
docker run -it -v {folder-results}:/root/TEs/results -v {absolute-path-to-folder-genomes}:{absolute-path-to-folder-genomes} --pids-limit {threads x 10000} --memory-swap -1 annotep/bash-interface:v2 python run_annotep.py --genome {absolute-path-to-folder-genomes/genome.fasta} --threads {number}
```

### Description:
- ``-v {folder-results}:/root/TEs/results``: This creates a volume between the host and the container to store data. You can replace ``-v {folder-results}`` with any folder path on your machine where you want to save the results, if you don't have the folder created Docker will create it. ``/root/TEs/www/results`` is the directory folder path, you don't need to change it.
- ``-v {absolute-path-to-folder-genomes}:{absolute-path-to-folder-genomes}``: It is responsible for creating a temporary copy of the genomic files inside Docker, which is why you must enter the correct address of the folder that stores the genomes in ``{absolute-path-to-folder-genomes}``.
- ``--genome {absolute-path-to-folder-genomes/genome.fasta}``: Here you must enter the correct address of the folder that stores the genomes along with the name of the genome you want to annotate.
- ``--threads {number}``: define the number of threads.
- ``--pids-limit {threads x 10000}``: Defines the limit of processes that the container can create. **Example:** If you use 12 threads, the value will be 120,000. This ensures that each thread can create subprocesses without exhausting the process limit, maintaining performance at high load.
- ``--memory-swap -1``: Disables the swap usage limit. This allows the container to use unlimited virtual memory, helping to avoid errors when physical RAM is insufficient.

* If you want to run tests, you can download the file _Arabidopsis thaliana_ (Chromosome 4) `AtChr4.fasta` from the repository. **The annotation process can take 1 hour if 10 threads are used.**.


#### Example 1:
```sh
docker run -it -v $HOME/results-annotep:/root/TEs/results -v /home/user/Documents/TEs:/home/user/Documents/TEs --pids-limit 120000 --memory-swap -1 annotep/bash-interface:v2 python run_annotep.py --genome /home/user/TEs/AtChr4.fasta
```

**Step 4.** Now wait for the genome annotation to be completed by following the analysis through the terminal

Return to [Table of contents](#table-of-contents)
<br>

# Installation with Github
 * The installation guide to be presented was adapted from [Plant genome Annotation](https://github.com/amvarani/Plant_Annotation_TEs), with some modifications throughout the code. 
 * **Plant Genome Annotation** uses modified code from the [AnnoSINE](https://github.com/baozg/AnnoSINE), [MGEScan-non-LTR](https://github.com/MGEScan), [TEsorter](https://github.com/zhangrengang/TEsorter) and [EDTA](https://github.com/oushujun/EDTA) pipelines.

## Prerequisites
- [Python 3.6+](https://www.python.org/)

- [Miniconda3](https://docs.conda.io/projects/miniconda/en/latest/)

- [R 4.4+](https://cran.r-project.org/bin/linux/ubuntu/fullREADME.html)

- System Ubuntu (20.04.6 LTS, 22.04.4 LTS)

#### MiniConda install
After downloading miniconda from the link above, run it in the terminal window:
```sh
bash Miniconda3-latest-Linux-x86_64.sh
```

## Download the repository
**Step 1.** In the terminal run:
```sh
git clone https://github.com/Marcos-Fernando/AnnoTEP_v1.git $HOME/TEs
```

**Step 2.** Access the repository location on the machine:
```sh
cd $HOME/TEs
```

Note: Pay attention to the name of the folder. In this guide, we will be using the folder named ``TEs``. To make configuration easier, we recommend using this name.

## Configuring the repository
### Libraries
**Step 1.** In the terminal download the following libraries:
```sh
sudo apt-get install libgdal-dev lib32z1 python-is-python3 python3-setuptools python3-biopython python3-xopen trf hmmer2 seqtk
sudo apt-get install hmmer emboss python3-virtualenv python2 python2-setuptools-whl python2-pip-whl cd-hit iqtree
sudo apt-get install python2-dev build-essential linux-generic libmpich-dev libopenmpi-dev bedtools pullseq bioperl
sudo apt-get install pdf2svg

# R dependencies
sudo apt-get install r-cran-ggplot2 r-cran-tidyr r-cran-reshape2 r-cran-reshape rs r-cran-viridis r-cran-tidyverse r-cran-gridextra r-cran-gdtools r-cran-phangorn r-cran-phytools r-cran-ggrepel
```
Access the R program from the terminal and install libraries from within it:
```sh
R

install.packages("hrbrthemes")

if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("ggtree")
BiocManager::install("ggtreeExtra")
```

- In the event of an error with BiocManager or the ggtree and ggtreeExtra packages, you can use another method:
```sh
if (!requireNamespace("devtools", quietly = TRUE))
    install.packages("devtools")
devtools::install_github("YuLab-SMU/ggtree")
devtools::install_github("YuLab-SMU/ggtreeExtra")
```

**Step 2.** After installing the libraries, copy the ``irf`` and ``break_fasta.pl`` scripts to local/bin on your machine:
```sh
sudo cp Scripts/irf /usr/local/bin
sudo cp Scripts/break_fasta.pl /usr/local/bin
```

**Step 3.** Then configure the TEsorter:
```sh
cd $HOME/TEs/TEsorter
sudo python3 setup.py install
```

Check the version of python on the machine to proceed with the configuration
* Python 3.7
```sh
cd /usr/local/lib/python3.7/dist-packages/TEsorter-1.4.1-py3.6.egg/TEsorter/database/
```

* Python 3.10
```sh
cd /usr/local/lib/python3.10/dist-packages/TEsorter-1.4.1-py3.10.egg/TEsorter/database/
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
### Downloading genomes for testing
At this stage you can choose to use your data or download some examples for testing:
* _Theobrama cacao_
```sh
wget https://cocoa-genome-hub.southgreen.fr/sites/cocoa-genome-hub.southgreen.fr/files/download/Theobroma_cacao_pseudochromosome_v1.0_tot.fna.tar.gz
tar xvfz Theobroma_cacao_pseudochromosome_v1.0_tot.fna.tar.gz
mv Theobroma_cacao_pseudochromosome_v1.0_tot.fna Tcacao.fasta
rm Theobroma_cacao_pseudochromosome_v1.0_tot.fna.tar.gz
```

* _Arabidopsis thaliana_ 
```sh
wget https://www.arabidopsis.org/download_files/Genes/TAIR10_genome_release/TAIR10_chromosome_files/TAIR10_chr_all.fas.gz
gzip -d TAIR10_chr_all.fas.gz
cat TAIR10_chr_all.fas | cut -f 1 -d" " > At.fasta
rm TAIR10_chr_all.fas
```

<!-- If the link fails, try it:
```sh
wget --header="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
"https://www.arabidopsis.org/download_files/Genes/TAIR10_genome_release/TAIR10_chromosome_files/TAIR10_chr_all.fas.gz"
``` -->


* If you can't download _Arabidopsis thaliana_ automatically, you can download it directly from [tair](https://www.arabidopsis.org/download/list?dir=Genes%2FTAIR10_genome_release%2FTAIR10_chromosome_files), by clicking on `TAIR10_chr_all.fas.gz` and following the steps in the command above from the second line onwards.


### Configuring modified EDTA
**Step 1.** Install and activate the EDTA conda environment:
```sh
cd EDTA
bash

conda env create -f EDTA_2.2.x.yml
conda activate EDTA2
perl EDTA.pl
```

**Step 2.** Running EDTA:
```sh
cd ..
mkdir Athaliana
cd Athaliana

nohup $HOME/TEs/EDTA/EDTA.pl --genome ../At.fasta --species others --step all --sensitive 1 --anno 1 --threads 12 > EDTA.log 2>&1 &
```

**Step 3.** Track progress by:
```sh
tail -f EDTA.log
```

**Notes:**

**1.** Set the number of threads available on your computer or server. Set the maximum available. In our code it is set to 12.

**2.** For more accurate TE detection and annotation, activate the "sensitive" flag. This will activate the RepeatModeler to identify remaining TEs and other repeats. The RepeatModeler step will also generate the Superfamily and Lineage TE classification.
<br>

---
### Smooth masking
Generally, non-autonomous elements can carry passenger genes (for example, non-autonomous LARDs and Helitrons). Therefore, for proper annotation of the genome, these elements must be partially masked. The modified EDTA pipeline will take care of this automatically and generate a suitably masked genome sequence for structural gene annotation. The softmasked genome sequence is available in the EDTA folder, with the name $genome-Softmasked.fa .

---
<br>

Return to [Table of contents](#table-of-contents)

# Results
## Generating reports
Still in the EDTA environment run:
```sh
cd $HOME/TEs
cd Athaliana
mkdir TE-REPORT
cd TE-REPORT
ln -s ../At.fasta.mod.EDTA.anno/At.fasta.mod.cat.gz .

perl $HOME/TEs/ProcessRepeats/ProcessRepeats-complete.pl -species viridiplantae -nolow -noint At.fasta.mod.cat.gz
mv At.fasta.mod.tbl TEs-Report-Complete.txt

perl $HOME/TEs/ProcessRepeats/ProcessRepeats-lite.pl -species viridiplantae -nolow -noint -a At.fasta.mod.cat.gz
mv At.fasta.mod.tbl TEs-Report-Lite.txt
```

The results obtained are: ``TEs-Report-Completo.txt`` and ``TEs-Report-Lite.txt``.
- ``TEs-Report-Complete.txt`` presents a table containing the classifications of the transposable elements, the partial elements named with the suffix “-like” (e.g. Angela-like);
<div align="center">
    <img src="graphic-interface/static/screenshot/TEs-Complete.png" alt="TEs-Complete" border="0" width="550px" />
</div>

- ``TEs-Report-Lite.txt`` generates a report similar to Report-Complete, but simpler.

<div align="center">
    <img src="graphic-interface/static/screenshot/TEs-Lite.png" alt="TEs-Lite" border="0" width="550px"/>
</div>

Continuing in the TE-REPORT folder, we will generate the graphs, using ``TEs-Report-Lite.txt`` as a base.

```sh
cat TEs-Report-Lite.txt | grep "%"   | cut -f 2 -d":"   | awk '{print $1}' > count.txt
cat TEs-Report-Lite.txt | grep "%"   | cut -f 2 -d":"   | awk '{print $2}' > bp.txt
cat TEs-Report-Lite.txt | grep "%"   | cut -f 2 -d":"   | awk '{print $4}' > percentage.txt
cat TEs-Report-Lite.txt | grep "%"   | cut -f 1 -d":"   | sed 's# ##g'  | sed 's#-##g'  | sed 's#|##g' > names.txt
	
paste names.txt count.txt bp.txt percentage.txt | grep -w NonLTR  > plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w LTRNonauto | sed 's#LTRNonauto#LTR_nonauto#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "LTR/Copia"  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "LTR/Gypsy"  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "Pararetrovirus"  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "ClassIUnknown" | sed 's#ClassIUnknown#Class_I_Unknown#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "TIRs"  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "ClassIIUnknown" | sed 's#ClassIIUnknown#Class_II_Unknown#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "Unclassified"  >> plot.txt
echo "Type	Number	length	percentage" > header.txt
cat header.txt plot.txt > plot1.txt
python $HOME/TEs/Scripts/plot_TEs.py
mv TE-Report.pdf TE-Report1.pdf
pdf2svg TE-Report1.pdf TE-Report1.svg
python $HOME/TEs/Scripts/plot_TEs-bubble.py
mv TE-Report.pdf TE-Report1-bubble.pdf
pdf2svg TE-Report1-bubble.pdf TE-Report1-bubble.svg
	
paste names.txt count.txt bp.txt percentage.txt | grep -w SINEs > plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w LINEs >> plot.txt
	
paste names.txt count.txt bp.txt percentage.txt | grep -w LARDs >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w TRIMs >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w TR_GAG >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w BARE2 >> plot.txt
	
paste names.txt count.txt bp.txt percentage.txt | grep -w Ale >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Alesia >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Angela >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Bianca >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Bryco >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Lyco >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w GymcoI >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w GymcoII >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w GymcoIII >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w GymcoIV >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Ikeros >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Ivana >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Osser >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w SIRE >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w TAR >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Tork >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Ty1outgroup | sed 's#Ty1outgroup#Ty1-outgroup#g' >> plot.txt
	
paste names.txt count.txt bp.txt percentage.txt | grep -w Phygy >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Selgy >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w OTA >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w OTAAthila | sed 's#OTAAthila#Athila#g'  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w OTATatI | sed 's#OTATatI#TatI#g'  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w OTATatII | sed 's#OTATatII#TatII#g'  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w OTATatIII | sed 's#OTATatIII#TatIII#g'  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w OTATatOgre | sed 's#OTATatOgre#Ogre#g'  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w OTATatRetand | sed 's#OTATatRetand#Retand#g'  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Chlamyvir >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Tcn1 >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w CRM >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Galadriel >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Tekay >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Reina >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w MITE >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w EnSpm_CACTA | sed 's#EnSpm_CACTA#CACTA#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w hAT >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w MuDR_Mutator | sed 's#MuDR_Mutator#MuDR#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w PIF_Harbinger | sed 's#PIF_Harbinger#Harbinger#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "RC/Helitron" | sed 's#RC/Helitron#Helitron#g' >> plot.txt
	
cat header.txt plot.txt > plot1.txt
python $HOME/TEs/Scripts/plot_TEs.py
mv TE-Report.pdf TE-Report2.pdf
pdf2svg TE-Report2.pdf TE-Report2.svg
    
python $HOME/TEs/Scripts/plot_TEs-bubble.py
mv TE-Report.pdf TE-Report2-bubble.pdf
pdf2svg TE-Report2-bubble.pdf TE-Report2-bubble.svg
```

The data obtained will be:
<div align="center">
    <img src="graphic-interface/static/screenshot/TE-Report1.svg" alt="TE-Report1" border="0" width="650px" />
    <img src="graphic-interface/static/screenshot/TE-Report1-bubble.svg" alt="TE-Report1-bubble" border="0" width="650px" />
    <img src="graphic-interface/static/screenshot/TE-Report2.svg" alt="TE-Report2" border="0" width="650px" />
    <img src="graphic-interface/static/screenshot/TE-Report2-bubble.svg" alt="TE-Report2-bubble" border="0" width="650px" />
</div>


## Repeated landscape graphs
The landscape repeat graph is a reasonable inference of the relative ages of each element identified in a given genome. To create it we will use the file with the ``.align`` extension created after using ``ProcessRepeats-lite.pl``

In the terminal, run:
```sh
cd $HOME/TEs
cd Athaliana/TE-REPORT

cat At.fasta.mod.align  | sed 's#TIR/.\+ #TIR &#g'  | sed 's#DNA/Helitron.\+ #Helitron &#g' | sed 's#LTR/Copia.\+ #LTR/Copia &#g' | sed 's#LTR/Gypsy.\+ #LTR/Gypsy &#g'  | sed 's#LINE-like#LINE#g' | sed 's#TR_GAG/Copia.\+ #LTR/Copia &#g' | sed 's#TR_GAG/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#TRBARE-2/Copia.\+ #LTR/Copia &#g' | sed 's#BARE-2/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#LINE/.\+ #LINE &#g' > tmp.txt
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

perl $HOME/TEs/ProcessRepeats/calcDivergenceFromAlign.pl -s At.divsum align2.txt

genome_size="`perl $HOME/TEs/EDTA/util/count_base.pl ../At.fasta.mod | cut -f 2`" 
perl $HOME/TEs/ProcessRepeats/createRepeatLandscape.pl -g $genome_size -div At.divsum > RepeatLandscape.html

tail -n 72 At.divsum > divsum.txt

cat $HOME/TEs/Rscripts/plotKimura.R | sed "s#_SIZE_GEN_#$genome_size#g" > plotKimura.R

Rscript plotKimura.R
mv Rplots.pdf RepeatLandScape.pdf
pdf2svg RepeatLandScape.pdf RLandScape.svg

rm align2.txt
rm tmp.txt
```

The graphics obtained will be: ``RepeatLandScape.pdf`` and ``RLandScape.svg``.
<div align="center">
    <img src="graphic-interface/static/screenshot/RLandScape.svg" alt="Repeat-Land-Scape" border="0" width="650px" />
</div>

### LTR age plot (Gypsy and Copia)
To plot the ages of the LTR Gypsy and LTR Copia elements, we will use a ggplot2 Rscript.
```sh
cd $HOME/TEs
cd Athaliana
mkdir LTR-AGE
cd LTR-AGE
ln -s ../At.fasta.mod.EDTA.raw/At.fasta.mod.LTR-AGE.pass.list .

ln -s $HOME/TEs/Rscripts/plot-AGE-Gypsy.R .
ln -s $HOME/TEs/Rscripts/plot-AGE-Copia.R .

cat -n At.fasta.mod.LTR-AGE.pass.list  | grep Gypsy  | cut -f 1,13 | sed 's# ##g'  | sed 's#^#Cluster_#g' | awk '{if ($2 > 0) print $n}'   > AGE-Gypsy.txt
cat -n At.fasta.mod.LTR-AGE.pass.list  | grep Copia  | cut -f 1,13 | sed 's# ##g'  | sed 's#^#Cluster_#g' | awk '{if ($2 > 0) print $n}'   > AGE-Copia.txt

Rscript plot-AGE-Gypsy.R
Rscript plot-AGE-Copia.R

pdf2svg AGE-Copia.pdf AGE-Copia.svg
pdf2svg AGE-Gypsy.pdf AGE-Gypsy.svg
```
The final files are: ``AGE-Copia.pdf``, ``AGE-Gypsys.pdf``, ``AGE-Copia.svg`` and ``AGE-Gypsy.svg``.

<div align="center">
    <img src="graphic-interface/static/screenshot/AGE-Copia.svg" alt="AGE-Copia" border="0" width="650px">
    <img src="graphic-interface/static/screenshot/AGE-Gypsy.svg" alt="AGE-Gypsy" border="0" width="650px">
</div>

### Plotting LTR elements Phylogeny and Density
Plotting the phylogeny of the alignments of all the LTR-RT domains.
```sh
cd $HOME/TEs
cd Athaliana
mkdir TREE
cd TREE

ln -s ../At.fasta.mod.EDTA.TElib.fa .
cat At.fasta.mod.EDTA.TElib.fa | sed 's/#/_CERC_/g'  | sed 's#/#_BARRA_#g'  > tmp.txt

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

cat GAG.aln | cut -f 1 -d" " > GAG.fas
cat PROT.aln | cut -f 1 -d" " > PROT.fas
cat RH.aln | cut -f 1 -d" " > RH.fas
cat RT.aln | cut -f 1 -d" " > RT.fas
cat INT.aln | cut -f 1 -d" " > INT.fas

perl $HOME/TEs/Scripts/catfasta2phyml.pl -c -f *.fas > all.fas
iqtree2 -s all.fas -alrt 1000 -bb 1000 -nt AUTO 

cat TE.cls.tsv | cut -f 1 | sed "s#^#cat ../At.fasta.mod.EDTA.TEanno.sum | grep -w \"#g"  | sed 's#$#"#g'   > pick-occur.sh
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
ln -s $HOME/TEs/Rscripts/LTR_tree_rec_1.R .
ln -s $HOME/TEs/Rscripts/LTR_tree_rec_2.R .

Rscript LTR_tree.R all.fas.contree TE.cls.tsv LTR_RT-Tree1.pdf
Rscript LTR_tree-density.R all.fas.contree TE.cls.tsv occurrences.tsv size.tsv LTR_RT-Tree2.pdf
Rscript LTR_tree_rec_1.R all.fas.contree TE.cls.tsv LTR_RT-Tree3.pdf
Rscript LTR_tree_rec_2.R all.fas.contree TE.cls.tsv LTR_RT-Tree4.pdf

pdf2svg LTR_RT-Tree1.pdf LTR_RT-Tree1.svg
pdf2svg LTR_RT-Tree2.pdf LTR_RT-Tree2.svg
pdf2svg LTR_RT-Tree3.pdf LTR_RT-Tree3.svg
pdf2svg LTR_RT-Tree4.pdf LTR_RT-Tree4.svg
```
The files generated will be: ``LTR_RT-Tree1.pdf``, ``LTR_RT-Tree2.pdf``, ``LTR_RT-Tree3.pdf``, ``LTR_RT-Tree4.pdf``, ``LTR_RT-Tree1.svg``, ``LTR_RT-Tree2.svg``, ``LTR_RT-Tree3.svg`` and ``LTR_RT-Tree2.svg``.

<div align="center">
    <img src="graphic-interface/static/screenshot/LTR_RT-Tree1.svg" alt="LTR-RT-Tree1" border="0" width="750px">
    <img src="graphic-interface/static/screenshot/LTR_RT-Tree3.svg" alt="LTR-RT-Tree3" border="0" width="750px">
    <img src="graphic-interface/static/screenshot/LTR_RT-Tree4.svg" alt="LTR-RT-Tree4" border="0" width="750px">
    <img src="graphic-interface/static/screenshot/LTR_RT-Tree2.svg" alt="LTR-RT-Tree2" border="0" width="750px">
</div>

- The outer circle (purple) represents the length (in bp) occupied by each element, while the inner circle (red) represents the number of occurrences of each element.

<br>

Return to [Table of contents](#table-of-contents)

<br>

# Running the platform with a graphical interface via github
**Step 1.** Access the ``graphic-interface`` folder folder and create a Python virtual environment by running the following commands in your terminal. Make sure you have done the [environment setup](#organizing-theenvironment) before proceeding.
```sh
python -m venv .graphic

. .graphic/bin/activate
```
<br>

**Step 2:** Install the packages needed for the application by running the following command (this only needs to be done once):
```sh
pip install -r required.txt 
```
- Inside the ``required.txt`` file, you'll find the fundamental libraries, such as Flask and python-dotenv. If any package shows an error, you'll need to install it manually.

**Step 3:** Now, inside the "graphic-interface" folder and with the virtual environment activated, run the following command to start the application:
```sh
flask run
```

If all the settings are correct, you will see a message similar to this one:
```sh
 * Serving Flask app 'main.py' (lazy loading)
 * Environment: development
 * Debug mode: on
 * Running on http://127.0.0.1:5000/ (Press CTRL+C to quit)
 * Restarting with stat
 * Debugger is active!
 * Debugger PIN: 264-075-516
```

**Step 4.** Click on the link http://127.0.0.1:5000/ or copy and paste it into your browser to access the platform and start testing it.

<br>

# Running the platform with bash interface via github
**Step 1.** Access the ``bash-interface`` folder folder and create a Python virtual environment by running the following commands in your terminal. Make sure you have done the [environment setup](#organizing-theenvironment) before proceeding.
```sh
python -m venv .venv

. .venv/bin/activate
```

**Step 2.** Go to the "local" folder and run the ``run_annotep.py`` script by typing the following command:
```sh
python run_annotep.py -h
```

- The ``-h`` parameter displays a user guide describing how to use the script:
```sh
usage: run_annotep.py [-h] --genome GENOME --threads THREADS
                      [--species {Rice,Maize,others}]
                      [--step {all,filter,final,anno}] [--sensitive {0,1}]
                      [--overwrite {0,1}] [--anno {0,1}] [--evaluate {0,1}]
                      [--force {0,1}] [--u U] [--maxdiv [0-100]] [--cds CDS]
                      [--curatedlib CURATEDLIB] [--exclude EXCLUDE]
                      [--rmlib RMLIB] [--rmout RMOUT]

Run annotep with specified parameters.

optional arguments:
  -h, --help            show this help message and exit

required arguments:
  --genome GENOME       The genome FASTA file (.fasta)
  --threads THREADS     Number of threads used to complete annotation (default threads: 4)

optional arguments:
  --species {Rice,Maize,others}
                        Specify the species for identification of TIR candidates. Default: others
  --step {all,filter,final,anno}
                        Specify which steps you want to run EDTA.
  --sensitive {0,1}     Use RepeatModeler to identify remaining TEs (1) or not (0, default). This step may help to recover some TEs.
  --overwrite {0,1}     If previous raw TE results are found, decide to overwrite (1, rerun) or not (0, default).
  --anno {0,1}          Perform (1) or not perform (0, default) whole-genome TE annotation after TE library construction.
  --evaluate {0,1}      Evaluate (1) classification consistency of the TE annotation. (--anno 1 required).
  --force {0,1}         When no confident TE candidates are found: 0, interrupt and exit (default); 1, use rice TEs to continue.
  --u U                 Neutral mutation rate to calculate the age of intact LTR elements. Intact LTR age is found in this file: *EDTA_raw/LTR/*.pass.list. Default: 1.3e-8 (per bp per year, from rice).
  --maxdiv [0-100]      Maximum divergence (0-100, default: 40) of repeat fragments comparing to library sequences.
  --cds CDS             Provide a FASTA file containing the coding sequence (no introns, UTRs, nor TEs) of this genome or its close relative.
  --curatedlib CURATEDLIB
                        Provided a curated library to keep consistant naming and classification for known TEs. TEs in this file will be trusted 100%, so please ONLY provide MANUALLY CURATED ones. This option is not mandatory. It is totally OK if no file is provided (default).
  --exclude EXCLUDE     Exclude regions (bed format) from TE masking in the MAKER.masked output. Default: undef. (--anno 1 required).
  --rmlib RMLIB         Provide the RepeatModeler library containing classified TEs to enhance the sensitivity especially for LINEs. If no file is provided (default), EDTA will generate such file for you.
  --rmout RMOUT         Provide your own homology-based TE annotation instead of using the EDTA library for masking. File is in RepeatMasker .out format. This file will be merged with the structural-based TE annotation. (--anno 1 required). Default: use the EDTA library for annotation.
```

**Step 3:** Run the command adding the full path of the directory containing the genome and the type of annotation you want:
```sh

python run_annotep.py --genome {absolute-path-to-folder-genomes}/genome.fasta --threads number
```

#### Example 1:
```sh
python run_annotep.py --genome /home/user/TEs/At.fasta --threads 12
```

#### Example 2:
```sh
python run_annotep.py --genome /home/user/Documents/At.fasta --threads 12 --sensitive 1 --anno 1
```

<br>

Return to [Table of contents](#table-of-contents)