#!/bin/bash

################################################################################
# DevOps Tools Installation Script for AWS Ubuntu Server
# This script installs and configures popular DevOps tools
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
   exit 1
fi

log "Starting DevOps tools installation on AWS Ubuntu Server..."

################################################################################
# System Update
################################################################################
log "Updating system packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    wget \
    git \
    vim \
    unzip \
    jq \
    tree \
    net-tools

################################################################################
# Install Docker
################################################################################
log "Installing Docker..."
# Remove old versions
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu || warning "Could not add ubuntu user to docker group"

log "Docker installed successfully: $(docker --version)"

################################################################################
# Install Docker Compose (standalone)
################################################################################
log "Installing Docker Compose standalone..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
log "Docker Compose installed: $(docker-compose --version)"

################################################################################
# Install Kubernetes tools (kubectl, kubeadm, kubelet)
################################################################################
log "Installing Kubernetes tools..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

log "Kubernetes tools installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

################################################################################
# Install Minikube (for local K8s testing)
################################################################################
log "Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
log "Minikube installed: $(minikube version --short)"

################################################################################
# Install Helm
################################################################################
log "Installing Helm..."
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update -y
apt-get install -y helm
log "Helm installed: $(helm version --short)"

################################################################################
# Install Terraform
################################################################################
log "Installing Terraform..."
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update -y
apt-get install -y terraform
log "Terraform installed: $(terraform --version | head -n1)"

################################################################################
# Install Ansible
################################################################################
log "Installing Ansible..."
add-apt-repository -y ppa:ansible/ansible
apt-get update -y
apt-get install -y ansible
log "Ansible installed: $(ansible --version | head -n1)"

################################################################################
# Install Jenkins
################################################################################
log "Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update -y

# Install Java (required for Jenkins)
apt-get install -y fontconfig openjdk-17-jre
apt-get install -y jenkins

# Start and enable Jenkins
systemctl start jenkins
systemctl enable jenkins

log "Jenkins installed and started on port 8080"
log "Initial admin password location: /var/lib/jenkins/secrets/initialAdminPassword"

################################################################################
# Install GitLab Runner
################################################################################
log "Installing GitLab Runner..."
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
apt-get install -y gitlab-runner
log "GitLab Runner installed: $(gitlab-runner --version)"

################################################################################
# Install AWS CLI v2
################################################################################
log "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip
log "AWS CLI installed: $(aws --version)"

################################################################################
# Install Prometheus
################################################################################
log "Installing Prometheus..."
PROM_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | jq -r .tag_name | sed 's/v//')
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar xvfz prometheus-${PROM_VERSION}.linux-amd64.tar.gz
mv prometheus-${PROM_VERSION}.linux-amd64 /opt/prometheus
rm prometheus-${PROM_VERSION}.linux-amd64.tar.gz

# Create Prometheus user
useradd --no-create-home --shell /bin/false prometheus || true

# Create directories
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

# Move files
cp /opt/prometheus/prometheus /usr/local/bin/
cp /opt/prometheus/promtool /usr/local/bin/
cp -r /opt/prometheus/consoles /etc/prometheus
cp -r /opt/prometheus/console_libraries /etc/prometheus

# Set ownership
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# Create Prometheus config
cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Create systemd service
cat > /etc/systemd/system/prometheus.service <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus

log "Prometheus installed and started on port 9090"

################################################################################
# Install Grafana
################################################################################
log "Installing Grafana..."
apt-get install -y apt-transport-https software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | tee /etc/apt/sources.list.d/grafana.list
apt-get update -y
apt-get install -y grafana

systemctl start grafana-server
systemctl enable grafana-server

log "Grafana installed and started on port 3000 (default login: admin/admin)"

################################################################################
# Install Node Exporter (for Prometheus)
################################################################################
log "Installing Node Exporter..."
NODE_VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | jq -r .tag_name | sed 's/v//')
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
tar xvfz node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
mv node_exporter-${NODE_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_VERSION}.linux-amd64*

# Create node_exporter user
useradd --no-create-home --shell /bin/false node_exporter || true

# Create systemd service
cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

log "Node Exporter installed and started on port 9100"

################################################################################
# Install Trivy (Security Scanner)
################################################################################
log "Installing Trivy..."
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
apt-get update -y
apt-get install -y trivy
log "Trivy installed: $(trivy --version)"

################################################################################
# Install SonarQube Scanner CLI
################################################################################
log "Installing SonarQube Scanner..."
SONAR_VERSION="5.0.1.3006"
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_VERSION}-linux.zip
unzip -q sonar-scanner-cli-${SONAR_VERSION}-linux.zip
mv sonar-scanner-${SONAR_VERSION}-linux /opt/sonar-scanner
rm sonar-scanner-cli-${SONAR_VERSION}-linux.zip
ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner
log "SonarQube Scanner installed"

################################################################################
# Install Maven
################################################################################
log "Installing Maven..."
apt-get install -y maven
log "Maven installed: $(mvn --version | head -n1)"

################################################################################
# Install Nginx
################################################################################
log "Installing Nginx..."
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
log "Nginx installed and started on port 80"

################################################################################
# Summary
################################################################################
log "=================================="
log "DevOps Tools Installation Complete!"
log "=================================="
echo ""
log "Installed tools and their versions:"
echo ""
echo "Docker: $(docker --version)"
echo "Docker Compose: $(docker-compose --version)"
echo "Kubectl: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
echo "Helm: $(helm version --short)"
echo "Terraform: $(terraform --version | head -n1)"
echo "Ansible: $(ansible --version | head -n1)"
echo "AWS CLI: $(aws --version)"
echo "Trivy: $(trivy --version)"
echo "Maven: $(mvn --version | head -n1)"
echo ""
log "Services running:"
echo "- Docker (systemctl status docker)"
echo "- Jenkins on port 8080 (systemctl status jenkins)"
echo "- Prometheus on port 9090 (systemctl status prometheus)"
echo "- Grafana on port 3000 (systemctl status grafana-server)"
echo "- Node Exporter on port 9100 (systemctl status node_exporter)"
echo "- Nginx on port 80 (systemctl status nginx)"
echo ""
log "Important notes:"
echo "- Jenkins initial password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo "- Grafana default login: admin/admin"
echo "- Remember to configure AWS security groups to allow required ports"
echo "- Add non-root users to docker group: sudo usermod -aG docker <username>"
echo "- Logout and login again for docker group changes to take effect"
echo ""
log "Installation completed successfully!"
