# FastAPI with CloudWatch Agent

Create EC2 instance (Amazon Linux 2) with IAM role (CloudWatchAgentServerPolicy)

## Installation

```bash
yum install -y amazon-cloudwatch-agent pip
```

```bash
pip install fastapi uvicorn
```

## Project Structure

```
/home/ubuntu/myapp/
    main.py
    app.log   (auto created by systemd)
```

## FastAPI Application

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def home():
    return {"message": "Hello from FastAPI on EC2"}
```

## Systemd Service Setup

```bash
which uvicorn  # e.g., /usr/local/bin/uvicorn
```

```bash
vim /etc/systemd/system/uvicorn.service
```

```ini
[Unit]
Description=Uvicorn FastAPI App
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user/myapp
ExecStart=/usr/local/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

# Save logs to a file so CloudWatch can read it
StandardOutput=append:/home/ec2-user/myapp/app.log
StandardError=append:/home/ec2-user/myapp/app.log

[Install]
WantedBy=multi-user.target
```

## Start and Enable Service

```bash
sudo systemctl daemon-reload
sudo systemctl start uvicorn
```

Enable automatic restart on reboot:

```bash
sudo systemctl enable uvicorn
```


Check log system start/end:
`vim /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`

```ini
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/home/ec2-user/myapp/app.log",
            "log_group_name": "fastapi-ec2-logs",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          }
        ]
      }
    }
  }
}
```

## Start CloudWatch Agent

```bash
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
sudo systemctl status amazon-cloudwatch-agent
```

## Debugging

Check cloudwatch sys logs (for debugging):

```bash
tail /var/log/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.log
```

check cloudwatch sys logs (for debugging):

`tail /var/log/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.log`