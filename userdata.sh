#!/bin/bash
set -euxo pipefail

# Log everything for debugging
exec > /var/log/user-data.log 2>&1

echo "===== USER DATA START ====="

# Wait for network
until ping -c1 google.com &>/dev/null; do
  echo "Waiting for network..."
  sleep 5
done

# Update system
dnf update -y

# Install required packages
dnf install -y git curl amazon-cloudwatch-agent

# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
dnf install -y nodejs

# Verify installation
node -v
npm -v

# App setup
APP_DIR="/var/www/app"
mkdir -p $APP_DIR
cd $APP_DIR

# Clone repo fresh
git clone https://github.com/SwagataMondal19/Assignment-App.git .

# Install dependencies
npm install

# Fix ownership
chown -R ec2-user:ec2-user $APP_DIR

# Setup PM2 as ec2-user
sudo -u ec2-user bash <<EOF
cd /var/www/app

# Install PM2 globally
npm install -g pm2

# Start app
pm2 start app.js --name app

# Save PM2 process list
pm2 save

# Setup PM2 startup (IMPORTANT FIX)
pm2 startup systemd -u ec2-user --hp /home/ec2-user | tail -1 | bash
EOF

# Enable PM2 service
systemctl enable pm2-ec2-user

# Setup CloudWatch Agent config
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
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
-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
-s

echo "===== USER DATA COMPLETE ====="
