#!/bin/bash
set -e

dnf update -y

dnf install -y git nodejs npm amazon-cloudwatch-agent

mkdir -p /var/www/app
cd /var/www/app

if [ ! -d ".git" ]; then
  git clone https://github.com/SwagataMondal19/Assignment-App.git .
else
  git pull origin main
fi

npm install

chown -R ec2-user:ec2-user /var/www/app

sudo -u ec2-user bash <<EOF
cd /var/www/app
npm install -g pm2
pm2 start app.js --name app || pm2 restart app
pm2 save
pm2 startup systemd -u ec2-user --hp /home/ec2-user
EOF
