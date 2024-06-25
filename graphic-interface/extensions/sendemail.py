from app import create_app;
from flask_mail import Message

_, mail = create_app()

def send_email_checking(email):
    msg_title = "Verification email"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = "Thank you for choosing AnnoTEP, your reliable tool for annotating transposable elements in plant genomes. We are excited to be part of your research journey! Remember to mention our work in your research to help advance our research. If you have any questions or need assistance, don't hesitate to contact us. Good luck with your studies!"
    mail.send(msg)

def send_email_complete_annotation(email):
    msg_title = "Full annotation"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = f"Your annotation has been completed! To view it, go to the 'results' folder. We hope you find this information useful in your research"
    mail.send(msg)