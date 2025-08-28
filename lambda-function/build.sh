#!/bin/bash
set -e

rm -rf package function.zip

# Install dependencies into package/
mkdir package
pip install -r requirements.txt --target ./package

# Create deployment package
cd package
zip -r9 ../function.zip .
cd ..

# Add lambda_function.py
zip -g function.zip lambda_function.py
