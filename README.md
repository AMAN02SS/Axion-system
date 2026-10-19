# Axion System - 3-Tier Architecture Infrastructure (Azure & Terraform)

This repository contains production-ready, modular Terraform code to deploy the **Axion System** on Microsoft Azure. The infrastructure is structured into a clean **Parent-Child modular layout** to eliminate clutter, ensure separation of concerns, and allow seamless maintenance.

---

## 🏛️ Architecture Overview

The system implements a true **3-Tier Architecture** within a single Virtual Network (`vnet-axion-dev`), segregated into three dedicated subnets with strict tier-to-tier Network Security Group (NSG) isolation:

```mermaid
graph TD
    User([🌐 End User / Browser])
    
    subgraph Azure_Cloud["Microsoft Azure (Resource Group: rg-axion-dev)"]
        subgraph VNet["Virtual Network: vnet-axion-dev (10.0.0.0/16)"]
            
            subgraph Tier1["Tier 1: Frontend Subnet (10.0.1.0/24)"]
                PIP["Public IP\n(pip-axion-frontend)"]
                FE["Frontend VM (Nginx Reverse Proxy)\nIP: 10.0.1.4\nPorts: 80, 443, 22"]
                NSG_FE["Frontend NSG\nAllow 80/443 (Internet)\nAllow 22 (SSH)"]
                PIP --> FE
            end
            
            subgraph Tier2["Tier 2: Backend Subnet (10.0.2.0/24)"]
                BE["Backend VM (Application Service)\nIP: 10.0.2.4 (Private Only)\nPort: 8080, 22"]
                NSG_BE["Backend NSG\nAllow Port 8080 (from Frontend Subnet only)\nAllow SSH 22 (from Frontend Subnet only)\nDeny Internet Inbound"]
            end
            
            subgraph Tier3["Tier 3: Database Subnet (10.0.3.0/24 - Delegated)"]
                DB["Azure Database for PostgreSQL\nFlexible Server (PaaS)\nPort: 5432"]
                DNS["Private DNS Zone\n(*.postgres.database.azure.com)"]
                NSG_DB["Database NSG\nAllow Port 5432 (from Backend Subnet only)\nDeny Internet Inbound"]
            end

        end
    end

    User -->|HTTP / HTTPS (Port 80/443)| PIP
    FE -->|Internal API Query (Port 8080)| BE
    BE -->|PostgreSQL Query (Port 5432)| DB
    DB -.->|Private Name Resolution| DNS
```

---

## 🔒 Traffic & Security Pairing Flow

1. **User ➔ Frontend VM (Tier 1)**:
   - Users hit the **Frontend Public IP** via web browser or REST client on port 80/443.
   - Frontend NSG allows inbound HTTP (80), HTTPS (443), and SSH (22).
2. **Frontend VM ➔ Backend VM (Tier 2)**:
   - The Frontend VM proxies application API requests internally to `http://10.0.2.4:8080`.
   - The Backend VM has **NO Public IP** and direct Internet inbound traffic is explicitly **blocked**.
   - Backend NSG permits incoming connections on port 8080 **strictly from the Frontend subnet CIDR (`10.0.1.0/24`)**.
3. **Backend VM ➔ PostgreSQL Flexible Server (Tier 3)**:
   - The Backend VM executes queries against Azure Database for PostgreSQL Flexible Server via port `5432`.
   - The database resides in a subnet delegated exclusively to `Microsoft.DBforPostgreSQL/flexibleServers` and resolves via an Azure Private DNS Zone.
   - Inbound access on port 5432 is restricted **strictly to the Backend subnet CIDR (`10.0.2.0/24`)**.

---

## 📁 Parent-Child Modular Directory Structure

```text
Axion_system/
├── modules/
│   ├── network/                   # Child Module: Network Backbone
│   │   ├── main.tf                # VNet, 3 Subnets, NSGs, and Subnet Associations
│   │   ├── variables.tf           # Network CIDRs, ports, and tags
│   │   └── outputs.tf             # Subnet IDs, VNet ID, Subnet CIDRs
│   │
│   ├── compute/                   # Child Module: Compute Layer
│   │   ├── main.tf                # Frontend VM (with PIP) & Backend VM (Private Only)
│   │   ├── variables.tf           # VM sizing, admin credentials, ports, cloud-init
│   │   └── outputs.tf             # Public IP, Private IPs, SSH Keys
│   │
│   └── database/                  # Child Module: PaaS Data Layer
│       ├── main.tf                # PostgreSQL Flexible Server, Private DNS, VNet Link
│       ├── variables.tf           # PG version, SKU, storage, credentials
│       └── outputs.tf             # Database FQDN, DB name, credentials
│
├── providers.tf                   # Terraform version & AzureRM provider configuration
├── main.tf                        # Root Module: Instantiates Resource Group & Child Modules
├── variables.tf                   # Root Variables with descriptions & defaults
├── outputs.tf                     # Root Outputs (URLs, connection commands, IPs)
├── terraform.tfvars.example       # Example variable inputs template
├── .gitignore                     # Git ignore rules for state files, secrets, & keys
└── README.md                      # Architecture guide and documentation
```

---

## 🚀 Quickstart Deployment

### Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/install) (v1.3+)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) logged in with an active subscription (`az login`)

### Step 1: Clone & Configure Variables
```bash
# Navigate to project directory
cd Axion_system

# Copy sample variables file
cp terraform.tfvars.example terraform.tfvars
```
*(Optional)* Customize region (`location`), VM sizes (`vm_size`), or database credentials in `terraform.tfvars`.

### Step 2: Initialize Terraform & TFLint
```bash
terraform init
tflint --init
```

### Step 3: Lint & Validate
```bash
# Run TFLint recursively across root and all child modules
tflint --recursive

# Validate Terraform syntax and references
terraform validate
```

### Step 4: Review Plan
```bash
terraform plan
```

### Step 5: Provision Infrastructure
```bash
terraform apply -auto-approve
```

---

## 🧪 Validating the 3-Tier Connectivity

Once `terraform apply` finishes, inspect the output values:

1. **Verify Frontend Web Interface**:
   Open the outputted `frontend_web_url` in your browser:
   ```text
   http://<frontend_public_ip>
   ```
   You will see the Axion System status page.

2. **Test End-to-End API Call (User ➔ Frontend ➔ Backend)**:
   Click the **"Test Backend Query"** button on the web page, or run:
   ```bash
   curl http://<frontend_public_ip>/api/status
   ```
   **Expected Response**:
   ```json
   {
     "system": "Axion System",
     "tier": "Tier 2 - Backend Application VM",
     "status": "Healthy & Online",
     "backend_private_ip": "10.0.2.4",
     "database_config": {
       "host": "axion-dev-psql-xxxxxx.postgres.database.azure.com",
       "database": "axion_db",
       "port": 5432
     },
     "message": "Backend successfully received request from Frontend and is ready to query PostgreSQL."
   }
   ```

3. **SSH Access**:
   - **Frontend VM**:
     ```bash
     ssh -i axion_dev_key.pem azureuser@<frontend_public_ip>
     ```
   - **Backend VM (via Frontend as Jumpbox/Bastion)**:
     ```bash
     ssh -i axion_dev_key.pem -J azureuser@<frontend_public_ip> azureuser@10.0.2.4
     ```

---

## 🧹 Teardown / Cleanup

To delete all resources and avoid incurring Azure charges:
```bash
terraform destroy -auto-approve
```
