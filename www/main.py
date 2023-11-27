import io
import os
import random
import subprocess
import csv
import base64

from gridfs import GridFS
from bson import ObjectId
from datetime import datetime, timedelta
from werkzeug.utils import secure_filename
from flask import Flask, render_template, request, redirect, flash, Response
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


#"mongodb://localhost:27017/annotepdb"
#"mongodb+srv://marcoscosta:xMhvCuaHWyuwoPy5@cluster-tep.qznvfsw.mongodb.net/annotepdb?retryWrites=true"

#configurando ambiente flask
app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MONGO_URI'] = "mongodb://localhost:27017/annotepdb"
#mongo = MongoClient(app.config['MONGO_URI'])
mongo = PyMongo(app)


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

def send_email_complete_annotation(email, key_security):
    msg_title = "Anotação completa"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    result_url = f'http://127.0.0.1:5000/results/{key_security}'
    msg.body = f"Sua anotação foi concluída! Para visualizar os dados obtidos clique no link: {result_url} . Esperamos que essas informações sejam úteis em sua pesquisa"

    mail.send(msg)

#Verificando se o nome/arquivo já existe no bd
def generate_unique_name(filename, existing_names):
    while True:
        random_numbers = [str(random.randint(0,9)) for i in range(4)]
        new_file_name = f'{filename[:2]}_{"".join(random_numbers)}'

        #Verificando no bd
        if new_file_name not in existing_names:
            return new_file_name

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
            filename, extension = os.path.splitext(file.filename)
           
            #-------------- Processo de nomeação dos dados -------------------
            existing_names = [doc["genome-output"] for doc in mongo.db.users.find({}, {"genome-output": 1})]
            generate_new_name = generate_unique_name(filename, existing_names)
            new_name = generate_new_name

            new_filename = f'{new_name}{extension}'
            folderSINE =f'{new_name}-SINE'
            seedSINE =f'{new_name}-Seed_SINE.fa'
            folderLINE = f'{new_name}-LINE'
            resultsLINE = f'{folderLINE}-results'
            libLINE = f'{new_name}-LINE-lib.fa'
            folderEDTA = f'Anno-{new_name}'
            file.save(os.path.join(app.config['UPLOAD_FOLDER'],'Temp', 'input', new_filename))

            # ---- Criando pasta temporária para receber os seedSINE e libLINE ---
            tempsl_folder = os.path.join(TEMPSL_FOLDER, new_name)
            os.makedirs(tempsl_folder)
            
            # ---- Criando pasta para armazena dados SINEs / LINEs compactados -----
            tempcom_folder = os.path.join(TEMPCOM_FOLDER, folderSINE)
            os.makedirs(tempcom_folder)

            #----------- Funções chamando os comandos do pipeline ------------------
            #Registro de erro
            e = "Dados não fornecidos ou não disponíveis"

            # ----- CONFIGURANDO DADOS PARA O BANCO DE DADOS --------
            ## --- Chave do usuário em formato hexadecimal ---
            secret_key = os.urandom(24)
            key_security = secret_key.hex()

            ## --- Definindo o período de expiração dos arquivos aramazenados ---
            expiration_period = timedelta(hours=72)
            expiration_date = datetime.utcnow() + expiration_period

            ### ---- Banco de dados mongodb, users dados ----
            print("Enviando dados do usuário para o banco de dados... ")
            mongo.db.users.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.users.insert_one({
                "key": key_security,
                "email": email,
                "genome-input": filename,
                "genome-output": new_name,
                "expiration-date": expiration_date
            })

            print("Dados registrados")
            print("")


            # -------------- Trabalhando com SINEs e LINEs  ------------------------
            try:
                annotation_elementSINE(new_filename, folderSINE, new_name, seedSINE)
                annotation_elementLINE(new_filename, new_name, folderLINE, resultsLINE, libLINE)
            except subprocess.CalledProcessError as e:
                flash(f'Annotation SINEs OR LINEs failed with error: {e}')
                return redirect(request.url)

            #------------------ Compactando os dados SINE e LINE ----------------
            # --- Dados SINEs  ----
            print("Processo de compactação SINE iniciado...")

            origin_folderSINE = os.path.join(SINE_FOLDER, 'temp', folderSINE)
            dest_zipSINE = os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-SINE')
            zip_folder(origin_folderSINE, dest_zipSINE)
            tar_folder(origin_folderSINE, dest_zipSINE)

            print("SINE compactado!")
            print("")

             # --- Dados LINEs  ----
            print("Processo de compactação LINE iniciado...")

            origin_folderLINE = os.path.join(NONLTR_FOLDER, 'temp', resultsLINE)
            dest_zipLINE = os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-LINE')
            zip_folder(origin_folderLINE, dest_zipLINE)
            tar_folder(origin_folderLINE, dest_zipLINE)

            print("LINE compactado!")
            print("")

            gridfs_zipsine = GridFS(mongo.db, collection='zipsine')
            gridfs_tarsine = GridFS(mongo.db, collection='tarsine')
            gridfs_zipline = GridFS(mongo.db, collection='zipline')
            gridfs_tarline = GridFS(mongo.db, collection='tarline')

            #Tranformando os arquivos em binário, aqui utilizo open com modo "rb" (read binary)
            print("Conversão de arquivos compactos em binário iniciada...")
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-SINE.zip'), "rb") as zip_fileSINE:
                zip_dataSINE = gridfs_zipsine.put(zip_fileSINE, filename=f'{new_name}-SINE.zip')
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-SINE.tar.gz'), "rb") as tar_fileSINE:
                tar_dataSINE = gridfs_tarsine.put(tar_fileSINE, filename=f'{new_name}-SINE.tar.gz')

            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-LINE.zip'), "rb") as zip_fileLINE:
                zip_dataLINE = gridfs_zipline.put(zip_fileLINE,filename=f'{new_name}-LINE.zip')
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-LINE.tar.gz'), "rb") as tar_fileLINE:
                tar_dataLINE = gridfs_tarline.put(tar_fileLINE,filename=f'{new_name}-LINE.tar.gz')
            print("Conversão concluída!")
            print("")

            # ----------------- BANCO DE DADOS ---------------
            ## --- Armazenando os arquivos SINE e LINE compactados ---
            print("Enviando binários para o banco de dados")
            mongo.db.zipsine_metadata.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.zipsine_metadata.insert_one({
                "key": key_security,
                "sine-data": folderSINE,
                "zip-sine-name": (f'{new_name}-SINE.zip'),
                "zip-sine-file": zip_dataSINE,
                "expiration-date": expiration_date
            })


            mongo.db.tarsine_metadata.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.tarsine_metadata.insert_one({
                "key": key_security,
                "sine-data": folderSINE,
                "tar-sine-name": (f'{new_name}-SINE.tar.gz'),
                "tar-sine-file": tar_dataSINE,
                "expiration-date": expiration_date
            })

            mongo.db.zipline_metadata.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.zipline_metadata.insert_one({
                "key": key_security,
                "line-data": folderLINE,
                "zip-line-name": (f'{new_name}-LINE.zip'),
                "zip-line-file": zip_dataLINE,
                "expiration-date": expiration_date
            })

            mongo.db.tarline_metadata.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.tarline_metadata.insert_one({
                "key": key_security,
                "line-data": folderLINE,
                "tar-line-name": (f'{new_name}-LINE.tar.gz'),
                "tar-line-file": tar_dataLINE,
                "expiration-date": expiration_date
            })

            print("Dados registrados")
            print("")

            # ----- Mesclando SINE e LINE e criando arvores filogeticas --------
            try:
                merge_SINE_LINE(new_filename, new_name, seedSINE, folderEDTA, libLINE)
                create_phylogeny(new_filename, folderEDTA)
            except subprocess.CalledProcessError as e:
                flash(f'Annotation EDTA failed with error: {e}')
                return redirect(request.url)

            ## ----------------- Leitura de arquivo TREE SVG ---------------
            print("Convertendo imagens TREE em binários...")
            with open(os.path.join(TEMPANNO_FOLDER, folderEDTA, 'TREE', 'LTR_RT-Tree1.svg'), "rb") as file_tree1:
                svg_tree1 = file_tree1.read()
            with open(os.path.join(TEMPANNO_FOLDER, folderEDTA, 'TREE', 'LTR_RT-Tree2.svg'), "rb") as file_tree2:
                svg_tree2 = file_tree2.read()
            
            print("Convertendo imagens LTR-AGE em binários...")
            ## ----------------- Leitura dos arquivos referente a idade dos LTRs (LTR-AGE) ---------------
            with open(os.path.join(TEMPANNO_FOLDER, folderEDTA, 'LTR-AGE', 'AGE-Copia.svg'), "rb") as file_copia:
                svg_copia = file_copia.read()
            with open(os.path.join(TEMPANNO_FOLDER, folderEDTA, 'LTR-AGE', 'AGE-Gypsy.svg'), "rb") as file_gypsy:
                svg_gypsy = file_gypsy.read()

            print("Convertendo imagens LandScape em binários...")
            ## ---------------- Leitura do arquivo RLandScape -------------------------
            with open(os.path.join(TEMPANNO_FOLDER, folderEDTA, 'RLandScape.svg'), "rb") as file_landscape:
                svg_landscape = file_landscape.read()

            print("Convertendo planilha Report-Complete em binários...")
            ## ---------------- Leitura da lista de dados completos em formato csv ----------------------
            with open(os.path.join(TEMPANNO_FOLDER, folderEDTA, 'TEs-Report-Complete.csv'), 'rb') as csv_file:
                binary_data = csv_file.read()

            print("Conervsões finalizadas!")
            print("")

            #--------------------Trabalhando com BD -----------------------------
            # ---- Dados CSV -----
            print("Enviando dados csv para o banco de dados")
            mongo.db.report.create_index("expiration-date", expireAfterSeconds=259200)
            with open(os.path.join(TEMPANNO_FOLDER, folderEDTA, 'TEs-Report-Complete.csv'), 'r') as csv_file:
                csv_reader = csv.DictReader(csv_file)
                for row in csv_reader:
                    document = {
                        "key": key_security,
                        "Name": row['Name'],
                        "Number of Elements": int(row['Number of Elements']),
                        "Length": int(row['Length']),
                        "Percentage": row['Percentage'],
                        "expiration-date": expiration_date
                    }

                    mongo.db.report.insert_one(document)

            mongo.db.csv.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.csv.insert_one({
                "key": key_security,
                "anno-data": folderEDTA,
                "file-csv": binary_data,
                "expiration-date": expiration_date
            })

            print("Dados registrados")

            ### ---- Dados LTR AGEs ----
            print("Enviando dados LTR-AGEs para o banco de dados")
            mongo.db.family.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.family.insert_one({
                "key": key_security,
                "anno-data": folderEDTA,
                "file-age-copia": svg_copia,
                "file-age-gypsy": svg_gypsy,
                "expiration-date": expiration_date
            })

            print("Dados registrados")

            ### --- Dados Landscape ---
            print("Enviando dados landscape para o banco de dados")
            mongo.db.landscape.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.landscape.insert_one({
                "key": key_security,
                "anno-data": folderEDTA,
                "file-landscape": svg_landscape,
                "expiration-date": expiration_date
            })
            
            print("Dados registrados")

            ### --- Dados das árvores filogenéticas ---
            print("Enviando dados TREE para o banco de dados")
            mongo.db.fileTree.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.fileTree.insert_one({
                 "key": key_security,
                 "anno-data": folderEDTA,
                 "file-Tree-1": svg_tree1,
                 "file-Tree-2": svg_tree2,
                 "expiration-date": expiration_date
            })

            print("Dados registrados")
            print("")

            send_email_complete_annotation(email, key_security)
            print("Dados enviados para: ", email)
            print("")

            #------ Informando as pastas criadas -------
            print("Pasta SINE: ", folderSINE)
            print("Pasta LINE: ", folderLINE)
            print("Pasta de Mesclagem: ", folderEDTA)
            print("Operação de anotação completa finalizada")
            print("")

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
            filename, extension = os.path.splitext(file.filename)
           
            #-------------- Processo de nomeação dos dados -------------------
            existing_names = [doc["genome-output"] for doc in mongo.db.users.find({}, {"genome-output": 1})]
            generate_new_name = generate_unique_name(filename, existing_names)
            new_name = generate_new_name

            new_filename = f'{new_name}{extension}'
            folderSINE =f'{new_name}-SINE'
            seedSINE =f'{new_name}-Seed_SINE.fa'
            file.save(os.path.join(app.config['UPLOAD_FOLDER'],'Temp', 'input', new_filename))

            # ---- Criando pasta temporária para receber os seedSINE e libLINE ---
            tempsl_folder = os.path.join(TEMPSL_FOLDER, new_name)
            os.makedirs(tempsl_folder)
            
            # ---- Criando pasta temporária para receber os dados compactados ---
            tempcom_folder = os.path.join(TEMPCOM_FOLDER, folderSINE)
            os.chdir(TEMPCOM_FOLDER)

            # ----- CONFIGURANDO DADOS PARA O BANCO DE DADOS --------
            ## --- Chave do usuário em formato hexadecimal ---
            secret_key = os.urandom(24)
            key_security = secret_key.hex()

            expiration_period = timedelta(hours=72)
            expiration_date = datetime.utcnow() + expiration_period

            ### ---- Banco de dados mongodb, users dados ----
            print("Enviando dados do usuário para o banco de dados... ")
            mongo.db.users.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.users.insert_one({
                "key": key_security,
                "email": email,
                "genome-input": filename,
                "genome-output": new_name,
                "expiration-date": expiration_date
            })
            print("Dados registrados")
            print("")

            #----------- Funções chamando os comandos do pipeline ------------------
            #Registro de erro
            e = "Dados não fornecidos ou não disponíveis"

            try:
                annotation_elementSINE(new_filename, folderSINE, new_name, seedSINE)
            except subprocess.CalledProcessError as e:
                flash(f'Annotation failed with error: {e}')
                return redirect(request.url)

            #------------------ Compactando os dados SINE e LINE ----------------
            print("Processo de compactação SINE iniciado...")
            origin_folderSINE = os.path.join(SINE_FOLDER, 'temp', folderSINE)
            dest_zipSINE = os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-SINE')
            zip_folder(origin_folderSINE, dest_zipSINE)
            tar_folder(origin_folderSINE, dest_zipSINE)

            print("SINE compactado!")
            print("")

            gridfs_zipsine = GridFS(mongo.db, collection='zipsine')
            gridfs_tarsine = GridFS(mongo.db, collection='tarsine')

            #Tranformando os arquivos em binário, aqui utilizo open com modo "rb" (read binary)
            print("Conversão de arquivos compactos em binário iniciada...")
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-SINE.zip'), "rb") as zip_fileSINE:
                zip_dataSINE = gridfs_zipsine.put(zip_fileSINE, filename=f'{new_name}-SINE.zip')
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-SINE.tar.gz'), "rb") as tar_fileSINE:
                tar_dataSINE = gridfs_tarsine.put(tar_fileSINE, filename=f'{new_name}-SINE.tar.gz')
            print("Conversão concluída!")
            print("")

            #--------------------Trabalhando com BD -----------------------------
            print("Enviando binários para o banco de dados")
            mongo.db.zipsine_metadata.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.zipsine_metadata.insert_one({
                 "key": key_security,
                 "sine-data": folderSINE,
                 "zip-sine-name": (f'{new_name}-SINE.zip'),
                 "zip-sine-file": zip_dataSINE,
                 "expiration-date": expiration_date
            })

            mongo.db.tarsine_metadata.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.tarsine_metadata.insert_one({
                 "key": key_security,
                 "sine-data": folderSINE,
                 "tar-sine-name": (f'{new_name}-SINE.tar.gz'),
                 "tar-sine-file": tar_dataSINE,
                 "expiration-date": expiration_date
            })

            print("Dados registrados")
            print("")

            send_email_complete_annotation(email, key_security)
            print("Dados enviados para: ", email)
            print("")

            #Informando as pastas criadas
            print("Pasta SINE: ", folderSINE)
            print("Operação de anotação SINE finalizada")
            print("")

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
            filename, extension = os.path.splitext(file.filename)
           
            #-------------- Processo de nomeação dos dados -------------------
            existing_names = [doc["genome-output"] for doc in mongo.db.users.find({}, {"genome-output": 1})]
            generate_new_name = generate_unique_name(filename, existing_names)
            new_name = generate_new_name

            new_filename = f'{new_name}{extension}'
            folderSINE =f'{new_name}-SINE'
            folderLINE = f'{new_name}-LINE'
            resultsLINE = f'{folderLINE}-results'
            libLINE = f'{new_name}-LINE-lib.fa'
            file.save(os.path.join(app.config['UPLOAD_FOLDER'],'Temp', 'input', new_filename))

            # ---- Pasta temporária para receber os seedSINE e libLINE
            tempsl_folder = os.path.join(TEMPSL_FOLDER, new_name)
            os.makedirs(tempsl_folder)

            # ---- Pasta temporária para receber os dados compactados
            tempcom_folder = os.path.join(TEMPCOM_FOLDER, folderSINE)
            os.makedirs(tempcom_folder)

            ### ---- Chave em formato hexadecimal do usuário ----
            secret_key = os.urandom(24)
            key_security = secret_key.hex()

            expiration_period = timedelta(hours=72)
            expiration_date = datetime.utcnow() + expiration_period

            ### ---- Banco de dados mongodb, users dados ----
            print("Enviando dados do usuário para o banco de dados... ")
            mongo.db.users.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.users.insert_one({
                "key": key_security,
                "email": email,
                "genome-input": filename,
                "genome-output": new_name,
                "expiration-date": expiration_date
            })
            print("Dados registrados")
            print("")

            #----------- Funções chamando os comandos do pipeline ------------------
            #Registro de erro
            e = "Dados não fornecidos ou não disponíveis"

            try:
                annotation_elementLINE(new_filename, new_name, folderLINE, resultsLINE, libLINE)
            except subprocess.CalledProcessError as e:
                flash(f'Annotation failed with error: {e}')
                return redirect(request.url)


            #------------------ Compactando os dados LINEs ----------------
            print("Processo de compactação LINE iniciado...")
            origin_folderLINE = os.path.join(NONLTR_FOLDER, 'temp', resultsLINE)
            dest_zipLINE = os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-LINE')
            zip_folder(origin_folderLINE, dest_zipLINE)
            tar_folder(origin_folderLINE, dest_zipLINE)

            print("LINE compactado!")
            print("")

            gridfs_zipline = GridFS(mongo.db, collection='zipline')
            gridfs_tarline = GridFS(mongo.db, collection='tarline')

            #Tranformando os arquivos em binário, aqui utilizo open com modo "rb" (read binary)
            print("Conversão de arquivos compactos em binário iniciada...")
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-LINE.zip'), "rb") as zip_fileLINE:
                zip_dataLINE = gridfs_zipline.put(zip_fileLINE,filename=f'{new_name}-LINE.zip')
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-LINE.tar.gz'), "rb") as tar_fileLINE:
                tar_dataLINE = gridfs_tarline.put(tar_fileLINE,filename=f'{new_name}-LINE.tar.gz')

            #--------------------Trabalhando com BD -----------------------------
            print("Enviando binários para o banco de dados")
            mongo.db.zipline_metadata.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.zipline_metadata.insert_one({
                 "key": key_security,
                 "line-data": folderLINE,
                 "zip-line-name": (f'{new_name}-LINE.zip'),
                 "zip-line-file": zip_dataLINE,
                 "expiration-date": expiration_date
            })

            mongo.db.tarline_metadata.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.tarline_metadata.insert_one({
                 "key": key_security,
                 "line-data": folderLINE,
                 "tar-line-name": (f'{new_name}-LINE.tar.gz'),
                 "tar-line-file": tar_dataLINE,
                 "expiration-date": expiration_date
            })

            print("Dados registrados")
            print("")

            send_email_complete_annotation(email, key_security)
            print("Dados enviados para: ", email)
            print("")

            #Informando as pastas criadas
            print("Pasta criada para armazenamento dos dados LINE: ", folderLINE)
            print("Operação de anotação LINEs finalizada")
            print("")

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
            filename, extension = os.path.splitext(file.filename)

            #-------------- Processo de nomeação dos dados -------------------
            existing_names = [doc["genome-output"] for doc in mongo.db.users.find({}, {"genome-output": 1})]
            generate_new_name = generate_unique_name(filename, existing_names)
            new_name = generate_new_name

            new_filename = f'{new_name}{extension}'
            folderSINE =f'{new_name}-SINE'
            seedSINE =f'{new_name}-Seed_SINE.fa'
            folderLINE = f'{new_name}-LINE'
            resultsLINE = f'{folderLINE}-results'
            libLINE = f'{new_name}-LINE-lib.fa'
            file.save(os.path.join(app.config['UPLOAD_FOLDER'],'Temp', 'input', new_filename))

            #Adiconado pasta de armazenamento temporário para receber os seedSINE e libLINE
            tempsl_folder = os.path.join(TEMPSL_FOLDER, new_name)
            os.makedirs(tempsl_folder)

            # ---- Pasta temporária para receber os dados compactados
            tempcom_folder = os.path.join(TEMPCOM_FOLDER, folderSINE)
            os.makedirs(tempcom_folder)

            ### ---- Chave em formato hexadecimal do usuário ----
            secret_key = os.urandom(24)
            key_security = secret_key.hex()

            expiration_period = timedelta(hours=72)
            expiration_date = datetime.utcnow() + expiration_period

            ### ---- Banco de dados mongodb, users dados ----
            print("Enviando dados do usuário para o banco de dados... ")
            mongo.db.users.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.users.insert_one({
                "key": key_security,
                "email": email,
                "genome-input": filename,
                "genome-output": new_name,
                "expiration-date": expiration_date
            })
            print("Dados registrados")
            print("")

            #----------- Funções chamando os comandos do pipeline ------------------
            #Registro de erro
            e = "Dados não fornecidos ou não disponíveis"

            try:
                annotation_elementSINE(new_filename, folderSINE, new_name, seedSINE)
                annotation_elementLINE(new_filename, new_name, folderLINE, resultsLINE, libLINE)
            except subprocess.CalledProcessError as e:
                flash(f'Annotation failed with error: {e}')
                return redirect(request.url)

            # --- Compactação de arquivos ----
            print("Processo de compactação SINE iniciado...")
            origin_folderSINE = os.path.join(SINE_FOLDER, 'temp', folderSINE)
            dest_zipSINE = os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-SINE')
            zip_folder(origin_folderSINE, dest_zipSINE)
            tar_folder(origin_folderSINE, dest_zipSINE)

            print("SINE compactado!")
            print("")

            print("Processo de compactação LINE iniciado...")
            origin_folderLINE = os.path.join(NONLTR_FOLDER, 'temp', resultsLINE)
            dest_zipLINE = os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-LINE')
            zip_folder(origin_folderLINE, dest_zipLINE)
            tar_folder(origin_folderLINE, dest_zipLINE)

            print("LINE compactado!")
            print("")

            gridfs_zipsine = GridFS(mongo.db, collection='zipsine')
            gridfs_tarsine = GridFS(mongo.db, collection='tarsine')
            gridfs_zipline = GridFS(mongo.db, collection='zipline')
            gridfs_tarline = GridFS(mongo.db, collection='tarline')

            #Tranformando os arquivos em binário, aqui utilizo open com modo "rb" (read binary)
            print("Conversão de arquivos compactos em binário iniciada...")
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-SINE.zip'), "rb") as zip_fileSINE:
                zip_dataSINE = gridfs_zipsine.put(zip_fileSINE, filename=f'{new_name}-SINE.zip')
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-SINE.tar.gz'), "rb") as tar_fileSINE:
                tar_dataSINE = gridfs_tarsine.put(tar_fileSINE, filename=f'{new_name}-SINE.tar.gz')

            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-LINE.zip'), "rb") as zip_fileLINE:
                zip_dataLINE = gridfs_zipline.put(zip_fileLINE,filename=f'{new_name}-LINE.zip')
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{new_name}-LINE.tar.gz'), "rb") as tar_fileLINE:
                tar_dataLINE = gridfs_tarline.put(tar_fileLINE,filename=f'{new_name}-LINE.tar.gz')
            print("Conversão concluída!")
            print("")

            #--------------------Trabalhando com BD -----------------------------
            print("Enviando binários para o banco de dados")
            mongo.db.zipsine_metadata.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.zipsine_metadata.insert_one({
                 "key": key_security,
                 "sine-data": folderSINE,
                 "zip-sine-name": (f'{new_name}-SINE.zip'),
                 "zip-sine-file": zip_dataSINE,
                 "expiration-date": expiration_date
            })

            mongo.db.tarsine_metadata.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.tarsine_metadata.insert_one({
                 "key": key_security,
                 "sine-data": folderSINE,
                 "tar-sine-name": (f'{new_name}-SINE.tar.gz'),
                 "tar-sine-file": tar_dataSINE,
                 "expiration-date": expiration_date
            })

            print("Dados registrados")

            mongo.db.zipline_metadata.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.zipline_metadata.insert_one({
                 "key": key_security,
                 "line-data": folderLINE,
                 "zip-line-name": (f'{new_name}-LINE.zip'),
                 "zip-line-file": zip_dataLINE,
                 "expiration-date": expiration_date
            })

            mongo.db.tarline_metadata.create_index("expiration-date", expireAfterSeconds=259200)
            mongo.db.tarline_metadata.insert_one({
                 "key": key_security,
                 "line-data": folderLINE,
                 "tar-line-name": (f'{new_name}-LINE.tar.gz'),
                 "tar-line-file": tar_dataLINE,
                 "expiration-date": expiration_date
            })

            print("Dados registrados")
            print("")

            send_email_complete_annotation(email, key_security)
            print("Dados enviados para: ", email)
            print("")

            #Informando as pastas criadas
            print("Pasta SINE: ", folderSINE)
            print("Pasta LINE: ", folderLINE)
            print("Processo de anotação SINE e LINE finalizada")
            print("")

            return render_template("index.html")        
    return render_template("index.html")


@app.route("/results/<key_security>")
def results(key_security):
    # Consulte o banco de dados usando a chave para obter informações relevantes
    user_info = mongo.db.users.find_one({"key": key_security})    

    gridfs_zipsine = GridFS(mongo.db, collection='zipsine')
    gridfs_tarsine = GridFS(mongo.db, collection='tarsine')
    gridfs_zipline = GridFS(mongo.db, collection='zipline')
    gridfs_tarline = GridFS(mongo.db, collection='tarline')
    
    # Verifique se a chave é válida (se o usuário existe no banco de dados)
    if user_info is None:
        return "Chave inválida. O usuário não foi encontrado."

    # Recupere informações relevantes do usuário
    email = user_info["email"]
    fileTree = mongo.db.fileTree.find_one({"key": key_security})
    if fileTree is None:
        svg_tree1 = ""
        svg_tree2 = ""
    else:
        svg_tree1 = base64.b64encode(fileTree.get("file-Tree-1")).decode('utf-8')
        svg_tree2 = base64.b64encode(fileTree.get("file-Tree-2")).decode('utf-8')

    fileLandscape = mongo.db.landscape.find_one({"key": key_security})
    if fileLandscape is None:
        svg_landscape = ""
    else:
        svg_landscape = base64.b64encode(fileLandscape.get("file-landscape")).decode('utf-8')
    
    fileFamily = mongo.db.family.find_one({"key": key_security})
    if fileFamily is None:
        svg_copia = ""
        svg_gypsy = ""
    else:
        svg_copia = base64.b64encode(fileFamily.get("file-age-copia")).decode('utf-8')
        svg_gypsy = base64.b64encode(fileFamily.get("file-age-gypsy")).decode('utf-8')

    documents = list(mongo.db.report.find({"key": key_security}))
    if not documents:
        # Se for vazio, defina list_documents como uma lista vazia
        list_documents = []
    else:
        list_documents = documents

    filecsv = mongo.db.csv.find_one({"key": key_security})
    if filecsv is None:
        file_csv = ""
    else:
        bin_file = filecsv.get("file-csv")
        file_csv = base64.b64encode(bin_file).decode('utf-8')

    # ---- arquivos compactados ---
    zipsine_info = mongo.db.zipsine_metadata.find_one({"key": key_security})
    if zipsine_info is None:
        zip_sine_file = ""
    else:
        # Recupere o ObjectId do arquivo no GridFS
        file_zipsine_id = zipsine_info.get("zip-sine-file")

        # Certifique-se de que 'file_zipsine_id' é um ObjectId
        if isinstance(file_zipsine_id, ObjectId):
            file_data_zipsine = gridfs_zipsine.get(file_zipsine_id).read()
            zip_sine_file = base64.b64encode(file_data_zipsine).decode('utf-8')
        else:
            zip_sine_file = ""

    # -----------------------
    zipline_info = mongo.db.zipline_metadata.find_one({"key": key_security})
    if zipline_info is None:
        zip_line_file = ""
    else:
        file_zipline_id = zipline_info.get("zip-line-file")

        if isinstance(file_zipline_id, ObjectId):
            file_data_zipline = gridfs_zipline.get(file_zipline_id).read()

            zip_line_file = base64.b64encode(file_data_zipline).decode('utf-8')
        else:
            zip_line_file = ""

    # -----------------------
    tarsine_info = mongo.db.tarsine_metadata.find_one({"key": key_security})
    if tarsine_info is None:
        tar_sine_file = ""
    else:
        file_tarsine_id = tarsine_info.get("tar-sine-file")

        if isinstance(file_tarsine_id, ObjectId):
            file_data_tarsine = gridfs_tarsine.get(file_tarsine_id).read()
            tar_sine_file = base64.b64encode(file_data_tarsine).decode('utf-8')
        else:
            tar_sine_file = ""

    # -----------------------
    tarline_info = mongo.db.tarline_metadata.find_one({"key": key_security})
    if tarline_info is None:
        tar_line_file = ""
    else:
        file_tarline_id = tarline_info.get("tar-line-file")

        if isinstance(file_tarline_id, ObjectId):
            file_data_tarline = gridfs_tarline.get(file_tarline_id).read()
            tar_line_file = base64.b64encode(file_data_tarline).decode('utf-8')
        else:
            tar_line_file = ""

    

    # Renderize o template HTML passando as informações relevantes
    return render_template("results-page.html", 
                           email=email, 
                           zip_sine_file=zip_sine_file, 
                           zip_line_file=zip_line_file,
                           tar_sine_file=tar_sine_file,
                           tar_line_file=tar_line_file,
                           svg_tree1=svg_tree1, 
                           svg_tree2=svg_tree2,
                           svg_copia=svg_copia,
                           svg_gypsy=svg_gypsy,
                           svg_landscape=svg_landscape,
                           list_documents=list_documents,
                           filecsv=file_csv)


if __name__ == "__main__":
    app.run(debug=True)
