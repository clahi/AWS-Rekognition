resource "aws_iam_role" "lambdaRole" {
  name = "lambdaRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow"
        "Action" : [
          "sts:AssumeRole"
        ]
        "Principal" : {
          "Service" : [
            "lambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambdaS3Policy" {
  name = "lambdaS3Policy"
  policy = jsonencode({
    Version : "2012-10-17"
    Statement : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        Effect : "Allow"
        Action : [
          "s3:GetObject"
        ]
        Resource : "arn:aws:s3:::my-source-bucket-76sdf700/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:PutItem"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "rekognition:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambdaRolePolicyAttachment" {
  policy_arn = aws_iam_policy.lambdaS3Policy.arn
  roles      = [aws_iam_role.lambdaRole.name]
  name       = "lambdaRolePolicyAttachment"
}

data "archive_file" "lambdaFile" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "autoSpeechRecog" {
  role             = aws_iam_role.lambdaRole.arn
  filename         = data.archive_file.lambdaFile.output_path
  source_code_hash = data.archive_file.lambdaFile.output_base64sha256
  function_name    = "autoSpeechRecog"
  timeout          = 60
  runtime          = "python3.9"
  handler          = "lambda.lambda_handler"

  # environment {
  #   variables = {
  #     DEST_BUCKET = aws_s3_bucket.myDestiBucket.id
  #   }
  # }
}

resource "aws_lambda_permission" "autoSpeechRecogPermission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.autoSpeechRecog.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.mySourceBucket.arn
}

resource "aws_s3_bucket_notification" "bucketNotification" {
  bucket = aws_s3_bucket.mySourceBucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.autoSpeechRecog.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "source/"
  }

  depends_on = [aws_lambda_permission.autoSpeechRecogPermission]
}