output "jumpPublicIp" {
  value = google_compute_instance.jump.network_interface.0.access_config.0.nat_ip
}

output "aviControllerPublicIp" {
  value = google_compute_instance.aviController.network_interface.0.access_config.0.nat_ip
}

output "destroy" {
  value = "ssh -o StrictHostKeyChecking=no -i ${var.privateKey} -t ubuntu@${google_compute_instance.jump.network_interface.0.access_config.0.nat_ip} 'git clone ${var.ansible.aviPbAbsentUrl} --branch ${var.ansible.aviPbAbsentTag}; ansible-playbook ansiblePbAviAbsent/local.yml --extra-vars @${var.controller.aviCredsJsonFile}' ; sleep 5 ; terraform destroy -auto-approve"
  description = "command to destroy the infra"
}
