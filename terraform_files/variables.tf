variable "libvirt_uri" {
  description = "Libvirt connection URI"
  type        = string
  default     = "qemu:///system"
}

variable "pool_name" {
  description = "Storage pool name"
  type        = string
  default     = "k3s-pool"
}

variable "base_image_path" {
  description = "Path to base Ubuntu image"
  type        = string
  default     = "/mnt/k3s-storage/jammy-server-cloudimg-amd64.img"
}

variable "master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 3
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "master_memory" {
  description = "Memory for master nodes in MB"
  type        = number
  default     = 2048
}

variable "master_vcpu" {
  description = "vCPUs for master nodes"
  type        = number
  default     = 2
}

variable "worker_memory" {
  description = "Memory for worker nodes in MB"
  type        = number
  default     = 3072
}

variable "worker_vcpu" {
  description = "vCPUs for worker nodes"
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "OS disk size in bytes (default 15GB)"
  type        = number
  default     = 15212254720
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "network_name" {
  description = "Libvirt network name"
  type        = string
  default     = "default"
}

variable "enable_longhorn" {
  description = "Enable additional storage volumes for Longhorn"
  type        = bool
  default     = true
}

variable "longhorn_disk_size" {
  description = "Additional disk size for Longhorn storage (default 50GB)"
  type        = number
  default     = 53687091200
}

variable "enable_load_balancer" {
  description = "Deploy dedicated load balancer VM"
  type        = bool
  default     = true
}

# Static IP configuration
variable "lb_ip" {
  description = "Static IP for load balancer"
  type        = string
  default     = "192.168.122.100"
}

variable "master_ips" {
  description = "Static IPs for master nodes"
  type        = list(string)
  default     = ["192.168.122.11", "192.168.122.12", "192.168.122.10"]
}

variable "worker_ips" {
  description = "Static IPs for worker nodes"
  type        = list(string)
  default     = ["192.168.122.20", "192.168.122.21", "192.168.122.22"]
}
