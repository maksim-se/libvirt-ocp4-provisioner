# variables that can be overriden
variable "hostname" { default = "worker" }
variable "memory" { default = 32 }
variable "cpu" { default = 10 }
variable "vm_count" { default = 3 }
variable "libvirt_network" { default = "ocp_auto" }
variable "libvirt_pool" { default = "default" }
variable "vm_volume_size" { default = 20 }
variable "ocs_disk1_size" { default = 10 }
variable "ocs_disk2_size" { default = 150 }

# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "os_image" {
  count = var.vm_count
  name = "${var.hostname}-os_image-${count.index}"
  pool = var.libvirt_pool
  size =  var.vm_volume_size*1073741824
  format = "qcow2"
}

resource "libvirt_volume" "storage1_image" {
  count= var.vm_count
  name = "${var.hostname}-storage_image-${count.index}"
  pool = var.libvirt_pool
  size = var.ocs_disk1_size*1073741824
  format = "qcow2"
}

resource "libvirt_volume" "storage2_image" {
  count= var.vm_count
  name = "${var.hostname}-storage2_image-${count.index}"
  pool = var.libvirt_pool
  size = var.ocs_disk2_size*1073741824
  format = "qcow2"
}

# Create the machine
resource "libvirt_domain" "worker" {
  count = var.vm_count
  name = "${var.hostname}-${count.index}"
  memory = var.memoryMB*1024
  vcpu = var.cpu

  cpu = {
    mode = "host-passthrough"
  }

  disk {
     volume_id = libvirt_volume.os_image[count.index].id
  }
  disk {
     volume_id = libvirt_volume.storage1_image[count.index].id
  }
  disk  {
     volume_id = libvirt_volume.storage2_image[count.index].id
  }

  network_interface {
       network_name = var.libvirt_network
  }

  boot_device {
    dev = [ "hd", "network" ]
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }
}

terraform { 
  required_version = ">= 0.12"
}

output "macs" {
  value = "${flatten(libvirt_domain.worker.*.network_interface.0.mac)}"
}

