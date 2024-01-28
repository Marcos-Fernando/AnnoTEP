from celery import Celery
from flask import Flask
from app import create_app
from extensions.annotation import sine_annotation, line_annotation, complete_annotation

def make_celery(app):
    celery = Celery(
        app.import_name,
        backend=app.config["result_backend"],
        broker=app.config['CELERY_BROKER_URL']
    )
    celery.conf.update(app.config)

    return celery

app, _, _, _ = create_app()
celery = make_celery(app)

@celery.task
def process_annotation(email, new_filename, annotation_type, resultsAddress):
    # Coloque o código do seu bloco 'if annotation_type' aqui
    if annotation_type == 1:
        sine_annotation(new_filename, resultsAddress)       
    elif annotation_type == 2:
        line_annotation(new_filename, resultsAddress)       
    elif annotation_type == 3:
        sine_annotation(new_filename, resultsAddress)        
        line_annotation(new_filename, resultsAddress)        
    elif annotation_type == 4:
        sine_annotation(new_filename, resultsAddress)
        line_annotation(new_filename, resultsAddress)
        complete_annotation(new_filename, resultsAddress)


    return f'Análise armazenada na pasta: {resultsAddress}'
