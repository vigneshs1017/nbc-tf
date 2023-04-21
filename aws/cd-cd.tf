##### IAM ROle #########
resource "aws_iam_role" "codebuild-role" {
  name = "codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "codebuild.amazonaws.com",
            "codepipeline.amazonaws.com"
          ]
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "codebuild-policy" {
  role = "${aws_iam_role.codebuild-role.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["codecommit:GitPull"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
        "ecr:UploadLayerPart"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
        "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
        "s3:GetBucketLocation"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.name}-codepipeline_role"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS", "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role", "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"]



 assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
           "*"
        ],
        "Resource": [
          "${aws_s3_bucket.bucket-artifact.arn}",
          "${aws_s3_bucket.bucket-artifact.arn}/*"
        ]
      },
      {
        "Effect": "Allow",
        "Resource": [
                "arn:aws:codecommit:${var.aws_region}:${var.account_id}:*"
            ],
        "Action": [
                "*"
            ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "cloudfront:*",
          "codedeploy:*",
          "ecr:*",
          "ecs:*"
        ],
        "Resource": "*"
      }
    ]
  }
 POLICY
}


data "aws_iam_role" "ecs-task" {
  name = "ecsTaskExecutionRole"
}

##### IAM ROle #########

########## Code Build ########
resource "aws_codebuild_project" "repo-project" {
  name         = "${var.name}-build"
  service_role = "${aws_iam_role.codebuild-role.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type     = "CODECOMMIT"
    location = var.repo_name
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
}
########## Code Build ########

########## Code Pipeline ##############
resource "aws_codepipeline" "pipeline" {
  name     = "pipeline"
  role_arn = "${aws_iam_role.codepipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.bucket-artifact.bucket}"
    type     = "S3"
  }
  # SOURCE
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = "${var.repo_name}"
        BranchName     = "${var.branch_name}"
      }
    }
  }
  # BUILD
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = "${var.name}-build"
      }
    }
  }
  # DEPLOY
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.aws-ecs-cluster.name
        ServiceName = aws_ecs_service.aws-ecs-service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
########## Code Pipeline ##############