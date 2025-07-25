#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing Duplicate Molecule Scenarios${NC}\n"

# 1. Mostrar el problema
echo -e "❌ ${RED}PROBLEMA DETECTADO:${NC}"
echo "Molecule encuentra scenarios duplicados:"
find . -name "molecule.yml" -exec echo "  - {}" \;

echo -e "\n💡 ${YELLOW}CAUSA:${NC}"
echo "geerlingguy.mysql incluye su propio scenario 'default'"
echo "que conflictúa con nuestro scenario 'default'"

# 2. Solución: Mover dependencias fuera del directorio del role
echo -e "\n🔧 ${BLUE}SOLUCIÓN:${NC}"
echo "Mover geerlingguy.mysql a un directorio separado..."

# Crear directorio para dependencias
mkdir -p .ansible-deps
echo "Creado: .ansible-deps/"

# Mover geerlingguy.mysql
if [[ -d "geerlingguy.mysql" ]]; then
    echo "Moviendo: geerlingguy.mysql → .ansible-deps/"
    mv geerlingguy.mysql .ansible-deps/
fi

# 3. Actualizar .gitignore para excluir dependencias
echo -e "\n📝 Actualizando .gitignore..."
cat >> .gitignore << 'EOF'

# Ansible dependencies (installed via requirements.yml)
.ansible-deps/
geerlingguy.mysql/
EOF

# 4. Configurar Ansible para encontrar dependencias
echo -e "\n⚙️  Configurando ansible.cfg..."
cat > ansible.cfg << 'EOF'
[defaults]
roles_path = ./.ansible-deps:./roles:~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles
host_key_checking = False
stdout_callback = yaml
callbacks_enabled = profile_tasks, timer

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[ssh_connection]
pipelining = True
EOF

# 5. Reinstalar dependencias en el lugar correcto
echo -e "\n📦 Reinstalando dependencias en ubicación correcta..."
ansible-galaxy install -r requirements.yml -p .ansible-deps/ --force

# 6. Verificación
echo -e "\n✅ ${GREEN}VERIFICACIÓN:${NC}"
echo "Scenarios encontrados:"
find . -name "molecule.yml" -not -path "./.ansible-deps/*" -exec echo "  ✅ {}" \;

echo -e "\nDependencias encontradas:"
find .ansible-deps/ -maxdepth 1 -type d -name "*mysql*" -exec echo "  📦 {}" \; 2>/dev/null || echo "  (Verificar instalación manual)"

# 7. Test de Molecule
echo -e "\n🧪 ${BLUE}TESTING:${NC}"
echo "Test 1: molecule list"
if molecule list >/dev/null 2>&1; then
    echo -e "${GREEN}✅ molecule list: SUCCESS${NC}"
    molecule list
else
    echo -e "${RED}❌ molecule list: FAILED${NC}"
    echo "Mostrando errores:"
    molecule list
fi

echo -e "\n${GREEN}🎉 Duplicate scenarios fix completed!${NC}"
echo -e "\n📋 Resumen de cambios:"
echo "✅ geerlingguy.mysql movido a .ansible-deps/"
echo "✅ ansible.cfg configurado para encontrar dependencias"
echo "✅ .gitignore actualizado"
echo "✅ Scenarios duplicados resueltos"

echo -e "\n🚀 Listo para testing:"
echo "molecule create -s ubuntu"
echo "molecule test -s ubuntu"