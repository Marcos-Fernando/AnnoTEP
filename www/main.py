import io
import os
import random
import subprocess
from werkzeug.utils import secure_filename
from flask import Flask, render_template, request, redirect, flash, url_for, send_from_directory, jsonify
from flask_mail import Mail, Message
from flask_pymongo import PyMongo
from extensions.annotation import annotation_elementSINE, annotation_elementLINE, merge_SINE_LINE, create_phylogeny
from extensions.compact import zip_folder, tar_folder

#Definindo local dos arquivos
#ambientes
CONDA = os.environ['CONDA_PREFIX']
UPLOAD_FOLDER = os.path.join(os.environ['HOME'], 'TEs')

#temporárias
TEMPSL_FOLDER = os.path.join(UPLOAD_FOLDER, 'Temp', 'sine-line')
TEMPINPUT_FOLDER = os.path.join(UPLOAD_FOLDER, 'Temp', 'input')
TEMPANNO_FOLDER = os.path.join(UPLOAD_FOLDER, 'Temp', 'annotation')
TEMPCOM_FOLDER = os.path.join(UPLOAD_FOLDER, 'Temp', 'compact')

#processos
SINE_FOLDER = os.path.join(UPLOAD_FOLDER, 'SINE', 'AnnoSINE', 'bin')
NONLTR_FOLDER = os.path.join(UPLOAD_FOLDER, 'non-LTR')
MGESCAN_FOLDER = os.path.join(NONLTR_FOLDER, 'mgescan')
EDTA_FOLDER = os.path.join(UPLOAD_FOLDER, 'EDTA')

#Extensões que serão permitidas
ALLOWED_EXTENSIONS = {'fasta'}

#configurando ambiente flask
app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MONGO_URI'] = "mongodb://localhost:27017/myDatabase"
mongo = PyMongo(app)

#ambiente para envio de email
app.config['MAIL_SERVER'] = 'smtp.googlemail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USE_SSL'] = False
app.config['MAIL_USERNAME'] = 'annoteps@gmail.com'
app.config['MAIL_PASSWORD'] = 'ioqh hqbi frpo yuuq'

mail = Mail(app)

@app.route("/")
def index():
    return render_template("index.html")

def send_email_checking(email):
    msg_title = "Email de verificação"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = "Este é o email de verificação"

    mail.send(msg)

def send_email_complete_annotation(email):
    msg_title = "Anotação completa"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = "Email contendo link de acesso aos resultados"

    mail.send(msg)


#Verifica se a extensão é válida e depois redireciona o usuário para a URL
def allowed_file(filename):
    return '.' in filename and \
            filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/complete-annotation', methods=['GET','POST'])
def upload_file_for_complete_annotation():
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
           
            #-------------- Processo de nomeação dos dados -------------------
            random_numbers = [str(random.randint(0,9)) for i in range(4)]

            filename, extension = os.path.splitext(file.filename)
            new_filename = f'{filename}_{"".join(random_numbers)}{extension}'
            folderSINE =f'{filename[:2]}_{"".join(random_numbers)}'
            seedSINE =f'{filename}_{"".join(random_numbers)}-Seed_SINE.fa'
            folderLINE = f'{folderSINE}-LINE'
            resultsLINE = f'{folderLINE}-results'
            libLINE = f'{folderSINE}-LINE-lib.fa'
            folderEDTA = f'Anno-{folderSINE}'
            file.save(os.path.join(app.config['UPLOAD_FOLDER'],'Temp', 'input', new_filename))

            #Adiconado pasta de armazenamento temporário para receber os seedSINE e libLINE
            tempsl_folder = os.path.join(TEMPSL_FOLDER, folderSINE)
            os.makedirs(tempsl_folder)

            #----------- Funções chamando os comandos do pipeline ------------------
            #Registro de erro
            e = "Dados não fornecidos ou não disponíveis"

            try:
                annotation_elementSINE(new_filename, folderSINE, seedSINE)
                annotation_elementLINE(new_filename, folderSINE, folderLINE, resultsLINE, libLINE)
                merge_SINE_LINE(new_filename, folderLINE, folderSINE, seedSINE, folderEDTA, libLINE)
                create_phylogeny(new_filename, folderEDTA)
            except subprocess.CalledProcessError as e:
                flash(f'Annotation failed with error: {e}')
                return redirect(request.url)

            #Informando as pastas criadas
            print("Pasta criada para armazenamento dos dados SINE: ", folderSINE)
            print("Pasta criada para armazenamento dos dados LINE: ", folderLINE)
            print("Pasta criada para armazenamento de anotações: ", folderEDTA)
            print("")


            #------------------ Compactando os dados SINE e LINE ----------------
            #Adiconado pasta de armazenamento temporário para receber os dados compactados
            #folderSINE = 'A._2639'
            
            tempcom_folder = os.path.join(TEMPCOM_FOLDER, folderSINE)
            os.makedirs(tempcom_folder)

            origin_folderSINE = os.path.join(SINE_FOLDER, 'temp', folderSINE)
            dest_zipSINE = os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-SINE')
            zip_folder(origin_folderSINE, dest_zipSINE)
            tar_folder(origin_folderSINE, dest_zipSINE)

            origin_folderLINE = os.path.join(NONLTR_FOLDER, 'temp', resultsLINE)
            dest_zipLINE = os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-LINE')
            zip_folder(origin_folderLINE, dest_zipLINE)
            tar_folder(origin_folderLINE, dest_zipLINE)

            #Tranformando os arquivos em binário, aqui utilizo open com modo "rb" (read binary)
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-SINE.zip'), "rb") as zip_fileSINE:
                zip_dataSINE = zip_fileSINE.read()
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-SINE.tar.gz'), "rb") as tar_fileSINE:
                tar_dataSINE = tar_fileSINE.read()
            
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-LINE.zip'), "rb") as zip_fileLINE:
                zip_dataLINE = zip_fileLINE.read()
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-LINE.tar.gz'), "rb") as tar_fileLINE:
                tar_dataLINE = tar_fileLINE.read()
        
            # Leitura de arquivo TREE SVG
            with open(os.path.join(TEMPANNO_FOLDER, folderEDTA, 'TREE', 'LTR_RT-Tree1.svg'), "rb") as file_tree1:
                svg_tree1 = file_tree1.read()
            with open(os.path.join(TEMPANNO_FOLDER, folderEDTA, 'TREE', 'LTR_RT-Tree1.svg'), "rb") as file_tree2:
                svg_tree2 = file_tree2.read()

            #--------------------Trabalhando com BD -----------------------------
            #Criando uma chave para o usuário busca dados
            secret_key = os.urandom(24)
            # Converta a chave em uma string hexadecimal
            key_security = secret_key.hex()

            #banco de dados mongodb
            mongo.db.users.insert_one({
                "key": key_security,
                "genome-name": filename,
                "email": email,
                "data": folderSINE,
                "anno-data": folderEDTA
            })

            mongo.db.zipSINE.insert_one({
                 "key": key_security,
                 "email": email,
                 "zip-sine-name": (f'{folderSINE}-SINE.zip'),
                 "zip-sine-file": zip_dataSINE
            })

            mongo.db.tarSINE.insert_one({
                 "key": key_security,
                 "email": email,
                 "tar-sine-name": (f'{folderSINE}-SINE.tar.gz'),
                 "tar-sine-file": tar_dataSINE
            })

            mongo.db.zipLINE.insert_one({
                 "key": key_security,
                 "email": email,
                 "zip-line-name": (f'{folderSINE}-LINE.zip'),
                 "zip-line-file": zip_dataLINE
            })

            mongo.db.tarLINE.insert_one({
                 "key": key_security,
                 "email": email,
                 "tar-line-name": (f'{folderSINE}-LINE.tar.gz'),
                 "tar-line-file": tar_dataLINE
            })

            mongo.db.files.insert_one({
                 "key": key_security,
                 "email": email,
                 "file-Tree-1": svg_tree1,
                 "file-Tree-2": svg_tree2
            })

            send_email_complete_annotation(email)
            return render_template("index.html")        
    return render_template("index.html")


@app.route('/sine-annotation', methods=['GET','POST'])
def upload_file_for_sine_annotation():
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
           
            #-------------- Processo de nomeação dos dados -------------------
            random_numbers = [str(random.randint(0,9)) for i in range(4)]

            filename, extension = os.path.splitext(file.filename)
            new_filename = f'{filename}_{"".join(random_numbers)}{extension}'
            folderSINE =f'{filename[:2]}_{"".join(random_numbers)}'
            seedSINE =f'{filename}_{"".join(random_numbers)}-Seed_SINE.fa'
            file.save(os.path.join(app.config['UPLOAD_FOLDER'],'Temp', 'input', new_filename))

            #Adiconado pasta de armazenamento temporário para receber os seedSINE e libLINE
            tempsl_folder = os.path.join(TEMPSL_FOLDER, folderSINE)
            os.makedirs(tempsl_folder)

            #----------- Funções chamando os comandos do pipeline ------------------
            #Registro de erro
            e = "Dados não fornecidos ou não disponíveis"

            try:
                annotation_elementSINE(new_filename, folderSINE, seedSINE)
            except subprocess.CalledProcessError as e:
                flash(f'Annotation failed with error: {e}')
                return redirect(request.url)

            #Informando as pastas criadas
            print("Pasta criada para armazenamento dos dados SINE: ", folderSINE)
            print("")


            #------------------ Compactando os dados SINE e LINE ----------------
            #Adiconado pasta de armazenamento temporário para receber os dados compactados
            
            tempcom_folder = os.path.join(TEMPCOM_FOLDER, folderSINE)
            os.chdir(TEMPCOM_FOLDER)

            origin_folderSINE = os.path.join(SINE_FOLDER, 'temp', folderSINE)
            dest_zipSINE = os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-SINE')

            zip_folder(origin_folderSINE, dest_zipSINE)
            tar_folder(origin_folderSINE, dest_zipSINE)

            #Tranformando os arquivos em binário, aqui utilizo open com modo "rb" (read binary)
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-SINE.zip'), "rb") as zip_fileSINE:
                zip_dataSINE = zip_fileSINE.read()
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-SINE.tar.gz'), "rb") as tar_fileSINE:
                tar_dataSINE = tar_fileSINE.read()

            #--------------------Trabalhando com BD -----------------------------
            #Criando uma chave para o usuário busca dados
            secret_key = os.urandom(24)
            # Converta a chave em uma string hexadecimal
            key_security = secret_key.hex()

            #banco de dados mongodb
            mongo.db.users.insert_one({
                "key": key_security,
                "genome-name": filename,
                "email": email,
                "data": folderSINE,
                "anno-data": 'null'
            })

            mongo.db.zipSINE.insert_one({
                 "key": key_security,
                 "email": email,
                 "zip-sine-name": (f'{folderSINE}-SINE.zip'),
                 "zip-sine-file": zip_dataSINE
            })

            mongo.db.tarSINE.insert_one({
                 "key": key_security,
                 "email": email,
                 "tar-sine-name": (f'{folderSINE}-SINE.tar.gz'),
                 "tar-sine-file": tar_dataSINE
            })

            send_email_complete_annotation(email)
            return render_template("index.html")        
    return render_template("index.html")

@app.route('/line-annotation', methods=['GET','POST'])
def upload_file_for_line_annotation():
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
           
            #-------------- Processo de nomeação dos dados -------------------
            random_numbers = [str(random.randint(0,9)) for i in range(4)]

            filename, extension = os.path.splitext(file.filename)
            new_filename = f'{filename}_{"".join(random_numbers)}{extension}'
            folderSINE =f'{filename[:2]}_{"".join(random_numbers)}'
            folderLINE = f'{folderSINE}-LINE'
            resultsLINE = f'{folderLINE}-results'
            libLINE = f'{folderSINE}-LINE-lib.fa'
            file.save(os.path.join(app.config['UPLOAD_FOLDER'],'Temp', 'input', new_filename))

            #Adiconado pasta de armazenamento temporário para receber os seedSINE e libLINE
            tempsl_folder = os.path.join(TEMPSL_FOLDER, folderSINE)
            os.makedirs(tempsl_folder)

            #----------- Funções chamando os comandos do pipeline ------------------
            #Registro de erro
            e = "Dados não fornecidos ou não disponíveis"

            try:
                annotation_elementLINE(new_filename, folderSINE, folderLINE, resultsLINE, libLINE)
            except subprocess.CalledProcessError as e:
                flash(f'Annotation failed with error: {e}')
                return redirect(request.url)

            #Informando as pastas criadas
            print("Pasta criada para armazenamento dos dados LINE: ", folderLINE)
            print("")


            #------------------ Compactando os dados SINE e LINE ----------------
            #Adiconado pasta de armazenamento temporário para receber os dados compactados
            
            tempcom_folder = os.path.join(TEMPCOM_FOLDER, folderSINE)
            os.makedirs(tempcom_folder)

            origin_folderLINE = os.path.join(NONLTR_FOLDER, 'temp', resultsLINE)
            dest_zipLINE = os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-LINE')
            zip_folder(origin_folderLINE, dest_zipLINE)
            tar_folder(origin_folderLINE, dest_zipLINE)

            #Tranformando os arquivos em binário, aqui utilizo open com modo "rb" (read binary)
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-LINE.zip'), "rb") as zip_fileLINE:
                zip_dataLINE = zip_fileLINE.read()
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-LINE.tar.gz'), "rb") as tar_fileLINE:
                tar_dataLINE = tar_fileLINE.read()

            #--------------------Trabalhando com BD -----------------------------
            #Criando uma chave para o usuário busca dados
            secret_key = os.urandom(24)
            # Converta a chave em uma string hexadecimal
            key_security = secret_key.hex()

            #banco de dados mongodb
            mongo.db.users.insert_one({
                "key": key_security,
                "genome-name": filename,
                "email": email,
                "data": folderSINE,
                "anno-data": 'null'
            })

            mongo.db.zipLINE.insert_one({
                 "key": key_security,
                 "email": email,
                 "zip-line-name": (f'{folderSINE}-LINE.zip'),
                 "zip-line-file": zip_dataLINE
            })

            mongo.db.tarLINE.insert_one({
                 "key": key_security,
                 "email": email,
                 "tar-line-name": (f'{folderSINE}-LINE.tar.gz'),
                 "tar-line-file": tar_dataLINE
            })

            send_email_complete_annotation(email)
            return render_template("index.html")        
    return render_template("index.html")

@app.route('/sineline-annotation', methods=['GET','POST'])
def upload_file_for_sineline_annotation():
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
           
            #-------------- Processo de nomeação dos dados -------------------
            random_numbers = [str(random.randint(0,9)) for i in range(4)]

            filename, extension = os.path.splitext(file.filename)
            new_filename = f'{filename}_{"".join(random_numbers)}{extension}'
            folderSINE =f'{filename[:2]}_{"".join(random_numbers)}'
            seedSINE =f'{filename}_{"".join(random_numbers)}-Seed_SINE.fa'
            folderLINE = f'{folderSINE}-LINE'
            resultsLINE = f'{folderLINE}-results'
            libLINE = f'{folderSINE}-LINE-lib.fa'
            file.save(os.path.join(app.config['UPLOAD_FOLDER'],'Temp', 'input', new_filename))

            #Adiconado pasta de armazenamento temporário para receber os seedSINE e libLINE
            tempsl_folder = os.path.join(TEMPSL_FOLDER, folderSINE)
            os.makedirs(tempsl_folder)

            #----------- Funções chamando os comandos do pipeline ------------------
            #Registro de erro
            e = "Dados não fornecidos ou não disponíveis"

            try:
                annotation_elementSINE(new_filename, folderSINE, seedSINE)
                annotation_elementLINE(new_filename, folderSINE, folderLINE, resultsLINE, libLINE)
            except subprocess.CalledProcessError as e:
                flash(f'Annotation failed with error: {e}')
                return redirect(request.url)

            #Informando as pastas criadas
            print("Pasta criada para armazenamento dos dados SINE: ", folderSINE)
            print("Pasta criada para armazenamento dos dados LINE: ", folderLINE)
            print("")


            #------------------ Compactando os dados SINE e LINE ----------------
            #Adiconado pasta de armazenamento temporário para receber os dados compactados
            #folderSINE = 'A._2639'
            
            tempcom_folder = os.path.join(TEMPCOM_FOLDER, folderSINE)
            os.makedirs(tempcom_folder)

            origin_folderSINE = os.path.join(SINE_FOLDER, 'temp', folderSINE)
            dest_zipSINE = os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-SINE')
            zip_folder(origin_folderSINE, dest_zipSINE)
            tar_folder(origin_folderSINE, dest_zipSINE)

            origin_folderLINE = os.path.join(NONLTR_FOLDER, 'temp', resultsLINE)
            dest_zipLINE = os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-LINE')
            zip_folder(origin_folderLINE, dest_zipLINE)
            tar_folder(origin_folderLINE, dest_zipLINE)

            #Tranformando os arquivos em binário, aqui utilizo open com modo "rb" (read binary)
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-SINE.zip'), "rb") as zip_fileSINE:
                zip_dataSINE = zip_fileSINE.read()
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-SINE.tar.gz'), "rb") as tar_fileSINE:
                tar_dataSINE = tar_fileSINE.read()
            
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-LINE.zip'), "rb") as zip_fileLINE:
                zip_dataLINE = zip_fileLINE.read()
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}-LINE.tar.gz'), "rb") as tar_fileLINE:
                tar_dataLINE = tar_fileLINE.read()

            #--------------------Trabalhando com BD -----------------------------
            #Criando uma chave para o usuário busca dados
            secret_key = os.urandom(24)
            # Converta a chave em uma string hexadecimal
            key_security = secret_key.hex()

            #banco de dados mongodb
            mongo.db.users.insert_one({
                "key": key_security,
                "genome-name": filename,
                "email": email,
                "data": folderSINE,
                "anno-data": 'null'
            })

            mongo.db.zipSINE.insert_one({
                 "key": key_security,
                 "email": email,
                 "zip-sine-name": (f'{folderSINE}-SINE.zip'),
                 "zip-sine-file": zip_dataSINE
            })

            mongo.db.tarSINE.insert_one({
                 "key": key_security,
                 "email": email,
                 "tar-sine-name": (f'{folderSINE}-SINE.tar.gz'),
                 "tar-sine-file": tar_dataSINE
            })

            mongo.db.zipLINE.insert_one({
                 "key": key_security,
                 "email": email,
                 "zip-line-name": (f'{folderSINE}-LINE.zip'),
                 "zip-line-file": zip_dataLINE
            })

            mongo.db.tarLINE.insert_one({
                 "key": key_security,
                 "email": email,
                 "tar-line-name": (f'{folderSINE}-LINE.tar.gz'),
                 "tar-line-file": tar_dataLINE
            })

            send_email_complete_annotation(email)
            return render_template("index.html")        
    return render_template("index.html")


@app.route("/results")
def results():
    return "results"

if __name__ == "__main__":
    app.run(debug=True)
