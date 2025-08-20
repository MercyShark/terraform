import json
import os
import requests

TELEGRAM_TOKEN = os.environ["TELEGRAM_TOKEN"]
TELEGRAM_API = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}"

def lambda_handler(event, context):
    # Telegram sends JSON in body
    body = json.loads(event["body"])
    
    if "message" in body:
        chat_id = body["message"]["chat"]["id"]
        text = body["message"].get("text", "")
        send_message(chat_id, f"You said: {text}")
    
    return {
        "statusCode": 200,
        "body": json.dumps("ok")
    }

def send_message(chat_id, text):
    requests.post(f"{TELEGRAM_API}/sendMessage", json={"chat_id": chat_id, "text": text})


