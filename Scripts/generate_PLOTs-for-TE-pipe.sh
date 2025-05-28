#!/usr/bin/bash
# Main Variables:
genome="$1" #genome .fa  .fasta
name=$(basename "$genome" | sed 's/\.[^.]*$//')     # For genera and species i.e Athaliana
CPU="20"
#
# TES="/home/amvarani/AnnoTEP/AnnoTEP_v1"
TES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$(dirname "$TES")/Scripts"
PROCESSREPEATS="$(dirname "$TES")/ProcessRepeats"
RSCRIPTS="$(dirname "$TES")/Rscripts"
EDTA="$(dirname "$TES")/EDTA"

#
# TE plotting 
#
mkdir -p REPORT
cd REPORT
#
# VCheck if the file ../"${genome}.fa.mod.EDTA.anno"/"${genome}.fa.mod.cat.gz" exists
source_file="../${genome}.mod.EDTA.anno/${genome}.mod.cat.gz"
if [ -f "$source_file" ]; then
    echo "File found: $source_file"
    # Creates or updates the symbolic link in the current folder
    ln -sf "$source_file" "${genome}.mod.cat.gz"
    echo "Symbolic link created ${genome}.mod.cat.gz -> $source_file"
else
    echo "Error: file $source_file not found. Aborting execution."
    exit 1
fi
#
#
# Displays the genome to be processed (optional)
echo "processing the genome: ${genome}"
#

python  $SCRIPTS/filter_repeatmasker_catgz.py  \
  --input "${genome}.mod.cat.gz" \
  --output "${genome}.mod.filtered.cat.gz" \
  --log removed.log \
  --containment-threshold 1.0



echo "Starting adapted ProcessRepeats ..."
# Perfoms processing with the Perl Script "ProcessRepeats-lite.pl"
perl $PROCESSREPEATS/ProcessRepeats-lite.pl -species viridiplantae -nolow -noint "${genome}.mod.filtered.cat.gz"

# Renames the output file to indicate that the LITE
mv "${genome}.mod.filtered.tbl" "${genome}.mod-LITE.tbl"

# Perfoms processing with the Perl Script "ProcessRepeats-complete.pl"
perl $PROCESSREPEATS/ProcessRepeats-complete.pl -species viridiplantae -nolow -noint -a "${genome}.mod.filtered.cat.gz"

# Renames the output file to indicate that the COMPLETE
mv "${genome}.mod.filtered.tbl" "${genome}.mod-COMPLETE.tbl"

#
#
echo "Creating repeat landscape started ..."
#
cat $genome.mod.filtered.align  | sed 's#TIR/.\+ #TIR &#g'  | sed 's#DNA/Helitron.\+ #Helitron &#g' | sed 's#LTR/Copia.\+ #LTR/Copia &#g' | sed 's#LTR/Gypsy.\+ #LTR/Gypsy &#g'  | sed 's#LINE-like#LINE#g' | sed 's#TR_GAG/Copia.\+ #LTR/Copia &#g' | sed 's#TR_GAG/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#TRBARE-2/Copia.\+ #LTR/Copia &#g' | sed 's#BARE-2/Gypsy.\+ #LTR/Gypsy &#g' | sed 's#LINE/.\+ #LINE &#g' > tmp.txt
#
# For convenience you may choose less elements just skipping the desirable lines below
#
cat tmp.txt  | grep "^[0-9]" -B 6 | grep -v "^--" | grep "LTR/Copia" -A 5 | grep -v "^--"  > align2.txt
cat tmp.txt  | grep "^[0-9]" -B 6 | grep -v "^--" | grep "LTR/Gypsy" -A 5 | grep -v "^--"  >> align2.txt
cat tmp.txt  | grep "^[0-9]" -B 6 | grep -v "^--" | grep "TIR" -A 5 | grep -v "^--"  >> align2.txt
cat tmp.txt  | grep "^[0-9]" -B 6 | grep -v "^--" | grep "LINE" -A 5 | grep -v "^--"  >> align2.txt
cat tmp.txt  | grep "^[0-9]" -B 6 | grep -v "^--" | grep -v LARD-like | grep "LARD" -A 5 | grep -v "^--"  >> align2.txt
cat tmp.txt  | grep "^[0-9]" -B 6 | grep -v "^--" | grep -v TRIM-like | grep "TRIM" -A 5 | grep -v "^--"  >> align2.txt
cat tmp.txt  | grep "^[0-9]" -B 6 | grep -v "^--" | grep "Helitron" -A 5 | grep -v "^--"  >> align2.txt
cat tmp.txt  | grep "^[0-9]" -B 6 | grep -v "^--" | grep "SINE" -A 5 | grep -v "^--"  >> align2.txt
cat tmp.txt  | grep "^[0-9]" -B 6 | grep -v "^--" | grep -v RC | grep "#Unknown" -A 5 | grep -v "^--"  >> align2.txt
#
#
awk 'c-- > 0 { next } /-like/ { c=4; next } 1' align2.txt > align3.txt
# Now calculate the divergence 
perl $PROCESSREPEATS/calcDivergenceFromAlign.pl -s $name.divsum align3.txt
#
# Calculate genome size
genome_size="`perl $EDTA/util/count_base.pl ../$genome | cut -f 2`" 
#
perl $PROCESSREPEATS/createRepeatLandscape.pl -g $genome_size -div $name.divsum > RepeatLandscape.html
#
tail -n 72 $name.divsum > divsum.txt
#
cat $RSCRIPTS/plotKimura.R | sed "s#_SIZE_GEN_#$genome_size#g" > plotKimura.R
Rscript plotKimura.R > /dev/null 2>&1
rm align2.txt
rm align3.txt
rm tmp.txt
rm Rplots.pdf
#
#
# AGEs
echo "Plotting age distribution started ..."
ln -s ../$genome.mod.EDTA.raw/$genome.mod.LTR-AGE.pass.list .
#
ln -s $RSCRIPTS/plot-AGE-Gypsy.R .
ln -s $RSCRIPTS/plot-AGE-Copia.R .
#
# Preparing the file
cat -n $genome.mod.LTR-AGE.pass.list  | grep Gypsy  | cut -f 1,13 | sed 's# ##g'  | sed 's#^#Cluster_#g' | awk '{if ($2 > 0) print $n}'   > AGE-Gypsy.txt
cat -n $genome.mod.LTR-AGE.pass.list  | grep Copia  | cut -f 1,13 | sed 's# ##g'  | sed 's#^#Cluster_#g' | awk '{if ($2 > 0) print $n}'   > AGE-Copia.txt
#
# Generating the plots
Rscript plot-AGE-Gypsy.R > /dev/null 2>&1
Rscript plot-AGE-Copia.R > /dev/null 2>&1
#
#
#
#	
# TREEs 
echo "Creating LTR phylogeny ..."
mkdir TREE
cd TREE
#
#
ln -s ../../$genome.mod.EDTA.TElib.fa .
ln -s ../../$genome.mod.EDTA.TEanno.sum . 
cat $genome.mod.EDTA.TElib.fa | sed 's/#/_CERC_/g'  | sed 's#/#_BARRA_#g'  > tmp.txt
mkdir tmp
break_fasta.pl < tmp.txt ./tmp
num_ltr="`ls tmp/*LTR* | wc -l`"
#
if [ "$num_ltr" -gt "700" ] ; then
	rm tmp/*like*.fasta
	cat tmp/*LTR* | sed 's#_CERC_#\t#g' | cut -f 1 > TE.fasta
else 
	cat tmp/*LTR* | sed 's#_CERC_#\t#g' | cut -f 1 > TE.fasta
fi
#
rm -f tmp.txt ; rm -f $genome.mod.EDTA.TElib.fa ; rm -Rf tmp
#
#
TEsorter -db rexdb-plant --hmm-database rexdb-plant -pre TE -p $CPU TE.fasta > /dev/null 2>&1
#
#
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
#
#
perl $SCRIPTS/catfasta2phyml.pl -c -f GAG.fas PROT.fas RH.fas RT.fas INT.fas > all.fas
#
OMP_NUM_THREADS=$CPU FastTreeMP -gamma -wag all.fas > all.nwk
#
#
#
cat TE.cls.tsv | cut -f 1 | sed "s#^#cat $genome.mod.EDTA.TEanno.sum | grep -w \"#g"  | sed 's#$#"#g'   > pick-occur.sh
bash pick-occur.sh  > occur.txt
cat occur.txt  | sed 's#^      TE_#TE_#g'  | awk '{print $1,$2,$3}' | sed 's# #\t#g' |  sort -k 2 -V  > sort_occur.txt
cat occur.txt  | sed 's#^      TE_#TE_#g'  | awk '{print $1,$2,$3}' | sed 's# #\t#g' |  sort -k 3 -V  > sort_size.txt
#
#
cat all.fas  | grep "^>" | sed 's#^>##g'   > ids.txt
#
cat sort_occur.txt | cut -f 1,2 | sed 's#^#id="#g' | sed 's#\t#" ; data="#g' | sed 's#$#" ; ver="`cat ids.txt | grep $id`" ; echo -e "$ver\\t$data" #g'   > pick.sh
bash pick.sh  | grep "^TE" | grep "^TE"  | sed 's/#/_/g' | sed 's#/#_#g'  > occurrences.tsv
#
#
cat sort_size.txt | cut -f 1,3 | sed 's#^#id="#g' | sed 's#\t#" ; data="#g' | sed 's#$#" ; ver="`cat ids.txt | grep $id`" ; echo -e "$ver\\t$data" #g'   > pick.sh
bash pick.sh  | grep "^TE" | grep "^TE"  | sed 's/#/_/g' | sed 's#/#_#g'  > size.tsv
#
rm -f pick-occur.sh sort_occur.txt sort_size.txt ids.txt pick.sh
#
ln -s $RSCRIPTS/LTR_tree.R .
ln -s $RSCRIPTS/LTR_tree-density.R .
#
Rscript LTR_tree.R all.nwk TE.cls.tsv LTR_RT-Tree1 > /dev/null 2>&1
Rscript LTR_tree-density.R all.nwk TE.cls.tsv occurrences.tsv size.tsv LTR_RT-Tree2 > /dev/null 2>&1
#
cp *.pdf ../
cp *.png ../
#
rm -f size.tsv occur.txt occurrences.tsv 
cd ..
#
echo "Starting creation of TE bar and bubble plots ..."
#
cat $genome.mod-LITE.tbl | grep "%"   | cut -f 2 -d":"   | awk '{print $1}' > count.txt
cat $genome.mod-LITE.tbl | grep "%"   | cut -f 2 -d":"   | awk '{print $2}' > bp.txt
cat $genome.mod-LITE.tbl | grep "%"   | cut -f 2 -d":"   | awk '{print $4}' > percentage.txt
cat $genome.mod-LITE.tbl | grep "%"   | cut -f 1 -d":"   | sed 's# ##g'  | sed 's#-##g'  | sed 's#|##g' > names.txt
#
#
#
paste names.txt count.txt bp.txt percentage.txt | grep -w NonLTR  > plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w LTRNonauto | sed 's#LTRNonauto#LTR_nonauto#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "LTR/Copia"  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "LTR/Gypsy"  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "Pararetrovirus"  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "ClassIUnknown" | sed 's#ClassIUnknown#Class_I_Unknown#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "TIRs"  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "ClassIIUnknown" | sed 's#ClassIIUnknown#Class_II_Unknown#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "Unclassified" | tail -n 1 >> plot.txt
echo "Type	Number	length	percentage" > header.txt
cat header.txt plot.txt > plot1.txt
#
#
ln -s $SCRIPTS/plot_TEs.py .
ln -s $SCRIPTS/plot_TEs-bubble.py .
#
python plot_TEs.py > /dev/null 2>&1
python plot_TEs-bubble.py > /dev/null 2>&1
#
#
#
#
#
paste names.txt count.txt bp.txt percentage.txt | grep -w SINEs > plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w LINEs >> plot.txt
#
paste names.txt count.txt bp.txt percentage.txt | grep -w LARDs >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w TRIMs >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w TR_GAG >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w BARE2 >> plot.txt
#
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
#
paste names.txt count.txt bp.txt percentage.txt | grep -w Alexandra >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Ferco >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Bryana >> plot.txt
#
#
#
#
paste names.txt count.txt bp.txt percentage.txt | grep -w Phygy >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Selgy >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Athila  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Tatius  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w TatI  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w TatII  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w TatIII  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Ogre  >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Retand  >> plot.txt
#
paste names.txt count.txt bp.txt percentage.txt | grep -w Chlamyvir >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Tcn1 >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w CRM >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Galadriel >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Tekay >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Reina >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Ferney >> plot.txt
#
#
paste names.txt count.txt bp.txt percentage.txt | grep -w Penelope >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w DIRS >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Pararetrovirus >> plot.txt
#
#
#
#
paste names.txt count.txt bp.txt percentage.txt | grep -w MITEs >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w EnSpm_CACTA | sed 's#EnSpm_CACTA#CACTA#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w hAT >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Kolobok >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Merlin >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w MuDR_Mutator | sed 's#MuDR_Mutator#MuDR#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Novosib >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Pelement | sed ' s#Pelement#P_element#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w PIF_Harbinger | sed 's#PIF_Harbinger#Harbinger#g' >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Ginger >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w PiggyBac >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Sola1 >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Sola2 >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Sola3 >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Tc1_Mariner >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w Transib >> plot.txt
paste names.txt count.txt bp.txt percentage.txt | grep -w "RC/Helitron" | sed 's#RC/Helitron#Helitron#g' >> plot.txt
#
paste names.txt count.txt bp.txt percentage.txt | grep -w Unclassified | tail -n 1 >> plot.txt
#
cat header.txt plot.txt | grep -v "0.00" > plot1.txt
#
#
ln -s $SCRIPTS/plot_TEs_2.py .
ln -s $SCRIPTS/plot_TEs-bubble_2.py .
#
python plot_TEs_2.py > /dev/null 2>&1
python plot_TEs-bubble_2.py > /dev/null 2>&1
#
#
#
ln -s ../$genome.mod.EDTA.anno/$genome.mod.EDTA.TEanno.split.density . 
ln -s $RSCRIPTS/density_plot.R . 
Rscript density_plot.R $genome.mod.EDTA.TEanno.split.density > /dev/null 2>&1
#
#
#
# Cleaning the mess
rm -f bp.txt count.txt divsum.txt header.txt names.txt percentage.txt plot1.txt plot.txt Rplots.pdf
#
echo "The generation of charts and reports has been completed"
#
#
exit 0
