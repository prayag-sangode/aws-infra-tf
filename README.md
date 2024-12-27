# AWS Infrastructure Terraform Setup - EKS, Bastion Host

This repository contains infrastructure-as-code (IaC) configurations using Terraform to manage AWS resources.

## Steps to Set Up AWS Resources

### Open CloudShell

1. **Create an S3 Bucket:**

   Run the following AWS CLI command to create an S3 bucket:

   ```bash
   aws s3 mb s3://aws-iac-tf-19159
   ```

2. **Check if the S3 Bucket was created:**

   List all S3 buckets to confirm creation:

   ```bash
   aws s3 ls
   ```

3. **Create a DynamoDB Table:**

   Create a DynamoDB table for state locking:

   ```bash
   aws dynamodb create-table \
       --table-name dynamodb-state-locking \
       --attribute-definitions AttributeName=LockID,AttributeType=S \
       --key-schema AttributeName=LockID,KeyType=HASH \
       --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
   ```

4. **Check if DynamoDB Table was created:**

   List all DynamoDB tables:

   ```bash
   aws dynamodb list-tables
   ```

5. **Create Key Pair (from AWS Console):**

   - In the AWS Console, create a Key Pair named `MyKeyPair.ppk`.
   - **Note:** `MyKeyPair.ppk` will be downloaded to your local system.

6. **Delete Resources (if required later):**

   - To delete the S3 bucket and DynamoDB table, use the following commands:

   ```bash
   aws s3 rb s3://aws-iac-tf-19159 --force
   aws dynamodb delete-table --table-name dynamodb-state-locking
   ```

---

## Clone the Repository

Clone the repository:

```bash
git clone https://github.com/prayag-sangode/aws-infra-tf
```

Make any necessary changes to the infrastructure code and push the changes. After a push, `terraform apply` will automatically run.

---

## AWS Access Keys (Use Securely)

Ensure to replace with your own credentials. Example credentials:

```bash
AWS Access Key: <replace-me>
AWS Secret Key: <replace-me>
```

---

## Set Up on Bastion Host

1. **Install AWS CLI:**

   On the bastion host, install the AWS CLI:

   ```bash
   sudo apt-get install awscli
   ```

2. **Configure AWS CLI:**

   Configure the AWS CLI with your credentials:

   ```bash
   aws configure
   ```

3. **Verify EKS Cluster:**

   List all EKS clusters:

   ```bash
   aws eks list-clusters
   ```

   Update the kubeconfig file for the cluster:

   ```bash
   aws eks update-kubeconfig --region us-east-1 --name my-cluster
   ```

4. **Install kubectl:**

   Install `kubectl` to interact with the Kubernetes cluster:

   ```bash
   sudo snap install kubectl --classic
   ```

5. **Check Cluster Nodes:**

   Get the list of nodes in the Kubernetes cluster:

   ```bash
   kubectl get nodes -o wide
   ```

6. **Create Deployment:**

   Create a deployment with 3 replicas using the `nginx` image:

   ```bash
   kubectl create deployment my-deployment --image=nginx --replicas=3
   ```

7. **Expose Deployment:**

   Expose the deployment with a LoadBalancer to port 80:

   ```bash
   kubectl expose deployment my-deployment --port=80 --target-port=80 --type=LoadBalancer
   ```

8. **Get All Kubernetes Resources:**

   Get a list of all resources in the cluster:

   ```bash
   kubectl get all
   ```

9. **Access Application:**

   Use `curl` to access the application through the LoadBalancer URL:

   ```bash
   curl <lb-url>
   ```

10. **Delete Kubernetes Resources:**

    To delete all Kubernetes resources:

    ```bash
    kubectl delete all --all
    ```

---

## Notes

- Ensure to securely handle your AWS credentials.
- Modify the Terraform configurations to suit your needs before applying.
```

### Key Sections:
- **AWS CLI commands** to create and delete S3 buckets and DynamoDB tables.
- **Instructions** for cloning the repo and setting up AWS resources.
- **Commands to interact with Kubernetes**, including creating deployments and exposing services via LoadBalancer.
- **Security Considerations** regarding handling AWS credentials.
