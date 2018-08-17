# Restrict IAM Users to Terminate/Start/Stop/Reboot only their EC2 Instances
This repo will help you create IAM policies to control users start, stop, reboot, and terminate only instances which a user has launched across all EC2 instances under an account.

Access to manage Amazon EC2 instances can be controlled using tags. You can do this by writing an Identity and Access Management (IAM) policy that grants users permissions to manage EC2 instances that have a specific tag. However, if you also give users permissions to create or delete tags, users can manipulate the values of the tags to gain access and manage additional instances.

I have used a combination of an Amazon CloudWatch Events rule and AWS Lambda to tag newly created instances. With this solution, your users do not need to have permissions to create tags ```ec2:createTags```, ```ec2:deleteTags``` because the Lambda function will have the permissions to tag the instances. The solution can be automatically deployed in the region of your choice with this [AWS CloudFormation][main_scr] or [Terraform][main_scr_2].

### IAM Policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowEveryEC2ActionOnAllResourse",
            "Action": [
                "ec2:*"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
            
        },
        {
            "Sid": "RestrictRebootStartStopTerminateToInstanceOwner",
            "Condition": {
                "StringNotEquals": {
                    "ec2:ResourceTag/PrincipalId": "${aws:userid}"
                }
            },
            "Action": [
                "ec2:RebootInstances",
                "ec2:TerminateInstances",
                "ec2:StartInstances",
                "ec2:StopInstances"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*",
            "Effect": "Deny"
            
        },
        {
            "Sid": "RestrictUsersFromCreatingDeletingTags",
            "Action": [
                "ec2:DeleteTags",
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*",
            "Effect": "Deny"
            
        }
    ]
}
```

This policy explicitly allows all EC2 describe actions and ec2:runInstances (in the LaunchEC2Instances statement). The core of the policy is in the ```RestrictRebootStartStopTerminateToInstanceOwner``` and  ```RestrictUsersFromCreatingDeletingTags``` statement. 

**```RestrictRebootStartStopTerminateToInstanceOwner```** applies a condition to EC2 actions we want to limit, in which we allow the action only if a tag named PrincipalId matches your current user ID. I am using the conditional variable, “${aws:userid}”, because it is always defined for any type of authenticated user. On the other hand, the AWS variable, aws:username, is only present for IAM users, and not for federated users.
For example, an IAM user cannot see the unique identifier, UserId, from the IAM console, but you can retrieve it with the AWS CLI by using the following command.

```aws iam get-user --user-name Bob```

>The following output comes from that command.

>```
>{
>    "User": {
>        "UserName": "Akshay",
>        "PasswordLastUsed": "2018-03-08T18:22:17Z",
>        "CreateDate": "2018-03-08T16:27:45Z",
>        "UserId": "AIDAJ7EQQEKUYVPO3NAZG",
>        "Path": "/",
>        "Arn": "arn:aws:iam::12345678910:user/Akshay"
>    }
>}
>```

In other cases, such as when assuming an IAM role to access an AWS account, the UserId is a combination of the assumed IAM role ID and the role session name that you specified at the time of the AssumeRole API call.

> ```role-id:role-session-name```
For a full list of values that you can substitute for policy variables, see Request Information That You Can Use for Policy Variables.

**```RestrictUsersFromCreatingDeletingTags```** applies a deny condition on actions ```ec2:DeleteTags```, ```ec2:CreateTags```.

### Tag automation
**1.** The IAM user has EC2 rights to launch an EC2 instance. Regardless of how the user creates the EC2 instance (with the AWS Management Console or AWS CLI), he performs a RunInstances API call.     **->**     **2.** CloudWatch Events records this activity.     **->**     **3.** A CloudWatch Events rule targets a Lambda function called AutoTag and it invokes the function with the event details. The event details contain the information about the user that completed the action (this information is retrieved automatically from AWS CloudTrail, which must be on for CloudWatch Events to work).     **->**     **4.** The Lambda function AutoTag scans the event details, and extracts all the possible resource IDs as well as the user’s identity     **->**     **5.** The function applies two tags to the created resources :

- ```Owner```, with the current ```userName```.
- ```PrincipalId```, with the current user’s ```aws:userid``` value.


<p align="center">
  <img width="60%" src="https://github.com/AkshaySiwal/Restrict_iam_users_to_terminate_only_their_ec2_instances/blob/master/images/AutoTag_steps.png">
</p>

### CloudFormation automation
This [CloudFormation template][main_scr] creates a Lambda function, and CloudWatch Events trigger that function in the region you choose. Lambda permissions to describe and tag EC2 resources are obtained from an IAM role the template creates along with the function. The template also creates an IAM group into which you can place your user to enforce the behavior described in this blog post. The template also creates a customer managed policy so that you can easily apply it to other IAM entities, such as IAM roles or other existing IAM groups.

### Terraform automation
This [Terraform][main_scr_2] does the same thing as of CloudFormation automation.


>**Note** : Currently, CloudWatch Events is available in [six regions][cloudwatch], and Lambda is available in [five regions][lambda]. Keep in mind that you can only use this post’s solution in regions where both CloudWatch Events and Lambda are available. As these services grow, you will be able to launch the same template in other regions as well.



<p align="center">
  <img width="60%" src="https://github.com/AkshaySiwal/Restrict_iam_users_to_terminate_only_their_ec2_instances/blob/master/images/Akshay_Cloud_Formation_v01-designer.png">
</p>

### Test IAM Policy
After creating a stack with this [CloudFormation template][main_scr] or [Terraform][main_scr_2] a new IAM Group **```IAM_Group_To_Manage_EC2_Instances_v01```**  will get created with required policies, make users part of this group and create an EC2 instance with one such user to test it.

Now go to EC2 Dashboard and click on show/hide column icon.
<p align="center">
  <img width="60%" src="https://github.com/AkshaySiwal/Restrict_iam_users_to_terminate_only_their_ec2_instances/blob/master/images/add_more_headers.png">
</p>

After clicking on show/hide column icon you will see two new tags **```Owner```** and **```PrincipalId```**, check both of these tags.
<p align="center">
  <img width="60%" src="https://github.com/AkshaySiwal/Restrict_iam_users_to_terminate_only_their_ec2_instances/blob/master/images/see_new_headers.png">
</p>

<p align="center">
  <img width="60%" src="https://github.com/AkshaySiwal/Restrict_iam_users_to_terminate_only_their_ec2_instances/blob/master/images/after_check_new_headers.png">
</p>

Now you will get to see ```Owner``` and ```PrincipalId``` columns with there respective values under EC2 Dashboard.
<p align="center">
  <img width="60%" src="https://github.com/AkshaySiwal/Restrict_iam_users_to_terminate_only_their_ec2_instances/blob/master/images/ins_with_new_headers.png">
</p>

And if you try to Stop/Start/Reboot/Terminate any EC2 Instance which does not belong to you, you will get an error saying **```You are not authorized to perform this operation.```**

<p align="center">
  <img width="60%" src="https://github.com/AkshaySiwal/Restrict_iam_users_to_terminate_only_their_ec2_instances/blob/master/images/error.png">
</p>

<br><br>
<br><br>

## References
- [References 1][r1]
- [References 2][r2]
- [References 3][r3]
- [References 4][r4]
- [References 5][r5]



## Getting Help

For any help feel free to contact me on [LinkedIn][linkedin-url] or [Facebook][facebook-url].





[facebook-url]: https://www.facebook.com/akshay.siwal.5
[linkedin-url]: https://www.linkedin.com/in/akshay-siwal-4b08b916/
[main_scr]: https://raw.githubusercontent.com/AkshaySiwal/Restrict_iam_users_to_terminate_only_their_ec2_instances/master/CloudFormation_template/Akshay_Cloud_Formation_v01.json
[main_scr_2]: https://raw.githubusercontent.com/AkshaySiwal/Restrict_iam_users_to_terminate_only_their_ec2_instances/master/Terraform_template/Akshay_terraform.tf
[cloudwatch]:https://docs.aws.amazon.com/general/latest/gr/rande.html#cwe_region
[lambda]:https://docs.aws.amazon.com/general/latest/gr/rande.html#lambda_region
[r1]:https://aws.amazon.com/blogs/security/resource-level-permissions-for-ec2-controlling-management-access-on-specific-instances/
[r2]:https://aws.amazon.com/blogs/aws/resource-permissions-for-ec2-and-rds-resources/
[r3]:https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html
[r4]:https://aws.amazon.com/blogs/security/how-to-automatically-tag-amazon-ec2-resources-in-response-to-api-events/
[r5]:https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_variables.html#policy-vars-infotouse
