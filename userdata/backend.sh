#!/bin/bash
sudo apt update
sudo apt install -y apache2
sudo mv /var/www/html/index.html /var/www/html/index.html.old
echo -e "Hello World - cloud is GCP - Node is $(hostname)" | sudo tee /var/www/html/index.html
echo "cloud init done" | tee /tmp/cloudInitDone.log
# while true
# do
# echo -e "HTTP/1.1 200 OK\n\nHello World - cloud is GCP - Node is $(hostname)" | nc -N -l -p 80
# done
