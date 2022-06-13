# Terraform Green/Blue Deployment

Hi,

What is Blue/Green deployment?
A blue/green deployment is a deployment strategy in which you create two separate, but identical environments. One environment (blue) is running the current application version and one environment (green) is running the new application version. Using a blue/green deployment strategy increases application availability and reduces deployment risk by simplifying the rollback process if a deployment fails. Once testing has been completed on the green environment, live application traffic is directed to the green environment and the blue environment is deprecated.

Here I created below resources using Blue/Green deployment in AWS by Terraform.

Content:
* main.tf: Application Load Balancer, Launch Configuration, Auto Scaling Group
* sgr.tf: Security Group for our resources
* variable.tf: Variables used in building resources
* user_data.sh.tpl: Instance user data 

Note: Dear Reader please bear in mind that while creating this infrastructure I was on the way learning Terraform.  And there are still so many things to improve. Open for your comments.

Source of my learning are course of Denis Astahov in udemy and Terraform documentation.