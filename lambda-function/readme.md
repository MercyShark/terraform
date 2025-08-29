before apply the terraform .
run
### for the first run
./build.sh
terraform  apply -auto-approve
### if you change the code in lambda_function.py then 
zip -g function.zip lambda_function.py thanks.html
terraform  apply -auto-approve


## Note: If you on windows then use git bash for running the build.sh file. 
And if zip command is not found then install it from
https://stackoverflow.com/questions/38782928/how-to-add-man-and-zip-to-git-bash-installation-on-windows