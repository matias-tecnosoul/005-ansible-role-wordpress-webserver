# Ansible Role: WordPress Webserver

[![CI](https://github.com/matias-tecnosoul/005-ansible-role-wordpress-webserver/workflows/CI%20Testing%20with%20Molecule/badge.svg)](https://github.com/matias-tecnosoul/005-ansible-role-wordpress-webserver/actions)
[![Galaxy](https://github.com/matias-tecnosoul/005-ansible-role-wordpress-webserver/workflows/Publish%20to%20Ansible%20Galaxy/badge.svg)](https://github.com/matias-tecnosoul/005-ansible-role-wordpress-webserver/actions)
[![License](https://img.shields.io/github/license/matias-tecnosoul/005-ansible-role-wordpress-webserver)](https://github.com/matias-tecnosoul/005-ansible-role-wordpress-webserver/blob/main/LICENSE)

Ansible role for **WordPress webserver setup only** with **automatic PHP version detection** by distribution, Apache HTTP Server configuration. **Database must be configured separately**.

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

## 📋 Requirements

- **Ansible** >= 2.12
- **Python** >= 3.8
- **Target Systems**: Ubuntu, Debian, Rocky Linux
- **Database**: MySQL/MariaDB must be configured separately (see examples below)

## 🏗️ Dependencies

### **No Required Role Dependencies**
This role is designed to be **database-agnostic**. You can use it with:
- `geerlingguy.mysql`
- `geerlingguy.mariadb` 
- External MySQL/PostgreSQL
- Docker containers
- Cloud databases (RDS, etc.)

### **Required Collections**
```yaml
collections:
  - community.general  # For apache2_module
  - ansible.posix     # For firewalld, seboolean
```

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
    # MySQL configuration (for geerlingguy.mysql)
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
    # 1. Setup database FIRST (user choice)
    - geerlingguy.mysql
    
    # 2. Setup webserver
    - matias_tecnosoul.wordpress_webserver
```

### Alternative Database Examples

#### With MariaDB
```yaml
roles:
  - geerlingguy.mariadb
  - matias_tecnosoul.wordpress_webserver
```

#### With External Database
```yaml
vars:
  wordpress_db_host: "external-mysql.example.com"
  wordpress_db_name: wordpress_db
  wordpress_db_user: wp_user
  wordpress_db_password: wp_secure_password

roles:
  - matias_tecnosoul.wordpress_webserver
```

#### With Docker MySQL
```yaml
pre_tasks:
  - name: Start MySQL container
    docker_container:
      name: mysql-wordpress
      image: mysql:8.0
      env:
        MYSQL_ROOT_PASSWORD: "{{ mysql_root_password }}"
        MYSQL_DATABASE: "{{ wordpress_db_name }}"
        MYSQL_USER: "{{ wordpress_db_user }}"
        MYSQL_PASSWORD: "{{ wordpress_db_password }}"
      ports:
        - "3306:3306"

roles:
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

# Database connection
wordpress_db_host: "localhost"                    # Database host

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

Webserver-Only Testing
This role follows the Single Responsibility Principle and only tests webserver components:
✅ What we test:

Apache HTTP server installation and configuration
PHP installation with required extensions
WordPress files downloaded and configured
Virtual host configuration
File permissions and ownership
Basic HTTP response from Apache

❌ What we DON'T test:

Database connectivity (external dependency)
WordPress installation wizard (requires database)
End-to-end functionality (requires complete LAMP stack)

Testing with Molecule
bash# Test webserver components only
molecule test -s ubuntu   # PHP 8.1
molecule test -s debian   # PHP 8.2  
molecule test -s rocky    # PHP 8.0

# Multi-distribution testing
molecule test -s default
Expected HTTP Responses

HTTP 500: Expected without database - WordPress can't connect
HTTP 200/302: With proper database configuration
HTTP 403/404: Also acceptable - Apache is working

Integration Testing
For complete WordPress functionality, combine with database role:
yaml# Complete testing playbook
- hosts: webservers
  roles:
    - geerlingguy.mysql
    - matias_tecnosoul.wordpress_webserver
  
  post_tasks:
    # Now test database connectivity
    - mysql_query:
        login_db: "{{ wordpress_db_name }}"
        query: "SELECT 1"
Manual Testing
After role execution, WordPress will be available for manual setup:

Ubuntu: http://localhost:8180
Debian: http://localhost:8181
Rocky: http://localhost:8182
```

## 📊 Supported Distributions

| Distribution | Version | PHP Version | Status |
|-------------|---------|-------------|---------|
| Ubuntu | 22.04 (Jammy) | 8.1 | ✅ Tested |
| Ubuntu | 20.04 (Focal) | 7.4 | ✅ Tested |
| Debian | 12 (Bookworm) | 8.2 | ✅ Tested |
| Debian | 11 (Bullseye) | 7.4 | ✅ Tested |
| Rocky Linux | 9 | 8.0 | ✅ Tested |

## 🐛 Troubleshooting

### Database Connection Issues
```bash
# Test database connectivity from webserver
mysql -h {{ wordpress_db_host }} -u {{ wordpress_db_user }} -p{{ wordpress_db_password }} {{ wordpress_db_name }}
```

### WordPress Configuration
```bash
# Check wp-config.php
cat /var/www/html/wordpress/wp-config.php | grep DB_
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Add tests for new functionality
4. Run the test suite: `molecule test`
5. Ensure ansible-lint compliance: `ansible-lint .`
6. Submit a pull request

## 📝 License

This project is licensed under the GPL-3.0-or-later License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

Created by [Matias TecnoSoul](https://github.com/matias-tecnosoul)

## 🙏 Acknowledgments

- The Ansible community for best practices and guidelines
- [Molecule](https://molecule.readthedocs.io/) for testing framework
- **Note**: Database setup examples use `geerlingguy.mysql` for demonstration only