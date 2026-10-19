resource "aws_s3_bucket" "test-cicd" {
  bucket = var.AWS_s3_Name
  tags = {
    Name        = "cicd_project"
    Environment = "lab"
    ManagedBY   = "Terrafom"
  }
}

