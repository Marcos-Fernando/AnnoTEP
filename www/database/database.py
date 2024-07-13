import os
import csv
import base64
from datetime import datetime

from flask import render_template
from gridfs import GridFS
from bson import ObjectId

def generate_unique_name(filename, existing_names):
    while True:
        #random_numbers = [str(random.randint(0,9)) for i in range(6)]
        now = datetime.now()
        formatted_date = now.strftime("%Y%m%d-%H%M%S")
        generated_name = f'{filename[:2]}_{"".join(formatted_date)}'

        #Verificando no bd
        if generated_name not in existing_names:
            return generated_name

def config_user(mongo, key_security, expiration_date, email, filename, new_generated_name):
    print("Sending user data to the database... ")
    mongo.db.users.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.users.insert_one({
        "key": key_security,
        "email": email,
        "genome-input": filename,
        "genome-output": new_generated_name,
        "expiration-date": expiration_date
    })

    print("Data recorded")
    print("")


def binary_SINEs_files(mongo, key_security, expiration_date, resultsAddress):

    gridfs_zipsine = GridFS(mongo.db, collection='zipsine')

    print("Converting compact files into binaries started...")
    with open(os.path.join(resultsAddress, 'SINEslibrary.zip'), "rb") as zip_file_SINE:
        zip_dataSINE = gridfs_zipsine.put(zip_file_SINE, filename='SINEslibrary.zip')
    print("Conversão concluída!")
    print("")

    #--------------------Trabalhando com BD -----------------------------
    print("Sending binaries to the database")
    mongo.db.zipsine_metadata.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.zipsine_metadata.insert_one({
        "key": key_security,
        "zip-sine-name": ('SINEslibrary.zip'),
        "zip-sine-file": zip_dataSINE,
        "expiration-date": expiration_date
    })
    print("Data recorded")
    print("")


def binary_LINEs_files(mongo, key_security, expiration_date, resultsAddress):

    gridfs_zipline = GridFS(mongo.db, collection='zipline')

    print("Conversão de arquivos compactos em binário iniciada...")
    with open(os.path.join(resultsAddress, 'LINEslibrary.zip'), "rb") as zip_file_SINE:
        zip_dataLINE = gridfs_zipline.put(zip_file_SINE, filename='LINEslibrary.zip')
    print("Conversão concluída!")
    print("")

    #--------------------Trabalhando com BD -----------------------------
    print("Enviando binários para o banco de dados")
    mongo.db.zipline_metadata.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.zipline_metadata.insert_one({
        "key": key_security,
        "zip-line-name": ('LINEslibrary.zip'),
        "zip-line-file": zip_dataLINE,
        "expiration-date": expiration_date
    })

    print("Data recorded")
    print("")

def binary_image_files(mongo, key_security, expiration_date, resultsAddress):
    completeAnalysis_folder = os.path.join(resultsAddress, 'complete-analysis')
    print("Converting TREE images into binaries...")
    with open(os.path.join(completeAnalysis_folder, 'TREE', 'LTR_RT-Tree1.svg'), "rb") as file_tree1:
        svg_tree1 = file_tree1.read()
    with open(os.path.join(completeAnalysis_folder, 'TREE', 'LTR_RT-Tree2.svg'), "rb") as file_tree2:
        svg_tree2 = file_tree2.read()
    with open(os.path.join(completeAnalysis_folder, 'TREE', 'LTR_RT-Tree3.svg'), "rb") as file_tree3:
        svg_tree3 = file_tree3.read()
    with open(os.path.join(completeAnalysis_folder, 'TREE', 'LTR_RT-Tree4.svg'), "rb") as file_tree4:
        svg_tree4 = file_tree4.read()    
            

    print("Converting LTR-AGE images to binaries...")
    with open(os.path.join(completeAnalysis_folder, 'LTR-AGE', 'AGE-Copia.svg'), "rb") as file_copia:
        svg_copia = file_copia.read()
    with open(os.path.join(completeAnalysis_folder, 'LTR-AGE', 'AGE-Gypsy.svg'), "rb") as file_gypsy:
        svg_gypsy = file_gypsy.read()


    print("Converting LandScape images to binaries...")
    with open(os.path.join(completeAnalysis_folder, 'RLandScape.svg'), "rb") as file_landscape:
        svg_landscape = file_landscape.read()


    print("Converting Report spreadsheets to binaries...")
    with open(os.path.join(completeAnalysis_folder, 'TEs-Report-Complete.csv'), 'rb') as csv_file:
        binary_data = csv_file.read()
    with open(os.path.join(completeAnalysis_folder, 'TEs-Report-lite.csv'), 'rb') as csv_file_lite:
        binary_data_lite = csv_file_lite.read()

    print("Conervations finalised!")
    print("")

    #--------------------Trabalhando com BD -----------------------------
    # ---- Dados CSV -----
    print("Sending csv data to the database")
    mongo.db.report.create_index("expiration-date", expireAfterSeconds=259200)
    with open(os.path.join(completeAnalysis_folder, 'TEs-Report-Complete.csv'), 'r') as csv_file:
        csv_reader = csv.DictReader(csv_file)
        for row in csv_reader:
            document = {
                "key": key_security,
                "Name": row['Name'],
                "Number of Elements": int(row['Number of Elements']),
                "Length": int(row['Length']),
                "Percentage": row['Percentage (%)'],
                "expiration-date": expiration_date
            }

            mongo.db.report.insert_one(document)

    mongo.db.csv.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.csv.insert_one({
        "key": key_security,
        "file-csv": binary_data,
        "expiration-date": expiration_date
    })

    # ----- report lite -------
    mongo.db.reportlite.create_index("expiration-date", expireAfterSeconds=259200)
    with open(os.path.join(completeAnalysis_folder, 'TEs-Report-lite.csv'), 'r') as csv_file_lite:
        csv_reader_lite = csv.DictReader(csv_file_lite)
        for row_lite in csv_reader_lite:
            document = {
                "key": key_security,
                "Name": row_lite['Name'],
                "Number of Elements": int(row_lite['Number of Elements']),
                "Length": int(row_lite['Length']),
                "Percentage": row_lite['Percentage (%)'],
                "expiration-date": expiration_date
            }

            mongo.db.reportlite.insert_one(document)

    mongo.db.csv_lite.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.csv_lite.insert_one({
        "key": key_security,
        "file-csv": binary_data_lite,
        "expiration-date": expiration_date
    })

    print("Data recorded")

        ### ---- Dados LTR AGEs ----
    print("Sending LTR-AGEs data to the database")
    mongo.db.family.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.family.insert_one({
        "key": key_security,
        "file-age-copia": svg_copia,
        "file-age-gypsy": svg_gypsy,
        "expiration-date": expiration_date
    })

    print("Data recorded")

        ### --- Dados Landscape ---
    print("Sending landscape data to the database")
    mongo.db.landscape.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.landscape.insert_one({
        "key": key_security,
        "file-landscape": svg_landscape,
        "expiration-date": expiration_date
    })
            
    print("Data recorded")

    ### --- Dados das árvores filogenéticas ---
    print("Sending TREE data to the database")
    mongo.db.fileTree.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.fileTree.insert_one({
        "key": key_security,
        "file-Tree-1": svg_tree1,
        "file-Tree-2": svg_tree2,
        "file-Tree-3": svg_tree3,
        "file-Tree-4": svg_tree4,
        "expiration-date": expiration_date
    })

# ------------ Results pages ------------
def analysis_results(key_security, mongo):
    user_info = mongo.db.users.find_one({"key": key_security})    

    gridfs_zipsine = GridFS(mongo.db, collection='zipsine')
    gridfs_zipline = GridFS(mongo.db, collection='zipline')
    
    # Verifique se a chave é válida (se o usuário existe no banco de dados)
    if user_info is None:
        return "Invalid key. The user was not found"

    # Recupere informações relevantes do usuário
    email = user_info["email"]
    fileTree = mongo.db.fileTree.find_one({"key": key_security})
    if fileTree is None:
        svg_tree1 = ""
        svg_tree2 = ""
        svg_tree3 = ""
        svg_tree4 = ""
    else:
        svg_tree1 = base64.b64encode(fileTree.get("file-Tree-1")).decode('utf-8')
        svg_tree2 = base64.b64encode(fileTree.get("file-Tree-2")).decode('utf-8')
        svg_tree3 = base64.b64encode(fileTree.get("file-Tree-3")).decode('utf-8')
        svg_tree4 = base64.b64encode(fileTree.get("file-Tree-4")).decode('utf-8')

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

    # report-lite
    documents_lite = list(mongo.db.reportlite.find({"key": key_security}))
    if not documents_lite:
        # Se for vazio, defina list_documents_lite como uma lista vazia
        list_documents_lite = []
    else:
        list_documents_lite = documents_lite

    filecsv_lite = mongo.db.csv_lite.find_one({"key": key_security})
    if filecsv_lite is None:
        file_csv_lite = ""
    else:
        bin_file = filecsv_lite.get("file-csv")
        file_csv_lite = base64.b64encode(bin_file).decode('utf-8')

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



    # Renderize o template HTML passando as informações relevantes
    return render_template("results-page.html", 
                           email=email, 
                           zip_sine_file=zip_sine_file, 
                           zip_line_file=zip_line_file,
                           svg_tree1=svg_tree1, 
                           svg_tree2=svg_tree2,
                           svg_tree3=svg_tree3, 
                           svg_tree4=svg_tree4,
                           svg_copia=svg_copia,
                           svg_gypsy=svg_gypsy,
                           svg_landscape=svg_landscape,
                           list_documents=list_documents,
                           list_documents_lite=list_documents_lite,
                           filecsv=file_csv,
                           filecsv_lite=file_csv_lite)
