locals {


  # Subnets públicas (para ALB, NAT Gateway)
  public_subnet_ids = [
    aws_subnet.public_az1.id,
    aws_subnet.public_az2.id
  ]

  # Subnets privadas (para ECS Fargate, Lambda, Aurora, ElastiCache)
  private_subnet_ids = [
    aws_subnet.private_az1.id,
    aws_subnet.private_az2.id
  ]

  # Availability Zones
  availability_zones = [
    "${var.myregion}a",
    "${var.myregion}b"
  ]

  # Tags comunes para todos los recursos
  common_tags = {
    Project     = "LMS"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}