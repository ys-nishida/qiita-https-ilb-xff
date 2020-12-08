#!/bin/bash
sudo su -
setenforce 0

dnf --assumeyes install nginx
dnf --assumeyes install tcpdump

gsutil cp gs://<bucket name>/nginx.conf /etc/nginx/
gsutil cp gs://<bucket name>/allow_ip_map.conf /etc/nginx/conf.d/
gsutil cp gs://<bucket name>/testapp.py ~

systemctl enable nginx
systemctl start nginx

dnf --assumeyes install python3
pip3 install flask
python3 ~/testapp.py &