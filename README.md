# Restrict iam users to terminate/start/stop/reboot only their ec2 instances
This repo will help you create IAM policies to control users start, stop, reboot, and terminate only instances which a user has launched across all EC2 instances under an account.

Access to manage Amazon EC2 instances can be controlled using tags. You can do this by writing an Identity and Access Management (IAM) policy that grants users permissions to manage EC2 instances that have a specific tag. However, if you also give users permissions to create or delete tags, users can manipulate the values of the tags to gain access and manage additional instances.

In this blog post, I will explore a method to automatically tag an EC2 instance and its associated resources without granting ec2:createTags, ec2:deleteTags permission to users. I have used a combination of an Amazon CloudWatch Events rule and AWS Lambda to tag newly created instances. With this solution, your users do not need to have permissions to create tags because the Lambda function will have the permissions to tag the instances. The solution can be automatically deployed in the region of your choice with this AWS CloudFormation.
