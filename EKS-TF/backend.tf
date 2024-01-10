terraform {
  backend "s3" {
    bucket = "awsbucketmrunmay" # Replace with your actual S3 bucket name
    region = "ap-south-1"
  }
}
