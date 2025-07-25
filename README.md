# Ansible Role: WordPress Webserver

[![CI](https://github.com/matias-tecnosoul/005-ansible-role-wordpress-webserver/workflows/CI%20Testing%20with%20Molecule/badge.svg)](https://github.com/matias-tecnosoul/005-ansible-role-wordpress-webserver/actions)
[![Galaxy](https://github.com/matias-tecnosoul/005-ansible-role-wordpress-webserver/workflows/Publish%20to%20Ansible%20Galaxy/badge.svg)](https://github.com/matias-tecnosoul/005-ansible-role-wordpress-webserver/actions)
[![License](https://img.shields.io/github/license/matias-tecnosoul/005-ansible-role-wordpress-webserver)](https://github.com/matias-tecnosoul/005-ansible-role-wordpress-webserver/blob/main/LICENSE)

Ansible role for complete WordPress webserver setup with **automatic PHP version detection** by distribution, Apache HTTP Server, and MySQL connectivity.

## 🎯 Key Features

### ✅ **Multi-Distribution Support**
- **Ubuntu 20.04/22.04** (Focal/Jammy)
- **Debian 11/12** (Bullseye/Bookworm)  
- **Rocky Linux 9** (and RHEL derivatives)

### ✅ **Automatic PHP Detection**
- **Ubuntu 22.04** → **PHP 8.1**
- **Ubuntu 20.04** → **PHP 7.4**
- **Debian 12** → **PHP 8.2**
- **Debian 11** → **PHP 7.4**
- **Rocky Linux 9** → **PHP 8.0**

### ✅ **Production-Ready Features**
- Security configurations and hardening
- Performance optimizations for WordPress
- SELinux and firewall setup for RHEL/Rocky
- Comprehensive error handling
- Idempotent operations

### ✅ **Comprehensive Testing**
- **Molecule testing** with Docker scenarios
- **Multi-distribution verification** (15+ checks)
- **CI/CD integration** with GitHub Actions
- **ansible-lint** and **yamllint** compliance

## 📋 Requirements

- **Ansible** >= 2.12
- **Python** >= 3.8
- **Docker** >= 20.10 (for testing with Molecule)
- **Target Systems**: Ubuntu, Debian, Rocky Linux

## 🐳 **Docker Compatibility Fix**

**Important**: Molecule has critical compatibility issues with different Docker versions. We provide a universal fix script:

```bash
# 1. Clone repository
git clone https://github.com/matias-tecnosoul/005-ansible-role-wordpress-webserver.git
cd 005-ansible-role-wordpress-webserver

# 2. Setup Python environment
python3.11 -m venv molecule-env
source molecule-env/bin/activate
pip install -r requirements-dev.txt

# 3. Fix Docker compatibility (CRITICAL STEP)
chmod +x fix-docker-universal.sh
./fix-docker-universal.sh

# 4. Install Galaxy dependencies
ansible-galaxy install -r requirements.yml

# 5. Verify everything works
molecule list
molecule test -s ubuntu
```

### **Why is the Docker fix needed?**

**Different Docker versions require different Python SDK versions:**
- **Docker 20.10.x** (Ubuntu 22.04) → `docker==6.1.3` 
- **Docker 25.x-27.x** (Updated systems) → `docker==7.0.0`
- **Docker 28.x+** (Manjaro/Arch) → `docker==7.0.0` + specific config

**Without this fix**: `Not supported URL scheme http+docker` error prevents Molecule from working.

### **Supported Platforms**
| Platform | Docker Version | Auto-Config | Status |
|----------|----------------|-------------|---------|
| Ubuntu 22.04 | 20.10.x | `stable-lts` | ✅ Perfect |
| Debian 12 | 20.10.x-24.x | `stable-lts` | ✅ Perfect |
| Manjaro/Arch | 28.x+ | `bleeding-edge` | ✅ Fixed |
| CentOS/RHEL | 24.x-27.x | `recent-stable` | ✅ Good |

## 🏗️ Dependencies

This role depends on:
- **`geerlingguy.mysql`** >= 5.0.0 (for database setup)

## 📦 Installation

### From Ansible Galaxy
```bash
ansible-galaxy role install matias_tecnosoul.wordpress_webserver
```

### From GitHub
```bash
ansible-galaxy role install git+https://github.com/matias-tecnosoul/005-ansible-role-wordpress-webserver.git
```

## 🚀 Usage

### Basic Playbook Example
```yaml
---
- hosts: webservers
  become: yes
  
  vars:
    # MySQL configuration
    mysql_root_password: "secure_root_password"
    mysql_databases:
      - name: wordpress_db
        encoding: utf8mb4
        collation: utf8mb4_unicode_ci
    mysql_users:
      - name: wp_user
        password: wp_secure_password
        priv: "wordpress_db.*:ALL"
    
    # WordPress configuration
    wordpress_domain: "mysite.com"
    wordpress_db_name: wordpress_db
    wordpress_db_user: wp_user
    wordpress_db_password: wp_secure_password
  
  roles:
    - geerlingguy.mysql
    - matias_tecnosoul.wordpress_webserver
```

### Advanced Configuration
```yaml
---
- hosts: webservers
  become: yes
  
  vars:
    # WordPress customization
    wordpress_install_dir: "/var/www/html/wordpress"
    wordpress_debug: false
    wordpress_table_prefix: "wp_"
    
    # PHP performance tuning
    php_memory_limit: "512M"
    php_max_execution_time: "300"
    php_upload_max_filesize: "128M"
    php_post_max_size: "128M"
    
    # Security keys (generate unique ones)
    wordpress_auth_key: "your-unique-auth-key-here"
    wordpress_secure_auth_key: "your-unique-secure-auth-key"
    # ... more keys
  
  roles:
    - geerlingguy.mysql
    - matias_tecnosoul.wordpress_webserver
```

## ⚙️ Role Variables

### Required Variables
```yaml
wordpress_domain: "example.com"              # Your domain name
wordpress_db_name: "wordpress_db"            # Database name
wordpress_db_user: "wp_user"                 # Database user
wordpress_db_password: "secure_password"     # Database password
```

### Optional Variables
```yaml
# WordPress configuration
wordpress_install_dir: "/var/www/html/wordpress"  # Installation directory
wordpress_version: "latest"                       # WordPress version
wordpress_debug: false                            # Debug mode
wordpress_table_prefix: "wp_"                     # Database table prefix

# PHP configuration (auto-detected by distribution)
php_memory_limit: "256M"                          # PHP memory limit
php_max_execution_time: "300"                     # Max execution time
php_upload_max_filesize: "64M"                    # Upload file size limit
php_post_max_size: "64M"                          # POST size limit

# Web server
webserver_type: "apache"                          # Web server type
wordpress_user: "www-data"                        # Web server user (auto-detected)
wordpress_group: "www-data"                       # Web server group (auto-detected)
```

See [`defaults/main.yml`](defaults/main.yml) for all available variables and their default values.

## 🧪 Testing

### Local Testing with Molecule

```bash
# 1. Setup development environment
python3.11 -m venv molecule-env
source molecule-env/bin/activate
pip install -r requirements-dev.txt

# 2. CRITICAL: Fix Docker compatibility
./fix-docker-universal.sh

# 3. Install Galaxy dependencies
ansible-galaxy install -r requirements.yml

# 4. Run multi-distribution testing
molecule test

# 5. Test specific distribution
molecule create -s ubuntu
molecule converge -s ubuntu
molecule verify -s ubuntu
molecule login -s ubuntu  # Debug if needed
molecule destroy -s ubuntu
```

### Manual Testing
After running the role, WordPress will be available at:
- **Ubuntu**: http://localhost:8180
- **Debian**: http://localhost:8181  
- **Rocky**: http://localhost:8182

## 🔄 CI/CD Integration

This role includes comprehensive CI/CD with GitHub Actions:
- **Automated testing** on Ubuntu 22.04, Debian 12, and Rocky Linux 9
- **ansible-lint** and **yamllint** compliance checking
- **Multi-distribution verification** with Molecule
- **Automatic Galaxy publishing** on releases

## 📊 Supported Distributions

| Distribution | Version | PHP Version | Status |
|-------------|---------|-------------|---------|
| Ubuntu | 22.04 (Jammy) | 8.1 | ✅ Tested |
| Ubuntu | 20.04 (Focal) | 7.4 | ✅ Tested |
| Debian | 12 (Bookworm) | 8.2 | ✅ Tested |
| Debian | 11 (Bullseye) | 7.4 | ✅ Tested |
| Rocky Linux | 9 | 8.0 | ✅ Tested |

## 🏗️ Architecture

### PHP Version Detection
The role automatically detects and installs the appropriate PHP version:

```yaml
# tasks/detect-php-version.yml
- name: Set PHP version based on distribution
  set_fact:
    php_version: >-
      {%- if ansible_distribution == "Ubuntu" and ansible_distribution_version is version('22.04', '==') -%}
        8.1
      {%- elif ansible_distribution == "Debian" and ansible_distribution_version is version('12', '>=') -%}
        8.2
      {%- elif ansible_os_family == "RedHat" -%}
        8.0
      {%- else -%}
        8.1
      {%- endif -%}
```

### Directory Structure
```
roles/wordpress_webserver/
├── defaults/           # Default variables
├── handlers/           # Service handlers
├── meta/              # Role metadata
├── molecule/          # Testing scenarios
├── tasks/             # Main role logic
├── templates/         # Jinja2 templates
├── vars/              # OS-specific variables
├── fix-docker-universal.sh  # Docker compatibility fix
└── README.md          # This file
```

## 🐛 Troubleshooting

### Docker Compatibility Issues
```bash
# Error: "Not supported URL scheme http+docker"
./fix-docker-universal.sh

# Error: "Permission denied" for Docker
sudo usermod -aG docker $USER
newgrep docker  # or logout/login
```

### Molecule Issues
```bash
# Role not found error
molecule list  # Check if scenarios are detected
ansible-config dump | grep ROLES_PATH  # Check role paths

# Container creation fails
docker ps  # Check if Docker daemon is running
molecule destroy  # Clean up previous containers
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. **Run Docker compatibility fix**: `./fix-docker-universal.sh`
4. Add tests for new functionality
5. Run the test suite: `molecule test`
6. Ensure ansible-lint compliance: `ansible-lint .`
7. Submit a pull request

## 📝 License

This project is licensed under the GPL-3.0-or-later License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

Created by [Matias TecnoSoul](https://github.com/matias-tecnosoul)

## 🙏 Acknowledgments

- [Jeff Geerling](https://github.com/geerlingguy) for the excellent `geerlingguy.mysql` role
- The Ansible community for best practices and guidelines
- [Molecule](https://molecule.readthedocs.io/) for testing framework
