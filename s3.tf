resource "aws_s3_bucket" "mySourceBucket" {
  bucket = "my-source-bucket-76sdf700-asd"
}

resource "aws_s3_bucket_ownership_controls" "bucketOwnerControls" {
  bucket = aws_s3_bucket.mySourceBucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "accessBlock" {
  bucket = aws_s3_bucket.mySourceBucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

}

resource "aws_s3_bucket_acl" "bucketAcl" {
  bucket = aws_s3_bucket.mySourceBucket.id
  acl    = "public-read"
  depends_on = [
    aws_s3_bucket_ownership_controls.bucketOwnerControls,
    aws_s3_bucket_public_access_block.accessBlock
  ]
}
