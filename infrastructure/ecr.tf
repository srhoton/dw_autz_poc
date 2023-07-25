resource "aws_ecr_repository" "authz-poc_repository" {
  name = "authz-poc_repository"
  tags = {
    Name = "authz-poc_repository"
  }
}
