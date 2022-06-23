terraform {

  required_version = ">= 0.14"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "1.37.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }
  }
}

provider "huaweicloud" {
  region = var.region
}