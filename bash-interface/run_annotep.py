import subprocess
import argparse
import os
import re
import shutil
from datetime import datetime
from argparse import RawTextHelpFormatter

# ===================== Environment ======================
BASH_DIR = os.path.dirname(os.path.abspath(__file__))
RESULTS_DIR = os.path.join(BASH_DIR, 'results')
UPLOAD_DIR = os.path.join(BASH_DIR, '..')
EDTA_DIR = os.path.join(UPLOAD_DIR,'EDTA')
SCRIPT_DIR = os.path.join(UPLOAD_DIR, 'Scripts')

def run_annotep(genome, threads, overwrite, anno, evaluate, force, u, maxdiv, cds, curatedlib, exclude, rmlib, rmout, species, step, sensitive, tirfilter, annottype):
    genome = os.path.abspath(genome)
    print(genome)

    genome_dir = os.path.dirname(genome)
    if not os.path.exists(genome_dir):
        raise Exception(f"The directory {genome_dir} does not exist.")

    if not os.path.exists(genome):
        raise Exception(f"The genome {genome} does not exist.")

    genome_fasta = os.path.basename(genome)
    genome_name, _ = os.path.splitext(os.path.basename(genome))
    print(f'The path to the genome is {genome}')
    print(f'{genome_name}')
    print(f'{genome_fasta}')

    num_threads = max(4, threads)
    if threads < 4:
        print("Warning: The number of threads provided is less than 4. Set to 4.")

    #Getting and formatting date and time
    now = datetime.now()
    formatted_date = now.strftime("%Y%m%d-%H%M%S")

    storageFolder = f'{genome_name}_{"".join(formatted_date)}'
    output_dir = os.path.join(RESULTS_DIR, storageFolder)
    os.makedirs(output_dir, exist_ok=True)

    genome_copy = os.path.join(output_dir, genome_fasta)
    shutil.copy2(genome, genome_copy)

    params = {
        '--overwrite': overwrite,
        '--anno': anno,
        '--sensitive': sensitive, 
        '--evaluate': evaluate,
        '--TIR_filter': tirfilter,
        '--ANNOT_TYPE': annottype,
        '--force': force,
        '--u': u,
        '--maxdiv': maxdiv,
        '--cds': cds,
        '--curatedlib': curatedlib,
        '--exclude': exclude,
        '--rmlib': rmlib,
        '--rmout': rmout
    }

    species = species if species else 'others'
    step = step if step else 'all'

    # Filters out empty parameters or parameters with a value of 0
    filtered_params = {key: value for key, value in params.items() if value not in [None, 0, '']}
    
    # Construct the parameter string for the command
    param_str = ' '.join([f"{key} {value}" for key, value in filtered_params.items()])

    print(f">>>>>>>>>> Annotation started >>>> Input: {genome_name}")
    cmds = f"""
        #cd {output_dir}

        source $HOME/miniconda3/etc/profile.d/conda.sh && conda activate EDTA-new &&
        export PATH="$HOME/miniconda3/envs/EDTA-new/bin:$PATH" &&
        export PATH="$HOME/miniconda3/envs/EDTA-new/bin/RepeatMasker:$PATH" &&
        export PATH="$HOME/miniconda3/envs/EDTA-new/bin/gt:$PATH" &&
        export PATH="{EDTA_DIR}/util:$PATH" &&
        
        {EDTA_DIR}/EDTA.pl --genome {genome} --species {species} --step {step} --threads {num_threads} {param_str} &&

        wait &&
        perl {SCRIPT_DIR}/generate_PLOTs-for-TE-pipe.sh {genome_fasta}
    """
    process = subprocess.Popen(cmds, shell=True, executable='/bin/bash', cwd=output_dir)
    process.wait()

    print(f">>>>>>>>>> Process finished >>>> Output: {storageFolder}")

# Function to check scientific notation
def check_scientific(value):
    if not re.match(r'^[0-9]+\.[0-9]+e[-+]?[0-9]+$', value):
        raise argparse.ArgumentTypeError(f"{value} is not a valid value in scientific notation.")
    return float(value)

# Function for checking input files
def check_file(value):
    try:
        with open(value, 'r') as file:
            return value
    except FileNotFoundError:
        raise argparse.ArgumentTypeError(f"The file {value} was not found.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run annotep with specified parameters.",
                                     formatter_class=argparse.RawTextHelpFormatter)

    required = parser.add_argument_group('required arguments')
    required.add_argument("--genome", type=str, help="The genome FASTA file", required=True)
    required.add_argument("--threads", type=int, help="Number of threads used to complete annotation (default threads: 4)", default=4)

    optional = parser.add_argument_group('optional arguments')
    optional.add_argument("--species", choices=["Rice", "Maize", "others"], default="others", 
                          help="Specify the species for identification of TIR candidates. Default: others")
    optional.add_argument("--step", choices=["all", "filter", "final", "anno"], default="all", 
                          help="Specify which steps you want to run EDTA.")
    optional.add_argument("--sensitive", type=int, choices=[0, 1], default=0, 
                          help="Use RepeatModeler to identify remaining TEs (1) or not (0, default). This step may help to recover some TEs.")
    optional.add_argument("--TIR_filter", type=int, choices=[0, 1], help="Filter TIRs without annotated domains: (1) Yes; (0) No [default]. Enabling this filter can substantially reduce false positives, but may also result in the loss of some true positives (false negatives).", default=0)
    optional.add_argument("--overwrite", type=int, choices=[0, 1], help="If previous raw TE results are found, decide to overwrite (1, rerun) or not (0, default).", default=0)
    optional.add_argument("--anno", type=int, choices=[0, 1], help="Perform (1) or not perform (0, default) whole-genome TE annotation after TE library construction.", default=0)
    optional.add_argument("--evaluate", type=int, choices=[0, 1], help="Evaluate (1) classification consistency of the TE annotation. (--anno 1 required).", default=0)
    optional.add_argument("--force", type=int, choices=[0, 1], help="When no confident TE candidates are found: 0, interrupt and exit (default); 1, use rice TEs to continue.", default=0)
    optional.add_argument("--u", type=check_scientific, help="Neutral mutation rate to calculate the age of intact LTR elements. Intact LTR age is found in this file: *EDTA_raw/LTR/*.pass.list. Default: 1.3e-8 (per bp per year, from rice).", default=None)
    optional.add_argument("--maxdiv", type=int, choices=range(0,101), metavar="[0-100]", help="Maximum divergence (0-100, default: 40) of repeat fragments comparing to library sequences.", default=None)
    optional.add_argument("--ANNOT_TYPE", type=int, choices=[0, 1], help="Specify whether to annotate the genome using a RepeatMasker-based library: (1) Yes; (0) No [default, uses intact elements]. Enabling this option (1) may negatively affect the filtering step and compromise benchmark results.", default=0)
    optional.add_argument("--cds", type=check_file, help="Provide a FASTA file containing the coding sequence (no introns, UTRs, nor TEs) of this genome or its close relative.", default=None)
    optional.add_argument("--curatedlib", type=check_file, help="Provided a curated library to keep consistant naming and classification for known TEs. TEs in this file will be trusted 100%, so please ONLY provide MANUALLY CURATED ones. This option is not mandatory. It's totally OK if no file is provided (default).".replace("%", "%%"), default=None)
    optional.add_argument("--exclude", type=check_file, help="Exclude regions (bed format) from TE masking in the MAKER.masked output. Default: undef. (--anno 1 required).", default=None)
    optional.add_argument("--rmlib", type=check_file, help="Provide the RepeatModeler library containing classified TEs to enhance the sensitivity especially for LINEs. If no file is provided (default), EDTA will generate such file for you.", default=None)
    optional.add_argument("--rmout", type=check_file, help="Provide your own homology-based TE annotation instead of using the EDTA library for masking. File is in RepeatMasker .out format. This file will be merged with the structural-based TE annotation. (--anno 1 required). Default: use the EDTA library for annotation.", default=None)

    args = parser.parse_args()

    # Chamada da função com os parâmetros obtidos
    run_annotep(args.genome, args.threads, args.overwrite, args.anno, args.evaluate, args.force, args.u, args.maxdiv, args.cds, args.curatedlib, args.exclude, args.rmlib, args.rmout, args.species, args.step, args.sensitive, args.TIR_filter, args.ANNOT_TYPE)
