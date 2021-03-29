
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "default" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "default" {
  name               = "iam-role-${var.id}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.default.json
}

resource "aws_iam_instance_profile" "default" {
  name = "iam-ip-${var.id}"
  role = aws_iam_role.default.name
}


data "aws_iam_policy_document" "key_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow EC2 to sign"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.default.arn]
    }
    actions   = [
      "kms:CreateKey",
      "kms:DescribeKey",
      "kms:GetPublicKey",
      "kms:Sign",
      "kms:Verify",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "kms_key" {
  enable_key_rotation      = false
  customer_master_key_spec = var.kms_key_spec
  key_usage                = "SIGN_VERIFY"
  policy                   = data.aws_iam_policy_document.key_policy.json
}

resource "aws_kms_alias" "a" {
  name          = var.kms_key_alias
  target_key_id = aws_kms_key.kms_key.key_id
}
