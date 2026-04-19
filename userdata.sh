#!/bin/bash
set -euxo pipefail

# Log everything (VERY IMPORTANT for debugging)
exec > /var/log/user-data.log 2>&1

echo "===== USER DATA START ====="

# Wait for network (prevents early failures)
until ping -c1 google.com &>/dev/null; do
  echo "Waiting for network..."
  sleep 5
done

# Update system
dnf update -y

# Install required packages
dnf install -y git curl amazon-cloudwatch-agent

# Install Node.js (Node 18)
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
dnf install -y nodejs

# Verify installation
node -v
npm -v

# App setup
APP_DIR="/var/www/app"
mkdir -p $APP_DIR
cd $APP_DIR

# Clone or pull repo (idempotent)
if [ ! -d ".git" ]; then
  git clone https://github.com/SwagataMondal19/Assignment-App.git .
else
  git pull origin main
fi

# Install app dependencies
npm install

# Fix ownership
chown -R ec2-user:ec2-user $APP_DIR

# Run everything as ec2-user
sudo -u ec2-user bash <<EOF
cd /var/www/app

# Install PM2 if not present
if ! command -v pm2 &> /dev/null; then
  npm install -g pm2
fi

# Start or restart app
pm2 start app.js --name app || pm2 restart app

# Save process list
pm2 save

# Setup startup script
pm2 startup systemd -u ec2-user --hp /home/ec2-user
EOF

# Enable PM2 service (safe)
systemctl enable pm2-ec2-user || true

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
