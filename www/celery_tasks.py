from celery import Celery
from flask import Flask
from app import create_app
from extensions.annotation import sine_annotation, line_annotation, complete_annotation

app, _, _, _ = create_app()

celery = Celery(
    app.import_name,
    backend=app.config['result_backend'],
    broker=app.config['CELERY_BROKER_URL']
)
celery.conf.update(app.config)


#Definindo a quantidade de tarefas a serem executadas
celery.conf.worker_concurrency = 2


@celery.task
def process_annotation(new_filename, annotation_type, resultsAddress):
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


def get_number_of_workers():
    inspect = celery.control.inspect()
    active_workers = inspect.active()
    
    if active_workers:
        return sum(len(worker) for worker in active_workers.values())
    else:
        return 0