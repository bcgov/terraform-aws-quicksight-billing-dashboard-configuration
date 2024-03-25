
# Data sources for the kms keys
data "aws_kms_key" "operations_account_key_by_alias" {
  key_id = "alias/${var.operations_account_kms_key_alias}"
}

data "aws_kms_key" "master_account_key_by_alias" {
  provider = aws.master-account
  key_id   = "alias/${var.master_account_kms_key_alias}"
}
# # Bucket for the cost and usage report exports
resource "aws_s3_bucket" "cur_export_bucket" {
  provider = aws.master-account
  bucket = var.cur_export_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "cur_export_bucket_versioning" {
  provider = aws.master-account
  bucket = aws_s3_bucket.cur_export_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Resource to create an s3 bucket in the operations account
resource "aws_s3_bucket" "destination_bucket" {
  bucket = var.cur_replication_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "destination_bucket_versioning" {
  bucket = aws_s3_bucket.destination_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket policy for the destination bucket
resource "aws_s3_bucket_policy" "destination_bucket_policy" {
  bucket = aws_s3_bucket.destination_bucket.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Id" : "PolicyForDestinationBucket",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "*"
          },
          "Action" : [
            "s3:GetBucketVersioning",
            "s3:GetObjectVersionTagging",
            "s3:ObjectOwnerOverrideToBucketOwner",
            "s3:PutBucketVersioning",
            "s3:ReplicateDelete",
            "s3:ReplicateObject",
            "s3:ReplicateTags",
            "s3:List*",
            "s3:GetEncryptionConfiguration"
          ],
          "Resource" : [
            "${aws_s3_bucket.destination_bucket.arn}",
            "${aws_s3_bucket.destination_bucket.arn}/*"
          ],
          "Condition" : {
            "ArnLike" : {
              "aws:PrincipalARN" : "${aws_iam_role.replication_role.arn}"
            }
          }
        }
      ]
    }
  )
}


# # Iam role in the management account
resource "aws_iam_role" "replication_role" {
  provider = aws.master-account
  name     = var.iam_replication_role_name
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : [
              "s3.amazonaws.com",
              "batchoperations.s3.amazonaws.com"
            ]
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "replication_policy" {
  provider = aws.master-account
  name     = var.iam_replication_policy_name
  policy = jsonencode(
    {
      "Statement" : [
        {
          "Action" : [
            "s3:GetObjectLegalHold",
            "s3:GetObjectRetention",
            "s3:GetObjectVersion",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersionTagging",
            "s3:GetReplicationConfiguration",
            "s3:ListBucket",
            "s3:ReplicateDelete",
            "s3:ReplicateObject",
            "s3:ReplicateTags",
            "s3:InitiateReplication",
            "s3:GetObject",
            "s3:PutObject",
            "s3:GetBucketVersioning",
            "s3:ObjectOwnerOverrideToBucketOwner",
            "s3:PutBucketVersioning",
            "s3:PutInventoryConfiguration"
          ],
          "Effect" : "Allow",
          "Resource" : [
            "${aws_s3_bucket.cur_export_bucket.arn}",
            "${aws_s3_bucket.cur_export_bucket.arn}/*",
            "${aws_s3_bucket.destination_bucket.arn}",
            "${aws_s3_bucket.destination_bucket.arn}/*"
          ]
        },
        {
          "Action" : [
            "kms:Decrypt",
            "kms:Encrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:CreateGrant"
          ],
          "Effect" : "Allow",
          "Resource" : ["${data.aws_kms_key.master_account_key_by_alias.arn}",
          "${data.aws_kms_key.operations_account_key_by_alias.arn}"]
        }
      ],
      "Version" : "2012-10-17"
    }
  )
}

resource "aws_iam_role_policy_attachment" "replication_role_policy_attachment" {
  provider   = aws.master-account
  role       = aws_iam_role.replication_role.name
  policy_arn = aws_iam_policy.replication_policy.arn
}

# # Resource to add replication rule to that bucket
resource "aws_s3_bucket_replication_configuration" "replication" {
  provider   = aws.master-account
  depends_on = [aws_s3_bucket_versioning.cur_export_bucket_versioning]
  bucket     = aws_s3_bucket.cur_export_bucket.id
  role       = aws_iam_role.replication_role.arn

  rule {
    id     = "cur-replication-to-operations"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.destination_bucket.arn
      storage_class = "STANDARD"
      account       = var.operations_account_id

      encryption_configuration {
        replica_kms_key_id = data.aws_kms_key.operations_account_key_by_alias.arn # Update this with your destination KMS key ARN
      }
      access_control_translation {
        owner = "Destination"
      }

    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }

    }
  }
}
