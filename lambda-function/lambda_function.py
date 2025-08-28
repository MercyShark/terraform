import requests
import json

def lambda_handler(event, context):
    res = requests.get("https://api.github.com")
    data = res.json()
    data['message'] = "hello world"
    return {
        "statusCode": 200,
        "body": json.dumps(data)   # ✅ serialize dict → JSON string
    }


