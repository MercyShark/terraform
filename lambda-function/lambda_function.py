import smtplib
import json
import datetime
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from jinja2 import Environment, FileSystemLoader
import os

def lambda_handler(event, context):

    env = Environment(loader=FileSystemLoader('.'))
    template = env.get_template('thanks.html')

    data = {
    "name": "Rishabh",
    "email": "rishabh@example.com",
    "message": "I want to know more about your pricing.",
    "ticket_id": "12345",
    "company_name": "Acme Co.",
    "support_url": "https://support.example.com",
    "support_email": "support@example.com",
    "phone": "+91-90000-00000",
    "response_time": "within 24 hours"
    }
    html_body = template.render(**data)

    # SMTP server details
    smtp_server = os.getenv("SMTP_SERVER", "smtp.gmail.com")
    smtp_port = os.getenv("SMTP_PORT", 465)
    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD") 

    # Email details
    sender = os.getenv("SENDER_EMAIL")
    receiver = "prajapatirishabh04@gmail.com"
    subject = "Hello from AWS Lambda"
    # body = f"This is a test email sent using SMTP from AWS Lambda! {datetime.datetime.utcnow()}"

    # Create message
    msg = MIMEMultipart()
    msg["From"] = sender
    msg["To"] = receiver
    msg["Subject"] = subject

    alt = MIMEMultipart('alternative')
    alt.attach(MIMEText(html_body, 'html'))
    msg.attach(alt)

    try:
        # Connect to SMTP server
        with smtplib.SMTP_SSL(smtp_server, smtp_port) as server:
            server.login(smtp_user, smtp_password)
            server.sendmail(sender, receiver, msg.as_string())

        return {
        'statusCode': 200,
        'body': json.dumps('Success Email')
        }


    except Exception as e:
        return {
        'statusCode': 200,
        'body': json.dumps('Fail Email')
        }
