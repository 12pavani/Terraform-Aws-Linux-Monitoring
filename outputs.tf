output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.web.public_ip
}

output "website_url" {
  description = "URL of the Nginx page served by the instance"
  value       = "http://${aws_instance.web.public_ip}"
}

output "sns_topic_arn" {
  description = "SNS topic that receives alarm notifications"
  value       = aws_sns_topic.alerts.arn
}

output "ssm_session_command" {
  description = "Command to open a shell on the instance without SSH"
  value       = "aws ssm start-session --target ${aws_instance.web.id} --region ${var.aws_region}"
}
