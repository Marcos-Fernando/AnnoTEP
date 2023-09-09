import subprocess
import os

#Definindo local dos arquivos
#ambientes
CONDA = os.environ['CONDA_PREFIX']

#principal
UPLOAD_FOLDER = os.path.join(os.environ['HOME'], 'TEs')

#temporárias
TEMPSL_FOLDER = os.path.join(UPLOAD_FOLDER, 'Temp', 'sine-line')
TEMPINPUT_FOLDER = os.path.join(UPLOAD_FOLDER, 'Temp', 'input')
TEMPANNO_FOLDER = os.path.join(UPLOAD_FOLDER, 'Temp', 'annotation')

#processos
SINE_FOLDER = os.path.join(UPLOAD_FOLDER, 'SINE', 'AnnoSINE', 'bin')
NONLTR_FOLDER = os.path.join(UPLOAD_FOLDER, 'non-LTR')
MGESCAN_FOLDER = os.path.join(NONLTR_FOLDER, 'mgescan')
EDTA_FOLDER = os.path.join(UPLOAD_FOLDER, 'EDTA')
 
#Funções de processo do pipeline
#Anotação do elemento SINE
def annotation_elementSINE(new_filename, folderSINE, seedSINE):
    print("Anotação SINE iniciada...")

    os.chdir(SINE_FOLDER)
    cmds = f"""
    . $CONDA_PREFIX/etc/profile.d/conda.sh && conda activate AnnoSINE
    export PATH="/home/marcoscosta/miniconda3/envs/AnnoSINE/bin:$PATH"

    python3 AnnoSINE.py 3 {os.path.join(TEMPINPUT_FOLDER, new_filename)} temp/{folderSINE}
    wait
    cp ./temp/{folderSINE}/Seed_SINE.fa {os.path.join(TEMPSL_FOLDER, folderSINE, seedSINE)}
    """
    process = subprocess.Popen(cmds, shell=True, executable='/bin/bash')
    process.wait()

    print("Anotação SINE finalizada")
    print("")

#Anotação LINE
def annotation_elementLINE(new_filename, folderSINE, folderLINE, resultsLINE, libLINE):
    print("Anotação LINE iniciada...")

    os.chdir(NONLTR_FOLDER)
    commands = f"""
    PATH=$HOME/TEs/non-LTR/hmmer-3.2/src/:$PATH

    cd {MGESCAN_FOLDER}
    source mgescan-virtualenv/bin/activate

    cd {NONLTR_FOLDER}/temp
    mkdir {folderLINE}
    cd {folderLINE}
    ln -s {os.path.join(TEMPINPUT_FOLDER, new_filename)} {new_filename}
    cd ../..

    ulimit -n 8192

    mgescan nonltr {os.path.join(NONLTR_FOLDER, 'temp', folderLINE)} --output={os.path.join(NONLTR_FOLDER, 'temp', resultsLINE)} --mpi=4

    wait
    cd {NONLTR_FOLDER}/temp
    cd {resultsLINE}

    cat info/full/*/*.dna > temp.fa
    cat temp.fa | grep \>  | sed 's#>#cat ./info/nonltr.gff3 | grep "#g'  | sed 's#$#" | cut -f 1,4,5#g'  > ver.sh
    bash ver.sh  | sed 's#\t#:#' | sed 's#\t#\.\.#'   > list.txt

    mkdir TMP
    break_fasta.pl < temp.fa TMP/
    cat temp.fa | grep \> | sed 's#>#cat ./TMP/#g' | sed 's#$#.fasta#g' > A.txt
    cat temp.fa | grep \> > list2.txt
    paste list2.txt list.txt | sed 's/>/ sed "s#/g'  | sed 's/\t/#/g' | sed 's/$/#g"/g'   > B.txt
    paste A.txt B.txt  -d"|"  > rename.sh
    bash rename.sh > candidates.fa

    /usr/local/bin/TEsorter -db rexdb-plant --hmm-database rexdb-plant -pre LINE -p 22 -cov 80 -eval 0.0001 -rule 80-80-80 candidates.fa
    more LINE.cls.lib  | sed 's/#/__/g'  | sed 's#.fa##g' | cut -f 1 -d" " | sed 's#/#-#g'  > pre1.fa
    mkdir pre1
    break_fasta.pl < pre1.fa pre1
    cat pre1/*LINE.fasta  | sed 's#__#\t#g' | cut -f 1  > pre2.fa

    /usr/local/bin/TEsorter -db rexdb-line --hmm-database rexdb-line -pre LINE2 -p 22 -cov 60 -eval 0.0001 -rule 80-80-80 pre2.fa
    more LINE2.cls.lib  | sed 's/#/__/g'  | sed 's#.fa##g' | cut -f 1 -d" " | sed 's#/#-#g'  > pre-final.fa
    mkdir pre-final
    break_fasta.pl < pre-final.fa pre-final
    cat pre-final/*LINE*.fasta  > pre-final2.fa
    cdhit-est -i pre-final2.fa -o clustered -c 0.8 -G 1 -T 22 -d 100 -s 0.6 -aL 0.6 -aS 0.6
    cat clustered | sed 's/__/#/g' | sed 's#-#/#g'  > LINE-lib.fa

    rm -rf pre1/ pre-final/ TMP/
    rm LINE2*
    rm LINE.cls.*
    rm A.txt B.txt clustered.clstr clustered LINE.dom* list2.txt list.txt pre1.fa pre2.fa pre-final2.fa pre-final.fa rename.sh temp.fa ver.sh candidates.fa
    cp LINE-lib.fa {os.path.join(TEMPSL_FOLDER, folderSINE, libLINE)}
    """

    process = subprocess.Popen(commands, shell=True, executable='/bin/bash')
    process.wait()

    print("Anotação LINE finalizado")
    print("")

def merge_SINE_LINE(new_filename, folderLINE, folderSINE, seedSINE, folderEDTA, libLINE):
    print("Processo de mesclagem iniciado, análise com pipeline EDTA")

    os.chdir(EDTA_FOLDER)
    cmds = f"""
    . $CONDA_PREFIX/etc/profile.d/conda.sh && conda activate EDTA
    export PATH="/home/marcoscosta/miniconda3/envs/EDTA/bin:$PATH"
    export PATH="/home/marcoscosta/miniconda3/envs/EDTA/bin/gt:$PATH"

    cd {TEMPANNO_FOLDER}
    mkdir {folderEDTA}

    cd {folderEDTA}
    nohup {EDTA_FOLDER}/EDTA.pl --genome ../../input/{new_filename} --species others --step all --line ../../sine-line/{folderSINE}/{libLINE} --sine ../../sine-line/{folderSINE}/{seedSINE} --sensitive 1 --anno 1 --threads 10 > EDTA.log 2>&1 &

    wait

    #Report
    mkdir TE-REPORT
    cd TE-REPORT
    ln -s ../{new_filename}.mod.EDTA.anno/{new_filename}.mod.cat.gz .

    perl {UPLOAD_FOLDER}/ProcessRepeats/ProcessRepeats-complete.pl -species viridiplantae -nolow -noint {new_filename}.mod.cat.gz
    mv {new_filename}.mod.tbl ../TEs-Report-Complete.txt

    perl {UPLOAD_FOLDER}/ProcessRepeats/ProcessRepeats-lite.pl -species viridiplantae -nolow -noint -a {new_filename}.mod.cat.gz
    mv {new_filename}.mod.tbl ../TEs-Report-lite.txt

    #Plot
    cat {new_filename}.mod.align  | sed 's#TIR/.\+ #TIR &#g'  | sed 's#DNA/Helitron.\+ #Helitron &#g' | sed 's#LTR/Copia.\+ #LTR/Copia &#g' | sed 's#LTR/Gypsy.\+ #LTR/Gypsy &#g'  | sed 's#LINE-like#LINE#g' | sed 's#TR_GAG/Copia.\+ #LTR/Copia &#g' | sed 's#TR_GAG/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#TRBARE-2/Copia.\+ #LTR/Copia &#g' | sed 's#BARE-2/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#LINE/.\+ #LINE &#g' > tmp.txt

    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "LTR/Copia" -A 5 |  grep -v "\-\-"  > align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "LTR/Gypsy" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "TIR" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "LINE" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "LARD" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "TRIM" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "Helitron" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "SINE" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "Unknown" -A 5 |  grep -v "\-\-"  >> align2.txt

    perl {UPLOAD_FOLDER}/ProcessRepeats/calcDivergenceFromAlign.pl -s At.divsum align2.txt

    genome_size="`perl {UPLOAD_FOLDER}/EDTA/util/count_base.pl ../{new_filename}.mod | cut -f 2`"
    perl {UPLOAD_FOLDER}/ProcessRepeats/createRepeatLandscape.pl -g $genome_size -div At.divsum > ../RepeatLandscape.html

    tail -n 72 At.divsum > divsum.txt

    cat {UPLOAD_FOLDER}/Rscripts/plotKimura.R | sed "s#_SIZE_GEN_#$genome_size#g" > plotKimura.R
    Rscript plotKimura.R
    mv Rplots.pdf ../RepeatLandScape.pdf

    rm align2.txt
    rm tmp.txt
    
    wait
    cd {TEMPANNO_FOLDER}/{folderEDTA}
    mkdir LTR-AGE
    cd LTR-AGE
    ln -s ../{new_filename}.mod.EDTA.raw/{new_filename}.mod.LTR-AGE.pass.list

    ln -s {UPLOAD_FOLDER}/Rscripts/plot-AGE-Gypsy.R
    ln -s {UPLOAD_FOLDER}/Rscripts/plot-AGE-Copia.R

    cat -n {new_filename}.mod.LTR-AGE.pass.list | grep Gypsy | cut -f 1,13 | sed 's# ##g' | sed 's#^#Cluster_#g' | awk '{{if ($2 > 0) print $n}}' > AGE-Gypsy.txt
    cat -n {new_filename}.mod.LTR-AGE.pass.list | grep Copia | cut -f 1,13 | sed 's# ##g' | sed 's#^#Cluster_#g' | awk '{{if ($2 > 0) print $n}}' > AGE-Copia.txt

    Rscript plot-AGE-Gypsy.R
    Rscript plot-AGE-Copia.R
    """

    process = subprocess.Popen(cmds, shell=True, executable='/bin/bash')
    process.wait()

def create_phylogeny(new_filename, folderEDTA):
    print("Criando arvores iniciada...")

    os.chdir(TEMPANNO_FOLDER)
    commandsTREE = f"""
    cd {folderEDTA}
    mkdir TREE
    cd TREE

    ln -s ../{new_filename}.mod.EDTA.TEanno.sum tree.mod.EDTA.TEanno.sum

    cat ../{new_filename}.mod.EDTA.TElib.fa | sed 's/#/_CERC_/g'  | sed 's#/#_BARRA_#g'  > tmp.txt
    mkdir tmp
    break_fasta.pl < tmp.txt ./tmp
    cat tmp/*LTR* | sed 's#_CERC_#\t#g' | cut -f 1 > TE.fasta


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
    
    perl {UPLOAD_FOLDER}/Scripts/catfasta2phyml.pl -c -f *.fas > all.fas
    iqtree2 -s all.fas -alrt 1000 -bb 1000 -nt AUTO

    wait
    cat TE.cls.tsv | cut -f 1 | sed 's#^#cat tree.mod.EDTA.TEanno.sum | grep -w "#g' | sed 's#$#"#g' > pick-occur.sh
    bash pick-occur.sh > occur.txt
    
    wait
    cat occur.txt  | sed 's#^      TE_#TE_#g'  | awk '{{print $1,$2,$3}}' | sed 's# #\t#g' |  sort -k 2 -V  > sort_occur.txt
    cat occur.txt  | sed 's#^      TE_#TE_#g'  | awk '{{print $1,$2,$3}}' | sed 's# #\t#g' |  sort -k 3 -V  > sort_size.txt

    cat all.fas | grep \> | sed 's#^>##g' > ids.txt

    cat sort_occur.txt | cut -f 1,2 | sed 's#^#id="#g' | sed 's#\t#" ; data="#g' | sed 's#$#" ; ver="`cat ids.txt | grep $id`" ; echo -e "$ver\\t$data" #g'   > occ-pick.sh
    bash occ-pick.sh  | grep "^TE" | grep "^TE"  | sed 's/#/_/g' | sed 's#/#_#g'  > occurrences.tsv

    cat sort_size.txt | cut -f 1,3 | sed 's#^#id="#g' | sed 's#\t#" ; data="#g' | sed 's#$#" ; ver="`cat ids.txt | grep $id`" ; echo -e "$ver\\t$data" #g'   > size-pick.sh
    bash size-pick.sh  | grep "^TE" | grep "^TE"  | sed 's/#/_/g' | sed 's#/#_#g'  > size.tsv
    
    ln -s {UPLOAD_FOLDER}/Rscripts/LTR_tree.R
    ln -s {UPLOAD_FOLDER}/Rscripts/LTR_tree-density.R

    Rscript LTR_tree.R all.fas.contree TE.cls.tsv LTR_RT-Tree1.pdf
    Rscript LTR_tree-density.R all.fas.contree TE.cls.tsv occurrences.tsv size.tsv LTR_RT-Tree2.pdf

    pdf2svg LTR_RT-Tree1.pdf LTR_RT-Tree1.svg
    pdf2svg LTR_RT-Tree2.pdf LTR_RT-Tree2.svg
    """

    process = subprocess.Popen(commandsTREE, shell=True, executable='/bin/bash')
    process.wait()

    print("Anotação registrada em EDTA.log")
    print("Processo EDTA finalizado")
    print("")


