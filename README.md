# DevOps Tools Installation Scripts for AWS Ubuntu Server

Automated installation scripts for popular DevOps tools on AWS Ubuntu Server.

## 📋 Available Scripts

### 1. **devops-install.sh** - Complete Installation
Installs all DevOps tools automatically without prompts.

### 2. **devops-install-modular.sh** - Modular Installation
Choose which tools to install with command-line options or interactive mode.

## 🛠️ Tools Included

- **Docker & Docker Compose** - Container platform
- **Kubernetes Tools** - kubectl, kubeadm, kubelet, minikube, Helm
- **Jenkins** - CI/CD automation server
- **Terraform** - Infrastructure as Code
- **Ansible** - Configuration management
- **AWS CLI v2** - AWS command line interface
- **Prometheus** - Monitoring and alerting
- **Grafana** - Metrics visualization
- **Node Exporter** - Hardware/OS metrics exporter
- **Trivy** - Container security scanner
- **SonarQube Scanner** - Code quality scanner
- **Maven** - Build automation
- **GitLab Runner** - CI/CD runner
- **Nginx** - Web server and reverse proxy

## 🚀 Usage

### Quick Start - Install Everything

```bash
# Download the script
wget https://your-server/devops-install.sh

# Make it executable
chmod +x devops-install.sh

# Run as root
sudo ./devops-install.sh
```

### Modular Installation

#### Option 1: Interactive Mode
```bash
chmod +x devops-install-modular.sh
sudo ./devops-install-modular.sh
# Follow the prompts to select tools
```

#### Option 2: Command Line Options
```bash
# Install specific tools
sudo ./devops-install-modular.sh --docker --k8s --jenkins

# Install all tools
sudo ./devops-install-modular.sh --all

# Available options:
#   --all           Install all tools
#   --docker        Docker and Docker Compose
#   --k8s           Kubernetes tools
#   --jenkins       Jenkins CI/CD
#   --monitoring    Prometheus, Grafana, Node Exporter
#   --terraform     Terraform
#   --ansible       Ansible
#   --aws           AWS CLI
#   --security      Security tools (Trivy)
```

### Examples

**Install Docker and Kubernetes only:**
```bash
sudo ./devops-install-modular.sh --docker --k8s
```

**Install CI/CD stack:**
```bash
sudo ./devops-install-modular.sh --docker --jenkins --aws
```

**Install complete monitoring stack:**
```bash
sudo ./devops-install-modular.sh --docker --monitoring
```

## 📊 Service Ports

| Service | Port | Access URL |
|---------|------|------------|
| Jenkins | 8080 | http://your-server:8080 |
| Prometheus | 9090 | http://your-server:9090 |
| Grafana | 3000 | http://your-server:3000 |
| Node Exporter | 9100 | http://your-server:9100/metrics |
| Nginx | 80 | http://your-server |

## 🔐 Default Credentials

**Jenkins:**
```bash
# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Grafana:**
- Username: `admin`
- Password: `admin` (will prompt to change on first login)

## ⚙️ Post-Installation Steps

### 1. Configure AWS Security Group
Open required ports in your AWS Security Group:
```
- 22 (SSH)
- 80 (HTTP/Nginx)
- 443 (HTTPS)
- 3000 (Grafana)
- 8080 (Jenkins)
- 9090 (Prometheus)
- 9100 (Node Exporter)
```

### 2. Add Users to Docker Group
```bash
# Add current user
sudo usermod -aG docker $USER

# Add ubuntu user
sudo usermod -aG docker ubuntu

# Logout and login again for changes to take effect
```

### 3. Verify Installations
```bash
# Check Docker
docker --version
docker ps

# Check Kubernetes
kubectl version --client
helm version

# Check services status
systemctl status docker
systemctl status jenkins
systemctl status prometheus
systemctl status grafana-server
```

### 4. Configure AWS CLI
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region name
# Default output format (json)
```

## 🔄 Managing Services

### Start/Stop/Restart Services
```bash
# Docker
sudo systemctl start docker
sudo systemctl stop docker
sudo systemctl restart docker

# Jenkins
sudo systemctl start jenkins
sudo systemctl stop jenkins
sudo systemctl restart jenkins

# Prometheus
sudo systemctl start prometheus
sudo systemctl stop prometheus

# Grafana
sudo systemctl start grafana-server
sudo systemctl stop grafana-server
```

### Check Service Status
```bash
sudo systemctl status docker
sudo systemctl status jenkins
sudo systemctl status prometheus
sudo systemctl status grafana-server
sudo systemctl status node_exporter
```

### View Service Logs
```bash
sudo journalctl -u docker -f
sudo journalctl -u jenkins -f
sudo journalctl -u prometheus -f
sudo journalctl -u grafana-server -f
```

## 🧪 Testing Tools

### Docker
```bash
docker run hello-world
docker-compose --version
```

### Kubernetes
```bash
kubectl cluster-info
minikube status
helm list
```

### Terraform
```bash
terraform version
terraform init
```

### Ansible
```bash
ansible --version
ansible localhost -m ping
```

### Trivy (Security Scanning)
```bash
# Scan a Docker image
trivy image nginx:latest

# Scan filesystem
trivy fs /path/to/project
```

## 📝 Configuration Files

| Tool | Config Location |
|------|----------------|
| Docker | /etc/docker/daemon.json |
| Jenkins | /var/lib/jenkins/ |
| Prometheus | /etc/prometheus/prometheus.yml |
| Grafana | /etc/grafana/grafana.ini |
| Nginx | /etc/nginx/nginx.conf |

## 🔧 Common Tasks

### Docker Cleanup
```bash
# Remove unused containers, networks, images
docker system prune -a

# Remove all stopped containers
docker container prune
```

### Jenkins Unlock
```bash
# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Grafana Add Prometheus Data Source
1. Login to Grafana (http://your-server:3000)
2. Go to Configuration > Data Sources
3. Add Prometheus
4. URL: http://localhost:9090
5. Save & Test

### Minikube Start
```bash
# Start minikube (as non-root user)
minikube start --driver=docker
```

## ⚠️ Troubleshooting

### Docker Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Logout and login again
```

### Jenkins Not Starting
```bash
# Check Java installation
java -version

# Check Jenkins logs
sudo journalctl -u jenkins -n 50

# Restart Jenkins
sudo systemctl restart jenkins
```

### Port Already in Use
```bash
# Find process using port 8080
sudo lsof -i :8080
sudo netstat -tulpn | grep 8080

# Kill the process
sudo kill -9 <PID>
```

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

## 🛡️ Security Recommendations

1. **Change default passwords** immediately
2. **Configure firewalls** properly
3. **Enable SSL/TLS** for all services
4. **Regular updates**: `sudo apt update && sudo apt upgrade`
5. **Limit SSH access** to specific IPs
6. **Use IAM roles** instead of AWS access keys when possible
7. **Enable Jenkins security** and configure authentication
8. **Scan containers** regularly with Trivy

## 📄 System Requirements

- **OS**: Ubuntu 20.04 LTS or 22.04 LTS
- **RAM**: Minimum 4GB (8GB+ recommended)
- **CPU**: 2+ cores
- **Disk**: 20GB+ free space
- **Network**: Internet connectivity required

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📜 License

This script is provided as-is for educational and professional use.

---

**Note**: These scripts are designed for AWS Ubuntu servers. Adjust security group settings and IAM roles as per your requirements.
