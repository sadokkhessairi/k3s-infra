output "master_ips" {
  description = "Static IP addresses of master nodes"
  value = {
    for idx in range(var.master_count) :
    "k3s-master-${idx}" => var.master_ips[idx]
  }
}

output "worker_ips" {
  description = "Static IP addresses of worker nodes"
  value = {
    for idx in range(var.worker_count) :
    "k3s-worker-${idx}" => var.worker_ips[idx]
  }
}

output "lb_ip" {
  description = "Static IP address of load balancer"
  value = var.enable_load_balancer ? {
    "k3s-lb" = var.lb_ip
  } : {}
}

output "all_ips" {
  description = "All node static IPs"
  value = merge(
    {
      for idx in range(var.master_count) :
      "k3s-master-${idx}" => var.master_ips[idx]
    },
    {
      for idx in range(var.worker_count) :
      "k3s-worker-${idx}" => var.worker_ips[idx]
    },
    var.enable_load_balancer ? {
      "k3s-lb" = var.lb_ip
    } : {}
  )
}

output "k3s_api_endpoint" {
  description = "Kubernetes API endpoint"
  value = var.enable_load_balancer ? "https://${var.lb_ip}:6443" : "https://${var.master_ips[0]}:6443"
}

output "longhorn_enabled" {
  description = "Whether Longhorn storage volumes are provisioned"
  value       = var.enable_longhorn
}
