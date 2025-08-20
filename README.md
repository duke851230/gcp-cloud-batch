# GCP Cloud Batch Cronjob

這是一個使用 Google Cloud Platform (GCP) 服務來執行定時批次作業的專案。專案結合了 Cloud Scheduler、Workflows 和 Cloud Batch 服務，實現了一個完整的無伺服器批次作業排程系統。

## 專案架構

```
Cloud Scheduler → Workflows → Cloud Batch → Container Image
```

### 核心組件

- **Cloud Scheduler**: 根據 cron 表達式觸發作業
- **Workflows**: 協調和建立 Cloud Batch 作業
- **Cloud Batch**: 執行容器化的工作負載
- **Artifact Registry**: 儲存 Docker 映像檔
- **Service Accounts**: 管理各服務間的權限

### 服務帳號權限設計

專案使用三個服務帳號來實現最小權限原則：

1. **batch-runner-sa**: 執行 Batch 作業
   - `roles/artifactregistry.reader`: 讀取 Artifact Registry 中的容器映像檔
   - `roles/logging.logWriter`: 寫入 Cloud Logging
   - `roles/batch.serviceAgent`: Batch 服務代理權限，允許 Batch 服務代表此服務帳號執行操作
   - `roles/batch.agentReporter`: Batch 代理報告權限，允許向 Batch 服務報告作業狀態

2. **workflows-batch-sa**: 建立和管理 Batch 作業
   - `roles/batch.admin`: 管理 Cloud Batch 作業
   - `roles/iam.serviceAccountUser`: 代表 batch-runner-sa 執行作業

3. **scheduler-invoker-sa**: 觸發 Workflows
   - `roles/workflows.invoker`: 觸發 Workflows 執行

## 本地開發環境設定

### 前置需求

- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install)
- [Docker](https://docs.docker.com/get-docker/)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [Make](https://www.gnu.org/software/make/)

### 1. 初始化 Google Cloud 環境

```bash
# 登入 Google Cloud（使用應用程式預設認證）
gcloud auth application-default login

# 設定專案 ID
gcloud config set project YOUR_PROJECT_ID

# 啟用必要的 API
gcloud services enable batch.googleapis.com
gcloud services enable workflows.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

### 2. 設定 Terraform 變數

複製並修改 `terraform/terraform.tfvars.example` 檔案：

```bash
# 複製範例檔案
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# 編輯設定檔
vim terraform/terraform.tfvars
```

修改 `terraform/terraform.tfvars` 中的必要參數：

```hcl
project_id         = "your-project-id"        # 你的 GCP 專案 ID
region             = "asia-east1"             # 主要區域
scheduler_location = "asia-east1"             # Scheduler 位置
timezone           = "Asia/Taipei"            # 時區
scheduler_cron     = "0 * * * *"              # cron 表達式（每小時執行）
artifact_repo_id   = "batch-jobs"             # Artifact Registry 倉庫 ID
image_name         = "python-job:latest"      # 容器映像檔名稱
machine_type       = "e2-small"               # 機器類型
task_cpu_milli     = 1000                     # 任務 CPU 限制（毫核心）
task_memory_mib    = 512                      # 任務記憶體限制（MiB）
```

### 3. 部署基礎設施

```bash
# 初始化 Terraform
make tf-init

# 驗證 Terraform 配置
make tf-validate

# 檢視部署計畫
make tf-plan

# 部署基礎設施（包含 Artifact Registry）
make tf-apply
```

### 4. 建置和推送 Docker 映像檔

```bash
# 登入 Artifact Registry
make ar-login

# 建置映像檔
make build

# 推送映像檔
make push
```

### 5. 刪除服務
```bash
# 刪除所有 Terraform 管理的資源
make tf-destroy
```


## 專案結構

```
gcp-cloud-batch-cronjob/
├── app/                    # 應用程式程式碼
│   ├── Dockerfile         # Docker 映像檔配置
│   ├── main.py           # 主要應用程式邏輯
│   └── requirements.txt  # Python 依賴套件
├── terraform/            # 基礎設施即程式碼
│   ├── main.tf          # 主要 Terraform 配置
│   ├── variables.tf     # 變數定義
│   ├── outputs.tf       # 輸出值
│   └── versions.tf      # Terraform 版本
├── Makefile             # 建置和部署指令
└── README.md           # 專案說明文件
```

## 自訂應用程式

### 調整資源配置

在 `terraform/terraform.tfvars` 中調整資源設定：

```hcl
# 調整機器類型
machine_type = "e2-medium"

# 調整排程
scheduler_cron = "0 2 * * *"  # 每天凌晨 2 點執行
```
