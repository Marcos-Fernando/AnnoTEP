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
    folderLINE = f'{new_file}-LINE'
    resultsLINE = f'{folderLINE}-results'
    libLINE = f'{new_file}-LINE-lib.fa'
    folderEDTA = f'Anno-{new_file}'

    if annotation_type == 1:
        annotation_elementSINE(new_file, destination_path, storageFolder)

        os.remove(destination_path)
       #matches_file = os.path.join(os.environ['HOME'], 'TEs', 'local', f'{new_file}-matches.fasta')
       #if os.path.exists(matches_file):
        os.remove(matches_file)

    elif annotation_type == 2:
        # Adicionar a função para a anotação LINE
        pass
    elif annotation_type == 3:
        # Adicionar função para a anotação SINE e LINE juntas
        pass
    elif annotation_type == 4:
        # Adicionar a função para a anotação completa
        pass
    else:
        print("Tipo de anotação inválido. Use 1, 2, 3 ou 4.")

def annotation_elementSINE(new_file, destination_path, storageFolder):
    print(new_file)

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

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run annotep with specified parameters.")
    parser.add_argument("--file", help="Nome do arquivo do genoma", required=True)
    parser.add_argument("--type", type=int, help="Tipo de anotação (1, 2, 3, or 4)", required=True)

    args = parser.parse_args()

    run_annotep(args.file, args.type)

