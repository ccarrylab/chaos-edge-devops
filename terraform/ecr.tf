# Create ECR Repository for the chaos-edge Go application
resource "aws_ecr_repository" "chaos_edge_go" {
  name                 = "chaos-edge-go"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "chaos-edge-go"
    Environment = "production"
  }
}

# Output the ECR repository URI
output "ecr_repository_uri" {
  description = "ECR Repository URI"
  value       = aws_ecr_repository.chaos_edge_go.repository_url
}

output "ecr_repository_name" {
  description = "ECR Repository Name"
  value       = aws_ecr_repository.chaos_edge_go.name
}
