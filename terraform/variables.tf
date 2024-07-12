variable "resource_group_name" {
  default = "asy-github-proxy"
}

variable "location" {
  default = "West Europe"
}

variable "app_service_plan_name" {
  default = "git-proxy-appserviceplan"
}

variable "app_service_name" {
  default = "git-proxy-appservice"
}

variable "acr_name" {
  default = "gitproxyacr"
}

variable "acr_repository" {
  default = "yourrepository"
}

variable "acr_tag" {
  description = "The tag of the ACR image"
}

