# https://cloud.redhat.com/experts/rosa/aws-efs/

data "aws_caller_identity" "current" {}

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
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${module.rhcs_cluster_rosa_hcp.oidc_config_id}"
        }
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${module.rhcs_cluster_rosa_hcp.oidc_config_id}:sub" = [
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

resource "aws_efs_file_system" "rosa_efs" {
  creation_token = "efs-token-1"
  encrypted      = true

  tags = {
    Name = "${var.cluster_name}-rosa-efs"
  }
}

# resource "aws_efs_mount_target" "efs_mount_pool_1" {
#   file_system_id = aws_efs_file_system.rosa_efs.id
#   subnet_id      = data.rhcs_hcp_machine_pool.hcp_mcp_pool_1.subnet_id
#   ##security_groups = [aws_security_group.ec2_security_group.id]
#   depends_on = [
#     module.rhcs_cluster_rosa_hcp
#   ]
# }
resource "aws_efs_mount_target" "efs_mount_worker_0" {
  file_system_id = aws_efs_file_system.rosa_efs.id
  subnet_id      = data.rhcs_hcp_machine_pool.hcp_mcp_workers_0.subnet_id
  ##security_groups = [aws_security_group.ec2_security_group.id]
  depends_on = [
    module.rhcs_cluster_rosa_hcp
  ]
}
resource "aws_efs_mount_target" "efs_mount_worker_1" {
  file_system_id = aws_efs_file_system.rosa_efs.id
  subnet_id      = data.rhcs_hcp_machine_pool.hcp_mcp_workers_1.subnet_id
  ##security_groups = [aws_security_group.ec2_security_group.id]
  depends_on = [
    module.rhcs_cluster_rosa_hcp
  ]
}

data "rhcs_hcp_machine_pool" "hcp_mcp_pool_1" {
  cluster = module.rhcs_cluster_rosa_hcp.rosa_cluster_hcp_cluster_id
  name    = "pool1"
  depends_on = [
    module.rhcs_cluster_rosa_hcp
  ]
}

data "rhcs_hcp_machine_pool" "hcp_mcp_workers_0" {
  cluster = module.rhcs_cluster_rosa_hcp.rosa_cluster_hcp_cluster_id
  name    = "workers-0"
  depends_on = [
    module.rhcs_cluster_rosa_hcp
  ]
}

data "rhcs_hcp_machine_pool" "hcp_mcp_workers_1" {
  cluster = module.rhcs_cluster_rosa_hcp.rosa_cluster_hcp_cluster_id
  name    = "workers-1"
  depends_on = [
    module.rhcs_cluster_rosa_hcp
  ]
}
