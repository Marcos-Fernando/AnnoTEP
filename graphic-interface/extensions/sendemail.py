from app import create_app;
from flask_mail import Message

_, mail = create_app()

def send_email_checking(email, genome_name, speciesTIR, stepsExecuted, sensitivity, threads, param_str):
    msg_title = "Verification email"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = f"""
    Thank you for choosing AnnoTEP, your reliable tool for annotating transposable elements in plant genomes. We are excited to be part of your research journey!

    Here are the parameters you used for the annotation:
    --genome {genome_name} --species {speciesTIR} --step {stepsExecuted} --sensitive {sensitivity} --threads {threads} {param_str}

    Please remember to mention our work in your research to help advance our study. If you have any questions or need assistance, do not hesitate to contact us. Happy researching!
    """

    mail.send(msg)

def send_email_complete_annotation(email, storageFolder):
    msg_title = "Full annotation"
    sender = "noreply@app.com"
    msg = Message(msg_title, sender=sender, recipients=[email])
    msg.body = f"Your annotation has been completed! To view it, go to the '{storageFolder}' folder. We hope you find this information useful in your research"
    mail.send(msg)