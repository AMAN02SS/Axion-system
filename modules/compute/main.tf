# Automatic SSH key generation if user does not supply one
resource "tls_private_key" "ssh" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  resolved_ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.ssh[0].public_key_openssh
  frontend_private_ip     = cidrhost(var.frontend_subnet_cidr, 4)
  backend_private_ip      = cidrhost(var.backend_subnet_cidr, 4)
}

# ==============================================================================
# Tier 1: Frontend Compute (Public Facing)
# ==============================================================================

# Public IP for Frontend VM
resource "azurerm_public_ip" "frontend_pip" {
  name                = "pip-${var.project_name}-${var.environment}-frontend"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Frontend Network Interface
resource "azurerm_network_interface" "frontend_nic" {
  name                = "nic-${var.project_name}-${var.environment}-frontend"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig-frontend"
    subnet_id                     = var.frontend_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.frontend_private_ip
    public_ip_address_id          = azurerm_public_ip.frontend_pip.id
  }
}

# Frontend Cloud-Init Script
# Configures Nginx reverse proxy targeting Backend VM and serves an architecture status page
locals {
  frontend_cloud_init = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx curl

    # Configure Nginx reverse proxy to route /api/ traffic to Backend VM
    cat <<'NGINX_CONF' > /etc/nginx/sites-available/default
    server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;
        index index.html;

        server_name _;

        location / {
            try_files $uri $uri/ =404;
        }

        location /api/ {
            proxy_pass http://${local.backend_private_ip}:${var.backend_app_port}/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_connect_timeout 5s;
            proxy_read_timeout 10s;
        }
    }
    NGINX_CONF

    # Create Axion System Dashboard HTML
    cat <<'HTML' > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Axion System - 3-Tier Infrastructure</title>
        <style>
            :root {
                --primary: #3b82f6;
                --bg: #0f172a;
                --card-bg: #1e293b;
                --text: #f8fafc;
                --muted: #94a3b8;
                --success: #10b981;
            }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                background-color: var(--bg);
                color: var(--text);
                margin: 0;
                padding: 40px 20px;
                display: flex;
                flex-direction: column;
                align-items: center;
            }
            .container {
                max-width: 900px;
                width: 100%;
            }
            .header {
                text-align: center;
                margin-bottom: 40px;
            }
            .header h1 {
                font-size: 2.5rem;
                margin-bottom: 10px;
                color: #60a5fa;
            }
            .badge {
                display: inline-block;
                padding: 6px 14px;
                background: #065f46;
                color: #34d399;
                border-radius: 9999px;
                font-size: 0.85rem;
                font-weight: 600;
            }
            .tiers {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
                gap: 20px;
                margin-bottom: 30px;
            }
            .card {
                background: var(--card-bg);
                border: 1px solid #334155;
                border-radius: 12px;
                padding: 24px;
                box-shadow: 0 4px 6px -1px rgba(0,0,0,0.2);
            }
            .card h3 {
                margin-top: 0;
                color: #38bdf8;
                font-size: 1.2rem;
            }
            .card p {
                color: var(--muted);
                font-size: 0.95rem;
                line-height: 1.5;
            }
            .status-indicator {
                display: flex;
                align-items: center;
                gap: 8px;
                margin-top: 15px;
                font-weight: 600;
                color: var(--success);
            }
            .dot {
                width: 10px;
                height: 10px;
                background-color: var(--success);
                border-radius: 50%;
            }
            .api-test {
                background: var(--card-bg);
                border: 1px solid #334155;
                border-radius: 12px;
                padding: 24px;
            }
            pre {
                background: #020617;
                padding: 16px;
                border-radius: 8px;
                overflow-x: auto;
                color: #38bdf8;
            }
            button {
                background: var(--primary);
                color: white;
                border: none;
                padding: 10px 18px;
                border-radius: 6px;
                font-weight: 600;
                cursor: pointer;
                transition: opacity 0.2s;
            }
            button:hover { opacity: 0.9; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Axion System</h1>
                <div class="badge">&#10003; 3-Tier Architecture Online</div>
                <p style="color: var(--muted); margin-top: 12px;">Parent-Child Modular Azure Infrastructure deployed via Terraform</p>
            </div>

            <div class="tiers">
                <div class="card">
                    <h3>Tier 1: Frontend VM</h3>
                    <p>Public-facing presentation layer. Handles client HTTP/HTTPS requests and proxies backend queries.</p>
                    <div class="status-indicator"><div class="dot"></div> Accessible via Public IP</div>
                </div>
                <div class="card">
                    <h3>Tier 2: Backend VM</h3>
                    <p>Internal business logic layer. Isolated in a private subnet, accepting connections strictly from Frontend.</p>
                    <div class="status-indicator"><div class="dot"></div> Private Subnet: ${local.backend_private_ip}</div>
                </div>
                <div class="card">
                    <h3>Tier 3: PostgreSQL</h3>
                    <p>Azure PostgreSQL Flexible Server PaaS in delegated subnet with Private DNS Zone resolution.</p>
                    <div class="status-indicator"><div class="dot"></div> Port 5432 Isolated</div>
                </div>
            </div>

            <div class="api-test">
                <h3>Backend Connectivity Test (/api/status)</h3>
                <p style="color: var(--muted);">Click to test end-to-end communication from your browser through the Frontend VM to the Backend VM:</p>
                <button onclick="testBackend()">Test Backend Query</button>
                <pre id="output">Click "Test Backend Query" to fetch live JSON from Tier 2 Backend VM...</pre>
            </div>
        </div>

        <script>
            async function testBackend() {
                const out = document.getElementById('output');
                out.innerText = 'Connecting to /api/status ...';
                try {
                    const res = await fetch('/api/status');
                    const data = await res.json();
                    out.innerText = JSON.stringify(data, null, 2);
                } catch(e) {
                    out.innerText = 'Response: ' + e.message + '\n(Note: Backend VM initial package install takes ~1-2 minutes after VM startup)';
                }
            }
        </script>
    </body>
    </html>
    HTML

    systemctl restart nginx
  EOF
}

# Frontend Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                  = "vm-${var.project_name}-${var.environment}-frontend"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.frontend_nic.id]
  custom_data           = base64encode(local.frontend_cloud_init)
  tags                  = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.resolved_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ==============================================================================
# Tier 2: Backend Compute (Private Subnet Only)
# ==============================================================================

# Backend Network Interface (No Public IP)
resource "azurerm_network_interface" "backend_nic" {
  name                = "nic-${var.project_name}-${var.environment}-backend"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig-backend"
    subnet_id                     = var.backend_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.backend_private_ip
  }
}

# Backend Cloud-Init Script
# Installs PostgreSQL client and starts a lightweight microservice on the app port
locals {
  backend_cloud_init = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip postgresql-client

    # Create lightweight Python microservice responding to /status
    cat <<'PY_SCRIPT' > /opt/backend_service.py
    import json
    from http.server import HTTPServer, BaseHTTPRequestHandler

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            response = {
                "system": "Axion System",
                "tier": "Tier 2 - Backend Application VM",
                "status": "Healthy & Online",
                "backend_private_ip": "${local.backend_private_ip}",
                "database_config": {
                    "host": "${var.db_host}",
                    "database": "${var.db_name}",
                    "port": 5432
                },
                "message": "Backend successfully received request from Frontend and is ready to query PostgreSQL."
            }
            self.wfile.write(json.dumps(response, indent=2).encode('utf-8'))

    server = HTTPServer(('0.0.0.0', ${var.backend_app_port}), Handler)
    print("Backend API running on port ${var.backend_app_port}")
    server.serve_forever()
    PY_SCRIPT

    # Set up systemd service to run backend daemon
    cat <<'SERVICE' > /etc/systemd/system/axion-backend.service
    [Unit]
    Description=Axion System Backend Microservice
    After=network.target

    [Service]
    ExecStart=/usr/bin/python3 /opt/backend_service.py
    Restart=always
    User=root

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable axion-backend.service
    systemctl start axion-backend.service
  EOF
}

# Backend Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "backend_vm" {
  name                  = "vm-${var.project_name}-${var.environment}-backend"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.backend_nic.id]
  custom_data           = base64encode(local.backend_cloud_init)
  tags                  = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.resolved_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
