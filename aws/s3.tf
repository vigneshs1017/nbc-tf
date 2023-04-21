resource "aws_s3_bucket" "bucket-artifact" {
  bucket = "nbcappdemo"
  acl    = "private"
}