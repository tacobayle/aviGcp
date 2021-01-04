data "google_compute_zones" "available" {
}

# Mysql server creation

resource "google_compute_instance" "mysql" {
  count = var.mysql.count
  name = "mysql-${count.index + 1 }"
  machine_type = var.mysql.type
  zone = element(data.google_compute_zones.available.names, count.index)
  boot_disk {
    initialize_params {
    image = var.mysql.image
    }
  }
  metadata_startup_script =  file(var.mysql.userdata)
  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.1.id
  }
  metadata  = {
    sshKeys = "ubuntu:${file(var.mysql.key)}"
  }
  labels = {
    group = "mysql"
    created_by = "terraform"
  }
}


resource "google_compute_instance" "backend" {
  count = var.backend.count
  name = "backend-${count.index + 1 }"
  machine_type = var.backend.type
  zone = element(data.google_compute_zones.available.names, count.index)
  boot_disk {
    initialize_params {
    image = var.backend.image
    }
  }
  metadata_startup_script =  file(var.backend.userdata)
  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.1.id
    #access_config {
    #}
  }
  metadata  = {
    sshKeys = "ubuntu:${file(var.backend.key)}"
  }
  labels = {
    group = "backend"
    created_by = "terraform"
  }
}

# opencart server creation

data "template_file" "opencart" {
  template = file(var.opencart.userdata)
  vars = {
    opencartDownloadUrl = var.opencart.opencartDownloadUrl
    domainName = var.avi_gslb.domain
  }
}

resource "google_compute_instance" "opencart" {
  count = var.opencart.count
  name = "opencart-${count.index + 1 }"
  machine_type = var.opencart.type
  zone = element(data.google_compute_zones.available.names, count.index)
  boot_disk {
    initialize_params {
    image = var.opencart.image
    }
  }
  metadata_startup_script =  data.template_file.opencart.rendered
  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.1.id
  }
  metadata  = {
    sshKeys = "ubuntu:${file(var.backend.key)}"
  }
  labels = {
    group = "opencart"
    created_by = "terraform"
  }
}


# Jump server creation

data "template_file" "jump" {
  template = file(var.jump.userdata)
  vars = {
    avisdkVersion = var.jump.avisdkVersion
    ansibleVersion = var.ansible.version
    ansiblePrefixGroup = var.ansible.prefixGroup
    privateKey = var.privateKey
    username = var.jump.username
    ansibleGcpServiceAccount = var.ansible.gcpServiceAccount
    googleProject = var.googleProject
  }
}

resource "google_compute_instance" "jump" {
  name = var.jump.name
  machine_type = var.jump.type
  zone = data.google_compute_zones.available.names[0]
  boot_disk {
    initialize_params {
    image = var.jump.image
    }
  }
  metadata_startup_script =  data.template_file.jump.rendered
  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.0.id
    access_config {
    }
  }
  metadata  = {
    sshKeys = "ubuntu:${file(var.jump.key)}"
  }
  labels = {
    group = "jump"
    created_by = "terraform"
  }
  service_account {
  email = var.googleEmail
  scopes = ["cloud-platform"]
  }

  connection {
    host        = self.network_interface.0.access_config.0.nat_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file(var.privateKey)
  }

  provisioner "remote-exec" {
    inline      = [
      "while [ ! -f /tmp/cloudInitDone.log ]; do sleep 1; done"
    ]
  }

  # to copy  ansible directory

  provisioner "file" {
  source      = var.privateKey
  destination = "~/.ssh/${basename(var.privateKey)}"
}

  provisioner "file" {
  source      = var.ansible.gcpServiceAccount
  destination = "/opt/ansible/inventory/${basename(var.ansible.gcpServiceAccount)}"
  }

  provisioner "file" {
  source      = var.ansible.directory
  destination = "~/ansible"
  }

  provisioner "file" {
    content      = <<EOF
---
googleDriveId: ${var.avi_googleId_gcp_20_1_3}
bucketAvi: ${var.gcp.bucketName}
googleEmail: ${var.googleEmail}
googleProject: ${var.googleProject}
EOF
  destination = "~/gcp.yml"
  }


  provisioner "remote-exec" {
    inline      = [
    "chmod 600 ${var.privateKey}",
    "cd ~/ansible ; git clone https://github.com/tacobayle/ansibleGcpStorageImage ; ansible-playbook ansibleGcpStorageImage/local.yml --extra-vars @~/gcp.yml",
    ]
  }

}

# avi controller creation

resource "google_compute_instance" "aviController" {
  depends_on = [google_compute_instance.jump]
  name = var.controller.name
  machine_type = var.controller.type
  zone = data.google_compute_zones.available.names[0]
  boot_disk {
    device_name = var.controller.diskName
    initialize_params {
    image = "projects/${var.googleProject}/global/images/avi-controller-image"
    type = var.controller.diskType
    size = var.controller.diskSize
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.0.id
    access_config {
    }
  }
  metadata  = {
    sshKeys = "ubuntu:${file(var.controller.key)}"
  }
  labels = {
    group = "controller"
    created_by = "terraform"
  }
  service_account {
  email = var.googleEmail
  scopes = ["cloud-platform"]
  }
}
