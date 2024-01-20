import os
import random

from datetime import datetime, timedelta
from werkzeug.utils import secure_filename
from flask import render_template, request, redirect, flash
from flask_mail import Message
from app import create_app
from database.database import config_user, binary_SINEs_files, binary_LINEs_files, binary_image_files, analysis_results
from celery_tasks import process_annotation


#Definindo local dos arquivos
#ambientes
CONDA = os.environ['CONDA_PREFIX']
UPLOAD_FOLDER = os.path.join(os.environ['HOME'], 'TEs')

#processos
SINE_FOLDER = os.path.join(UPLOAD_FOLDER, 'SINE', 'AnnoSINE', 'bin')
NONLTR_FOLDER = os.path.join(UPLOAD_FOLDER, 'non-LTR')
MGESCAN_FOLDER = os.path.join(NONLTR_FOLDER, 'mgescan')
EDTA_FOLDER = os.path.join(UPLOAD_FOLDER, 'EDTA')

LOCAL_FOLDER = os.path.join(UPLOAD_FOLDER, 'www')
RESULTS_FOLDER = os.path.join(LOCAL_FOLDER, 'results')

#Extensões que serão permitidas
ALLOWED_EXTENSIONS = {'fasta'}

app, mongo, mail, celery = create_app()


@app.route("/")
def index():
    return render_template("index.html")

def send_email_checking(email):
    msg_title = "Email de verificação"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = "Obrigado por escolher a AnnoTEP, a sua ferramenta confiável para anotar elementos transponíveis em genomas de plantas. Estamos empolgados por fazer parte da sua jornada de pesquisa! Lembre-se de mencionar nosso trabalho em suas pesquisas para ajudar a promover o avanço da nossa pesquisa. Se tiver alguma dúvida ou precisar de assistência, não hesite em entrar em contato conosco. Boa sorte em seus estudos!"

    mail.send(msg)

def send_email_complete_annotation(email, key_security):
    msg_title = "Anotação completa"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    result_url = f'http://127.0.0.1:5000/results/{key_security}'
    msg.body = f"Sua anotação foi concluída! Para visualizar os dados obtidos clique no link: {result_url} . Esperamos que essas informações sejam úteis em sua pesquisa"

    mail.send(msg)


def generate_unique_name(filename, existing_names):
    while True:
        random_numbers = [str(random.randint(0,9)) for i in range(4)]
        generated_name = f'{filename[:2]}_{"".join(random_numbers)}'

        #Verificando no bd
        if generated_name not in existing_names:
            return generated_name

#Verifica se a extensão é válida e depois redireciona o usuário para a URL
def allowed_file(filename):
    return '.' in filename and \
            filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/annotation-process', methods=['GET','POST'])
def upload_file():
    if request.method == 'POST':
        if 'email' in request.form:
            email = request.form.get('email')
            send_email_checking(email)

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
            #------------------------------------------------
 
        if 'annotation_type' in request.form:
                annotation_type = int(request.form.get('annotation_type'))
                result_process = process_annotation.delay(new_filename, annotation_type, resultsAddress)              
                try:
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

    return render_template("index.html")


@app.route("/results/<key_security>")
def results_page(key_security):
    return analysis_results(key_security, mongo)

@app.route('/results-example', endpoint='result_example')
def result_example():
    return render_template('results-fixo.html')

if __name__ == "__main__":
    app.run(debug=True)
