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