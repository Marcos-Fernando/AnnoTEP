import os
import random
import subprocess

from werkzeug.utils import secure_filename
from flask import Flask, render_template, request, redirect, flash, Response
from flask_mail import Mail, Message
from extensions.annotation import sine_annotation, line_annotation, complete_annotation

#Definindo local dos arquivos
#ambientes
CONDA = os.environ['CONDA_PREFIX']
UPLOAD_FOLDER = os.path.join(os.environ['HOME'], 'TEs')

#processos
SINE_FOLDER = os.path.join(UPLOAD_FOLDER, 'SINE', 'AnnoSINE', 'bin')
NONLTR_FOLDER = os.path.join(UPLOAD_FOLDER, 'non-LTR')
MGESCAN_FOLDER = os.path.join(NONLTR_FOLDER, 'mgescan')
EDTA_FOLDER = os.path.join(UPLOAD_FOLDER, 'EDTA')

LOCAL_FOLDER = os.path.join(UPLOAD_FOLDER, 'desktop')
RESULTS_FOLDER = os.path.join(LOCAL_FOLDER, 'results')

#Extensões que serão permitidas
ALLOWED_EXTENSIONS = {'fasta'}

#configurando ambiente flask
app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

#ambiente para envio de email
app.config['MAIL_SERVER'] = os.environ.get('MAIL_SERVER')
app.config['MAIL_PORT'] = int(os.environ.get('MAIL_PORT'))
app.config['MAIL_USERNAME'] = os.environ.get('MAIL_USERNAME')
app.config['MAIL_PASSWORD'] = os.environ.get('MAIL_PASSWORD')
app.config['MAIL_USE_TLS'] = os.environ.get('MAIL_USE_TLS') == 'True'
app.config['MAIL_USE_SSL'] = os.environ.get('MAIL_USE_SSL') == 'True'
mail = Mail(app)

@app.route("/")
def index():
    return render_template("index.html")

def send_email_checking(email):
    msg_title = "Email de verificação"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = "Obrigado por escolher a AnnoTEP, a sua ferramenta confiável para anotar elementos transponíveis em genomas de plantas. Estamos empolgados por fazer parte da sua jornada de pesquisa! Lembre-se de mencionar nosso trabalho em suas pesquisas para ajudar a promover o avanço da nossa pesquisa. Se tiver alguma dúvida ou precisar de assistência, não hesite em entrar em contato conosco. Boa sorte em seus estudos!"

    mail.send(msg)

def send_email_complete_annotation(email):
    msg_title = "Anotação completa"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = f"Sua anotação foi concluída! Para visualizar acesse a pasta 'results'. Esperamos que essas informações sejam úteis em sua pesquisa"

    mail.send(msg)


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
            random_numbers = [str(random.randint(0,9)) for i in range(4)]
            storageFolder = f'results-{filename}_{"".join(random_numbers)}'

            resultsAddress = os.path.join(RESULTS_FOLDER, storageFolder)
            os.makedirs(resultsAddress)

            new_filename = f'{filename}{extension}'
            file.save(os.path.join(RESULTS_FOLDER, storageFolder, new_filename))

        if 'annotation_type' in request.form:
                annotation_type = int(request.form.get('annotation_type'))
                if annotation_type == 1:
                    sine_annotation(new_filename, resultsAddress)
                    send_email_complete_annotation(email)
                elif annotation_type == 2:
                    line_annotation(new_filename, resultsAddress)
                    send_email_complete_annotation(email)
                elif annotation_type == 3:
                    sine_annotation(new_filename, resultsAddress)
                    line_annotation(new_filename, resultsAddress)
                    send_email_complete_annotation(email)
                elif annotation_type == 4:
                    sine_annotation(new_filename, resultsAddress)
                    line_annotation(new_filename, resultsAddress)
                    complete_annotation(new_filename, resultsAddress)
                    send_email_complete_annotation(email)

    return render_template("index.html")

@app.route('/result_example')
def result_example():
    # Adicione lógica para processar o resultado aqui
    return render_template('result_example.html')

if __name__ == "__main__":
    app.run(debug=True)
