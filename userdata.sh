#!/bin/bash
set -e

yum update -y
yum install -y nodejs npm git amazon-cloudwatch-agent

mkdir -p /var/www/app
cd /var/www/app

git clone https://github.com/SwagataMondal19/Assignment-App.git .

npm install

npm install -g pm2
pm2 start app.js --name app
pm2 save

pm2 startup systemd -u ec2-user --hp /home/ec2-user

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

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
-s
