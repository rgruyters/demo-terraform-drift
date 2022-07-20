output "demo_instances_ips" {
  value = aws_instance.demo_instance.*.public_ip
}
