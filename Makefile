# 使用 grep 和 sed 來讀取 HCL 格式的 terraform.tfvars
PROJECT ?= $(shell grep 'project_id' terraform/terraform.tfvars | sed 's/.*= "\(.*\)"/\1/' 2>/dev/null || echo "")
REGION  ?= $(shell grep 'region' terraform/terraform.tfvars | sed 's/.*= "\(.*\)"/\1/' 2>/dev/null || echo "asia-east1")
REPO_ID ?= $(shell grep 'artifact_repo_id' terraform/terraform.tfvars | sed 's/.*= "\(.*\)"/\1/' 2>/dev/null || echo "batch-jobs")
IMAGE_NAME ?= $(shell grep 'image_name' terraform/terraform.tfvars | sed 's/.*= "\(.*\)"/\1/' 2>/dev/null || echo "python-job:latest")
IMAGE_URI = $(REGION)-docker.pkg.dev/$(PROJECT)/$(REPO_ID)/$(IMAGE_NAME)

ar-login:
	gcloud auth configure-docker $(REGION)-docker.pkg.dev -q

build:
	docker build -t $(IMAGE_URI) -f app/Dockerfile .

push:
	docker push $(IMAGE_URI)

print-image:
	@echo $(IMAGE_URI)

# Terraform 指令
tf-init:
	cd terraform && terraform init

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply -auto-approve

tf-destroy:
	cd terraform && terraform destroy -auto-approve

tf-output:
	cd terraform && terraform output

tf-validate:
	cd terraform && terraform validate