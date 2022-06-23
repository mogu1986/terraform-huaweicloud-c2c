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

module "c2c" {
  source = "../"

  region = "cn-north-4"

  myip = "220.249.82.10/32"

  // VPC Vars
  vpc_name        = "c2c"
  vpc_description = "上海老干妈有限公司"
  subnet_name     = "c2c-subnet"

  // MySQL Vars
  rds_create     = true
  rds_name       = "c2c-mysql"
  rds_db_version = "5.7"
  rds_password   = "Huangwei@120521"

  // Redis Vars
  dcs_create   = false
  dcs_name     = "c2c-redis"
  dcs_capacity = 1
  dcs_password = "Huangwei@120521"
  dcs_whitelists = [
    {
      group_name = "test-group1"
      ip_address = ["192.168.10.0/16"]
    }
  ]

  // Mongodb Vars
  dds_create   = false
  dds_name     = "c2c-mongodb"
  dds_password = "Huangwei@120521"

  // RabbitMQ Vars
  rabbitmq_create = false
  rabbitmq_name   = "c2c"
  rabbitmq_password = "Huangwei@120521"

  // Elasticsearch Vars
  css_create = false
  css_name = "c2c_es"

  // CCE Vars
  cce_create = true
  cce_cluster_name = "c2c-cce"
  cce_nodepool_name = "c2c-pool"

}