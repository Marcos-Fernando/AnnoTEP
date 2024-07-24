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


def binary_files(mongo, key_security, expiration_date, resultsAddress):

    gridfs_zip = GridFS(mongo.db, collection='zipfile')

    print("Converting compact files into binaries started...")
    with open(os.path.join(resultsAddress, 'library.zip'), "rb") as zip_file:
        zip_data = gridfs_zip.put(zip_file, filename='library.zip')
    print("Conversão concluída!")
    print("")

    #--------------------Trabalhando com BD -----------------------------
    print("Sending binaries to the database")
    mongo.db.zip_metadata.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.zip_metadata.insert_one({
        "key": key_security,
        "zip-name": ('library.zip'),
        "zip-file": zip_data,
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
    with open(os.path.join(completeAnalysis_folder, 'TE-REPORT', 'RLandScape.svg'), "rb") as file_landscape:
        svg_landscape = file_landscape.read()
    
    print("Converting Report Graphic images to binaries...")
    with open(os.path.join(completeAnalysis_folder, 'TE-REPORT', 'TE-Report1.svg'), "rb") as file_Report1:
        svg_Report1 = file_Report1.read()
    with open(os.path.join(completeAnalysis_folder, 'TE-REPORT', 'TE-Report1-bubble.svg'), "rb") as file_Report1_bubble:
        svg_Report1_bubble = file_Report1_bubble.read()
    with open(os.path.join(completeAnalysis_folder, 'TE-REPORT', 'TE-Report2.svg'), "rb") as file_Report2:
        svg_Report2 = file_Report2.read()
    with open(os.path.join(completeAnalysis_folder, 'TE-REPORT', 'TE-Report2-bubble.svg'), "rb") as file_Report2_bubble:
        svg_Report2_bubble = file_Report2_bubble.read()

    print("Converting Report spreadsheets to binaries...")
    with open(os.path.join(completeAnalysis_folder, 'TE-REPORT', 'TEs-Report-Complete.txt'), 'r') as file_complete_txt:
        file_complete = file_complete_txt.read()

    with open(os.path.join(completeAnalysis_folder, 'TE-REPORT', 'TEs-Report-Lite.txt'), 'r') as file_lite_txt:
        file_lite = file_lite_txt.read()


    # print("Converting Report spreadsheets to binaries...")
    # with open(os.path.join(completeAnalysis_folder, 'TEs-Report-Complete.csv'), 'rb') as csv_file:
    #     binary_data = csv_file.read()
    # with open(os.path.join(completeAnalysis_folder, 'TEs-Report-lite.csv'), 'rb') as csv_file_lite:
    #     binary_data_lite = csv_file_lite.read()
    
    print("Conervations finalised!")
    print("")

    mongo.db.TEreport.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.TEreport.insert_one({
        "key": key_security,
        "file-complete": file_complete,
        "file-lite": file_lite,
        "file-Report1": svg_Report1,
        "file-Report1-bubble": svg_Report1_bubble,
        "file-Report2": svg_Report2,
        "file-Report2-bubble": svg_Report2_bubble,
        "expiration-date": expiration_date
    })

    #--------------------Trabalhando com BD -----------------------------
    # ---- Dados CSV -----
    # print("Sending csv data to the database")
    # mongo.db.report.create_index("expiration-date", expireAfterSeconds=259200)
    # with open(os.path.join(completeAnalysis_folder, 'TEs-Report-Complete.csv'), 'r') as csv_file:
    #     csv_reader = csv.DictReader(csv_file)
    #     for row in csv_reader:
    #         document = {
    #             "key": key_security,
    #             "Name": row['Name'],
    #             "Number of Elements": int(row['Number of Elements']),
    #             "Length": int(row['Length']),
    #             "Percentage": row['Percentage (%)'],
    #             "expiration-date": expiration_date
    #         }

    #         mongo.db.report.insert_one(document)

    # mongo.db.csv.create_index("expiration-date", expireAfterSeconds=259200)
    # mongo.db.csv.insert_one({
    #     "key": key_security,
    #     "file-csv": binary_data,
    #     "expiration-date": expiration_date
    # })

    # ----- report lite -------
    # mongo.db.reportlite.create_index("expiration-date", expireAfterSeconds=259200)
    # with open(os.path.join(completeAnalysis_folder, 'TEs-Report-lite.csv'), 'r') as csv_file_lite:
    #     csv_reader_lite = csv.DictReader(csv_file_lite)
    #     for row_lite in csv_reader_lite:
    #         document = {
    #             "key": key_security,
    #             "Name": row_lite['Name'],
    #             "Number of Elements": int(row_lite['Number of Elements']),
    #             "Length": int(row_lite['Length']),
    #             "Percentage": row_lite['Percentage (%)'],
    #             "expiration-date": expiration_date
    #         }

    #         mongo.db.reportlite.insert_one(document)

    # mongo.db.csv_lite.create_index("expiration-date", expireAfterSeconds=259200)
    # mongo.db.csv_lite.insert_one({
    #     "key": key_security,
    #     "file-csv": binary_data_lite,
    #     "expiration-date": expiration_date
    # })

    # print("Data recorded")

    ### ---- Dados LTR AGEs ----
    mongo.db.family.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.family.insert_one({
        "key": key_security,
        "file-age-copia": svg_copia,
        "file-age-gypsy": svg_gypsy,
        "expiration-date": expiration_date
    })

    ### --- Dados Landscape ---
    mongo.db.landscape.create_index("expiration-date", expireAfterSeconds=259200)
    mongo.db.landscape.insert_one({
        "key": key_security,
        "file-landscape": svg_landscape,
        "expiration-date": expiration_date
    })

    ### --- Dados das árvores filogenéticas ---
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
    gridfs_zip = GridFS(mongo.db, collection='zipfile')
    
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

    filereport = mongo.db.TEreport.find_one({"key": key_security})
    if filereport is None:
        file_complete = ""
        file_lite = ""
        svg_Report1  = ""
        svg_Report2  = ""
        svg_Report1_bubble  = ""
        svg_Report2_bubble  = ""
    else:
        file_complete = base64.b64encode(filereport.get("file-complete")).decode('utf-8')
        file_complete_table = filereport.get("file-complete").decode('utf-8')
        file_lite = base64.b64encode(filereport.get("file-lite")).decode('utf8')
        svg_Report1  = base64.b64encode(filereport.get("file-Report1")).decode('utf-8')
        svg_Report2  = base64.b64encode(filereport.get("file-Report2")).decode('utf-8')
        svg_Report1_bubble  = base64.b64encode(filereport.get("file-Report1-bubble")).decode('utf-8')
        svg_Report2_bubble  = base64.b64encode(filereport.get("file-Report2-bubble")).decode('utf-8')

    # documents = list(mongo.db.report.find({"key": key_security}))
    # if not documents:
    #     # Se for vazio, defina list_documents como uma lista vazia
    #     list_documents = []
    # else:
    #     list_documents = documents

    # filecsv = mongo.db.csv.find_one({"key": key_security})
    # if filecsv is None:
    #     file_csv = ""
    # else:
    #     bin_file = filecsv.get("file-csv")
    #     file_csv = base64.b64encode(bin_file).decode('utf-8')

    # # report-lite
    # documents_lite = list(mongo.db.reportlite.find({"key": key_security}))
    # if not documents_lite:
    #     # Se for vazio, defina list_documents_lite como uma lista vazia
    #     list_documents_lite = []
    # else:
    #     list_documents_lite = documents_lite

    # filecsv_lite = mongo.db.csv_lite.find_one({"key": key_security})
    # if filecsv_lite is None:
    #     file_csv_lite = ""
    # else:
    #     bin_file = filecsv_lite.get("file-csv")
    #     file_csv_lite = base64.b64encode(bin_file).decode('utf-8')

    # ---- arquivos compactados ---
    zip_info = mongo.db.zip_metadata.find_one({"key": key_security})
    if zip_info is None:
        zip_file = ""
    else:
        # Recupere o ObjectId do arquivo no GridFS
        file_zip_id = zip_info.get("zip-file")

        # Certifique-se de que 'file_zip_id' é um ObjectId
        if isinstance(file_zip_id, ObjectId):
            file_data_zip = gridfs_zip.get(file_zip_id).read()
            zip_file = base64.b64encode(file_data_zip).decode('utf-8')
        else:
            zip_file = ""

    # Renderize o template HTML passando as informações relevantes
    return render_template("results-page.html", 
                           email=email, 
                           zip_file=zip_file, 
                           svg_tree1=svg_tree1, 
                           svg_tree2=svg_tree2,
                           svg_tree3=svg_tree3, 
                           svg_tree4=svg_tree4,
                           svg_copia=svg_copia,
                           svg_gypsy=svg_gypsy,
                           svg_landscape=svg_landscape,
                           file_complete=file_complete,
                           file_lite=file_lite,
                           file_complete_table=file_complete_table,
                           svg_Report1=svg_Report1,
                           svg_Report2=svg_Report2,
                           svg_Report1_bubble=svg_Report1_bubble,
                           svg_Report2_bubble=svg_Report2_bubble)
