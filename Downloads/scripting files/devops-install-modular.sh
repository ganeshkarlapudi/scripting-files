#!/bin/bash

################################################################################
# Modular DevOps Tools Installation Script for AWS Ubuntu Server
# Usage: sudo ./devops-install-modular.sh [options]
# Options: --all, --docker, --k8s, --jenkins, --monitoring, --terraform, --ansible
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
   exit 1
fi

# Parse arguments
INSTALL_ALL=false
INSTALL_DOCKER=false
INSTALL_K8S=false
INSTALL_JENKINS=false
INSTALL_MONITORING=false
INSTALL_TERRAFORM=false
INSTALL_ANSIBLE=false
INSTALL_AWS=false
INSTALL_SECURITY=false

if [ $# -eq 0 ]; then
    info "No options provided. Interactive mode..."
    INTERACTIVE=true
else
    for arg in "$@"; do
        case $arg in
            --all) INSTALL_ALL=true ;;
            --docker) INSTALL_DOCKER=true ;;
            --k8s|--kubernetes) INSTALL_K8S=true ;;
            --jenkins) INSTALL_JENKINS=true ;;
            --monitoring) INSTALL_MONITORING=true ;;
            --terraform) INSTALL_TERRAFORM=true ;;
            --ansible) INSTALL_ANSIBLE=true ;;
            --aws) INSTALL_AWS=true ;;
            --security) INSTALL_SECURITY=true ;;
            --help)
                echo "Usage: sudo $0 [options]"
                echo "Options:"
                echo "  --all           Install all tools"
                echo "  --docker        Install Docker and Docker Compose"
                echo "  --k8s           Install Kubernetes tools (kubectl, helm, minikube)"
                echo "  --jenkins       Install Jenkins"
                echo "  --monitoring    Install Prometheus, Grafana, Node Exporter"
                echo "  --terraform     Install Terraform"
                echo "  --ansible       Install Ansible"
                echo "  --aws           Install AWS CLI"
                echo "  --security      Install Trivy, SonarQube Scanner"
                echo "  --help          Show this help message"
                exit 0
                ;;
        esac
    done
fi

if [ "$INSTALL_ALL" = true ]; then
    INSTALL_DOCKER=true
    INSTALL_K8S=true
    INSTALL_JENKINS=true
    INSTALL_MONITORING=true
    INSTALL_TERRAFORM=true
    INSTALL_ANSIBLE=true
    INSTALL_AWS=true
    INSTALL_SECURITY=true
fi

# Interactive mode
if [ "$INTERACTIVE" = true ]; then
    echo ""
    echo "======================================="
    echo "DevOps Tools Installation Script"
    echo "======================================="
    echo ""
    read -p "Install Docker? (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_DOCKER=true
    
    read -p "Install Kubernetes tools? (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_K8S=true
    
    read -p "Install Jenkins? (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_JENKINS=true
    
    read -p "Install Monitoring (Prometheus, Grafana)? (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_MONITORING=true
    
    read -p "Install Terraform? (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_TERRAFORM=true
    
    read -p "Install Ansible? (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_ANSIBLE=true
    
    read -p "Install AWS CLI? (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_AWS=true
    
    read -p "Install Security Tools (Trivy)? (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && INSTALL_SECURITY=true
fi

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
# Docker Installation
################################################################################
if [ "$INSTALL_DOCKER" = true ]; then
    log "Installing Docker..."
    
    # Remove old versions
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start and enable
    systemctl start docker
    systemctl enable docker
    
    # Add ubuntu user to docker group
    usermod -aG docker ubuntu 2>/dev/null || true
    
    # Install Docker Compose standalone
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    log "✓ Docker installed: $(docker --version)"
fi

################################################################################
# Kubernetes Tools
################################################################################
if [ "$INSTALL_K8S" = true ]; then
    log "Installing Kubernetes tools..."
    
    # kubectl, kubeadm, kubelet
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
    
    apt-get update -y
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
    
    # Minikube
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    
    # Helm
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
    apt-get update -y
    apt-get install -y helm
    
    log "✓ Kubernetes tools installed"
fi

################################################################################
# Jenkins
################################################################################
if [ "$INSTALL_JENKINS" = true ]; then
    log "Installing Jenkins..."
    
    # Add Jenkins repository
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update -y
    
    # Install Java
    apt-get install -y fontconfig openjdk-17-jre
    
    # Install Jenkins
    apt-get install -y jenkins
    
    # Start and enable
    systemctl start jenkins
    systemctl enable jenkins
    
    log "✓ Jenkins installed (port 8080)"
    info "Jenkins initial password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
fi

################################################################################
# Monitoring Stack
################################################################################
if [ "$INSTALL_MONITORING" = true ]; then
    log "Installing Monitoring Stack..."
    
    # Prometheus
    PROM_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | jq -r .tag_name | sed 's/v//')
    wget -q https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
    tar xzf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
    mv prometheus-${PROM_VERSION}.linux-amd64 /opt/prometheus
    rm prometheus-${PROM_VERSION}.linux-amd64.tar.gz
    
    useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true
    mkdir -p /etc/prometheus /var/lib/prometheus
    
    cp /opt/prometheus/prometheus /usr/local/bin/
    cp /opt/prometheus/promtool /usr/local/bin/
    cp -r /opt/prometheus/consoles /etc/prometheus
    cp -r /opt/prometheus/console_libraries /etc/prometheus
    
    chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
    chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
    
    cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF
    
    chown prometheus:prometheus /etc/prometheus/prometheus.yml
    
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
    
    # Node Exporter
    NODE_VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | jq -r .tag_name | sed 's/v//')
    wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
    tar xzf node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
    mv node_exporter-${NODE_VERSION}.linux-amd64/node_exporter /usr/local/bin/
    rm -rf node_exporter-${NODE_VERSION}.linux-amd64*
    
    useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true
    
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
    
    # Grafana
    wget -q -O - https://packages.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | tee /etc/apt/sources.list.d/grafana.list
    apt-get update -y
    apt-get install -y grafana
    
    systemctl start grafana-server
    systemctl enable grafana-server
    
    log "✓ Monitoring stack installed"
    info "Prometheus: http://localhost:9090"
    info "Grafana: http://localhost:3000 (admin/admin)"
fi

################################################################################
# Terraform
################################################################################
if [ "$INSTALL_TERRAFORM" = true ]; then
    log "Installing Terraform..."
    
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
    apt-get update -y
    apt-get install -y terraform
    
    log "✓ Terraform installed: $(terraform --version | head -n1)"
fi

################################################################################
# Ansible
################################################################################
if [ "$INSTALL_ANSIBLE" = true ]; then
    log "Installing Ansible..."
    
    add-apt-repository -y ppa:ansible/ansible
    apt-get update -y
    apt-get install -y ansible
    
    log "✓ Ansible installed: $(ansible --version | head -n1)"
fi

################################################################################
# AWS CLI
################################################################################
if [ "$INSTALL_AWS" = true ]; then
    log "Installing AWS CLI..."
    
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
    
    log "✓ AWS CLI installed: $(aws --version)"
fi

################################################################################
# Security Tools
################################################################################
if [ "$INSTALL_SECURITY" = true ]; then
    log "Installing Security Tools..."
    
    # Trivy
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | tee /usr/share/keyrings/trivy.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
    apt-get update -y
    apt-get install -y trivy
    
    log "✓ Security tools installed"
fi

################################################################################
# Summary
################################################################################
echo ""
log "=========================================="
log "Installation Complete!"
log "=========================================="
echo ""

if [ "$INSTALL_DOCKER" = true ]; then
    echo "✓ Docker: $(docker --version)"
    echo "  Status: systemctl status docker"
fi

if [ "$INSTALL_K8S" = true ]; then
    echo "✓ Kubernetes tools installed"
    echo "  kubectl: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
    echo "  helm: $(helm version --short)"
fi

if [ "$INSTALL_JENKINS" = true ]; then
    echo "✓ Jenkins running on port 8080"
    echo "  Status: systemctl status jenkins"
    echo "  Password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
fi

if [ "$INSTALL_MONITORING" = true ]; then
    echo "✓ Monitoring stack installed"
    echo "  Prometheus: http://localhost:9090"
    echo "  Grafana: http://localhost:3000 (admin/admin)"
    echo "  Node Exporter: port 9100"
fi

if [ "$INSTALL_TERRAFORM" = true ]; then
    echo "✓ Terraform: $(terraform --version | head -n1)"
fi

if [ "$INSTALL_ANSIBLE" = true ]; then
    echo "✓ Ansible: $(ansible --version | head -n1)"
fi

if [ "$INSTALL_AWS" = true ]; then
    echo "✓ AWS CLI: $(aws --version)"
fi

if [ "$INSTALL_SECURITY" = true ]; then
    echo "✓ Trivy: $(trivy --version)"
fi

echo ""
info "Remember to:"
echo "  - Configure AWS security groups for required ports"
echo "  - Logout and login for group changes to take effect"
echo "  - Configure each tool based on your requirements"
echo ""
log "All done! 🚀"
