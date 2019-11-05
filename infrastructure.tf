provider "aws" {
  region = "us-east-1"
  profile = "cloudblueprint-jpcedenog"
}

resource "aws_cognito_user_pool" "notes-user-pool" {
  name = "notes-user-pool"
  username_attributes = ["email"]
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "client" {
  name = "notes-app"

  user_pool_id = "${aws_cognito_user_pool.notes-user-pool.id}"

  generate_secret = false
  refresh_token_validity = 30
  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH"]
}

resource "aws_cognito_user_pool_domain" "notes-app-jpcedeno" {
  domain = "notes-app-jpcedeno"
  user_pool_id = "${aws_cognito_user_pool.notes-user-pool.id}"
}

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name = "notes identity pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = "${aws_cognito_user_pool_client.client.id}"
    provider_name           = "${aws_cognito_user_pool.notes-user-pool.endpoint}"
    server_side_token_check = false
  }
}

resource "aws_iam_role" "authenticated" {
  name = "Cognito_notesAuth_Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.main.id}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "authenticated" {
  name = "authenticated_policy"
  role = "${aws_iam_role.authenticated.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "mobileanalytics:PutEvents",
        "cognito-sync:*",
        "cognito-identity:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "execute-api:Invoke"
      ],
      "Resource": [
        "arn:aws:execute-api:us-east-1:*:wt2r9wvpna/*"
      ]
    }
  ]
}
EOF
}

 resource "aws_iam_role" "unauthenticated" {
    name = "unauth_iam_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
            "Federated": "cognito-identity.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

 resource "aws_iam_role_policy" "unauthenticated" {
    name = "web_iam_unauth_role_policy"
    role = "${aws_iam_role.unauthenticated.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Action": "*",
      "Effect": "Deny",
      "Resource": "*"
    }
  ]
}
 EOF
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = "${aws_cognito_identity_pool.main.id}"

  roles = {
    "authenticated" = "${aws_iam_role.authenticated.arn}"
    "unauthenticated" = "${aws_iam_role.unauthenticated.arn}"
  }
}