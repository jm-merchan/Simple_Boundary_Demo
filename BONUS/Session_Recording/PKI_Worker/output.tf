output "upstreamWorker_publicIP" {
  value = aws_instance.boundary_upstream_worker.public_ip
}

output "upstreamWorker_publicFQDN" {
  value = aws_instance.boundary_upstream_worker.public_dns
}

output "internal-target_privateIP" {
  value = aws_instance.internal_target.private_ip
}
