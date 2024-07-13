import os
import shutil
from datetime import datetime

from app import create_app, allowed_file
from werkzeug.utils import secure_filename
from flask import render_template, request, redirect, flash
from extensions.sendemail import send_email_checking, send_email_complete_annotation
from extensions.annotation import sine_annotation, line_annotation, complete_annotation

app, _ = create_app()

# ===================== Ambientes ======================
UPLOAD_FOLDER = os.path.join(os.environ['HOME'], 'TEs')

# ================= Locais dos arquivos ================
RESULTS_FOLDER = os.path.join(UPLOAD_FOLDER, 'graphic-interface', 'results')

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
            #Obtendo e formatando data e hora
            now = datetime.now()
            formatted_date = now.strftime("%Y%m%d-%H%M%S")
            storageFolder = f'{filename}_{"".join(formatted_date)}'

            resultsAddress = os.path.join(RESULTS_FOLDER, storageFolder)
            os.makedirs(resultsAddress)

            new_filename = f'{filename}{extension}'
            file.save(os.path.join(RESULTS_FOLDER, storageFolder, new_filename))

        if 'annotation_type' in request.form:
                annotation_type = int(request.form.get('annotation_type'))
                if annotation_type == 1:
                    sine_annotation(new_filename, resultsAddress)
                    send_email_complete_annotation(email, storageFolder)
                elif annotation_type == 2:
                    line_annotation(new_filename, resultsAddress)
                    send_email_complete_annotation(email, storageFolder)
                elif annotation_type == 3:
                    sine_annotation(new_filename, resultsAddress)
                    line_annotation(new_filename, resultsAddress)
                    send_email_complete_annotation(email, storageFolder)
                elif annotation_type == 4:
                    sine_annotation(new_filename, resultsAddress)
                    line_annotation(new_filename, resultsAddress)
                    complete_annotation(new_filename, resultsAddress)
                    send_email_complete_annotation(email, storageFolder)

    return render_template("index.html")

if __name__ == "__main__":
    app.run(debug=True)
