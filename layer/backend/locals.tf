# Backend Layer - Local Variables

locals {
  common_tags = {
    Environment = var.environment
    Layer      = "backend"
  }
}