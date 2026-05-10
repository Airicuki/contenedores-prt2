variable "aws_region" {
  default = "us-east-1"
}

variable "key_name" {
  description = "Nombre de la clave SSH de AWS"
}

variable "github_repo" {
  description = "Repositorio GitHub del proyecto"
}