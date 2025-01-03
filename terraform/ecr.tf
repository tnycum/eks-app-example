resource "aws_ecr_repository" "hello-world-go" {
    name = "hello-world-go"
    image_tag_mutability = "IMMUTABLE"

    force_delete = true

    image_scanning_configuration {
      scan_on_push = true
    }
}