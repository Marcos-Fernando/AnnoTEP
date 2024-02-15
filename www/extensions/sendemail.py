import os
import smtplib
from flask import Flask, jsonify, request
from flask_mail import Message
from app import create_app

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

_, _, mail, _ = create_app()

def send_email_checking(email, mail_password):

    mail = smtplib.SMTP('smtp.gmail.com', 587)
    mail.starttls()
    mail.ehlo()
    mail.login('annoteps@gmail.com', mail_password)

    msg_title = "Verification email"
    sender = "noreply@app.com"

    msg = MIMEMultipart()
    msg.attach(MIMEText("Thank you for choosing AnnoTEP, your trusted tool for annotating transposable elements in plant genomes. We are excited to be part of your research journey! Remember to mention our work in your research to help advance our research. If you have any questions or need assistance, don't hesitate to contact us. Good luck with your studies!", 'plain'))

    msg['From'] = sender
    msg['To'] = email
    msg['Subject'] = msg_title

    mail.sendmail(sender, [email], msg.as_string())
    mail.quit()

def send_email_complete_annotation(email, key_security):
    msg_title = "Complete annotation"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    result_url = f'http://127.0.0.1:5000/results/{key_security}'
    msg.body = f"Your annotation has been completed! To view the data obtained, click on the link: {result_url} . We hope this information will be useful in your research"

    mail.send(msg)

def send_email_error_extension(email):
    msg_title = "Error checking file"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = f"Your annotation could not be completed. The file you sent has a different extension than you expected. Please make sure you are sending a file with the correct extension, FASTA format, as requested. If you need further assistance, please don't hesitate to get in touch."

    mail.send(msg)

def send_email_error_annotation(email):
    msg_title = "Error in the annotation process"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = f"Your annotation could not be completed due to an error while parsing the file. Please review the submitted file and try again. If the problem persists, please contact us for assistance"

    mail.send(msg)

def submit_form():
    data = request.json

    sender = data.get('from')
    title = data.get('title')
    subject = data.get('subject') 
    
    try:
        confirmation_msg = Message(subject="We received your question", sender=os.environ.get('MAIL_USERNAME'), recipients=[sender])
        confirmation_msg.body = "Thank you for getting in touch. We've received your query and will be in touch shortly."
        mail.send(confirmation_msg)

        # Aqui você pode enviar o e-mail
        msg = Message(subject=title, sender=sender, recipients=[os.environ.get('MAIL_USERNAME')])
        msg.html = f"<p><b>Email:</b> {sender}</p> <p><b>Text:</b> {subject}</p>"
        mail.send(msg)
        
        response = {'status': 'success', 'message': 'Email sent successfully!'}
    except Exception as e:
        # Lidar com exceções durante o envio do e-mail
        print(f"Erro ao enviar e-mail: {str(e)}")
        response = {'status': 'error', 'message': 'Error sending e-mail. Try again later.'}
    
    return jsonify(response)
    
