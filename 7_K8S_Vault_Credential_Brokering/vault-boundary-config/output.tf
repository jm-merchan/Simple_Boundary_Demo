output "k8s_connect" {
  value = "boundary connect kube -target-id=${var.scenario6_alias}"
}

output "k8s_connect_alias" {
  value = "boundary connect kube ${var.scenario6_alias}"
}


output "k8s_authorize_connect" {
  value = <<-EOF
  eval "$(boundary targets authorize-session -id ${var.scenario6_alias} -format json | jq -r '.item | "export BOUNDARY_SESSION_TOKEN=\(.authorization_token) BOUNDARY_K8S_TOKEN=\(.credentials[0].secret.decoded.service_account_token)"')"
  boundary connect kube ${var.scenario6_alias} -- run my-pod3 --image=nginx -n test --token=$BOUNDARY_K8S_TOKEN --certificate-authority=ca.crt
  
  EOF
}