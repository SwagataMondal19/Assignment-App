#!/bin/bash
set -e

# Update system
dnf update -y

# Install packages
dnf install -y git nodejs npm amazon-cloudwatch-agent

# App setup
mkdir -p /var/www/app
cd /var/www/app

# Clone or pull repo
if [ ! -d ".git" ]; then
  git clone https://github.com/SwagataMondal19/Assignment-App.git .
else
  git pull origin main
fi

# Install dependencies
npm install

# Fix ownership
chown -R ec2-user:ec2-user /var/www/app

# Run app as ec2-user
sudo -u ec2-user bash <<EOF
cd /var/www/app

npm install -g pm2
pm2 start app.js --name app || pm2 restart app
pm2 save
pm2 startup systemd -u ec2-user --hp /home/ec2-user
EOF

# CloudWatch Agent config
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
  "metrics": {
    "append_dimensions": {
      "InstanceId": "\${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"]
      },
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["*"]
      }
    }
  }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
-s
