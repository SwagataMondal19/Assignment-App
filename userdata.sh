#!/bin/bash
set -euxo pipefail

# Log everything
exec > /var/log/user-data.log 2>&1

echo "===== USER DATA START ====="

# Wait for network
until ping -c1 google.com &>/dev/null; do
  echo "Waiting for network..."
  sleep 5
done

# Update system
dnf update -y

# Install required packages (NO curl)
dnf install -y git amazon-cloudwatch-agent

# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
dnf install -y nodejs

# Fix node/npm path
ln -s /usr/bin/node /usr/local/bin/node || true
ln -s /usr/bin/npm /usr/local/bin/npm || true

# Verify installation
node -v
npm -v

# Install PM2 globally as ROOT (🔥 FIX)
npm install -g pm2

# App setup
APP_DIR="/var/www/app"
mkdir -p $APP_DIR
cd $APP_DIR

# Clone repo
git clone https://github.com/SwagataMondal19/Assignment-App.git .

# Install dependencies
npm install

# Fix ownership
chown -R ec2-user:ec2-user $APP_DIR

# Run app as ec2-user
sudo -u ec2-user bash <<EOF
export PATH=\$PATH:/usr/local/bin

cd /var/www/app

# Start app
pm2 start app.js --name app

# Save process
pm2 save

# Setup startup
pm2 startup systemd -u ec2-user --hp /home/ec2-user | tail -1 | bash
EOF

# Enable + start PM2 service
systemctl enable pm2-ec2-user
systemctl start pm2-ec2-user

# CloudWatch config
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
