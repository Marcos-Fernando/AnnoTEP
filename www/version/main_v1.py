import io
import os
import random
import subprocess
import matplotlib.pyplot as plt
from werkzeug.utils import secure_filename
from flask import Flask, render_template, request, redirect, flash, url_for, send_from_directory

#Definindo local onde os arquivos ficarão salvo
CONDA = os.environ['CONDA_PREFIX']
HOME = os.environ['HOME']
UPLOAD_FOLDER = os.path.join(HOME, 'TEs')
SINE_FOLDER = os.path.join(UPLOAD_FOLDER, 'SINE', 'AnnoSINE', 'bin')
NONLTR_FOLDER = os.path.join(UPLOAD_FOLDER, 'non-LTR')
MGESCAN_FOLDER = os.path.join(NONLTR_FOLDER, 'mgescan')
EDTA_FOLDER = os.path.join(UPLOAD_FOLDER, 'EDTA')

#Extensões que serão permitidas
ALLOWED_EXTENSIONS = {'fasta'}
app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route("/")
def index():
    return render_template("index.html")

#Verifica se a extensão é válida e depois redireciona o usuário para a URL
def allowed_file(filename):
    return '.' in filename and \
            filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

#Anotação do elemento SINE
def annoSINE(new_filename, newfolder, seedSINE):
    print("Iniciando processo de anotação dos elementos SINEs")
    print("Pasta criada para armazenamento dos dados: ", newfolder)

    os.chdir(SINE_FOLDER)
    cmds = f"""
    . $CONDA_PREFIX/etc/profile.d/conda.sh && conda activate AnnoSINE
    export PATH="/home/marcoscosta/miniconda3/envs/AnnoSINE/bin:$PATH"

    python3 AnnoSINE.py 3 {os.path.join(UPLOAD_FOLDER, new_filename)} {newfolder}
    cp ./{newfolder}/Seed_SINE.fa {os.path.join(UPLOAD_FOLDER, seedSINE)}
    """
    process = subprocess.Popen(cmds, shell=True, executable='/bin/bash')
    process.wait()

    print("Anotação SINE finalizada")

#Anotação LINE
def annoLINE(new_filename, newfolder, folderLINE, resultsLINE, libLINE):
    print("Iniciando processo de anotação dos elementos LINEs")
    print("Pasta criada para armazenamento dos dados: ", folderLINE)

    os.chdir(NONLTR_FOLDER)
    commands = f"""
    PATH=$HOME/TEs/non-LTR/hmmer-3.2/src/:$PATH

    cd {MGESCAN_FOLDER}
    source mgescan-virtualenv/bin/activate

    cd {NONLTR_FOLDER}
    mkdir {folderLINE}
    cd {folderLINE}
    ln -s {os.path.join(UPLOAD_FOLDER, new_filename)} {new_filename}
    cd ..

    ulimit -n 8192

    mgescan nonltr {os.path.join(NONLTR_FOLDER, folderLINE)} --output={os.path.join(NONLTR_FOLDER, resultsLINE)} --mpi=4

    cd {NONLTR_FOLDER}
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
    cp LINE-lib.fa {os.path.join(UPLOAD_FOLDER, libLINE)}
    """

    process = subprocess.Popen(commands, shell=True, executable='/bin/bash')
    process.wait()
    print("Anotação LINE finalizado")

def annoMSC(new_filename, newfolder, seedSINE, mscfolder, libLINE):
    print("Processo de mesclagem iniciado, análise com pipeline EDTA")

    os.chdir(EDTA_FOLDER)
    cmds = f"""
    . $CONDA_PREFIX/etc/profile.d/conda.sh && conda activate EDTA
    export PATH="/home/marcoscosta/miniconda3/envs/EDTA/bin:$PATH"
    export PATH="/home/marcoscosta/miniconda3/envs/EDTA/bin/gt:$PATH"

    cd {UPLOAD_FOLDER}
    mkdir {mscfolder}

    cd {mscfolder}
    nohup {EDTA_FOLDER}/EDTA.pl --genome ../{new_filename} --species others --step all --line ../{libLINE} --sine ../{seedSINE} --sensitive 1 --anno 1 --threads 10 > EDTA.log 2>&1 &

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

    cat $HOME/TEs/Rscripts/plotKimura.R | sed "s#_SIZE_GEN_#$genome_size#g" > plotKimura.R
    Rscript plotKimura.R
    mv Rplots.pdf ../RepeatLandScape.pdf

    rm align2.txt
    rm tmp.txt
    
    
    cd {UPLOAD_FOLDER}/{mscfolder}
    mkdir LTR-AGE
    cd LTR-AGE
    ln -s ../{new_filename}.mod.EDTA.raw/{new_filename}.mod.LTR-AGE.pass.list

    ln -s {UPLOAD_FOLDER}/Rscripts/plot-AGE-Gypsy.R
    ln -s {UPLOAD_FOLDER}/Rscripts/plot-AGE-Copia.R

    cat -n {new_filename}.mod.LTR-AGE.pass.list | grep Gypsy | cut -f 1,13 | sed 's# ##g' | sed 's#^#Cluster_#g' | awk '{{if ($2 > 0) print $n}}' > AGE-Gypsy.txt
    cat -n {new_filename}.mod.LTR-AGE.pass.list | grep Copia | cut -f 1,13 | sed 's# ##g' | sed 's#^#Cluster_#g' | awk '{{if ($2 > 0) print $n}}' > AGE-Copia.txt

    Rscript plot-AGE-Gypsy.R
    Rscript plot-AGE-Copia.R

    cd {UPLOAD_FOLDER}/{mscfolder}
    mkdir TREE
    cd TREE

    ln -s ../{new_filename}.mod.EDTA.TElib.fa .

    cat {new_filename}.mod.EDTA.TElib.fa | sed 's/#/_CERC_/g'  | sed 's#/#_BARRA_#g'  > tmp.txt
    mkdir tmp
    break_fasta.pl < tmp.txt ./tmp
    cat tmp/*LTR* | sed 's#_CERC_#\t#g' | cut -f 1 > TE.fasta

    rm -f tmp.txt ; rm -f {new_filename}.mod.EDTA.TElib.fa ; rm -Rf tmp

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

    cat TE.cls.tsv | cut -f 1 | sed "s#^#cat ../{new_filename}.mod.EDTA.TEanno.sum | grep -w \"#g"  | sed 's#$#"#g'   > pick-occur.sh
    bash pick-occur.sh  > occur.txt
    cat occur.txt  | sed 's#^      TE_#TE_#g'  | awk '{{print $1,$2,$3}}' | sed 's# #\t#g' |  sort -k 2 -V  > sort_occur.txt
    cat occur.txt  | sed 's#^      TE_#TE_#g'  | awk '{{print $1,$2,$3}}' | sed 's# #\t#g' |  sort -k 3 -V  > sort_size.txt

    cat all.fas  | grep \> | sed 's#^>##g'   > ids.txt

    cat sort_occur.txt | cut -f 1,2 | sed 's#^#id="#g' | sed 's#\t#" ; data="#g' | sed 's#$#" ; ver="`cat ids.txt | grep $id`" ; echo -e "$ver\\t$data" #g'   > pick.sh
    bash pick.sh  | grep "^TE" | grep "^TE"  | sed 's/#/_/g' | sed 's#/#_#g'  > occurrences.tsv

    cat sort_size.txt | cut -f 1,3 | sed 's#^#id="#g' | sed 's#\t#" ; data="#g' | sed 's#$#" ; ver="`cat ids.txt | grep $id`" ; echo -e "$ver\\t$data" #g'   > pick.sh
    bash pick.sh  | grep "^TE" | grep "^TE"  | sed 's/#/_/g' | sed 's#/#_#g'  > size.tsv

    rm -f pick-occur.sh sort_occur.txt sort_size.txt ids.txt pick.sh

    ln -s {UPLOAD_FOLDER}/Rscripts/LTR_tree.R .
    ln -s {UPLOAD_FOLDER}/Rscripts/LTR_tree-density.R .

    Rscript LTR_tree.R all.fas.contree TE.cls.tsv LTR_RT-Tree1.pdf
    Rscript LTR_tree-density.R all.fas.contree TE.cls.tsv occurrences.tsv size.tsv LTR_RT-Tree2.pdf
    """

    process = subprocess.Popen(cmds, shell=True, executable='/bin/bash')
    process.wait()
    print("Processo EDTA finalizado")


@app.route('/processar-arquivo', methods=['GET','POST'])
def upload_file():
    if request.method == 'POST':
        #Verificando se a solicitação de postagem tem a parte do arquivo
        if 'file' not in request.files:
            flash('No file part')
            return redirect(request.url)
        file = request.files['file']
        #Se o usuário selecionar um arquivo, o navegador enviará um
        #Arquivo vazio sem um nome de arquivo
        if file.filename == '':
            flash('No selected file')
            return redirect(request.url)

        if file and allowed_file(file.filename):
            #secure_filename() verificar se um inject foi aplicado, se o arquivo conter ../ será alterado para: " " ou "_"
            filename = secure_filename(file.filename)
            print("Arquivo recebido: ", filename)
           
            #Gerando quatro números randomicos para renomear o arquivo enviado
            random_numbers = [str(random.randint(0,9)) for i in range(4)]
           
            #Salvando nome e extensão para não perde-los durante processo
            filename, extension = os.path.splitext(file.filename)
            new_filename = f'{filename}_{"".join(random_numbers)}{extension}'
            print("Arquivo modificado para: ", new_filename)
           
            #criando a pasta para armazenar dados SINE
            newfolder =f'{filename[:2]}_{"".join(random_numbers)}'

            #Seed_SINE
            seedSINE =f'{filename}_{"".join(random_numbers)}-Seed_SINE.fa'

            #criando a pasta para armazenamento LINE
            folderLINE = f'{newfolder}-LINE'
            resultsLINE = f'{folderLINE}-results'

            #arquivo para ultima operação LINE
            libLINE = f'{newfolder}-LINE-lib.fa'

            #Cirando a pasta que contera a Mesclagem do SINE e LINE
            mscfolder = f'msc-{newfolder}'

            print("Repositórios de armazenamento: ")
            print("Anotação SINE: ", newfolder)
            print("Anotação LINE: ", folderLINE)
            print("Análise SINE e LINE: ", mscfolder)

            print("Documentos principais gerados: ")
            print("SINE: ", seedSINE)
            print("LINE", libLINE)

            file.save(os.path.join(app.config['UPLOAD_FOLDER'],new_filename))

	        # 1° processo - anotação dos elemntos SINE
            # Executar a função e verificar o status de saída com try except
            try:
                annoSINE(new_filename, newfolder, seedSINE)
            except subprocess.CalledProcessError as e:
                flash(f'Annotation SINE failed with error: {e}')
                return redirect(request.url)

            # 2° processo - anotação dos elementos LINE
            try:
                annoLINE(new_filename, newfolder, folderLINE, resultsLINE, libLINE)
            except:
                flash(f'Annotation LINE failde with error: {e}')
                return redirect(request.url)
            
            # 3° processo - mesclagem dos dados SINEs e LINEs
            try:
                annoMSC(new_filename, newfolder, seedSINE, mscfolder, libLINE)
            except:
                flask(f'Annotation Complete  failde with error: {e}')
                return redirect(request.url)

            return render_template("index.html")
    return render_template("index.html")

@app.route("/results")
def results():
    return "results"
if __name__ == "__main__":
    app.run(debug=True)
