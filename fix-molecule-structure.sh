#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing Molecule Role Structure${NC}\n"

# Verificar que estemos en el directorio correcto
if [[ ! -f "meta/main.yml" ]]; then
    echo -e "${YELLOW}⚠️  Not in role root directory${NC}"
    echo "Please cd to the role directory (where meta/main.yml exists)"
    echo "Current path: $(pwd)"
    exit 1
fi

echo -e "${GREEN}✅ In role root directory${NC}"

# Backup de archivos actuales
echo -e "\n📦 Creating backups..."
mkdir -p .molecule-backup
cp -r molecule/ .molecule-backup/ 2>/dev/null || echo "No previous molecule/ found"

# Fix 1: Actualizar todos los converge.yml para usar path relativo
echo -e "\n🔧 Fixing converge.yml files..."

# Default scenario
cat > molecule/default/converge.yml << 'EOF'
---
- name: Converge Multi-Distro
  hosts: all
  become: true
  gather_facts: true
  
  tasks:
    - name: Include wordpress_webserver role (relative path)
      ansible.builtin.include_role:
        name: "{{ playbook_dir | dirname | dirname | basename }}"
EOF

# Ubuntu scenario
cat > molecule/ubuntu/converge.yml << 'EOF'
---
- name: Converge Ubuntu
  hosts: all
  become: true
  gather_facts: true
  
  tasks:
    - name: Include wordpress_webserver role (relative path)
      ansible.builtin.include_role:
        name: "{{ playbook_dir | dirname | dirname | basename }}"
EOF

# Debian scenario
cat > molecule/debian/converge.yml << 'EOF'
---
- name: Converge Debian
  hosts: all
  become: true
  gather_facts: true
  
  tasks:
    - name: Include wordpress_webserver role (relative path)
      ansible.builtin.include_role:
        name: "{{ playbook_dir | dirname | dirname | basename }}"
EOF

# Rocky scenario
cat > molecule/rocky/converge.yml << 'EOF'
---
- name: Converge Rocky
  hosts: all
  become: true
  gather_facts: true
  
  tasks:
    - name: Include wordpress_webserver role (relative path)
      ansible.builtin.include_role:
        name: "{{ playbook_dir | dirname | dirname | basename }}"
EOF

# Fix 2: Crear ansible.cfg para Molecule
echo -e "\n⚙️  Creating molecule ansible.cfg..."
cat > ansible.cfg << 'EOF'
[defaults]
roles_path = ./
host_key_checking = False
stdout_callback = yaml
callbacks_enabled = profile_tasks, timer

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[ssh_connection]
pipelining = True
EOF

# Fix 3: Alternativa más simple - usar tasks directas
echo -e "\n🎯 Creating simplified converge files (alternative method)..."

mkdir -p molecule/simple/

cat > molecule/simple/converge.yml << 'EOF'
---
- name: Converge Simple
  hosts: all
  become: true
  gather_facts: true
  
  tasks:
    # Importar tareas directamente en lugar de usar el role
    - name: Include main tasks
      ansible.builtin.include_tasks: ../../tasks/main.yml
      vars:
        # Variables necesarias para el role
        mysql_root_password: "test_root_password"
        mysql_databases:
          - name: "test_wordpress_db"
            encoding: utf8mb4
            collation: utf8mb4_unicode_ci
        mysql_users:
          - name: "test_wp_user"
            password: "test_wp_password"
            priv: "test_wordpress_db.*:ALL"
        wordpress_domain: "simple-test.local"
        wordpress_db_name: "test_wordpress_db"
        wordpress_db_user: "test_wp_user"
        wordpress_db_password: "test_wp_password"
EOF

cat > molecule/simple/molecule.yml << 'EOF'
---
dependency:
  name: galaxy
  options:
    requirements-file: ../../requirements.yml

driver:
  name: docker

platforms:
  - name: simple-instance
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    command: /lib/systemd/systemd
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host
    published_ports:
      - "8183:80"

provisioner:
  name: ansible
  config_options:
    defaults:
      host_key_checking: false
      stdout_callback: yaml

verifier:
  name: ansible
EOF

echo -e "\n${GREEN}🎉 Molecule structure fixed!${NC}"
echo -e "\n📋 Available testing methods:"
echo -e "${YELLOW}Method 1 - Direct role inclusion:${NC}"
echo "   molecule test -s ubuntu"
echo ""
echo -e "${YELLOW}Method 2 - Simple tasks inclusion:${NC}"  
echo "   molecule test -s simple"
echo ""
echo -e "${YELLOW}Method 3 - Quick test:${NC}"
echo "   molecule create -s ubuntu"
echo "   molecule converge -s ubuntu"
echo ""
echo -e "🔍 If issues persist, check:"
echo "   molecule list"
echo "   ansible-config dump | grep ROLES_PATH"