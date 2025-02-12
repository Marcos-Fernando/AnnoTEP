import os
from datetime import datetime
import subprocess

from app import create_app, allowed_file
from werkzeug.utils import secure_filename
from flask import render_template, request, redirect, flash, jsonify
from extensions.sendemail import send_email_checking, send_email_complete_annotation
from extensions.annotation import dataGeneration

app, _ = create_app()

# ===================== Ambientes ======================
GRAPHIC_FOLDER = os.path.dirname(os.path.abspath(__file__))

# ================= Locais dos arquivos ================
RESULTS_FOLDER = os.path.join(GRAPHIC_FOLDER, 'results')
UPLOAD_FOLDER = os.path.join(GRAPHIC_FOLDER, '..')
EDTA_FOLDER = os.path.join(UPLOAD_FOLDER,'EDTA')

@app.route("/")
def index():
    return render_template("index.html")

@app.route('/annotation_process', methods=['GET','POST'])
def annotation_process():
    # Recebendo os dados do front-end
    email = request.form.get('email')
    genome = request.files.get('genome')

    # Extrai o primeiro item de cada lista ou deixa vazio caso a lista esteja vazia
    speciesTIR = request.form.getlist('tircandidates')[0] if request.form.getlist('tircandidates') else None
    stepsExecuted = request.form.getlist('stepannotation')[0] if request.form.getlist('stepannotation') else None

    overwrite = int(request.form.get('overwrite', 0))
    sensitivity = int(request.form.get('sensitivity', 0))
    annotation = int(request.form.get('annotation', 0))
    evaluate = int(request.form.get('evaluate', 0))
    force = int(request.form.get('force', 0))

    mutation_rate = request.form.get("mutation_rate") 
    max_divergence = request.form.get("max_divergence")
    threads = int(request.form.get('thread'))

    cds_file = request.files.get('cds_file')
    curate_lib_file = request.files.get('curate_lib')
    masked_regions_file = request.files.get('masked_region')
    rm_lib_file = request.files.get('rm_lib')
    rmout_file = request.files.get('rmout_lib')

    #verificação de dados
    if genome.filename == '':
        flash('No selected file')
        return redirect(request.url)
    
    if genome and allowed_file(genome.filename):
        #secure_filename() verificar se um inject foi aplicado, se o arquivo conter ../ será alterado para: " " ou "_"
        genome_name = secure_filename(genome.filename)
        genome_name, extension = os.path.splitext(genome.filename)

    #-------------- Processo de nomeação dos dados -------------------
    #Obtendo e formatando data e hora
    now = datetime.now()
    formatted_date = now.strftime("%Y%m%d-%H%M%S")
    storageFolder = f'{genome_name}_{"".join(formatted_date)}'

    resultsAddress = os.path.join(RESULTS_FOLDER, storageFolder)
    os.makedirs(resultsAddress)

    new_genome_name = f'{genome_name}{extension}'
    genome.save(os.path.join(RESULTS_FOLDER, storageFolder, new_genome_name))

    params = {
        '--overwrite': overwrite,
        '--anno': annotation,
        '--evaluate': evaluate,
        '--force': force,
        '--u': mutation_rate,
        '--maxdiv': max_divergence,
        '--cds': cds_file.filename if cds_file else '',
        '--curatedlib': curate_lib_file.filename if curate_lib_file else '',
        '--exclude': masked_regions_file.filename if masked_regions_file else '',
        '--rmlib': rm_lib_file.filename if rm_lib_file else '',
        '--rmout': rmout_file.filename if rmout_file else ''
    }

    # Filtre parâmetros que estão vazios ou com valor 0
    filtered_params = {key: value for key, value in params.items() if value not in [None, 0, '']}
    # Construa a string de parâmetros
    param_str = ' '.join([f"{key} {value}" for key, value in filtered_params.items()])

    #enviando email informando os dados utilizados
    send_email_checking(email, new_genome_name, speciesTIR, stepsExecuted, sensitivity, threads, param_str)

    # Comando final
    cmds = f"""
    cd {resultsAddress}

    source $HOME/miniconda3/etc/profile.d/conda.sh && conda activate EDTA2 &&
    export PATH="$HOME/miniconda3/envs/EDTA2/bin:$PATH" &&
    export PATH="$HOME/miniconda3/envs/EDTA2/bin/RepeatMasker:$PATH" &&
    export PATH="$HOME/miniconda3/envs/EDTA2/bin/gt:$PATH" &&
    export PATH="$HOME/TEs/EDTA/util:$PATH" &&
        
    {EDTA_FOLDER}/EDTA.pl --genome {new_genome_name} --species {speciesTIR} --step {stepsExecuted} --sensitive {sensitivity} --threads {threads} {param_str}
    """

    process = subprocess.Popen(cmds, shell=True, executable='/bin/bash')
    process.wait()

    dataGeneration(new_genome_name, resultsAddress)
    send_email_complete_annotation(email, storageFolder)

    print("Finished annotation")
    print("")

    # print("Email:", email)
    # print("Threads:", threads)
    # print("Genome File:", genome.filename)
    # print("TIR:", speciesTIR)
    # print("Step:", stepsExecuted)
    # print("Overwrite:", overwrite)
    # print("Sensitivity:", sensitivity)
    # print("Annotation:", annotation)
    # print("Evaluate:", evaluate)
    # print("Force:", force)
    # print("Mutation Rate:", mutation_rate)
    # print("Maximum Divergence:", max_divergence)
    # print("CDS:", cds_file.filename if cds_file else '')
    # print("CurateLib:", curate_lib_file.filename if curate_lib_file else '')
    # print("MaskedRegions:", masked_regions_file.filename if masked_regions_file else '')
    # print("RM_Lib:", rm_lib_file.filename if rm_lib_file else '')
    # print("RM_out:", rmout_file.filename if rmout_file else '')
    return render_template("index.html")

if __name__ == "__main__":
    app.run(debug=True)
