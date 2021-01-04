resource "null_resource" "foo7" {
  depends_on = [google_compute_instance.aviController]
  connection {
    host        = google_compute_instance.jump.network_interface.0.access_config.0.nat_ip
    type        = "ssh"
    agent       = false
    user        = "ubuntu"
    private_key = file(var.privateKey)
  }

  provisioner "file" {
    content      = <<EOF
---
mysql_db_hostname: ${google_compute_instance.mysql[0].network_interface.0.network_ip}

controller:
  environment: ${var.controller.environment}
  username: ${var.avi_user}
  version: ${var.controller.version}
  password: ${var.avi_password}
  count: ${var.controller.count}
  from_email: ${var.controller.from_email}
  se_in_provider_context: ${var.controller.se_in_provider_context}
  tenant_access_to_provider_se: ${var.controller.tenant_access_to_provider_se}
  tenant_vrf: ${var.controller.tenant_vrf}
  aviCredsJsonFile: ${var.controller.aviCredsJsonFile}

controllerPrivateIps:
${yamlencode(google_compute_instance.aviController.*.network_interface.0.network_ip)}

controllerPublicIps:
${yamlencode(google_compute_instance.aviController.*.network_interface.0.access_config.0.nat_ip)}

googleDriveId: ${var.avi_googleId_gcp_20_1_3}

ntpServers:
${yamlencode(var.controller.ntp.*)}

dnsServers:
${yamlencode(var.controller.dns.*)}

bucketAvi: ${var.gcp.bucketName}

googleEmail: ${var.googleEmail}

googleProject: ${var.googleProject}

domain:
  name: ${var.domain.name}


gcp:
  gcs_bucket_name: ${var.gcp.bucketName}
  region_name: ${var.gcp.region}
  cloudName: &cloud0 ${var.avi_cloud.name}
  se_project_id: ${var.googleProject}
  firewall_target_tags: avi-fw-tag
  network_config:
    config: INBAND_MANAGEMENT
    inband:
      vpc_subnet_name: ${var.subnetworkName.1}
      vpc_network_name: ${var.gcp.vpcName}
      vpc_project_id: ${var.googleProject}

network:
  cloud_ref: ${var.avi_cloud.name}
  cidr: ${var.network.cidr}
  ipStartPool: ${var.network.ipStartPool}
  ipEndPool: ${var.network.ipEndPool}

gcpZones:
${yamlencode(data.google_compute_zones.available.names)}

avi_applicationprofile:
  http:
    - name: &appProfile0 applicationProfileOpencart

avi_servers:
${yamlencode(google_compute_instance.backend.*.network_interface.0.network_ip)}

avi_servers_open_cart:
${yamlencode(google_compute_instance.opencart.*.network_interface.0.network_ip)}

avi_pool:
  name: ${var.avi_pool.name}
  lb_algorithm: ${var.avi_pool.lb_algorithm}
  cloud_ref: ${var.avi_cloud.name}

avi_pool_open_cart:
  application_persistence_profile_ref: ${var.avi_pool_opencart.application_persistence_profile_ref}
  name: ${var.avi_pool_opencart.name}
  lb_algorithm: ${var.avi_pool_opencart.lb_algorithm}
  cloud_ref: ${var.avi_cloud.name}

avi_gslb:
  dns_configs:
    - domain_name: ${var.avi_gslb.domain}

EOF
    destination = var.ansible.yamlFile
  }

  provisioner "file" {
    content      = <<EOF
{"serviceEngineGroup": ${jsonencode(var.serviceEngineGroup)}, "avi_virtualservice": ${jsonencode(var.avi_virtualservice)}}
EOF
    destination = var.ansible.jsonFile
  }

  provisioner "remote-exec" {
    inline      = [
    "cd ~/ansible ; git clone ${var.ansible.opencartInstallUrl} --branch ${var.ansible.opencartInstallTag} ; ansible-playbook ansibleOpencartInstall/local.yml --extra-vars @${var.ansible.yamlFile}",
    "cd ~/ansible ; git clone ${var.ansible.aviConfigureUrl} --branch ${var.ansible.aviConfigureTag} ; ansible-playbook aviConfigure/local.yml --extra-vars @${var.ansible.yamlFile} --extra-vars @${var.ansible.jsonFile}",
    ]
  }

}
