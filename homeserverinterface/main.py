import os
import random
import shutil

from app import create_app, allowed_file
from werkzeug.utils import secure_filename
from flask import render_template, request, redirect, flash
from extensions.sendemail import send_email_checking, send_email_complete_annotation
from extensions.annotation import sine_annotation, line_annotation, complete_annotation

app, _ = create_app()

# ===================== Ambientes ======================
CONDA = os.environ['CONDA_PREFIX']
UPLOAD_FOLDER = os.path.join(os.environ['HOME'], 'TEs')

# ================= Locais dos arquivos ================
LOCAL_FOLDER = os.path.join(UPLOAD_FOLDER, 'desktop')
RESULTS_FOLDER = os.path.join(LOCAL_FOLDER, 'results')


@app.route("/")
def index():
    return render_template("index.html")

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

                if os.path.exists(resultsAddress):
                    # Excluir a pasta "LINE" e seu conteúdo
                    line_folder = os.path.join(resultsAddress, "LINE")
                    if os.path.exists(line_folder):
                        shutil.rmtree(line_folder)

                    # Excluir arquivos com extensões ".fasta" e ".fa"
                    for file in os.listdir(resultsAddress):
                        if file.endswith((".fasta", ".fa")):
                            file_path = os.path.join(resultsAddress, file)
                            os.remove(file_path)

                    #print(f"A limpeza em {resultsAddress} foi concluída com sucesso.")
                else:
                    print(f"The folder {resultsAddress} does not exist.")

    return render_template("index.html")

if __name__ == "__main__":
    app.run(debug=True)
