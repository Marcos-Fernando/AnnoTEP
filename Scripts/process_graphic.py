import subprocess
import os
import argparse


#Definindo local dos arquivos
#principal
SCRIPT = os.path.dirname(os.path.abspath(__file__))

#processos
PROCESSREPEATS = os.path.join(SCRIPT, '..', 'ProcessRepeats')
EDTA_FOLDER = os.path.join(SCRIPT, '..', 'EDTA')
RSCRIPT = os.path.join(SCRIPT, '..','Rscripts')

def dataGeneration(genome):
    cmds = f"""
    mkdir TE-REPORT
    cd TE-REPORT
    ln -s ../{genome}.mod.EDTA.anno/{genome}.mod.cat.gz .

    perl {PROCESSREPEATS}/ProcessRepeats-complete.pl -species viridiplantae -nolow -noint {genome}.mod.cat.gz
    mv {genome}.mod.tbl TEs-Report-Complete.txt

    perl {PROCESSREPEATS}/ProcessRepeats-lite.pl -species viridiplantae -nolow -noint -a {genome}.mod.cat.gz
    mv {genome}.mod.tbl TEs-Report-Lite.txt

    #Plot
    cat {genome}.mod.align  | sed 's#TIR/.\+ #TIR &#g'  | sed 's#DNA/Helitron.\+ #Helitron &#g' | sed 's#LTR/Copia.\+ #LTR/Copia &#g' | sed 's#LTR/Gypsy.\+ #LTR/Gypsy &#g'  | sed 's#LINE-like#LINE#g' | sed 's#TR_GAG/Copia.\+ #LTR/Copia &#g' | sed 's#TR_GAG/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#TRBARE-2/Copia.\+ #LTR/Copia &#g' | sed 's#BARE-2/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#SINE/.\+ #SINE &#g'| sed 's#LINE/.\+ #LINE &#g' > tmp.txt

    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "LTR/Copia" -A 5 |  grep -v "\-\-"  > align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "LTR/Gypsy" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "TIR" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "LINE" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "LARD" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "TRIM" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "Helitron" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "SINE" -A 5 |  grep -v "\-\-"  >> align2.txt
    cat tmp.txt  | grep "^[0-9]"  -B 6 |  grep -v "\-\-"  | grep "Unknown" -A 5 |  grep -v "\-\-"  >> align2.txt

    perl {PROCESSREPEATS}/calcDivergenceFromAlign.pl -s At.divsum align2.txt

    genome_size="`perl {EDTA_FOLDER}/util/count_base.pl ../{genome}.mod | cut -f 2`"
    perl {PROCESSREPEATS}/createRepeatLandscape.pl -g $genome_size -div At.divsum > RepeatLandscape.html

    tail -n 72 At.divsum > divsum.txt

    cat {RSCRIPT}/plotKimura.R | sed "s#_SIZE_GEN_#$genome_size#g" > plotKimura.R
    Rscript plotKimura.R
    mv Rplots.pdf RepeatLandScape.pdf
    pdf2svg RepeatLandScape.pdf RLandScape.svg

    rm align2.txt

    # ========= Plotting ==============
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
    
	python {SCRIPT}/plot_TEs_length.py
	mv TE-Report.pdf TE-Report1.pdf
    pdf2svg TE-Report1.pdf TE-Report1.svg

	python {SCRIPT}/plot_TEs-bubble.py
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
	python {SCRIPT}/plot_TEs_length.py
	mv TE-Report.pdf TE-Report2.pdf
    pdf2svg TE-Report2.pdf TE-Report2.svg

	python {SCRIPT}/plot_TEs-bubble.py
	mv TE-Report.pdf TE-Report2-bubble.pdf
    pdf2svg TE-Report2-bubble.pdf TE-Report2-bubble.svg

    wait
    rm -f *.divsum \
      *.mod.align \
      *.mod.cat.gz \
      *.mod.out \
      bp.txt \
      count.txt \
      divsum.txt \
      header.txt \
      names.txt \
      percentage.txt \
      plot.txt \
      plot1.txt \
      plotKimura.R \
      tmp.txt

    # ========================
    wait
    cd ..
    mkdir LTR-AGE
    cd LTR-AGE
    ln -s ../{genome}.mod.EDTA.raw/{genome}.mod.LTR-AGE.pass.list

    ln -s {RSCRIPT}/plot-AGE-Gypsy.R
    ln -s {RSCRIPT}/plot-AGE-Copia.R

    cat -n {genome}.mod.LTR-AGE.pass.list | grep Gypsy | cut -f 1,13 | sed 's# ##g' | sed 's#^#Cluster_#g' | awk '{{if ($2 > 0) print $n}}' > AGE-Gypsy.txt
    cat -n {genome}.mod.LTR-AGE.pass.list | grep Copia | cut -f 1,13 | sed 's# ##g' | sed 's#^#Cluster_#g' | awk '{{if ($2 > 0) print $n}}' > AGE-Copia.txt

    Rscript plot-AGE-Gypsy.R
    Rscript plot-AGE-Copia.R

    pdf2svg AGE-Copia.pdf AGE-Copia.svg
    pdf2svg AGE-Gypsy.pdf AGE-Gypsy.svg

    wait
    rm -f *mod.LTR-AGE.pass.list \
            plot-AGE-Copia.R \
            plot-AGE-Gypsy.R

    # =============================
    cd ..
    mkdir TREE
    cd TREE

    ln -s ../{genome}.mod.EDTA.TEanno.sum tree.mod.EDTA.TEanno.sum

    cat ../{genome}.mod.EDTA.TElib.fa | sed 's/#/_CERC_/g'  | sed 's#/#_BARRA_#g'  > tmp.txt
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
    
    perl {SCRIPT}/catfasta2phyml.pl -c -f *.fas > all.fas
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
    
    ln -s {RSCRIPT}/LTR_tree.R
    ln -s {RSCRIPT}/LTR_tree-density.R
    ln -s {RSCRIPT}/LTR_tree_rec_1.R
    ln -s {RSCRIPT}/LTR_tree_rec_2.R

    Rscript LTR_tree.R all.fas.contree TE.cls.tsv LTR_RT-Tree1.pdf
    Rscript LTR_tree-density.R all.fas.contree TE.cls.tsv occurrences.tsv size.tsv LTR_RT-Tree2.pdf
    Rscript LTR_tree_rec_1.R all.fas.contree TE.cls.tsv LTR_RT-Tree3.pdf
    Rscript LTR_tree_rec_2.R all.fas.contree TE.cls.tsv LTR_RT-Tree4.pdf

    pdf2svg LTR_RT-Tree1.pdf LTR_RT-Tree1.svg
    pdf2svg LTR_RT-Tree2.pdf LTR_RT-Tree2.svg
    pdf2svg LTR_RT-Tree3.pdf LTR_RT-Tree3.svg
    pdf2svg LTR_RT-Tree4.pdf LTR_RT-Tree4.svg

    wait
    rm -f all.fas \
            all.fas.* \
            GAG.* \
            ids.txt \
            INT.* \
            occ-pick.sh \
            occur.txt \
            occurrences.tsv \
            sort_occur.txt \
            sort_size.txt \
            pick-occur.sh \
            PROT.* \
            RH.* \
            RT.* \
            size.tsv \
            size-pick.sh \
            TE.* \
            tmp.txt \
            tree.mod.* \
            LTR_tree.R \
            LTR_tree-density.R \
            LTR_tree_rec_1.R \
            LTR_tree_rec_2.R

    rm -rf tmp
    """

    process = subprocess.Popen(cmds, shell=True, executable='/bin/bash')
    process.wait()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Graph creation script")
    parser.add_argument("genome", type=str, help="Name genome .fasta")

    args = parser.parse_args()
    dataGeneration(args.genome)
