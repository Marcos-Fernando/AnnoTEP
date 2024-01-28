import os
import csv
import base64
import random

from flask import render_template
from gridfs import GridFS
from bson import ObjectId

def generate_unique_name(filename, existing_names):
    while True:
        random_numbers = [str(random.randint(0,9)) for i in range(4)]
        generated_name = f'{filename[:2]}_{"".join(random_numbers)}'

        #Verificando no bd
        if generated_name not in existing_names:
            return generated_name

def config_user(mongo, key_security, expiration_date, email, filename, new_generated_name):
    print("Enviando dados do usuário para o banco de dados... ")
    mongo.db.users.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.users.insert_one({
        "key": key_security,
        "email": email,
        "genome-input": filename,
        "genome-output": new_generated_name,
        "expiration-date": expiration_date
    })

    print("Dados registrados")
    print("")


def binary_SINEs_files(mongo, key_security, expiration_date, resultsAddress):

    gridfs_zipsine = GridFS(mongo.db, collection='zipsine')
    gridfs_tarsine = GridFS(mongo.db, collection='tarsine')

    print("Conversão de arquivos compactos em binário iniciada...")
    with open(os.path.join(resultsAddress, 'CompactSINE.zip'), "rb") as zip_file_SINE:
        zip_dataSINE = gridfs_zipsine.put(zip_file_SINE, filename='CompactSINE.zip')
    with open(os.path.join(resultsAddress, 'CompactSINE.zip'), "rb") as tar_file_SINE:
        tar_dataSINE = gridfs_tarsine.put(tar_file_SINE, filename='CompactSINE.tar.gz')
    print("Conversão concluída!")
    print("")

    #--------------------Trabalhando com BD -----------------------------
    print("Enviando binários para o banco de dados")
    mongo.db.zipsine_metadata.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.zipsine_metadata.insert_one({
        "key": key_security,
        "zip-sine-name": ('CompactSINE.zip'),
        "zip-sine-file": zip_dataSINE,
        "expiration-date": expiration_date
    })

    mongo.db.tarsine_metadata.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.tarsine_metadata.insert_one({
        "key": key_security,
        "tar-sine-name": ('CompactSINE.tar.gz'),
        "tar-sine-file": tar_dataSINE,
        "expiration-date": expiration_date
    })

    print("Dados registrados")
    print("")


def binary_LINEs_files(mongo, key_security, expiration_date, resultsAddress):

    gridfs_zipline = GridFS(mongo.db, collection='zipline')
    gridfs_tarline = GridFS(mongo.db, collection='tarline')

    print("Conversão de arquivos compactos em binário iniciada...")
    with open(os.path.join(resultsAddress, 'CompactLINE.zip'), "rb") as zip_file_SINE:
        zip_dataLINE = gridfs_zipline.put(zip_file_SINE, filename='CompactLINE.zip')
    with open(os.path.join(resultsAddress, 'CompactLINE.tar.gz'), "rb") as tar_file_LINE:
        tar_dataLINE = gridfs_tarline.put(tar_file_LINE, filename='CompactLINE.tar.gz')
    print("Conversão concluída!")
    print("")

    #--------------------Trabalhando com BD -----------------------------
    print("Enviando binários para o banco de dados")
    mongo.db.zipline_metadata.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.zipline_metadata.insert_one({
        "key": key_security,
        "zip-line-name": ('CompactLINE.zip'),
        "zip-line-file": zip_dataLINE,
        "expiration-date": expiration_date
    })

    mongo.db.tarline_metadata.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.tarline_metadata.insert_one({
        "key": key_security,
        "tar-line-name": ('CompactLINE.tar.gz'),
        "tar-line-file": tar_dataLINE,
        "expiration-date": expiration_date
    })

    print("Dados registrados")
    print("")

def binary_image_files(mongo, key_security, expiration_date, resultsAddress):
    completeAnalysis_folder = os.path.join(resultsAddress, 'complete-analysis')
    print("Convertendo imagens TREE em binários...")
    with open(os.path.join(completeAnalysis_folder, 'TREE', 'LTR_RT-Tree1.svg'), "rb") as file_tree1:
        svg_tree1 = file_tree1.read()
    with open(os.path.join(completeAnalysis_folder, 'TREE', 'LTR_RT-Tree2.svg'), "rb") as file_tree2:
        svg_tree2 = file_tree2.read()
            
    print("Convertendo imagens LTR-AGE em binários...")
    with open(os.path.join(completeAnalysis_folder, 'LTR-AGE', 'AGE-Copia.svg'), "rb") as file_copia:
        svg_copia = file_copia.read()
    with open(os.path.join(completeAnalysis_folder, 'LTR-AGE', 'AGE-Gypsy.svg'), "rb") as file_gypsy:
        svg_gypsy = file_gypsy.read()

    print("Convertendo imagens LandScape em binários...")
    with open(os.path.join(completeAnalysis_folder, 'RLandScape.svg'), "rb") as file_landscape:
        svg_landscape = file_landscape.read()

    print("Convertendo planilha Report-Complete em binários...")
    with open(os.path.join(completeAnalysis_folder, 'TEs-Report-Complete.csv'), 'rb') as csv_file:
        binary_data = csv_file.read()

    print("Conervsões finalizadas!")
    print("")

    #--------------------Trabalhando com BD -----------------------------
    # ---- Dados CSV -----
    print("Enviando dados csv para o banco de dados")
    mongo.db.report.create_index("expiration-date", expireAfterSeconds=259200)
    with open(os.path.join(completeAnalysis_folder, 'TEs-Report-Complete.csv'), 'r') as csv_file:
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
        "file-csv": binary_data,
        "expiration-date": expiration_date
    })

    print("Dados registrados")

        ### ---- Dados LTR AGEs ----
    print("Enviando dados LTR-AGEs para o banco de dados")
    mongo.db.family.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.family.insert_one({
        "key": key_security,
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
        "file-landscape": svg_landscape,
        "expiration-date": expiration_date
    })
            
    print("Dados registrados")

    ### --- Dados das árvores filogenéticas ---
    print("Enviando dados TREE para o banco de dados")
    mongo.db.fileTree.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.fileTree.insert_one({
        "key": key_security,
        "file-Tree-1": svg_tree1,
        "file-Tree-2": svg_tree2,
        "expiration-date": expiration_date
    })

# ------------ Results pages ------------
def analysis_results(key_security, mongo):
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
