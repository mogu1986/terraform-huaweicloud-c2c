# terraform-alicloud-redis

#### 介绍
**alicloud redis module**

#### 软件架构
软件架构说明


#### 安装教程

1.  install Terraform
2.  deploy ak(aliyun)
3.  terraform apply

#### 使用说明

```json
provider "alicloud" {
  profile = "default"
  version = "1.151.0"
}

variable "name" {
  default = "redis"
}

data "alicloud_zones" "default" {
  available_resource_creation = "KVStore"
}

resource "alicloud_vpc" "default" {
  vpc_name       = var.name
  cidr_block = "172.16.0.0/16"
}

resource "alicloud_vswitch" "default" {
  vpc_id       = alicloud_vpc.default.id
  cidr_block   = "172.16.0.0/24"
  zone_id      = data.alicloud_zones.default.zones[0].id
  vswitch_name = var.name
  depends_on = [alicloud_vpc.default]
}

locals {
  dms_group = ["0.0.0.0/0"]
  default_group = ["172.16.0.0/16"]

  instance_name = "redis"

  #################################
  #                               #
  #            databases          #
  #                               #
  #################################

  config = {
    maxmemory-policy  = "volatile-ttl",
    appendonly        = "no",
    notify-keyspace-events        = "Ex"
  }

  accounts = [
    {
      name         = "user1"
      password     = "Test12345"
      privilege = "RoleReadWrite"
      description  = "desp1"
    },
    {
      name         = "user2"
      password     = "Test12345"
      privilege    = "RoleReadOnly"
      description  = "deps2"
    },
    {
      name         = "user3"
      password     = "Test12345"
      privilege    = "RoleRepl"
      description  = "deps3"
    }
  ]

  tags = {
    app = "ebike"
    tenant = "xiaojiu"
    env    = "prod"
  }

}

module "rds" {
  source  = "git@gitee.com:mmbluex/terraform-alicloud-redis.git"

  db_instance_name  = local.instance_name
  vswitch_id     = alicloud_vswitch.default.id
  security_ips   = concat(local.default_group, local.dms_group)
  config         = local.config
  allocate_public_connection = true
  connection_string_prefix = "allocatetestupdate"
  accounts       = local.accounts
  tags           = local.tags
}
```
