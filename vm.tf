# Copyright 2019. IBM All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

variable "dai_image_url" {
  description = "URL to DAI docker images for PPC"
  default = "https://s3.amazonaws.com/artifacts.h2o.ai/releases/ai/h2o/dai/rel-1.8.5-64/ppc64le-centos7/dai-docker-centos7-ppc64le-1.8.5.1-10.0.tar.gz"
}

variable "dai_version" {
  description = "DAI Version"
  default = "1.8.5.1"
}

variable "vpc_basename" {
  description = "Denotes the name of the VPC that DAI will be deployed into. Resources associated with DAI will be prepended with this name. Keep this at 25 characters or fewer."
  default = "h2o-dai-trial"
}

variable "dai_tar_name" {
  description = "Install images name (e.g. dai-docker-centos7-ppc64le-1.8.5.1-10.0.tar.gz)"
  default = "dai-docker-centos7-ppc64le-1.8.5.1-10.0.tar.gz"
}

variable "boot_image_name" {
  description = "name of the base image for the virtual server (should be an Ubuntu 18.04 base)"
  default = "ibm-ubuntu-18-04-3-minimal-ppc64le-2"
}

variable "vpc_region" {
  description = "Target region to create this instance of DAI. Valid values are 'us-south' only at this time."
  default = "us-south"
}

variable "vpc_zone" {
  description = "Target availbility zone to create this instance of DAI. Valid values are 'us-south-1' 'us-south-2' or 'us-south-3' at this time."
  default = "us-south-2"
}

variable "vm_profile" {
  description = "What resources or VM profile should we create for compute? 'gp2-24x224x2' provides 2 GPUs, and 'gp2-32x256x4' provides 4 GPUs. Valid values must be POWER9 GPU profiles from https://cloud.ibm.com/docs/vpc?topic=vpc-profiles#gpu ."
  default = "gp2-24x224x2"
}

#################################################
##               End of variables              ##
#################################################

data ibm_is_image "bootimage" {
    name =  "${var.boot_image_name}"
}


#Create a VPC for the application
resource "ibm_is_vpc" "vpc" {
  name = "${var.vpc_basename}-vpc1"
}

#Create a subnet for the application
resource "ibm_is_subnet" "subnet" {
  name = "${var.vpc_basename}-subnet1"
  vpc = "${ibm_is_vpc.vpc.id}"
  zone = "${var.vpc_zone}"
  ip_version = "ipv4"
  total_ipv4_address_count = 32
}

#Create an SSH key which will be used for provisioning by this template, and for debug purposes
resource "ibm_is_ssh_key" "public_key" {
  name = "${var.vpc_basename}-public-key"
  public_key = "${tls_private_key.dai_keypair.public_key_openssh}"
}

#Create a public floating IP so that the app is available on the Internet
resource "ibm_is_floating_ip" "fip1" {
  name = "${var.vpc_basename}-subnet-fip1"
  target = "${ibm_is_instance.vm.primary_network_interface.0.id}"
}

#Enable ssh into the instance for debug
resource "ibm_is_security_group_rule" "sg1-tcp-rule" {
  depends_on = [
    "ibm_is_floating_ip.fip1"
  ]
  group = "${ibm_is_vpc.vpc.default_security_group}"
  direction = "inbound"
  remote = "0.0.0.0/0"


  tcp {
    port_min = 22
    port_max = 22
  }
}

#Enable port 443 - main application port
resource "ibm_is_security_group_rule" "sg2-tcp-rule" {
  depends_on = [
    "ibm_is_floating_ip.fip1"
  ]
  group = "${ibm_is_vpc.vpc.default_security_group}"
  direction = "inbound"
  remote = "0.0.0.0/0"

  tcp {
    port_min = 443
    port_max = 443
  }
}

#Enable port 80 - only use to redirect to port 443
resource "ibm_is_security_group_rule" "sg3-tcp-rule" {
  depends_on = [
    "ibm_is_floating_ip.fip1"
  ]
  group = "${ibm_is_vpc.vpc.default_security_group}"
  direction = "inbound"
  remote = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

#Enable port 12345 - DAI default port
resource "ibm_is_security_group_rule" "sg4-tcp-rule" {
  depends_on = [
    "ibm_is_floating_ip.fip1"
  ]
  group = "${ibm_is_vpc.vpc.default_security_group}"
  direction = "inbound"
  remote = "0.0.0.0/0"

  tcp {
    port_min = 12345
    port_max = 12345
  }
}

resource "ibm_is_instance" "vm" {
  name = "${var.vpc_basename}-vm1"
  image = "${data.ibm_is_image.bootimage.id}"
  profile = "${var.vm_profile}"

  primary_network_interface {
    subnet = "${ibm_is_subnet.subnet.id}"
  }

  vpc = "${ibm_is_vpc.vpc.id}"
  zone = "${var.vpc_zone}" //make this a variable when there's more than one option

  keys = [
    "${ibm_is_ssh_key.public_key.id}"
  ]

  timeouts {
    create = "10m"
    delete = "10m"
  }

}

#Create a ssh keypair which will be used to provision code onto the system - and also access the VM for debug if needed.
resource "tls_private_key" "dai_keypair" {
  algorithm = "RSA"
  rsa_bits = "2048"
}


#Provision the app onto the system
resource "null_resource" "provisioners" {

  triggers = {
    vmid = "${ibm_is_instance.vm.id}"
  }

  depends_on = [
    "ibm_is_security_group_rule.sg1-tcp-rule"
  ]

  provisioner "file" {
    source = "scripts"
    destination = "/tmp"
    connection {
      type = "ssh"
      user = "root"
      agent = false
      timeout = "5m"
      host = "${ibm_is_floating_ip.fip1.address}"
      private_key = "${tls_private_key.dai_keypair.private_key_pem}"
    }
  }


  provisioner "file" {
    content = <<ENDENVTEMPL
#!/bin/bash -xe
export RAMDISK=/tmp/ramdisk
export DOCKERMOUNT=/var/lib/docker
export URLDAIDOCKERMAGES=${var.dai_image_url}
ENDENVTEMPL
    destination = "/tmp/scripts/env.sh"
    connection {
      type = "ssh"
      user = "root"
      agent = false
      timeout = "5m"
      host = "${ibm_is_floating_ip.fip1.address}"
      private_key = "${tls_private_key.dai_keypair.private_key_pem}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "chmod +x /tmp/scripts*/*",
      "/tmp/scripts/ramdisk_tmp_create.sh",
      "/tmp/scripts/ramdisk_docker_create.sh",
      "/tmp/scripts/wait_bootfinished.sh",
      "/tmp/scripts/install_gpu_drivers.sh",
      "/tmp/scripts/fetch_dai.sh",
      "/tmp/scripts/install_docker.sh",
      "/tmp/scripts/install_nvidiadocker2.sh",
      "/tmp/scripts/install_dai.sh",
      "/tmp/scripts/ramdisk_tmp_destroy.sh",
      "/tmp/scripts/dai_start.sh",
      "rm -rf /tmp/scripts"
    ]
    connection {
      type = "ssh"
      user = "root"
      agent = false
      timeout = "5m"
      host = "${ibm_is_floating_ip.fip1.address}"
      private_key = "${tls_private_key.dai_keypair.private_key_pem}"
    }
  }
}
