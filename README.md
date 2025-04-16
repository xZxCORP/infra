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
- Transcrypt cli

## Usage

### Terraform

To deploy the Oracle Cloud infrastructure, you have to get some informations :

- your tenancy ocid
  - You have this information on the dashboard
- your user ocid
  - You have this information on the dashboard
- your api key fingerprint
  - You have this information on the dashboard
- your oci private key
- your ssh private key 
- your ssh public key
  - Usually on ~/.ssh folder
- your availibility domain
  - `oci iam availability-domain list`
- your compartment id

  - `oci iam availability-domain list`

- your instance image ocid
  - https://docs.oracle.com/en-us/iaas/images/

After collecting all the information, fill out the `terraform.tfvars` following the structure of `variables.tf`
OR

- decrypt the `terraform.tfvars` file with the `transcrypt` cli

- `terraform init`
- `terraform apply`

### Cluster

#### Deploy the required component to run the CI
- create the cluster ansible vault password
  - `touch ansible/.vault-pass.txt`
- deploy the cluster github runner in local to use the Github Action after the first deployment
- `cd ansible && ansible-playbook cluster.yml --tags=ci`

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.
