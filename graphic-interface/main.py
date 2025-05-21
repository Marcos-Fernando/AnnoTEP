import os, json
import re
from datetime import datetime
import subprocess

from app import create_app, allowed_file
from werkzeug.utils import secure_filename
from flask import render_template, request, redirect, flash, jsonify
from extensions.sendemail import send_email_checking, send_email_complete_annotation, send_email_error_annotation

app, _ = create_app()

# ===================== Environments ======================
GRAPHIC_DIR = os.path.dirname(os.path.abspath(__file__))
RESULTS_DIR = os.path.join(GRAPHIC_DIR, 'results')
UPLOAD_DIR = os.path.join(GRAPHIC_DIR, '..')
EDTA_DIR = os.path.join(UPLOAD_DIR,'EDTA')
SCRIPT_DIR = os.path.join(UPLOAD_DIR,'Scripts')

@app.route("/")
def index():
    return render_template("index.html")

@app.route('/annotation_process', methods=['GET','POST'])
def annotation_process():
    # Receiving data from the front-end
    email = request.form.get('email')
    email = email.strip() if email else None
    genome = request.files.get('genome')

    # Extracts the first item from each list or leaves it empty if the list is empty
    speciesTIR = request.form.getlist('tircandidates')[0] if request.form.getlist('tircandidates') else None
    stepsExecuted = request.form.getlist('stepannotation')[0] if request.form.getlist('stepannotation') else None

    overwrite = int(request.form.get('overwrite', 0))
    sensitivity = int(request.form.get('sensitivity', 0))
    annotation = int(request.form.get('annotation', 0))
    evaluate = int(request.form.get('evaluate', 0))
    force = int(request.form.get('force', 0))

    mutation_rate = request.form.get("mutation_rate") 
    max_divergence = request.form.get("max_divergence")
    num_threads = int(request.form.get('thread'))

    cds_file = request.files.get('cds_file')
    curate_lib_file = request.files.get('curate_lib')
    masked_regions_file = request.files.get('masked_region')
    rm_lib_file = request.files.get('rm_lib')
    rmout_file = request.files.get('rmout_lib')

    #Data verification
    if genome.filename == '':
        flash('No selected file')
        return redirect(request.url)
    
    if genome and allowed_file(genome.filename):
        #secure_filename() check if an inject has been applied, if the file contains ../ it will be changed to: ‘ ’ or ‘_’
        filename_genome = secure_filename(genome.filename)
        genome_name, extension = os.path.splitext(filename_genome)

    #-------------- Data naming process -------------------
    #Getting and formatting date and time
    now = datetime.now()
    formatted_date = now.strftime("%Y%m%d-%H%M%S")
    storageFolder = f'{genome_name}_{"".join(formatted_date)}'

    output_dir = os.path.join(RESULTS_DIR, storageFolder)
    os.makedirs(output_dir)

    genome_fasta = f'{genome_name}{extension}'
    genome.save(os.path.join(RESULTS_DIR, storageFolder, genome_fasta))

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

    # Filter out parameters that are empty or have a value of 0
    filtered_params = {key: value for key, value in params.items() if value not in [None, 0, '']}
    # Build the parameter string
    param_str = ' '.join([f"{key} {value}" for key, value in filtered_params.items()])

    #If you have a registered e-mail address, a message will be sent informing you of the data used.
    if email:
        send_email_checking(email, genome_fasta, speciesTIR, stepsExecuted, sensitivity, num_threads, param_str)


    log_file_path = os.path.join(output_dir, "log.txt")
    success = True

    # Final command
    try:
        cmds = f"""
            cd {output_dir}

            source $HOME/miniconda3/etc/profile.d/conda.sh && conda activate EDTA-new &&
            export PATH="$HOME/miniconda3/envs/EDTA-new/bin:$PATH" &&
            export PATH="$HOME/miniconda3/envs/EDTA-new/bin/RepeatMasker:$PATH" &&
            export PATH="$HOME/miniconda3/envs/EDTA-new/bin/gt:$PATH" &&
            export PATH="{EDTA_DIR}/util:$PATH" &&

            {EDTA_DIR}/EDTA.pl --genome {genome_fasta} --species {speciesTIR} --step {stepsExecuted} --sensitive {sensitivity} --threads {num_threads} {param_str} &&

            wait &&
            perl {SCRIPT_DIR}/generate_PLOTs-for-TE-pipe.sh {genome_fasta}
        """

        with open(log_file_path, "w") as logfile:
            process = subprocess.Popen(cmds, shell=True, executable='/bin/bash',
                                   stdout=logfile, stderr=logfile)
            process.wait()

        # Check if it failed
        if process.returncode != 0:
            success = False
            badAnnotation = "Error in the annotation step"
        else:
            succeededAnnotation = "Annotation finalised"
            
        with open(os.path.join(output_dir, "status.txt"), "w") as f:
            f.write(succeededAnnotation if success else badAnnotation)

    except Exception as e:
        success = False
        with open(log_file_path, "a") as logfile:
            logfile.write(f"\n\n[Pipeline Error]\n{str(e)}\n")

    finally:
        if email:
            if success:
                send_email_complete_annotation(email, storageFolder, log_file_path)
            else:
                send_email_error_annotation(email, storageFolder, log_file_path)


    print("Finished annotation")
    print("")

    # print("Email:", email)
    # print("Threads:", num_threads)
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

@app.route("/status")
def status():
    subfolders = sorted(
        [os.path.join(RESULTS_DIR, p) for p in os.listdir(RESULTS_DIR)],
        key=lambda p: os.path.getctime(p),
        reverse=True
    )[:10]

    data = [read_page_status(p) for p in subfolders]
    return jsonify(data)

def read_page_status(folder):
    try:
        log_path = os.path.join(folder, "log.txt")
        status_path = os.path.join(folder, "status.txt")
        
        start_time = extract_folder_time(os.path.basename(folder))

        status = {
            "name": os.path.basename(folder),
            "start": start_time,
            "completed": False,
            "end": None,
            "results": None,
            "last_lines_log": read_last_lines_log(log_path) if os.path.exists(log_path) else []
        }

        if os.path.exists(status_path):
            status["completed"] = True
            status["end"] = os.path.getmtime(status_path)

            try:
                with open(status_path, 'r') as f:
                    status["results"] = f.read().strip()
            except Exception as e:
                status["results"] = f"Erro ao ler status: {str(e)}"

        return status
        
    except Exception as e:
        return {
            "nome": os.path.basename(folder),
            "erro": str(e)
        }

def read_last_lines_log(log_path, num_lines=20):
    try:
        with open(log_path, "r") as f:
            lines = f.readlines()
            # Returns the last `num_lines` of the file, and ensures that each line has a date/time
            return [line.strip() for line in lines[-num_lines:]]  # Remove line breaks
    except FileNotFoundError:
        return []
    
# def read_last_lines_log(log_path):
#     try:
#         with open(log_path, "r") as f:
#             lines = f.readlines()
#             return [line.strip() for line in lines]  # Returns all lines, without limit
#     except FileNotFoundError:
#         return []

def extract_folder_time(name_folder):
    # Regular expression to extract the ‘YYYYMMDD-HHMMSS’ part of the folder name
    match = re.search(r"(\d{8}-\d{6})$", name_folder)
    
    if match:
        # Extracts the part of the folder name that contains the date and time
        data_str = match.group(1)
        
        # Converts the date string to a datetime object
        try:
            time = datetime.strptime(data_str, "%Y%m%d-%H%M%S")
            
            # Returns the ISO format to be understood by JavaScript
            return time.isoformat()
        except ValueError:
            return None  # If unable to convert, returns None
    return None  # If you don't find the expected format
    

if __name__ == "__main__":
    app.run(debug=True)
