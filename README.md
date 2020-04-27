## License Agreement
By deploying this terraform template via IBM Cloud Schematics or via Terraform, you accept the Terms and Conditions of the [IBM License Agreement for Evaluation of Programs](https://www14.software.ibm.com/cgi-bin/weblap/lap.pl?li_formnum=L-CKIE-BL45W3).  If you do not agree to these terms, do not deploy this template.

## Deployment Architecture

This provisions a dedicated instance of H2O.ai Driverless AI in IBM Cloud utilizing IBM Cloud Schematics or with standalone Terraform. It follows http://docs.h2o.ai/driverless-ai/latest-stable/docs/userguide/install/ibm-docker.html#install-on-ibm-with-gpus.

Once created, its public IP address along with a username and password to log into the application will be displayed for easy access.

More specifically, it creates the following resources:

* a Virtual Private Cloud (VPC)
* a Subnet
* a Virtual Server Instance within the VPC and a particular region and availability zone (AZ)
* a floating IP (FIP) address on the public Internet
* a security group that allows ingress traffic on port 443 (SSL) and on port 22 (for debug)

IMPORTANT: Reboots of the VM are not supported, and will result in loss of data. Back up any datasets or models prior to a reboot or shutdown of underlying VPC infrastructure.

NOTE: Please note that provisioning may take approximately twenty minutes.


## Standalone Terraform Deployment Steps

### Prerequisites

To run as a standalone Terraform deployment, you need the following prerequisites.

```
terraform: v0.11.x or greater
ibm terraform provider: v0.24.x or greater
```

Use the [IBM Cloud VPC Terraform Documentation](https://cloud.ibm.com/docs/terraform?topic=terraform-getting-started#install) for information on how to install Terraform and the IBM Terraform Provider.

You also need to have an [IBM Cloud API Key](https://cloud.ibm.com/docs/iam?topic=iam-userapikey).

### Installation Steps

1. Clone this git respository
2. Review the deployment attributes in the vm.tf file.  You may use the defaults.
3. Run `terraform apply`

When deployment starts, it will ask you for your API key.  The application will then take ~20 minutes to launch.

### Destroy

Simply run `terraform destroy` to remove the application infrastructure.  The solution will also remove the VPC, Subnet, and all other associated resources it created.  It will not touch other infrastructure in your IBM Cloud account.
