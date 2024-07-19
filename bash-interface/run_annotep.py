import subprocess
import argparse
import os
from datetime import datetime
from argparse import RawTextHelpFormatter

#Definindo local dos arquivos
#principal
UPLOAD_FOLDER = os.path.join(os.environ['HOME'], 'TEs')

#processos
SINE_FOLDER = os.path.join(UPLOAD_FOLDER, 'SINE', 'AnnoSINE', 'bin')
NONLTR_FOLDER = os.path.join(UPLOAD_FOLDER, 'non-LTR')
MGESCAN_FOLDER = os.path.join(NONLTR_FOLDER, 'mgescan')
EDTA_FOLDER = os.path.join(UPLOAD_FOLDER, 'EDTA')

#folders local
RESULTS_FOLDER = os.path.join(UPLOAD_FOLDER, 'bash-interface', 'results')

#verifica se o arquivo é do tipo fasta
def check_fasta_file(value):
    ext = os.path.splitext(value)[-1].lower()
    if ext != '.fasta':
        raise argparse.ArgumentTypeError(f"The file must have the .fasta extension: {value}")
    return value

def run_annotep(file, annotation_type, threads):
    file_dir = os.path.dirname(file)
    if not os.path.exists(file_dir):
        raise Exception(f"The directory {file_dir} does not exist.")

    if not os.path.exists(file):
        raise Exception(f"The file {file} does not exist.")

    new_file, _ = os.path.splitext(os.path.basename(file))
    print(f'The path to the file is {file}')
    print(f'{new_file}')

    if threads < 4:
        print("Warning: The number of threads provided is less than 4. Set to 4.")
        adjusted_threads = 4
    else:
        adjusted_threads = threads

    #Obtendo e formatando data e hora
    now = datetime.now()
    formatted_date = now.strftime("%Y%m%d-%H%M%S")

    storageFolder = f'{new_file}_{"".join(formatted_date)}'

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
        complete_Analysis(new_file, file, resultsAddress, adjusted_threads)
    
        print(f">>>>>>>>>> Process finished >>>> Output: {storageFolder}")

    else:
        print("Invalid annotation type. Use 1 - SINE, 2 - LINE, 3 - SINE and LINE or 4 Advanced Analysis.")

def annotation_elementSINE(file, resultsAddress):
    print("SINE annotation started...")

    os.chdir(SINE_FOLDER)
    cmds = f"""
    source $HOME/miniconda3/etc/profile.d/conda.sh && conda activate AnnoSINE &&
    export PATH="$HOME/miniconda3/envs/AnnoSINE/bin:$PATH" &&
    python3 AnnoSINE.py 3 {file} {resultsAddress}/SINE
    wait
    cp {resultsAddress}/SINE/Seed_SINE.fa {resultsAddress}/Seed_SINE.fa
    """

    process = subprocess.Popen(cmds, shell=True, executable='/bin/bash')
    process.wait()

    print("SINE annotation completed")
    print("")

def annotation_elementLINE(new_file, file, resultsAddress):
    line_folder = os.path.join(resultsAddress, 'LINE')
    os.makedirs(line_folder, exist_ok=True)
    output_folder = os.path.join(resultsAddress, 'LINE-results')

    print("LINE annotation started...")

    os.chdir(NONLTR_FOLDER)
    commands = f"""
    PATH=$HOME/TEs/non-LTR/hmmer-3.2/src/:$PATH
    cd {MGESCAN_FOLDER}
    source mgescan-virtualenv/bin/activate
    
    cd {line_folder}
    ln -s {file} {new_file}.fasta
    cd ../..

    ulimit -n 8192
    mgescan nonltr {line_folder} --output={output_folder} --mpi=4
    wait

    cd {output_folder}
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
    cp LINE-lib.fa {resultsAddress}/LINE-lib.fa
    """

    process = subprocess.Popen(commands, shell=True, executable='/bin/bash')
    process.wait()

    print("LINE annotation finished")
    print("")


def complete_Analysis(new_file, file, resultsAddress, adjusted_threads):
    completeAnalysis_folder = os.path.join(resultsAddress, 'complete-analysis')
    os.makedirs(completeAnalysis_folder, exist_ok=True)

    print("Deep annotation process started...")

    os.chdir(EDTA_FOLDER)
    cmds = f"""
    source $HOME/miniconda3/etc/profile.d/conda.sh && conda activate EDTA &&
    export PATH="$HOME/miniconda3/envs/EDTA/bin:$PATH" &&
    export PATH="$HOME/TEs/EDTA/util:$PATH" &&
    export PATH="$HOME/miniconda3/envs/EDTA/bin/gt:$PATH" &&

    cd {completeAnalysis_folder}
    {EDTA_FOLDER}/EDTA.pl --genome {file} --species others --step all --line {resultsAddress}/LINE-lib.fa  --sine {resultsAddress}/Seed_SINE.fa --sensitive 1 --anno 1 --threads {adjusted_threads}
    wait

    cd {completeAnalysis_folder}
    mkdir TE-REPORT
    cd TE-REPORT
    ln -s ../{new_file}.fasta.mod.EDTA.anno/{new_file}.fasta.mod.cat.gz .

    perl {UPLOAD_FOLDER}/ProcessRepeats/ProcessRepeats-complete.pl -species viridiplantae -nolow -noint {new_file}.fasta.mod.cat.gz
    mv {new_file}.fasta.mod.tbl TEs-Report-Complete.txt
    perl {UPLOAD_FOLDER}/ProcessRepeats/ProcessRepeats-lite.pl -species viridiplantae -nolow -noint -a {new_file}.fasta.mod.cat.gz
    mv {new_file}.fasta.mod.tbl TEs-Report-Lite.txt

    #Plot
    cat {new_file}.fasta.mod.align  | sed 's#TIR/.\+ #TIR &#g'  | sed 's#DNA/Helitron.\+ #Helitron &#g' | sed 's#LTR/Copia.\+ #LTR/Copia &#g' | sed 's#LTR/Gypsy.\+ #LTR/Gypsy &#g'  | sed 's#LINE-like#LINE#g' | sed 's#TR_GAG/Copia.\+ #LTR/Copia &#g' | sed 's#TR_GAG/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#TRBARE-2/Copia.\+ #LTR/Copia &#g' | sed 's#BARE-2/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#LINE/.\+ #LINE &#g' > tmp.txt
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

    genome_size="`perl {UPLOAD_FOLDER}/EDTA/util/count_base.pl ../{new_file}.fasta.mod | cut -f 2`"
    perl {UPLOAD_FOLDER}/ProcessRepeats/createRepeatLandscape.pl -g $genome_size -div At.divsum > ../RepeatLandscape.html

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
    
	python {UPLOAD_FOLDER}/Scripts/plot_TEs.py
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
	python {UPLOAD_FOLDER}/Scripts/plot_TEs.py
	mv TE-Report.pdf TE-Report2.pdf
    pdf2svg TE-Report2.pdf TE-Report2.svg

	python {UPLOAD_FOLDER}/Scripts/plot_TEs-bubble.py
	mv TE-Report.pdf TE-Report2-bubble.pdf
    pdf2svg TE-Report2-bubble.pdf TE-Report2-bubble.svg

    wait
    cd {completeAnalysis_folder}
    mkdir LTR-AGE
    cd LTR-AGE
    ln -s ../{new_file}.fasta.mod.EDTA.raw/{new_file}.fasta.mod.LTR-AGE.pass.list

    ln -s {UPLOAD_FOLDER}/Rscripts/plot-AGE-Gypsy.R
    ln -s {UPLOAD_FOLDER}/Rscripts/plot-AGE-Copia.R

    cat -n {new_file}.fasta.mod.LTR-AGE.pass.list | grep Gypsy | cut -f 1,13 | sed 's# ##g' | sed 's#^#Cluster_#g' | awk '{{if ($2 > 0) print $n}}' > AGE-Gypsy.txt
    cat -n {new_file}.fasta.mod.LTR-AGE.pass.list | grep Copia | cut -f 1,13 | sed 's# ##g' | sed 's#^#Cluster_#g' | awk '{{if ($2 > 0) print $n}}' > AGE-Copia.txt

    Rscript plot-AGE-Gypsy.R
    Rscript plot-AGE-Copia.R

    pdf2svg AGE-Copia.pdf AGE-Copia.svg
    pdf2svg AGE-Gypsy.pdf AGE-Gypsy.svg

    cd {completeAnalysis_folder}
    mkdir TREE
    cd TREE

    ln -s ../{new_file}.fasta.mod.EDTA.TEanno.sum tree.mod.EDTA.TEanno.sum

    cat ../{new_file}.fasta.mod.EDTA.TElib.fa | sed 's/#/_CERC_/g'  | sed 's#/#_BARRA_#g'  > tmp.txt
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

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run annotep with specified parameters.",
                                 formatter_class=RawTextHelpFormatter)

    required = parser.add_argument_group('required arguments')
    required.add_argument("--file", type=check_fasta_file, help="Genome file name (.fasta)", required=True)
    required.add_argument("--type", type=int, choices=[1, 2, 3, 4],
                        help="Type annotation:\n [1] SINE Annotation \n [2] LINE Annotation\n [3] SINE and LINE annotation\n [4] Complete Annotation",
                        required=True)

    parser.add_argument("--threads", type=int, help="Number of threads used to complete annotation (default threads: 4).\nThis parameter does not need to be set for the other annotation types [1, 2, 3].", default=4)

    args = parser.parse_args()

    run_annotep(args.file, args.type, args.threads)
