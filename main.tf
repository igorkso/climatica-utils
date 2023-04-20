# Inicializando o terraform e indicando o provider do libvirt

terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.7.1"
    }
  }
}

provider "libvirt" {
   uri = "qemu:///system" #destino da vm
}


# Criando o volume onde todas as vms serão conectadas

resource "libvirt_volume" "sda" {
  name    = "${var.VOL_NAME}_${var.vms}"
  pool    = "${var.POOL_NAME}"
  source  = "${var.IMG_SOURCE}"
  format  = "qcow2"
}


resource "libvirt_volume" "ubuntu-qcow2-resized" {

  name           = "${var.VOL_NAME}_${var.vms}-resized.qcow2"
  pool           = "${var.POOL_NAME}"
  base_volume_id = libvirt_volume.sda.id
  size           = var.disk
  
}


data "template_file" "user_data" {
  
  template = templatefile("${path.module}/templates/cloud_init.tpl", {
  hostname = var.vms
  })

}

resource "libvirt_cloudinit_disk" "cloud_init" {
  name      = "commoninit_${var.vms}.iso"
  pool      = "${var.POOL_NAME}"
  user_data = "${data.template_file.user_data.rendered}"
}

resource "libvirt_domain" "ubuntu" {
  name   = "${var.vms}"
  memory = "${var.MEMORY_SIZE}"
  vcpu   = "${var.VCPU_SIZE}"
  #host = "{var.vms}"  


  network_interface {
    network_name = "default"
    hostname     = "${var.vms}"
  }

  disk {
    volume_id = libvirt_volume.ubuntu-qcow2-resized.id
  }

  cloudinit = "${libvirt_cloudinit_disk.cloud_init.id}"

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}



