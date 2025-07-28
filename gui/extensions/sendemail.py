from app import create_app;
from flask_mail import Message
import os

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

# def send_email_complete_annotation(email, storageFolder, log_path):
#     msg_title = "Full annotation"
#     sender = "noreply@app.com"
#     msg = Message(msg_title, sender=sender, recipients=[email])
#     msg.body = f"Your annotation has been completed! To view it, go to the '{storageFolder}' folder. We hope you find this information useful in your research"
#     attachments=[str(log_path)]

#     mail.send(msg)

# def send_email_error_annotation(email, storageFolder, log_path):
#     msg_title = "Full annotation"
#     sender = "noreply@app.com"
#     msg = Message(msg_title, sender=sender, recipients=[email])
#     msg.body = f"Error annotation verification log"
#     attachments=[str(log_path)]
    
#     mail.send(msg)

def send_email_complete_annotation(email, storageFolder, log_path):
    """Envia email de conclusão com log anexado"""
    try:
        msg_title = "Annotation Completed Successfully"
        sender = "noreply@app.com"
        
        # Verifica se o arquivo de log existe
        if not os.path.exists(log_path):
            raise FileNotFoundError(f"Log file not found at {log_path}")
        
        msg = Message(
            subject=msg_title,
            sender=sender,
            recipients=[email]
        )
        
        msg.body = f"""Your genome annotation has been successfully completed!

                    Results location: {storageFolder}
                            
                    The detailed execution log is attached to this email.
                            
                    We hope you find this information useful in your research.
                            
                    Best regards,
                    Annotation Team"""
        
        # Adiciona anexo corretamente
        with open(log_path, 'rb') as fp:
            msg.attach(
                filename="annotation_log.txt",
                content_type="text/plain",
                data=fp.read()
            )
        
        mail.send(msg)
        return True
    
    except Exception as e:
        print(f"Failed to send completion email: {str(e)}")
        return False

def send_email_error_annotation(email, storageFolder, log_path):
    """Envia email de erro com log anexado"""
    try:
        msg_title = "Annotation Failed - Error Report"
        sender = "noreply@app.com"
        
        # Verifica se o arquivo de log existe
        if not os.path.exists(log_path):
            raise FileNotFoundError(f"Log file not found at {log_path}")
        
        msg = Message(
            subject=msg_title,
            sender=sender,
            recipients=[email]
        )
        
        msg.body = f"""We regret to inform you that your genome annotation process failed.

                    - The execution log is attached to this email
                    - Folder location: {storageFolder}

                    Please review the attached log file for detailed error information. 
                    If the problem persists, contact our support team.

                    We apologize for the inconvenience."""
        
        # Adiciona anexo corretamente
        with open(log_path, 'rb') as fp:
            msg.attach(
                filename="error_log.txt",
                content_type="text/plain",
                data=fp.read()
            )
        
        mail.send(msg)
        return True
    
    except Exception as e:
        print(f"Failed to send error email: {str(e)}")
        return False