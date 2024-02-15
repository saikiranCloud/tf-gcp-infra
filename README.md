# tf-gcp-infra
# GCP Infra with Terraform

This Terraform configuration sets up networking infrastructure on Google Cloud Platform (GCP). 

## Prerequisites

1. [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed.
2. [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed.
3. GCP Service Account.

## Usage

### 1. Configure Variables

Create a `terraform.tfvars` file and specify the required variables:

```hcl
service_account_key_file = "/path/to/service-account-key.json"
project_id              = "project-id"
region                  = "us-east1"
```

### 2. Initialize Terraform

Run the following command to initialize Terraform:

```bash
terraform init
```

### 3. Apply Configuration

Apply the Terraform configuration to create the networking infrastructure:

```bash
terraform apply
```

Follow the prompts to confirm the changes.

### 4. Clean Up (Optional)

To destroy the created resources, run:

```bash
terraform destroy
```

Confirm the destruction by typing `yes` when prompted.

## Directory Structure

- **main.tf**: Main Terraform configuration file to initialize providers and include modules.
- **variables.tf**: Declare variables for better reusability.
- **network.tf**: Define the VPC and subnetworks.
- **routes.tf**: Define the routes.

## Notes

- Google Compute Engine API is enabled in order to create Network VPCs and Routes.
