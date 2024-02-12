from flask_mail import Message
from app import create_app

app, mongo, mail, celery = create_app()

def send_email_checking(email):
    msg_title = "Email de verificação"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = "Obrigado por escolher a AnnoTEP, a sua ferramenta confiável para anotar elementos transponíveis em genomas de plantas. Estamos empolgados por fazer parte da sua jornada de pesquisa! Lembre-se de mencionar nosso trabalho em suas pesquisas para ajudar a promover o avanço da nossa pesquisa. Se tiver alguma dúvida ou precisar de assistência, não hesite em entrar em contato conosco. Boa sorte em seus estudos!"

    mail.send(msg)

def send_email_complete_annotation(email, key_security):
    msg_title = "Anotação completa"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    result_url = f'http://127.0.0.1:5000/results/{key_security}'
    msg.body = f"Sua anotação foi concluída! Para visualizar os dados obtidos clique no link: {result_url} . Esperamos que essas informações sejam úteis em sua pesquisa"

    mail.send(msg)

def send_email_error_extension(email):
    msg_title = "Error na checagem do arquivo"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = f"Sua anotação não pôde ser concluída. O arquivo enviado possui uma extensão diferente da esperada. Certifique-se de que está enviando um arquivo com a extensão correta, formato FASTA, conforme solicitado. Se precisar de assistência adicional, não hesite em entrar em contato."

    mail.send(msg)

def send_email_error_annotation(email):
    msg_title = "Error no processo de anotação"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = f"Sua anotação não pôde ser concluída devido a um erro durante a análise do arquivo. Por favor, revise o arquivo enviado e tente novamente. Se o problema persistir, entre em contato para obter assistência"

    mail.send(msg)