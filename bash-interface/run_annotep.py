import subprocess
import argparse
import os
import re
from datetime import datetime
from argparse import RawTextHelpFormatter

#Definindo local dos arquivos
#principal
# ===================== Ambientes ======================
BASH_FOLDER = os.path.dirname(os.path.abspath(__file__))

# ================= Locais dos arquivos ================
RESULTS_FOLDER = os.path.join(BASH_FOLDER, 'results')
UPLOAD_FOLDER = os.path.join(BASH_FOLDER, '..')
EDTA_FOLDER = os.path.join(UPLOAD_FOLDER,'EDTA')

#verifica se o arquivo é do tipo fasta
def check_fasta_file(value):
    ext = os.path.splitext(value)[-1].lower()
    if ext != '.fasta':
        raise argparse.ArgumentTypeError(f"The file must have the .fasta extension: {value}")
    return value

def run_annotep(genome, threads, overwrite, anno, evaluate, force, u, maxdiv, cds, curatedlib, exclude, rmlib, rmout, species, step, sensitive):
    genome_dir = os.path.dirname(genome)
    if not os.path.exists(genome_dir):
        raise Exception(f"The directory {genome_dir} does not exist.")

    if not os.path.exists(genome):
        raise Exception(f"The genome {genome} does not exist.")

    new_genome, _ = os.path.splitext(os.path.basename(genome))
    print(f'The path to the genome is {genome}')
    print(f'{new_genome}')

    adjusted_threads = max(4, threads)
    if threads < 4:
        print("Warning: The number of threads provided is less than 4. Set to 4.")

    #Obtendo e formatando data e hora
    now = datetime.now()
    formatted_date = now.strftime("%Y%m%d-%H%M%S")

    storageFolder = f'{new_genome}_{"".join(formatted_date)}'
    resultsAddress = os.path.join(RESULTS_FOLDER, storageFolder)
    os.makedirs(resultsAddress, exist_ok=True)

    params = {
        '--overwrite': overwrite,
        '--anno': anno,
        '--sensitive': sensitive, 
        '--evaluate': evaluate,
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

    # Filtra os parâmetros vazios ou com valor 0
    filtered_params = {key: value for key, value in params.items() if value not in [None, 0, '']}
    
    # Construa a string de parâmetros para o comando
    param_str = ' '.join([f"{key} {value}" for key, value in filtered_params.items()])

    print(f">>>>>>>>>> Annotation started >>>> Input: {new_genome}")
    cmds = f"""
        cd {resultsAddress}

        source $HOME/miniconda3/etc/profile.d/conda.sh && conda activate EDTA2 &&
        export PATH="$HOME/miniconda3/envs/EDTA2/bin:$PATH" &&
        export PATH="$HOME/miniconda3/envs/EDTA2/bin/RepeatMasker:$PATH" &&
        export PATH="$HOME/miniconda3/envs/EDTA2/bin/gt:$PATH" &&
        export PATH="$HOME/TEs/EDTA/util:$PATH" &&
        
        {EDTA_FOLDER}/EDTA.pl --genome {genome} --species {species} --step {step} --threads {adjusted_threads} {param_str}

        wait
    """
    process = subprocess.Popen(cmds, shell=True, executable='/bin/bash')
    process.wait()
    
    complete_Analysis(new_genome, resultsAddress)

    # cmds = f""" EDTA.pl --genome {genome} --species {species} --step {step} --threads {adjusted_threads} {param_str} """
    # print(cmds)
    
    print(f">>>>>>>>>> Process finished >>>> Output: {storageFolder}")


def complete_Analysis(new_genome, resultsAddress):
    cmds = f"""
    cd {resultsAddress}
    mkdir TE-REPORT
    cd TE-REPORT
    ln -s ../{new_genome}.fasta.mod.EDTA.anno/{new_genome}.fasta.mod.cat.gz .

    perl {UPLOAD_FOLDER}/ProcessRepeats/ProcessRepeats-complete.pl -species viridiplantae -nolow -noint {new_genome}.fasta.mod.cat.gz
    mv {new_genome}.fasta.mod.tbl TEs-Report-Complete.txt
    perl {UPLOAD_FOLDER}/ProcessRepeats/ProcessRepeats-lite.pl -species viridiplantae -nolow -noint -a {new_genome}.fasta.mod.cat.gz
    mv {new_genome}.fasta.mod.tbl TEs-Report-Lite.txt

    #Plot
    cat {new_genome}.fasta.mod.align  | sed 's#TIR/.\+ #TIR &#g'  | sed 's#DNA/Helitron.\+ #Helitron &#g' | sed 's#LTR/Copia.\+ #LTR/Copia &#g' | sed 's#LTR/Gypsy.\+ #LTR/Gypsy &#g'  | sed 's#LINE-like#LINE#g' | sed 's#TR_GAG/Copia.\+ #LTR/Copia &#g' | sed 's#TR_GAG/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#TRBARE-2/Copia.\+ #LTR/Copia &#g' | sed 's#BARE-2/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#LINE/.\+ #LINE &#g' > tmp.txt
    sed -i '/RC\/Helitron/d' tmp.txt
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

    genome_size="`perl {UPLOAD_FOLDER}/EDTA/util/count_base.pl ../{new_genome}.fasta.mod | cut -f 2`"
    perl {UPLOAD_FOLDER}/ProcessRepeats/createRepeatLandscape.pl -g $genome_size -div At.divsum > RepeatLandscape.html

    tail -n 72 At.divsum > divsum.txt

    cat {UPLOAD_FOLDER}/Rscripts/plotKimura.R | sed "s#_SIZE_GEN_#$genome_size#g" > plotKimura.R
    Rscript plotKimura.R
    mv Rplots.pdf RepeatLandScape.pdf
    pdf2svg RepeatLandScape.pdf RLandScape.svg
    
    rm align2.txt
    rm tmp.txt

    #Plotting
    cat TEs-Report-Lite.txt | grep "%"   | cut -f 2 -d":"   | awk '{{print $1}}' > count.txt
	cat TEs-Report-Lite.txt | grep "%"   | cut -f 2 -d":"   | awk '{{print $2}}' > bp.txt
	cat TEs-Report-Lite.txt | grep "%"   | cut -f 2 -d":"   | awk '{{print $4}}' > percentage.txt
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
    
	python {UPLOAD_FOLDER}/Scriptsplot_TEs_length.py
	mv TE-Report.pdf TE-Report1.pdf
    pdf2svg TE-Report1.pdf TE-Report1.svg

	python {UPLOAD_FOLDER}/Scripts/plot_TEs-bubble.py
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
	python {UPLOAD_FOLDER}/Scriptsplot_TEs_length.py
	mv TE-Report.pdf TE-Report2.pdf
    pdf2svg TE-Report2.pdf TE-Report2.svg

	python {UPLOAD_FOLDER}/Scripts/plot_TEs-bubble.py
	mv TE-Report.pdf TE-Report2-bubble.pdf
    pdf2svg TE-Report2-bubble.pdf TE-Report2-bubble.svg

    wait
    cd {resultsAddress}
    mkdir LTR-AGE
    cd LTR-AGE
    ln -s ../{new_genome}.fasta.mod.EDTA.raw/{new_genome}.fasta.mod.LTR-AGE.pass.list

    ln -s {UPLOAD_FOLDER}/Rscripts/plot-AGE-Gypsy.R
    ln -s {UPLOAD_FOLDER}/Rscripts/plot-AGE-Copia.R

    cat -n {new_genome}.fasta.mod.LTR-AGE.pass.list | grep Gypsy | cut -f 1,13 | sed 's# ##g' | sed 's#^#Cluster_#g' | awk '{{if ($2 > 0) print $n}}' > AGE-Gypsy.txt
    cat -n {new_genome}.fasta.mod.LTR-AGE.pass.list | grep Copia | cut -f 1,13 | sed 's# ##g' | sed 's#^#Cluster_#g' | awk '{{if ($2 > 0) print $n}}' > AGE-Copia.txt

    Rscript plot-AGE-Gypsy.R
    Rscript plot-AGE-Copia.R

    pdf2svg AGE-Copia.pdf AGE-Copia.svg
    pdf2svg AGE-Gypsy.pdf AGE-Gypsy.svg

    cd {resultsAddress}
    mkdir TREE
    cd TREE

    ln -s ../{new_genome}.fasta.mod.EDTA.TEanno.sum tree.mod.EDTA.TEanno.sum

    cat ../{new_genome}.fasta.mod.EDTA.TElib.fa | sed 's/#/_CERC_/g'  | sed 's#/#_BARRA_#g'  > tmp.txt
    mkdir tmp
    break_fasta.pl < tmp.txt ./tmp
    cat tmp/*LTR* | sed 's#_CERC_#\t#g' | cut -f 1 > TE.fasta

    source $HOME/miniconda3/etc/profile.d/conda.sh && conda activate EDTA2 &&
    TEsorter -db rexdb-plant --hmm-database rexdb-plant -pre TE -dp2 -p 40 TE.fasta >/dev/null 2>&1 &&
    conda deactivate

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
    ln -s {UPLOAD_FOLDER}/Rscripts/LTR_tree_rec_1.R
    ln -s {UPLOAD_FOLDER}/Rscripts/LTR_tree_rec_2.R

    Rscript LTR_tree.R all.fas.contree TE.cls.tsv LTR_RT-Tree1.pdf
    Rscript LTR_tree-density.R all.fas.contree TE.cls.tsv occurrences.tsv size.tsv LTR_RT-Tree2.pdf
    Rscript LTR_tree_rec_1.R all.fas.contree TE.cls.tsv LTR_RT-Tree3.pdf
    Rscript LTR_tree_rec_2.R all.fas.contree TE.cls.tsv LTR_RT-Tree4.pdf

    pdf2svg LTR_RT-Tree1.pdf LTR_RT-Tree1.svg
    pdf2svg LTR_RT-Tree2.pdf LTR_RT-Tree2.svg
    pdf2svg LTR_RT-Tree3.pdf LTR_RT-Tree3.svg
    pdf2svg LTR_RT-Tree4.pdf LTR_RT-Tree4.svg
    """

    process = subprocess.Popen(cmds, shell=True, executable='/bin/bash')
    process.wait()

    print("Finished annotation")
    print("")

# Função para verificar a notação científica
def check_scientific(value):
    if not re.match(r'^[0-9]+\.[0-9]+e[-+]?[0-9]+$', value):
        raise argparse.ArgumentTypeError(f"{value} não é um valor válido em notação científica.")
    return float(value)

# Função para verificar arquivos de entrada
def check_file(value):
    try:
        with open(value, 'r') as file:
            return value
    except FileNotFoundError:
        raise argparse.ArgumentTypeError(f"O arquivo {value} não foi encontrado.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run annotep with specified parameters.",
                                     formatter_class=argparse.RawTextHelpFormatter)

    required = parser.add_argument_group('required arguments')
    required.add_argument("--genome", type=check_fasta_file, help="The genome FASTA file (.fasta)", required=True)
    required.add_argument("--threads", type=int, help="Number of threads used to complete annotation (default threads: 4)", default=4, required=True)

    optional = parser.add_argument_group('optional arguments')
    optional.add_argument("--species", choices=["Rice", "Maize", "others"], default="others", 
                          help="Specify the species for identification of TIR candidates. Default: others")
    optional.add_argument("--step", choices=["all", "filter", "final", "anno"], default="all", 
                          help="Specify which steps you want to run EDTA.")
    optional.add_argument("--sensitive", type=int, choices=[0, 1], default=0, 
                          help="Use RepeatModeler to identify remaining TEs (1) or not (0, default). This step may help to recover some TEs.")
    
    optional.add_argument("--overwrite", type=int, choices=[0, 1], help="If previous raw TE results are found, decide to overwrite (1, rerun) or not (0, default).", default=0)
    optional.add_argument("--anno", type=int, choices=[0, 1], help="Perform (1) or not perform (0, default) whole-genome TE annotation after TE library construction.", default=0)
    optional.add_argument("--evaluate", type=int, choices=[0, 1], help="Evaluate (1) classification consistency of the TE annotation. (--anno 1 required).", default=0)
    optional.add_argument("--force", type=int, choices=[0, 1], help="When no confident TE candidates are found: 0, interrupt and exit (default); 1, use rice TEs to continue.", default=0)
    optional.add_argument("--u", type=check_scientific, help="Neutral mutation rate to calculate the age of intact LTR elements. Intact LTR age is found in this file: *EDTA_raw/LTR/*.pass.list. Default: 1.3e-8 (per bp per year, from rice).", default=None)
    optional.add_argument("--maxdiv", type=int, choices=range(0,101), metavar="[0-100]", help="Maximum divergence (0-100, default: 40) of repeat fragments comparing to library sequences.", default=None)
    
    optional.add_argument("--cds", type=check_file, help="Provide a FASTA file containing the coding sequence (no introns, UTRs, nor TEs) of this genome or its close relative.", default=None)
    optional.add_argument("--curatedlib", type=check_file, help="Provided a curated library to keep consistant naming and classification for known TEs. TEs in this file will be trusted 100%, so please ONLY provide MANUALLY CURATED ones. This option is not mandatory. It's totally OK if no file is provided (default).".replace("%", "%%"), default=None)
    optional.add_argument("--exclude", type=check_file, help="Exclude regions (bed format) from TE masking in the MAKER.masked output. Default: undef. (--anno 1 required).", default=None)
    optional.add_argument("--rmlib", type=check_file, help="Provide the RepeatModeler library containing classified TEs to enhance the sensitivity especially for LINEs. If no file is provided (default), EDTA will generate such file for you.", default=None)
    optional.add_argument("--rmout", type=check_file, help="Provide your own homology-based TE annotation instead of using the EDTA library for masking. File is in RepeatMasker .out format. This file will be merged with the structural-based TE annotation. (--anno 1 required). Default: use the EDTA library for annotation.", default=None)

    args = parser.parse_args()

    # Chamada da função com os parâmetros obtidos
    run_annotep(args.genome, args.threads, args.overwrite, args.anno, args.evaluate, args.force, args.u, args.maxdiv, args.cds, args.curatedlib, args.exclude, args.rmlib, args.rmout, args.species, args.step, args.sensitive)
