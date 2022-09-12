# Deploy on GCP by Terraform

Enable required services:

```
gcloud services enable compute.googleapis.com sqladmin.googleapis.com iam.googleapis.com servicenetworking.googleapis.com
```

Deploy the sample web application:

```
git clone https://github.com/ryotat7/role-play-webapp.git
cd role-play-webapp/provisioning
terraform init
terraform apply -var="project_id=${GOOGLE_CLOUD_PROJECT}"
```