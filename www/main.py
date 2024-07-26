import os
import zipfile

from app import create_app
from datetime import datetime, timedelta
from werkzeug.utils import secure_filename
from flask import render_template, request, redirect, flash, send_from_directory
from celery_tasks import get_number_of_workers, process_annotation
from extensions.sendemail import send_email_complete_annotation, send_email_error_extension, submit_form, send_email_error_size
from database.database import generate_unique_name, config_user, binary_files, binary_image_files, analysis_results

# ======= AMBIENTES =======
UPLOAD_FOLDER = os.path.join(os.environ['HOME'], 'TEs')
RESULTS_FOLDER = os.path.join(UPLOAD_FOLDER, 'www', 'results')
MAX_CONTENT_LENGTH = 30 * 1024 * 1024  # 30 MB

#Extensões que serão permitidas
ALLOWED_EXTENSIONS = {'fasta'}

app, mongo, _, _ = create_app()

#Verifica se a extensão é válida e depois redireciona o usuário para a URL
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def compact_items(origin_items, dest_compact):
    with zipfile.ZipFile(dest_compact, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for item in origin_items:
            if os.path.isdir(item):
                for root, _, files in os.walk(item):
                    for file in files:
                        file_path = os.path.join(root, file)
                        arcname = os.path.relpath(file_path, os.path.dirname(item))
                        zipf.write(file_path, arcname)
            elif os.path.isfile(item):
                arcname = os.path.basename(item)
                zipf.write(item, arcname)

# ======= Routes
@app.route("/")
def index():
    num_workers = get_number_of_workers()
    return render_template("index.html", num_workers=num_workers)

@app.route('/annotation-process', methods=['GET','POST'])
def upload_file():
    if request.method == 'POST':
        if 'email' in request.form:
            email = request.form.get('email')

        #Verificando se a solicitação de postagem tem a parte do arquivo
        if 'file' not in request.files:
            flash('No file part')
            return redirect(request.url)

        file = request.files['file']
        
        if file.filename == '':
            flash('No selected file')
            return redirect(request.url)

        if file and allowed_file(file.filename):
            # Verifica o tamanho do arquivo
            if request.content_length > MAX_CONTENT_LENGTH:
                send_email_error_size(email, file.filename)
                flash('File size exceeds the maximum limit of 30 MB.')
                return redirect(request.url)
            
            #secure_filename() verificar se um inject foi aplicado, se o arquivo conter ../ será alterado para: " " ou "_"
            filename = secure_filename(file.filename)
            filename, extension = os.path.splitext(file.filename)
           
            #-------------- Processo de nomeação dos dados -------------------
            existing_names = [doc["genome-output"] for doc in mongo.db.users.find({}, {"genome-output": 1})]
            new_generated_name = generate_unique_name(filename, existing_names)
        
            storageFolder = f'{new_generated_name}'
            new_filename = f'{new_generated_name}{extension}'

            resultsAddress = os.path.join(RESULTS_FOLDER, storageFolder)
            os.makedirs(resultsAddress)
            file.save(os.path.join(RESULTS_FOLDER, storageFolder, new_filename))

            #------ Configurando o banco de dados ----------
            secret_key = os.urandom(24)
            key_security = secret_key.hex()

            expiration_period = timedelta(hours=72)
            expiration_date = datetime.utcnow() + expiration_period
            
            config_user(mongo, key_security, expiration_date, email, filename, new_generated_name)
           
        else:
            send_email_error_extension(email)

        if 'annotation_type' in request.form:
            annotation_type = int(request.form.get('annotation_type'))
            mail_password = os.environ.get('MAIL_PASSWORD')
            result_process = process_annotation.delay(new_filename, annotation_type, resultsAddress, email, mail_password)              
            try:
                #send_email_checking(email)
                result_process.get()
            except Exception as e:
                print(f"Erro ao aguardar a conclusão da tarefa: {e}")
                
            if annotation_type == 1:
                sine = os.path.join(resultsAddress, 'SINE')
                origin_items = [sine]
                dest_compact = os.path.join(resultsAddress, 'library.zip')
                compact_items(origin_items, dest_compact)

                binary_files(mongo, key_security, expiration_date, resultsAddress)
                send_email_complete_annotation(email, key_security)
                print(f'Anotação dos elementos SINEs armazenada em: {storageFolder}')

            elif annotation_type == 2:
                line = os.path.join(resultsAddress, 'LINE')
                origin_items = [line]
                dest_compact = os.path.join(resultsAddress, 'library.zip')
                compact_items(origin_items, dest_compact)
                
                binary_files(mongo, key_security, expiration_date, resultsAddress)
                send_email_complete_annotation(email, key_security)
                print(f'Anotação dos elementos LINEs armazenada em: {storageFolder}')

            elif annotation_type == 3:
                sine = os.path.join(resultsAddress, 'SINE')
                line = os.path.join(resultsAddress, 'LINE')
                origin_items = [sine, line]
                dest_compact = os.path.join(resultsAddress, 'library.zip')
                compact_items(origin_items, dest_compact)

                binary_files(mongo, key_security, expiration_date, resultsAddress)
                send_email_complete_annotation(email, key_security)
                print(f'Análise armazenada na pasta: {storageFolder}')

            elif annotation_type == 4:
                TEanno_sum = os.path.join(resultsAddress, 'complete-analysis', f'{storageFolder}.fasta.mod.EDTA.TEanno.sum')
                TEanno_gff3 = os.path.join(resultsAddress, 'complete-analysis', f'{storageFolder}.fasta.mod.EDTA.TEanno.gff3')
                intact_gff3 = os.path.join(resultsAddress, 'complete-analysis', f'{storageFolder}.fasta.mod.EDTA.intact.gff3')
                TElib_fa = os.path.join(resultsAddress, 'complete-analysis', f'{storageFolder}.fasta.mod.EDTA.TElib.fa')
                mod_LAI = os.path.join(resultsAddress, 'complete-analysis', f'{storageFolder}.fasta.mod.LAI')
                softmasked = os.path.join(resultsAddress, 'complete-analysis', f'{storageFolder}.fasta.mod-Softmasked.fa')

                helitron = os.path.join(resultsAddress, 'complete-analysis', f'{storageFolder}.fasta.mod.EDTA.raw', 'Helitron')
                ltr = os.path.join(resultsAddress, 'complete-analysis', f'{storageFolder}.fasta.mod.EDTA.raw', 'LTR')
                tir = os.path.join(resultsAddress, 'complete-analysis', f'{storageFolder}.fasta.mod.EDTA.raw', 'TIR')
                line_complete = os.path.join(resultsAddress, 'complete-analysis', f'{storageFolder}.fasta.mod.EDTA.raw', 'LINE')
                sine_complete = os.path.join(resultsAddress, 'complete-analysis', f'{storageFolder}.fasta.mod.EDTA.raw', 'SINE') 

                origin_items = [TEanno_sum, TEanno_gff3, intact_gff3, TElib_fa, mod_LAI, softmasked, tir, line_complete, sine_complete, helitron, ltr]
                dest_compact = os.path.join(resultsAddress, 'library.zip')
                compact_items(origin_items, dest_compact)

                binary_files(mongo, key_security, expiration_date, resultsAddress)
                binary_image_files(mongo, key_security, expiration_date, resultsAddress)
                send_email_complete_annotation(email, key_security)
                print(f'Análise armazenada na pasta: {storageFolder}')

            #if os.path.exists(resultsAddress):
            #    shutil.rmtree(resultsAddress)
            #    print(f"A pasta {resultsAddress} foi excluída com sucesso.")
            #else:
            #    print(f"A pasta {resultsAddress} não existe.")

    return render_template("index.html")

@app.route('/send_email', methods=['POST'])
def send_email():
    return submit_form()

@app.route("/results/<key_security>")
def results_page(key_security):
    return analysis_results(key_security, mongo)

@app.route('/results-example', endpoint='result_example')
def result_example():
    return render_template('results-fixo.html')

@app.route('/A_thaliana', endpoint='A_thaliana')
def genome_page():
    return render_template('/genomes/A_thaliana.html')

# @app.route('/results-fixo.html')
# def results_fixo():
#     return render_template('results-fixo.html')

if __name__ == "__main__":
    app.run(debug=True)
