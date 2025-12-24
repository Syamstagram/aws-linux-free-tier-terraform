# Outputs for AWS Free Tier Linux EC2 Instance

output "instance_details" {
  description = "Complete instance information"
  value = {
    instance_id       = aws_instance.linux_free_tier.id
    instance_type     = aws_instance.linux_free_tier.instance_type
    ami_id           = aws_instance.linux_free_tier.ami
    public_ip        = aws_instance.linux_free_tier.public_ip
    private_ip       = aws_instance.linux_free_tier.private_ip
    public_dns       = aws_instance.linux_free_tier.public_dns
    availability_zone = aws_instance.linux_free_tier.availability_zone
    vpc_id           = data.aws_vpc.default.id
    subnet_id        = aws_instance.linux_free_tier.subnet_id
    security_groups  = aws_instance.linux_free_tier.vpc_security_group_ids
  }
}

output "connection_info" {
  description = "Connection information"
  value = {
    ssh_command      = "ssh ec2-user@${aws_instance.linux_free_tier.public_ip}"
    ssh_with_key     = var.public_key_path != "" ? "ssh -i ~/.ssh/your-key ec2-user@${aws_instance.linux_free_tier.public_ip}" : "Use EC2 Instance Connect"
    http_url         = "http://${aws_instance.linux_free_tier.public_ip}"
    https_url        = "https://${aws_instance.linux_free_tier.public_ip}"
    custom_app_url   = "http://${aws_instance.linux_free_tier.public_ip}:${var.custom_port}"
  }
}

output "monitoring_info" {
  description = "Monitoring and logging information"
  value = {
    cloudwatch_log_group = aws_cloudwatch_log_group.instance_logs.name
    cpu_alarm           = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
    status_alarm        = aws_cloudwatch_metric_alarm.instance_status_check.alarm_name
  }
}

output "aws_console_links" {
  description = "AWS Console links for easy access"
  value = {
    ec2_instance = "https://console.aws.amazon.com/ec2/v2/home?region=${var.aws_region}#Instances:search=${aws_instance.linux_free_tier.id}"
    cloudwatch   = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#alarmsV2:alarm/${aws_cloudwatch_metric_alarm.high_cpu.alarm_name}"
    logs         = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.instance_logs.name, "/", "%2F")}"
  }
}