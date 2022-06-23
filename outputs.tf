output "zones" {
  value = data.huaweicloud_availability_zones.this.names
}

output "mysql" {
  value = huaweicloud_rds_instance.this.0.public_ips
}