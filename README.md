<div align="center">
  <img src="assets/zcorp_logo.webp" alt="Logo" width="120" height="120">
  <h3 align="center">Z Corp Infra</h3>
  <p align="center">
    The infra-as-code of the Z corp team.
    <br />
  </p>
</div>

## Requirements

- [Terraform cli](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [OCI cli](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
  - Configured with `oci config setup`

## Usage

### Terraform

To deploy the Oracle Cloud infrastructure, you have to get some informations :

- your tenancy ocid
  - You have this information on the dashboard
- your user ocid
  - You have this information on the dashboard
- your api key fingerprint
  - You have this information on the dashboard
- your oci private key path
  - Default value is good
- your ssh public key path
  - Usually on ~/.ssh folder
- your availibility domain
  - `oci iam availability-domain list`
- your compartment id

  - `oci iam availability-domain list`

- your instance image ocid
  - https://docs.oracle.com/en-us/iaas/images/

After collecting all the information, fill out the `terraform.tfvars` following the structure of `variables.tf`

- `terraform init`
- `terraform apply`

### Cluster

#### Env
Configure `.env` file before running the scripts

#### Order of scripts to run
- deploy_iptables
- deploy_cluster
- deploy_runner
- deploy_stacks

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.
