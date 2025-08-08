#!/bin/bash
sudo apt update -y && sudo apt install -y docker.io
sudo systemctl start docker
sudo docker run -p 80:80 -d nginx 