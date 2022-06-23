variable "region" {
  type    = string
  default = "cn-north-4"
}

variable "enterprise_project_id" {
  type    = string
  default = "181906e2-0b75-47d1-8517-158818e6e3e3" // 公司账号、公共资源
}

variable "vpc_name" {
  default = "vpc-basic"
}

variable "vpc_cidr" {
  default = "192.168.0.0/16"
}

variable "myip" {
  default = "127.0.0.1"
}

variable "vpc_tags" {
  type    = map(string)
  default = {}
}

variable "vpc_description" {
  type    = string
  default = "端到端课程"
}

variable "subnet_name" {
  default = "c2c-subent"
}

variable "subnet_tags" {
  type    = map(string)
  default = {}
}

variable "availability_zones" {
  type    = list(string)
  default = null
}

variable "subnet_gateway" {
  default = "192.168.0.1"
}

variable "primary_dns" {
  default = "100.125.1.250"
}

// rds
variable "rds_create" {
  type    = bool
  default = true
}

variable "rds_name" {
  type    = string
  default = ""
}

variable "rds_flavor" {
  type    = string
  default = "rds.mysql.n1.large.2" // 鲲鹏通用增强型
#  default = "rds.mysql.large.arm2.single" // 鲲鹏通用增强型
}

variable "rds_db_type" {
  type    = string
  default = "MySQL"
}

variable "rds_fixed_ip" {
  type    = string
  default = ""
}

variable "rds_db_version" {
  type    = string
  default = "5.7"
}

variable "rds_password" {
  type    = string
  default = ""
}
// redis
variable "dcs_create" {
  type    = bool
  default = false
}

variable "dcs_name" {
  type    = string
  default = ""
}

variable "dcs_engine" {
  type    = string
  default = "redis"
}

variable "dcs_cache_mode" {
  type    = string
  default = "single"
}

variable "dcs_capacity" {
  type    = number
  default = 1
}

variable "dcs_engine_version" {
  type    = string
  default = "5.0"
}

variable "dcs_password" {
  type    = string
}

variable "dcs_whitelists" {
  #  type = list(map(string))
  default = []
}

variable "dcs_description" {
  type    = string
  default = ""
}

// dds
variable "dds_create" {
  type    = bool
  default = false
}

variable "dds_name" {
  type    = string
  default = ""
}

variable "dds_password" {
  type    = string
  default = ""
}

// RabbitMQ
variable "rabbitmq_create" {
  type    = bool
  default = false
}
variable "rabbitmq_name" {
  type = string
  default = ""
}

variable "rabbitmq_access_user" {
  type = string
  default = "root"
}

variable "rabbitmq_password" {
  type = string
}

// Elasticsearch
variable "css_create" {
  type = bool
  default = false
}

variable "css_name" {
  type    = string
  default = ""
}

variable "css_engine_version" {
  type    = string
  default = "7.9.3"
}

variable "css_flavor" {
  type    = string
  default = "ess.spec-kc1.xlarge.2"
}

variable "css_expect_node_num" {
  type    = number
  default = 1
}

variable "css_volume_type" {
  type    = string
  default = "HIGH"
}

variable "css_volume_size" {
  type    = number
  default = 40
}

// CCE
variable "cce_create" {
  type = bool
  default = false
}

variable "cce_bandwidth_name" {
  default = "c2c-cce"
}

variable "cce_cluster_name" {
  type = string
  default = ""
}

variable "cce_cluster_version" {
  type = string
  default = "v1.23"
}

variable "cce_cluster_flavor" {
  type = string
  default = "cce.s1.small"
}

variable "cce_nodepool_name" {
  type = string
  default = "c2c-pool"
}

variable "cce_nodepool_os" {
  type = string
  default = "EulerOS 2.9"
}

variable "cce_nodepool_flavor" {
  type = string
  default = "c7.large.2"
}