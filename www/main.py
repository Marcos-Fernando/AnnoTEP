import io
import os
import random
import subprocess
from werkzeug.utils import secure_filename
from flask import Flask, render_template, request, redirect, flash, url_for, send_from_directory, jsonify
from flask_pymongo import PyMongo
from extensions.annotation import annoSINE, annoLINE, annoMSC, annoTREE
from extensions.compact import zip_folder, tar_folder

#Definindo local dos arquivos
#ambientes
CONDA = os.environ['CONDA_PREFIX']
HOME = os.environ['HOME']

#principal
UPLOAD_FOLDER = os.path.join(HOME, 'TEs')

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

# Gere uma chave secreta aleatória
#secret_key = os.urandom(24)
# Converta a chave em uma string hexadecimal
#secret_key_hex = secret_key.hex()
# Exiba a chave secreta
#print(f"Secret Key: {secret_key_hex}")

#configurando ambiente flask
app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MONGO_URI'] = "mongodb://localhost:27017/myDatabase"
#app.secret_key = secret_key_hex
#app.config["MONGO_URI"] = "mongodb+srv://marcoscosta:xMhvCuaHWyuwoPy5@cluster-tep.qznvfsw.mongodb.net/AnnoTEP?retryWrites=true&w=majority"
mongo = PyMongo(app)

@app.route("/")
def index():
    #online_users = mongo.db.users.find({"online": True})
    #mongo.db.invetory.insert_one({"teste":1})
    return render_template("index.html")

#Verifica se a extensão é válida e depois redireciona o usuário para a URL
def allowed_file(filename):
    return '.' in filename and \
            filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/loading', methods=['GET','POST'])
def upload_file():
    if request.method == 'POST':
        if 'email' in request.form:
            email = request.form.get('email')

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
           
            #-------------- Processo de nomeação dos dados -------------------
            #Gerando quatro números randomicos para renomear o arquivo enviado
            random_numbers = [str(random.randint(0,9)) for i in range(4)]

            #Salvando nome e extensão para não perde-los durante processo
            filename, extension = os.path.splitext(file.filename)
            new_filename = f'{filename}_{"".join(random_numbers)}{extension}'
           
            #criando a pasta para armazenar dados SINE
            folderSINE =f'{filename[:2]}_{"".join(random_numbers)}'

            #Nome para Seed_SINE
            seedSINE =f'{filename}_{"".join(random_numbers)}-Seed_SINE.fa'

            #criando pasta para armazenamento dos dados LINE
            folderLINE = f'{folderSINE}-LINE'
            resultsLINE = f'{folderLINE}-results'

            #recebendo nome do para o arquivo lib da anotação LINE
            libLINE = f'{folderSINE}-LINE-lib.fa'

            #Criando a pasta que irá conter a Mesclagem do seedSINE e libLINE
            folderEDTA = f'Anno-{folderSINE}'

            #Salvando arquivo recebido
            file.save(os.path.join(app.config['UPLOAD_FOLDER'],'Temp', 'input', new_filename))

            #Adiconado pasta de armazenamento temporário para receber os seedSINE e libLINE
            os.chdir(TEMPSL_FOLDER)
            cmdtemp = f""" mkdir {folderSINE} """
            process = subprocess.Popen(cmdtemp, shell=True, executable='/bin/bash')
            process.wait()


            #----------- Funções chamando os comandos do pipeline ------------------
            #Registro de erro
            e = "Dados não fornecidos ou não disponíveis"

	        # 1° processo - anotação dos elementos SINE
            try:
                annoSINE(new_filename, folderSINE, seedSINE)
            except subprocess.CalledProcessError as e:
                flash(f'Annotation SINE failed with error: {e}')
                return redirect(request.url)

            # 2° processo - anotação dos elementos LINE
            try:
                annoLINE(new_filename, folderSINE, folderLINE, resultsLINE, libLINE)
            except:
                flash(f'Annotation LINE failde with error: {e}')
                return redirect(request.url)
            
            # 3° processo - mesclagem dos dados SINEs e LINEs
            try:
                annoMSC(new_filename, folderLINE, folderSINE, seedSINE, folderEDTA, libLINE)
            except:
                flash(f'Annotation Complete  failde with error: {e}')
                return redirect(request.url)

            #Criação da filogenia e densidade
            try:
                annoTREE(new_filename, folderEDTA)
            except:
                flash(f'Annotation Complete  failde with error: {e}')
                return redirect(request.url)

            #Informando as pastas criadas
            print("Pasta criada para armazenamento dos dados SINE: ", folderSINE)
            print("Pasta criada para armazenamento dos dados LINE: ", folderLINE)
            print("Pasta criada para armazenamento de anotações: ", folderEDTA)
            print("")


            #------------------ Compactando os dados SINE e LINE ----------------
            #Adiconado pasta de armazenamento temporário para receber os dados compactados
            #folderSINE = 'A._2639'

            os.chdir(TEMPCOM_FOLDER)
            cmdtemp = f""" mkdir {folderSINE} """
            process = subprocess.Popen(cmdtemp, shell=True, executable='/bin/bash')
            process.wait()

            origin_folder = os.path.join(SINE_FOLDER, 'temp', folderSINE)
            dest_zip = os.path.join(TEMPCOM_FOLDER, folderSINE, folderSINE)
            zip_folder(origin_folder, dest_zip)
            tar_folder(origin_folder, dest_zip)

            #Tranformando os arquivos em binário, aqui utilizo open com modo "rb" (read binary)
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}.zip'), "rb") as zip_file:
                zip_data = zip_file.read()
            with open(os.path.join(TEMPCOM_FOLDER, folderSINE, f'{folderSINE}.tar.gz'), "rb") as tar_file:
                tar_data = tar_file.read()
        
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

            mongo.db.compactzip.insert_one({
                 "key": key_security,
                 "email": email,
                 "zip-name": (f'{folderSINE}.zip'),
                 "zip-file": zip_data
            })

            mongo.db.compacttar.insert_one({
                 "key": key_security,
                 "email": email,
                 "tar-name": (f'{folderSINE}.tar.gz'),
                 "tar-file": tar_data
            })

            mongo.db.files.insert_one({
                 "key": key_security,
                 "email": email,
                 "file-Tree-1": svg_tree1,
                 "file-Tree-2": svg_tree2
            })

            return render_template("index.html")        
    return render_template("index.html")

@app.route("/results")
def results():
    return "results"
if __name__ == "__main__":
    app.run(debug=True)
