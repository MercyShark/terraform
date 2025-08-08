import requests
ip = requests.get("https://checkip.amazonaws.com").text.strip()
print(f'{{"authorized_ip": "{ip}/32"}}')
