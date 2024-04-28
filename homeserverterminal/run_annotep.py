import argparse
import os

import random
from argparse import RawTextHelpFormatter

from annotation import RESULTS_FOLDER,annotation_elementLINE, annotation_elementSINE, complete_Analysis

#verifica se o arquivo é do tipo fasta
def check_fasta_file(value):
    ext = os.path.splitext(value)[-1].lower()
    if ext != '.fasta':
        raise argparse.ArgumentTypeError(f"The file must have the .fasta extension: {value}")
    return value

def run_annotep(file, annotation_type):
    if not os.path.exists(file):
        raise Exception(f"The file {file} does not exist.")
    
    new_file, _ = os.path.splitext(os.path.basename(file))
    print(f'o caminho para o arquivo é {file}')
    print(f'{new_file}')

    #numeros randomicos para não sobreescrever trabalhos
    random_numbers = [str(random.randint(0,9)) for i in range(4)]
    storageFolder = f'results-{new_file}_{"".join(random_numbers)}'

    resultsAddress = os.path.join(RESULTS_FOLDER, storageFolder)
    os.makedirs(resultsAddress)
    
    print(f">>>>>>>>>> Annotation started >>>> Input: {new_file}")
    if annotation_type == 1:
        annotation_elementSINE(file, resultsAddress)
        print(f">>>>>>>>>> Process finished >>>> Output: {storageFolder}")

    elif annotation_type == 2:
        annotation_elementLINE(new_file, file, resultsAddress)
        print(f">>>>>>>>>> Process finished >>>> Output: {storageFolder}")

    elif annotation_type == 3:
        annotation_elementSINE(file, resultsAddress)
        annotation_elementLINE(new_file, file, resultsAddress)
        print(f">>>>>>>>>> Process finished >>>> Output: {storageFolder}")

    elif annotation_type == 4:
        annotation_elementSINE(file, resultsAddress)
        annotation_elementLINE(new_file, file, resultsAddress)
        complete_Analysis(new_file, file, resultsAddress)
        print(f">>>>>>>>>> Process finished >>>> Output: {storageFolder}")

    else:
        print("Invalid annotation type. Use 1 - SINE, 2 - LINE, 3 - SINE and LINE or 4 Advanced Analysis.")
    

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run annotep with specified parameters.", 
                                 formatter_class=RawTextHelpFormatter)
    parser.add_argument("--file", type=check_fasta_file, help="Genome file name (.fasta)", required=True)
    parser.add_argument("--type", type=int, choices=[1, 2, 3, 4], 
                        help="Type annotation:\n [1] SINE Annotation \n [2] LINE Annotation\n [3] SINE and LINE annotation\n [4] Complete Annotation",
                        required=True)

    args = parser.parse_args()

    run_annotep(args.file, args.type)

