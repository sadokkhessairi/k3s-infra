terraform {
  required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.1"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

# Base OS image
resource "libvirt_volume" "os_image" {
  name   = "ubuntu-22.04-base"
  pool   = var.pool_name
  source = var.base_image_path
  format = "qcow2"
}

# Cloud-init user data
data "template_file" "user_data" {
  template = file("${path.module}/files/cloud_init.yaml")
  vars = {
    ssh_public_key = file(pathexpand(var.ssh_public_key_path))
  }
}

# ========================================
# MASTER NODES
# ========================================

# Master OS volumes
resource "libvirt_volume" "master" {
  count          = var.master_count
  name           = "k3s-master-${count.index}.qcow2"
  base_volume_id = libvirt_volume.os_image.id
  pool           = var.pool_name
  size           = var.disk_size
}

# Cloud-init for masters
resource "libvirt_cloudinit_disk" "master" {
  count     = var.master_count
  name      = "cloudinit-master-${count.index}.iso"
  pool      = var.pool_name
  user_data = data.template_file.user_data.rendered
  meta_data = templatefile("${path.module}/files/meta_data.yaml", {
    hostname = "k3s-master-${count.index}"
  })
}

# Master domains
resource "libvirt_domain" "master" {
  count  = var.master_count
  name   = "k3s-master-${count.index}"
  memory = var.master_memory
  vcpu   = var.master_vcpu

  cloudinit = libvirt_cloudinit_disk.master[count.index].id

  network_interface {
    network_name   = var.network_name
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.master[count.index].id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# ========================================
# WORKER NODES
# ========================================

# Worker OS volumes
resource "libvirt_volume" "worker" {
  count          = var.worker_count
  name           = "k3s-worker-${count.index}.qcow2"
  base_volume_id = libvirt_volume.os_image.id
  pool           = var.pool_name
  size           = var.disk_size
}

# Additional storage volumes for Longhorn (one per worker)
resource "libvirt_volume" "worker_storage" {
  count  = var.enable_longhorn ? var.worker_count : 0
  name   = "k3s-worker-${count.index}-storage.qcow2"
  pool   = var.pool_name
  size   = var.longhorn_disk_size
  format = "qcow2"
}

# Cloud-init for workers
resource "libvirt_cloudinit_disk" "worker" {
  count     = var.worker_count
  name      = "cloudinit-worker-${count.index}.iso"
  pool      = var.pool_name
  user_data = data.template_file.user_data.rendered
  meta_data = templatefile("${path.module}/files/meta_data.yaml", {
    hostname = "k3s-worker-${count.index}"
  })
}

# Worker domains
resource "libvirt_domain" "worker" {
  count  = var.worker_count
  name   = "k3s-worker-${count.index}"
  memory = var.worker_memory
  vcpu   = var.worker_vcpu

  cloudinit = libvirt_cloudinit_disk.worker[count.index].id

  network_interface {
    network_name   = var.network_name
    wait_for_lease = true
  }

  # OS disk
  disk {
    volume_id = libvirt_volume.worker[count.index].id
  }

  # Additional storage disk for Longhorn
  dynamic "disk" {
    for_each = var.enable_longhorn ? [1] : []
    content {
      volume_id = libvirt_volume.worker_storage[count.index].id
    }
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# ========================================
# LOAD BALANCER 
# ========================================

# HAProxy/LB volume
resource "libvirt_volume" "lb" {
  count          = var.enable_load_balancer ? 1 : 0
  name           = "k3s-lb.qcow2"
  base_volume_id = libvirt_volume.os_image.id
  pool           = var.pool_name
  size           = 10737418240 # 10GB
}

# Cloud-init for LB
resource "libvirt_cloudinit_disk" "lb" {
  count     = var.enable_load_balancer ? 1 : 0
  name      = "cloudinit-lb.iso"
  pool      = var.pool_name
  user_data = data.template_file.user_data.rendered
  meta_data = templatefile("${path.module}/files/meta_data.yaml", {
    hostname = "k3s-lb"
  })
}

# Load Balancer domain
resource "libvirt_domain" "lb" {
  count  = var.enable_load_balancer ? 1 : 0
  name   = "k3s-lb"
  memory = 1024
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.lb[0].id

  network_interface {
    network_name   = var.network_name
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.lb[0].id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
