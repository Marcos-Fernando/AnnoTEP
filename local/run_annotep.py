import subprocess
import argparse
import os
import shutil
import random

#Definindo local dos arquivos
#ambientes
CONDA = os.environ['CONDA_PREFIX']

#principal
UPLOAD_FOLDER = os.path.join(os.environ['HOME'], 'TEs')

#processos
SINE_FOLDER = os.path.join(UPLOAD_FOLDER, 'SINE', 'AnnoSINE', 'bin')
NONLTR_FOLDER = os.path.join(UPLOAD_FOLDER, 'non-LTR')
MGESCAN_FOLDER = os.path.join(NONLTR_FOLDER, 'mgescan')
EDTA_FOLDER = os.path.join(UPLOAD_FOLDER, 'EDTA')


def run_annotep(file, annotation_type):
    new_file, _ = os.path.splitext(os.path.basename(file))
    
    #copiar arquivo para pasta para poder trabalhar com ele
    destination_path = os.path.join(os.environ['HOME'], 'TEs', 'local', os.path.basename(new_file) + ".fasta")
    shutil.copy(file, destination_path)
    matches_file = os.path.join(os.environ['HOME'], 'TEs', 'local', f'{new_file}-matches.fasta')

    #numeros randomicos para não sobreescrever trabalhos
    random_numbers = [str(random.randint(0,9)) for i in range(4)]

    storageFolder = f'results-{new_file}_{"".join(random_numbers)}'
    folderEDTA = f'Anno-{new_file}'

    if annotation_type == 1:
        annotation_elementSINE(new_file, destination_path, storageFolder)
        os.remove(destination_path)

        if os.path.exists(matches_file):
            os.remove(matches_file)

    elif annotation_type == 2:
        annotation_elementLINE(new_file, destination_path, storageFolder)
        os.remove(destination_path)

        if os.path.exists(matches_file):
            os.remove(matches_file)

    elif annotation_type == 3:
        annotation_elementSINE(destination_path, storageFolder)
        annotation_elementLINE(new_file, destination_path, storageFolder)
        os.remove(destination_path)

        if os.path.exists(matches_file):
            os.remove(matches_file)


    elif annotation_type == 4:
        # Adicionar a função para a anotação completa
        pass
    else:
        print("Tipo de anotação inválido. Use 1, 2, 3 ou 4.")

def annotation_elementSINE(destination_path, storageFolder):
    print("Anotação SINE iniciada...")

    os.chdir(SINE_FOLDER)
    cmds = f"""
    . $CONDA_PREFIX/etc/profile.d/conda.sh && conda activate AnnoSINE
    export PATH="/home/marcoscosta/miniconda3/envs/AnnoSINE/bin:$PATH"

    mkdir $HOME/TEs/local/results/{storageFolder}

    python3 AnnoSINE.py 3 {destination_path} $HOME/TEs/local/results/{storageFolder}/SINE
    wait

    cp $HOME/TEs/local/results/{storageFolder}/SINE/Seed_SINE.fa $HOME/TEs/local/results/{storageFolder}/Seed_SINE.fa
    """
    
    process = subprocess.Popen(cmds, shell=True, executable='/bin/bash')
    process.wait()

    print("Anotação SINE finalizada")
    print("")

def annotation_elementLINE(new_file, destination_path, storageFolder):
    print("Anotação LINE iniciada...")

    os.chdir(NONLTR_FOLDER)
    commands = f"""
    PATH=$HOME/TEs/non-LTR/hmmer-3.2/src/:$PATH

    cd {MGESCAN_FOLDER}
    source mgescan-virtualenv/bin/activate

    mkdir $HOME/TEs/local/results/{storageFolder}
    cd $HOME/TEs/local/results/{storageFolder}

    mkdir LINE
    cd LINE
    ln -s {destination_path} {new_file}.fasta
    cd ../..

    ulimit -n 8192

    mgescan nonltr $HOME/TEs/local/results/{storageFolder}/LINE --output=$HOME/TEs/local/results/{storageFolder}/LINE-results --mpi=4

    wait
    cd $HOME/TEs/local/results/{storageFolder}/LINE-results

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
    cp LINE-lib.fa $HOME/TEs/local/results/{storageFolder}/LINE-lib.fa
    """

    process = subprocess.Popen(commands, shell=True, executable='/bin/bash')
    process.wait()

    print("Anotação LINE finalizado")
    print("")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run annotep with specified parameters.")
    parser.add_argument("--file", help="Nome do arquivo do genoma", required=True)
    parser.add_argument("--type", type=int, help="Tipo de anotação (1, 2, 3, or 4)", required=True)

    args = parser.parse_args()

    run_annotep(args.file, args.type)

