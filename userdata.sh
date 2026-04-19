#!/bin/bash
yum update -y
yum install -y nodejs npm git amazon-cloudwatch-agent

# App setup
mkdir -p /var/www/app
cd /var/www/app

git clone https://github.com/SwagataMondal19/Assignment-App.git .

npm install

# Start app
npm install -g pm2
pm2 start app.js --name app
pm2 save

# Enable PM2 on reboot
pm2 startup systemd -u ec2-user --hp /home/ec2-user

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
