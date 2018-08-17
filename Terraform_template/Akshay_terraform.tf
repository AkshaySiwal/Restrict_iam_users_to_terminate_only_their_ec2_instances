variable "IsCloudTrailEnabled" {
  description = "Is CloudTrail already enabled in this region? CloudTrail is a requirement for Cloudwatch Events. If not enabled, please enable CloudTrail before proceeding. (yes/no)"
}

variable "aws_access_key" {
  description = "Enter aws access key to login"
}

variable "aws_secret_key" {
  description = "Enter aws secret key"
}

variable "aws_region" {
  description = "Enter aws region"
}

variable "vpc_id" {
  description = "VPC Id for lambda function"
}

variable "subnet_ids" {
  description = "List of subnet ids for lambda function"
  type = "list"
}

variable "security_group_ids" {
  description = "List of subnet security groups for lambda function"
  type = "list"
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

resource "aws_lambda_permission" "PermissionForEventsToInvokeLambdav01" {
  count         = "${replace(replace(var.IsCloudTrailEnabled, "/^yes$/", "1"), "/^[a-zA-Z2-9_]*$/", "0")}"
  statement_id  = "PermissionForEventsToInvokeLambdav01"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.Lambda_FucntionForAutoTagv01.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.CloudWatchEC2EventRulev01.arn}"
}

resource "aws_lambda_function" "Lambda_FucntionForAutoTagv01" {
  count            = "${replace(replace(var.IsCloudTrailEnabled, "/^yes$/", "1"), "/^[a-zA-Z2-9_]*$/", "0")}"
  filename         = "lambda_function_payload.zip"
  function_name    = "Lambda_FucntionForAutoTagv01"
  role             = "${aws_iam_role.RoleForLambdaToAutoTagv01.arn}"
  handler          = "index.lambda_handler"
  source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  runtime          = "python2.7"
  timeout          = "60"
  description      = "This function tags EC2 Resources in response to Cloudwatch Events."
  vpc_config {
    subnet_ids         = ["${var.subnet_ids}"]
    security_group_ids = ["${var.security_group_ids}"]
  }
}

resource "aws_cloudwatch_event_rule" "CloudWatchEC2EventRulev01" {
  count       = "${replace(replace(var.IsCloudTrailEnabled, "/^yes$/", "1"), "/^[a-zA-Z2-9_]*$/", "0")}"
  name        = "CloudWatch_EC2_Event_Rule_v01"
  description = "Trigger a Lambda function anytime a new EC2 resource is created (EC2 instance, EBS volume, EBS Snapshot or AMI)"

  event_pattern = <<EOF
{
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
            "ec2.amazonaws.com"
                   ],
            "eventName": [
                     "CreateVolume",
                     "RunInstances",
                     "CreateImage",
                     "CreateSnapshot"
                        ]
   }
}
EOF
}

resource "aws_cloudwatch_event_target" "CloudWatchEC2EventRulev01" {
  count     = "${replace(replace(var.IsCloudTrailEnabled, "/^yes$/", "1"), "/^[a-zA-Z2-9_]*$/", "0")}"
  target_id = "LambdaFucntionForAutoTagv01"
  rule      = "${aws_cloudwatch_event_rule.CloudWatchEC2EventRulev01.name}"
  arn       = "${aws_lambda_function.Lambda_FucntionForAutoTagv01.arn}"
}

resource "aws_iam_role" "RoleForLambdaToAutoTagv01" {
  count = "${replace(replace(var.IsCloudTrailEnabled, "/^yes$/", "1"), "/^[a-zA-Z2-9_]*$/", "0")}"
  name  = "Role_For_Lambda_To_Auto_Tag_v01"

  assume_role_policy = <<EOF
{
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Effect": "Allow",
                            "Principal": {
                                "Service": [
                                    "lambda.amazonaws.com"
                                ]
                            },
                            "Action": [
                                "sts:AssumeRole"
                            ]
                        }
                    ]
}
EOF
}

resource "aws_iam_policy" "InLinePolicyForLambdaToCreateTagsv01" {
  count = "${replace(replace(var.IsCloudTrailEnabled, "/^yes$/", "1"), "/^[a-zA-Z2-9_]*$/", "0")}"
  name  = "InLine_Policy_For_Lambda_To_Create_Tags_v01"

  policy = <<EOF
{
                            "Version": "2012-10-17",
                            "Statement": [
                                {
                                    "Sid": "Stmt1458923097000",
                                    "Effect": "Allow",
                                    "Action": [
                                        "cloudtrail:LookupEvents"
                                    ],
                                    "Resource": [
                                        "*"
                                    ]
                                },
                                {
                                    "Sid": "Stmt1458923121000",
                                    "Effect": "Allow",
                                    "Action": [
                                        "ec2:CreateTags",
                                        "ec2:Describe*",
                                        "ec2:DescribeNetworkInterfaces",
                                        "ec2:CreateNetworkInterface",
                                        "ec2:DeleteNetworkInterface",
                                        "logs:CreateLogGroup",
                                        "logs:CreateLogStream",
                                        "logs:PutLogEvents"
                                    ],
                                    "Resource": [
                                        "*"
                                    ]
                                }
                            ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "RoleForLambdaToAutoTagv01" {
  count      = "${replace(replace(var.IsCloudTrailEnabled, "/^yes$/", "1"), "/^[a-zA-Z2-9_]*$/", "0")}"
  role       = "${aws_iam_role.RoleForLambdaToAutoTagv01.name}"
  policy_arn = "${aws_iam_policy.InLinePolicyForLambdaToCreateTagsv01.arn}"
}

resource "aws_iam_group" "IAMGroupToManageEC2Instancesv01" {
  count = "${replace(replace(var.IsCloudTrailEnabled, "/^yes$/", "1"), "/^[a-zA-Z2-9_]*$/", "0")}"
  name  = "IAM_Group_To_Manage_EC2_Instances_v01"
}

resource "aws_iam_group_policy_attachment" "IAMGroupToManageEC2Instancesv01" {
  count      = "${replace(replace(var.IsCloudTrailEnabled, "/^yes$/", "1"), "/^[a-zA-Z2-9_]*$/", "0")}"
  group      = "${aws_iam_group.IAMGroupToManageEC2Instancesv01.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_policy" "IAMPolicyForTagBasedEC2Restrictionsv01" {
  count       = "${replace(replace(var.IsCloudTrailEnabled, "/^yes$/", "1"), "/^[a-zA-Z2-9_]*$/", "0")}"
  name        = "IAM_Policy_For_Tag_Based_EC2_Restrictions_v01"
  description = "This policy allows Start/Stop/Reboot/Terminate for EC2 instances where the tag Owner doesnt match the current requesters user ID."

  policy = <<EOF
{
                    "Version": "2012-10-17",
                    "Statement": [
                        {
                            "Sid": "AllowEveryEC2ActionOnAllResourse",
                            "Effect": "Allow",
                            "Action": [
                                "ec2:*"
                            ],
                            "Resource": [
                                "*"
                            ]
                        },
                        {
                            "Sid": "RestrictRebootStartStopTerminateToInstanceOwner",
                            "Effect": "Deny",
                            "Action": [
                                "ec2:RebootInstances",
                                "ec2:TerminateInstances",
                                "ec2:StartInstances",
                                "ec2:StopInstances"
                            ],
                            "Resource": "arn:aws:ec2:*:*:instance/*",
                            "Condition": {
                                "StringNotEquals": {
                                    "ec2:ResourceTag/PrincipalId": "$${aws:userid}"
                                }
                            }
                        },
                        {
                            "Sid": "RestrictUsersFromCreatingDeletingTags",
                            "Effect": "Deny",
                            "Action": [
                                "ec2:DeleteTags",
                                "ec2:CreateTags"
                            ],
                            "Resource": "arn:aws:ec2:*:*:instance/*"
                        }
                    ]
}
EOF
}

resource "aws_iam_group_policy_attachment" "IAMPolicyForTagBasedEC2Restrictionsv01" {
  count      = "${replace(replace(var.IsCloudTrailEnabled, "/^yes$/", "1"), "/^[a-zA-Z2-9_]*$/", "0")}"
  group      = "${aws_iam_group.IAMGroupToManageEC2Instancesv01.name}"
  policy_arn = "${aws_iam_policy.IAMPolicyForTagBasedEC2Restrictionsv01.arn}"
}
