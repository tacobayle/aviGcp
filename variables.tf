# Google variables

variable "googleEmail" {}
variable "googleProject" {}
variable "avi_googleId_gcp_20_1_3" {}

variable "gcp" {
  type = map
  default = {
    dnsZoneName = "avidemo"
    bucketName = "bucket-avi"
    vpcName = "vpc-avi"
    region = "europe-west1"
    sgName = "sg-avi"
  }
}

variable "subnetworkName" {
  type = list
  default = ["subnet-mgt", "subnet-backend", "subnet-vip"]
}

variable "subnetworkCidr" {
  type = list
  default = ["192.168.0.0/24", "192.168.1.0/24", "192.168.2.0/24"]
}

variable "sgTcp" {
  type = list
  default = ["22", "53", "80", "443", "3306", "8443"]
}

variable "sgUdp" {
  type = list
  default = ["53"]
}

## instance

variable "privateKey" {
  default = "~/.ssh/cloudKey"
}

variable "domain" {
  type = map
  default = {
    name = "gcp.avidemo.fr"
  }
}

variable "network" {
  type = map
  default = {
    ipStartPool = "51"
    ipEndPool = "100"
    cidr = "192.168.10.0/24"
    type = "V4"
  }
}

### jump

variable "jump" {
  type = map
  default = {
    name = "jump"
    type = "f1-micro"
    image = "ubuntu-os-cloud/ubuntu-1804-lts"
    userdata = "userdata/jump.sh"
    key = "~/.ssh/cloudKey.pub"
    avisdkVersion = "18.2.9"
    username = "ubuntu"
  }
}

variable "ansible" {
  type = map
  default = {
    version = "2.9.12"
    prefixGroup = "gcp"
    gcpServiceAccount = "/home/nic/creds/projectavi-283209-298e9656bfa5.json"
    aviPbAbsentUrl = "https://github.com/tacobayle/ansiblePbAviAbsent"
    aviPbAbsentTag = "v1.43"
    directory = "ansible"
    aviConfigureTag = "v3.11"
    aviConfigureUrl = "https://github.com/tacobayle/aviConfigure"
    opencartInstallUrl = "https://github.com/tacobayle/ansibleOpencartInstall"
    opencartInstallTag = "v1.19"
    jsonFile = "~/ansible/fromTf.json"
    yamlFile = "~/ansible/fromTf.yml"
  }
}

### backend

variable "mysql" {
  type = map
  default = {
    type = "e2-medium"
    userdata = "userdata/mysql.sh"
    count = "1"
    image = "ubuntu-os-cloud/ubuntu-1804-lts"
    key = "~/.ssh/cloudKey.pub"
  }
}

variable "backend" {
  type = map
  default = {
    type = "f1-micro"
    image = "ubuntu-os-cloud/ubuntu-2004-lts"
    userdata = "userdata/backend.sh"
    key = "~/.ssh/cloudKey.pub"
    count = 3
  }
}

variable "opencart" {
  type = map
  default = {
    type = "e2-medium"
    userdata = "userdata/opencart.sh"
    count = "2"
    image = "ubuntu-os-cloud/ubuntu-1804-lts"
    opencartDownloadUrl = "https://github.com/opencart/opencart/releases/download/3.0.3.5/opencart-3.0.3.5.zip"
    key = "~/.ssh/cloudKey.pub"
  }
}

variable "avi_password" {}
variable "avi_user" {}

variable "controller" {
  default = {
    name = "avi-controller"
    type = "n2-standard-8"
    diskName = "avi-controller"
    diskType = "pd-ssd"
    diskSize = "128"
    key = "~/.ssh/cloudKey.pub"
    environment = "GCP"
    version = "20.1.3"
    count = "1"
    dns =  ["8.8.8.8", "8.8.4.4"]
    ntp = ["95.81.173.155", "188.165.236.162"]
    floatingIp = "1.1.1.1"
    from_email = "avicontroller@avidemo.fr"
    se_in_provider_context = "false"
    tenant_access_to_provider_se = "true"
    tenant_vrf = "false"
    aviCredsJsonFile = "~/ansible/creds.json"
  }
}

variable "avi_cloud" {
  type = map
  default = {
    name = "cloudGcp" # don't change this name
  }
}

variable "serviceEngineGroup" {
  default = [
    {
      name = "Default-Group"
      cloud_ref = "cloudGcp"
      ha_mode = "HA_MODE_SHARED"
      min_scaleout_per_vs = 2
      buffer_se = 0
      instance_flavor = "n1-standard-2"
      realtime_se_metrics = {
        enabled = true
        duration = 0
      }
    },
    {
      name = "seGroupCpuAutoScale"
      cloud_ref = "cloudGcp"
      ha_mode = "HA_MODE_SHARED"
      min_scaleout_per_vs = 1
      buffer_se = 0
      instance_flavor = "n1-standard-1"
      extra_shared_config_memory = 0
      auto_rebalance = true
      auto_rebalance_interval = 30
      auto_rebalance_criteria = [
        "SE_AUTO_REBALANCE_CPU"
      ]
      realtime_se_metrics = {
        enabled = true
        duration = 0
      }
    },
    {
      name: "seGroupGslb"
      cloud_ref = "cloudGcp"
      ha_mode = "HA_MODE_SHARED"
      min_scaleout_per_vs: 1
      buffer_se: 0
      instance_flavor = "n1-standard-2"
      extra_shared_config_memory = 2000
      realtime_se_metrics = {
        enabled: true
        duration: 0
      }
    }
  ]
}

variable "avi_pool" {
  type = map
  default = {
    name = "pool1"
    lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
  }
}

variable "avi_pool_opencart" {
  type = map
  default = {
    name = "poolOpencart"
    lb_algorithm = "LB_ALGORITHM_ROUND_ROBIN"
    application_persistence_profile_ref = "System-Persistence-Client-IP"
  }
}

variable "avi_virtualservice" {
  default = {
    http = [
      {
        name = "app1"
        pool_ref = "pool1"
        cloud_ref = "cloudGcp"
        services: [
          {
            port = 80
            enable_ssl = "false"
          },
          {
            port = 443
            enable_ssl = "true"
          }
        ]
      },
      {
        name = "opencart"
        pool_ref = "poolOpencart"
        cloud_ref = "cloudGcp"
        services: [
          {
            port = 80
            enable_ssl = "false"
          },
          {
            port = 443
            enable_ssl = "true"
          }
        ]
      }
    ]
    dns = [
      {
        name = "app3-dns"
        cloud_ref = "cloudGcp"
        services: [
          {
            port = 53
          }
        ]
      },
      {
        name = "app4-gslb"
        cloud_ref = "cloudGcp"
        services: [
          {
            port = 53
          }
        ]
        se_group_ref: "seGroupGslb"
      }
    ]
  }
}

variable "avi_gslb" {
  type = map
  default = {
    domain = "gslb.avidemo.fr"
  }
}
