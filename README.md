# aviGcp

## Goals
Spin up a full Gcp/Avi environment (through Terraform)

## Prerequisites:
- Terraform in installed in the orchestrator VM
- GCP credential/details are configured as environment variable:
```
GOOGLE_CLOUD_KEYFILE_JSON=**************
```
- DNS zone configured in GCP and in var.domain.name
- Google Drive Id where the Avi Image is available configured in var.avi_googleId_gcp_20_1_3
- Avi version needs to be configured in var.controller.version  
- SSH key configured

## Environment:

Terraform tf has/have been tested against:

### terraform

```
Terraform v0.14.3
+ provider registry.terraform.io/hashicorp/google v3.51.0
+ provider registry.terraform.io/hashicorp/null v3.0.0
+ provider registry.terraform.io/hashicorp/template v2.2.0
```

### Avi version

```
Avi 20.1.3 with one controller node
```

### GCP Region:

- europe-north1
- europe-west3

## Input/Parameters:

- All the paramaters/variables are stored in variables.tf

## Use the the terraform script to:
- Create the VPC and subnets with a cloud NAT service for the private subnets
- Spin up a mysql server
- Spin up two opencart servers
- Spin up 3 backend servers (second subnet) across the 3 zones - no NAT public IP - apache deployed through userdata
- Spin up a jump server with ansible in the mgt subnet (first subnet) - NAT Public IP - ansible through userdata
- Create a GCP storage bucket
- Call ansible to do the gcp prerequisite config.: Download the Avi image to the jump server,  Upload the Avi image to the bucket, Create an GCP image
- Spin up an Avi controller (in the first subnet) based on the Avi Imaged created before
- Call ansible to do the configuration (opencart app) based on dynamic inventory
- Call ansible to do the configuration (avi) based on dynamic inventory

## Run the terraform:
```
cd ~ ; git clone https://github.com/tacobayle/aviGcp ; cd aviGcp ; terraform init ; terraform apply -auto-approve
# the terraform will output the command to destroy the environment.
```
