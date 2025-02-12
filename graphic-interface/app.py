import os

from flask import Flask
from flask_mail import Mail
from flask_pymongo import PyMongo
from celery import Celery

def create_app():
    GRAPHIC_FOLDER = os.path.dirname(os.path.abspath(__file__))
    UPLOAD_FOLDER = os.path.join(GRAPHIC_FOLDER, '..')

    app = Flask(__name__)
    app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

    #ambiente para envio de email
    app.config['MAIL_SERVER'] = os.environ.get('MAIL_SERVER')
    app.config['MAIL_PORT'] = int(os.environ.get('MAIL_PORT', 587))
    app.config['MAIL_USERNAME'] = os.environ.get('MAIL_USERNAME')
    app.config['MAIL_PASSWORD'] = os.environ.get('MAIL_PASSWORD')
    app.config['MAIL_USE_TLS'] = os.environ.get('MAIL_USE_TLS') == 'True'
    app.config['MAIL_USE_SSL'] = os.environ.get('MAIL_USE_SSL') == 'True'
    mail = Mail(app)

    return app, mail

#Verifica se a extensão é válida e depois redireciona o usuário para a URL
def allowed_file(filename):
    ALLOWED_EXTENSIONS = {'fasta'}
    
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS