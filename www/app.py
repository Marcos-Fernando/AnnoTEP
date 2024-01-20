import os

from flask import Flask
from flask_mail import Mail
from flask_pymongo import PyMongo
from celery import Celery

def create_app():
#configurando ambiente flask
    UPLOAD_FOLDER = os.path.join(os.environ['HOME'], 'TEs')

    app = Flask(__name__)
    app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
    app.config['MONGO_URI'] = "mongodb://localhost:27017/annotepdb"
    mongo = PyMongo(app)

    #ambiente para envio de email
    app.config['MAIL_SERVER'] = os.environ.get('MAIL_SERVER')
    app.config['MAIL_PORT'] = int(os.environ.get('MAIL_PORT', 587))
    app.config['MAIL_USERNAME'] = os.environ.get('MAIL_USERNAME')
    app.config['MAIL_PASSWORD'] = os.environ.get('MAIL_PASSWORD')
    app.config['MAIL_USE_TLS'] = os.environ.get('MAIL_USE_TLS') == 'True'
    app.config['MAIL_USE_SSL'] = os.environ.get('MAIL_USE_SSL') == 'True'
    mail = Mail(app)

    # configurando celery
    app.config["CELERY_BROKER_URL"] = "redis://localhost:6379/0"
    app.config["result_backend"] = "redis://localhost:6379/1"
    celery = Celery(app.name, broker=app.config["CELERY_BROKER_URL"])
    celery.conf.update(app.config)

    return app, mongo, mail, celery