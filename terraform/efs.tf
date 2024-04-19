# https://cloud.redhat.com/experts/rosa/aws-efs/

resource "aws_iam_policy" "rosa_efs_csi_policy_iam" {
  name        = "${var.cluster_name}-rosa-efs-csi"
  path        = "/"
  description = "AWS EFS CSI Driver Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "elasticfilesystem:TagResource",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:CreateAccessPoint"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:RequestTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:DeleteAccessPoint",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/efs.csi.aws.com/cluster" = "true"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "rosa_efs_csi_role_iam" {
  name = "${var.cluster_name}-rosa-efs-csi-role-iam"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_config_id
        }
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${var.oidc_config_id}:sub" = [
              "system:serviceaccount:openshift-cluster-csi-drivers:aws-efs-csi-driver-operator",
              "system:serviceaccount:openshift-cluster-csi-drivers:aws-efs-csi-driver-controller-sa"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rosa_efs_csi_role_iam_attachment" {
  role       = aws_iam_role.rosa_efs_csi_role_iam.name
  policy_arn = aws_iam_policy.rosa_efs_csi_policy_iam.arn
}
