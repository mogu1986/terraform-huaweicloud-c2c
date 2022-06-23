data "huaweicloud_availability_zones" "this" {
}

data "huaweicloud_images_image" "this" {
  most_recent = true
}

locals {
  welink = "gw"

  availability_zones = data.huaweicloud_availability_zones.this.names
  subnet_cidrs       = [for i, v in data.huaweicloud_availability_zones.this.names : format("192.168.%d.0/20", 16 * i)]
  subnet_gateways    = [for i, v in data.huaweicloud_availability_zones.this.names : format("192.168.%d.1", 16 * i)]
}

resource "huaweicloud_vpc" "this" {
  name                  = var.vpc_name
  cidr                  = var.vpc_cidr
  tags                  = var.vpc_tags
  description           = var.vpc_description
  enterprise_project_id = var.enterprise_project_id
}

resource "huaweicloud_vpc_subnet" "this" {
  count  = length(local.availability_zones) > 0 ? length(local.availability_zones) : 0

  name              = format("%s-%01d", var.subnet_name, count.index + 1)
  availability_zone = element(local.availability_zones, count.index)
  cidr              = element(local.subnet_cidrs, count.index)
  gateway_ip        = element(local.subnet_gateways, count.index)
  tags              = var.subnet_tags

  vpc_id = huaweicloud_vpc.this.id

  depends_on = [huaweicloud_vpc.this]
}

// 安全、ssh凭证
resource "huaweicloud_compute_keypair" "this" {
  name       = format("%s-terraform", local.welink)
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEsG8+9oGzomG9sI2Mlv/rzZ8UCPtw7havcbKGPtHaX5PFeNTxAOCzJrhuuc6VjSeqVQVSQfFeeCidQaq+9avwm2yC2n80ScFoMyP7iy/oxmptJ5encT6cSTn+KrkVycIBswxyT7dl8vJo0IngXNPqF/ORppK4gjTxGxF/cS/wAE7/6zpqLMydTjUT2PSU+DV2FJ8WyzYxfEXfIyrdM+s67BeEktDAHv4aOFFWbVgB9TefmV0O/xGtOyRJ0FQsYQ+xntGPUdilulpfTioRegkEn/BR36tXNPr9lVY7IuXcJ867AqKxyNs4LMIW4GMUIKVwTjAPx8xiuTs2Z5CrUXCB ops@xiaoan.local"
}

// 安全组白名单
resource "huaweicloud_vpc_address_group" "this" {
  name = format("%s-group-test", local.welink)
  addresses = [
    "192.168.10.10",
    "192.168.1.1-192.168.1.50"
  ]
}

resource "huaweicloud_networking_secgroup" "this" {
  name                  = format("%s-secgroup_1", local.welink)
  description           = "My security group"
  enterprise_project_id = var.enterprise_project_id
}

resource "huaweicloud_networking_secgroup_rule" "this" {
  security_group_id = huaweicloud_networking_secgroup.this.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = "80,443"
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "mysql" {
  security_group_id = huaweicloud_networking_secgroup.this.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  ports             = "3306"
  remote_ip_prefix  = var.myip
}

resource "huaweicloud_vpc_eip" "mysql" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "mysql"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
  enterprise_project_id = var.enterprise_project_id
  depends_on = [huaweicloud_vpc_subnet.this]
}

// 1. rds
resource "huaweicloud_rds_instance" "this" {
  count             = var.rds_create ? 1 : 0
  name              = var.rds_name
  flavor            = var.rds_flavor
  vpc_id            = huaweicloud_vpc.this.id
  subnet_id         = huaweicloud_vpc_subnet.this.0.id
  security_group_id = huaweicloud_networking_secgroup.this.id
  availability_zone = [
    data.huaweicloud_availability_zones.this.names[0]
  ]

  fixed_ip = var.rds_fixed_ip != "" ? var.rds_fixed_ip : null

  db {
    type     = var.rds_db_type
    version  = var.rds_db_version
    password = var.rds_password
  }
  volume {
    type = "CLOUDSSD"
    size = 40
  }
  backup_strategy {
    start_time = "03:00-04:00"
    keep_days  = 1
  }

  enterprise_project_id = var.enterprise_project_id

  depends_on = [huaweicloud_vpc_subnet.this]
}

data "huaweicloud_networking_port" "rds_port" {
  network_id = huaweicloud_vpc_subnet.this.0.id
  fixed_ip   = huaweicloud_rds_instance.this.0.private_ips[0]
}

resource "huaweicloud_networking_eip_associate" "this" {
  public_ip = huaweicloud_vpc_eip.mysql.address
  port_id   = data.huaweicloud_networking_port.rds_port.id
}

resource "null_resource" "setup_db" {

  provisioner "local-exec" {
    command = <<EOF
        mysql -u root -p${var.rds_password} -h ${huaweicloud_vpc_eip.mysql.address} < mall.sql
    EOF
  }

  depends_on = [huaweicloud_networking_eip_associate.this]
}

// 2. redis dcs
data "huaweicloud_dcs_flavors" "single_flavors" {
  cache_mode = var.dcs_cache_mode
  capacity   = var.dcs_capacity
}

resource "huaweicloud_dcs_instance" "this" {
  count = var.dcs_create ? 1 : 0

  name           = var.dcs_name
  engine         = var.dcs_engine
  engine_version = var.dcs_engine_version
  capacity       = data.huaweicloud_dcs_flavors.single_flavors.capacity
  flavor         = data.huaweicloud_dcs_flavors.single_flavors.flavors[0].name

  availability_zones = [
    data.huaweicloud_dcs_flavors.single_flavors.flavors[0].available_zones.0
  ]

  vpc_id        = huaweicloud_vpc.this.id
  subnet_id     = huaweicloud_vpc_subnet.this.0.id
  password      = var.dcs_password
  charging_mode = "postPaid"

  #  whitelists {
  #    group_name = "test-group1"
  #    ip_address = ["192.168.10.100", "192.168.0.0/24"]
  #  }

  #  dynamic "whitelists" {
  #    for_each       = var.dcs_whitelists
  #    content {
  #      group_name = lookup(whitelists.value, "group_name")
  #      ip_address = lookup(whitelists.value, "ip_address")
  #    }
  #  }

  description           = var.dcs_description
  enterprise_project_id = var.enterprise_project_id
  depends_on = [huaweicloud_vpc_subnet.this]
}

// MongoDB
resource "huaweicloud_dds_instance" "this" {
  count = var.dds_create ? 1 : 0

  name = var.dds_name

  datastore {
    type           = "DDS-Community"
    version        = "4.0"
    storage_engine = "wiredTiger"
  }

  availability_zone = data.huaweicloud_availability_zones.this.names[0]
  vpc_id            = huaweicloud_vpc.this.id
  subnet_id         = huaweicloud_vpc_subnet.this.0.id
  security_group_id = huaweicloud_networking_secgroup.this.id
  password          = var.dds_password
  mode              = title("single")

  flavor {
    type      = "single"
    num       = 1
    storage   = "ULTRAHIGH"
    size      = 30
    spec_code = "dds.mongodb.c3.large.2.single"
  }

  enterprise_project_id = var.enterprise_project_id
  depends_on = [huaweicloud_vpc_subnet.this]
}

// RabbitMQ
data "huaweicloud_dms_product" "this" {
  engine        = "rabbitmq"
  instance_type = "single" //
  version       = "3.7.17"
}

resource "huaweicloud_dms_rabbitmq_instance" "this" {
  count = var.rabbitmq_create ? 1 : 0

  name              = var.rabbitmq_name
  product_id        = data.huaweicloud_dms_product.this.id
  engine_version    = data.huaweicloud_dms_product.this.version
  storage_spec_code = data.huaweicloud_dms_product.this.storage_spec_code

  vpc_id            = huaweicloud_vpc.this.id
  network_id        = huaweicloud_vpc_subnet.this.0.id
  security_group_id = huaweicloud_networking_secgroup.this.id

  availability_zones = [
    data.huaweicloud_availability_zones.this.names[0]
  ]

  access_user           = var.rabbitmq_access_user
  password              = var.rabbitmq_password
  enterprise_project_id = var.enterprise_project_id
  depends_on = [huaweicloud_vpc_subnet.this]
}

// Elasticsearch
resource "huaweicloud_css_cluster" "this" {
  count = var.css_create ? 1: 0

  expect_node_num = var.css_expect_node_num
  name            = var.css_name
  engine_version  = var.css_engine_version

  node_config {
    flavor            = var.css_flavor
    availability_zone = data.huaweicloud_availability_zones.this.names[0]

    network_info {
      security_group_id = huaweicloud_networking_secgroup.this.id
      subnet_id         = huaweicloud_vpc_subnet.this.0.id
      vpc_id            = huaweicloud_vpc.this.id
    }

    volume {
      volume_type = var.css_volume_type
      size        = var.css_volume_size
    }
  }

  enterprise_project_id = var.enterprise_project_id
  depends_on = [huaweicloud_vpc_subnet.this]
}

resource "huaweicloud_vpc_eip" "this" {
  count = var.cce_create ? 1 : 0

  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = var.cce_bandwidth_name
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
  enterprise_project_id = var.enterprise_project_id
  depends_on = [huaweicloud_vpc_subnet.this]
}

resource "huaweicloud_cce_cluster" "this" {
  count = var.cce_create ? 1 : 0
  name                   = var.cce_cluster_name
  flavor_id              = var.cce_cluster_flavor
  cluster_version        = var.cce_cluster_version
  vpc_id                 = huaweicloud_vpc.this.id
  subnet_id              = huaweicloud_vpc_subnet.this.0.id
  container_network_type = "overlay_l2"
  eip                    = huaweicloud_vpc_eip.this[0].address
  enterprise_project_id = var.enterprise_project_id
  depends_on = [huaweicloud_vpc_subnet.this, huaweicloud_vpc_eip.this]
}

resource "huaweicloud_cce_node_pool" "node_pool" {
  cluster_id               = huaweicloud_cce_cluster.this.0.id
  name                     = var.cce_nodepool_name
  os                       = var.cce_nodepool_os
  initial_node_count       = 1
  flavor_id                = var.cce_nodepool_flavor
  key_pair                 = huaweicloud_compute_keypair.this.id
  scall_enable             = true
  min_node_count           = 1
  max_node_count           = 10
  scale_down_cooldown_time = 100
  priority                 = 1
  type                     = "vm"

  root_volume {
    size       = 40
    volumetype = "SAS"
  }
  data_volumes {
    size       = 100
    volumetype = "SAS"
  }
}

resource "huaweicloud_cce_addon" "addon_test" {
  cluster_id    = huaweicloud_cce_cluster.this.0.id
  template_name = "metrics-server"
  version       = "1.0.0"
}
