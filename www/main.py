import os

from datetime import datetime, timedelta
import shutil
from werkzeug.utils import secure_filename
from flask import render_template, request, redirect, flash, session
from app import create_app
from database.database import generate_unique_name, config_user, binary_SINEs_files, binary_LINEs_files, binary_image_files, analysis_results
from celery_tasks import get_number_of_workers, process_annotation
from extensions.sendemail import send_email_complete_annotation, send_email_checking, send_email_error_extension, send_email_error_annotation, submit_form

# ======= AMBIENTES =======
UPLOAD_FOLDER = os.path.join(os.environ['HOME'], 'TEs')
LOCAL_FOLDER = os.path.join(UPLOAD_FOLDER, 'www')
RESULTS_FOLDER = os.path.join(LOCAL_FOLDER, 'results')

#Extensões que serão permitidas
ALLOWED_EXTENSIONS = {'fasta'}

app, mongo, _, _ = create_app()

@app.route("/")
def index():
    num_workers = get_number_of_workers()
    return render_template("index.html", num_workers=num_workers)

#Verifica se a extensão é válida e depois redireciona o usuário para a URL
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

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
            #secure_filename() verificar se um inject foi aplicado, se o arquivo conter ../ será alterado para: " " ou "_"
            filename = secure_filename(file.filename)
            filename, extension = os.path.splitext(file.filename)
           
            #-------------- Processo de nomeação dos dados -------------------
            existing_names = [doc["genome-output"] for doc in mongo.db.users.find({}, {"genome-output": 1})]
            new_generated_name = generate_unique_name(filename, existing_names)
        
            storageFolder = f'results-{new_generated_name}'
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
                binary_SINEs_files(mongo, key_security, expiration_date, resultsAddress)
                send_email_complete_annotation(email, key_security)
                print(f'Análise armazenada na pasta: {storageFolder}')
            elif annotation_type == 2:
                binary_LINEs_files(mongo, key_security, expiration_date, resultsAddress)
                send_email_complete_annotation(email, key_security)
                print(f'Análise armazenada na pasta: {storageFolder}')
            elif annotation_type == 3:
                binary_SINEs_files(mongo, key_security, expiration_date, resultsAddress)
                binary_LINEs_files(mongo, key_security, expiration_date, resultsAddress)
                send_email_complete_annotation(email, key_security)
                print(f'Análise armazenada na pasta: {storageFolder}')
            elif annotation_type == 4:
                binary_SINEs_files(mongo, key_security, expiration_date, resultsAddress)
                binary_LINEs_files(mongo, key_security, expiration_date, resultsAddress)
                binary_image_files(mongo, key_security, expiration_date, resultsAddress)
                send_email_complete_annotation(email, key_security)
                print(f'Análise armazenada na pasta: {storageFolder}')

            if os.path.exists(resultsAddress):
                shutil.rmtree(resultsAddress)
                print(f"A pasta {resultsAddress} foi excluída com sucesso.")
            else:
                print(f"A pasta {resultsAddress} não existe.")

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

# @app.route('/results-fixo.html')
# def results_fixo():
#     return render_template('results-fixo.html')

if __name__ == "__main__":
    app.run(debug=True)
