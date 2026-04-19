#AWS AMI-Based CI/CD Deployment

Project Overview
This project demonstrates automated deployment of a Node.js application on AWS using:
•	Terraform (Infrastructure as Code)
•	GitHub Actions (CI/CD)
•	AMI-based deployment strategy
•	Auto Scaling Group (ASG)
•	Application Load Balancer (ALB)
The application is a simple Node.js web app running with PM2.

Architecture
User > ALB > EC2 (Auto Scaling Group) > Node.js App (PM2)

CI/CD Flow:
GitHub Push > GitHub Actions >Temporary EC2 > Run userdata.sh > Create AMI  > Update Launch Template > Refresh ASG > New instances deployed

Technologies Used
•	AWS EC2
•	Auto Scaling Group
•	Application Load Balancer
•	Launch Template
•	IAM Roles
•	CloudWatch Agent
•	Terraform
•	GitHub Actions
•	Node.js
•	PM2

Setup Instructions
1. Clone Repository
git clone:  https://github.com/SwagataMondal19/Assignment-App.git 
cd Assignment-App 

2. Configure GitHub Secrets
Add the following secrets in GitHub:
•	AWS_ACCESS_KEY_ID
•	AWS_SECRET_ACCESS_KEY

4. Deploy Application
Commit changes to main branch:
This triggers CI/CD pipeline automatically.

CI/CD Workflow
1.	Launch temporary EC2 instance
2.	Execute userdata script (install app + dependencies)
3.	Create AMI from instance
4.	Update Launch Template
5.	Trigger Auto Scaling Group refresh
6.	New instances serve updated app


 Features
•	Automated deployments using CI/CD
•	Immutable infrastructure (AMI-based)
•	Auto Scaling support
•	Load-balanced architecture
•	Monitoring with CloudWatch

 Notes
•	Application runs on port 3000
•	PM2 is used as process manager
•	Instances are launched as t2.micro (free-tier)

 Author
Swagata Mondal 
