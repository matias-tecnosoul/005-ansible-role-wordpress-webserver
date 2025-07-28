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
