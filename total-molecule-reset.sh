#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 Complete Molecule Reset & Cleanup${NC}\n"

# Verificar entorno virtual
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo -e "${RED}❌ Virtual environment not active${NC}"
    echo "Run: source molecule-env/bin/activate"
    exit 1
fi

echo -e "${GREEN}✅ Virtual environment active${NC}"

# 1. Nuclear cleanup - forzar eliminación de todos los contenedores
echo -e "\n💥 Nuclear cleanup - removing all containers..."

# Parar todos los contenedores de Molecule
echo "Stopping all molecule containers..."
docker ps -a --filter "label=molecule_project" --format "{{.Names}}" | xargs -r docker stop 2>/dev/null || true
docker ps -a --filter "name=molecule" --format "{{.Names}}" | xargs -r docker stop 2>/dev/null || true

# Eliminar contenedores específicos que vimos en la lista
CONTAINERS_TO_REMOVE=(
    "ubuntu-instance"
    "debian-instance" 
    "rocky-instance"
    "ubuntu2204-instance"
    "debian12-instance"
    "rocky9-instance"
)

for container in "${CONTAINERS_TO_REMOVE[@]}"; do
    if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
        echo "Removing container: $container"
        docker rm -f "$container" 2>/dev/null || true
    fi
done

# Limpiar cualquier otro contenedor molecule
docker ps -a --filter "label=molecule_project" -q | xargs -r docker rm -f 2>/dev/null || true
docker ps -a --filter "name=molecule" -q | xargs -r docker rm -f 2>/dev/null || true

echo -e "${GREEN}✅ All containers removed${NC}"

# 2. Limpiar completamente el estado de Molecule
echo -e "\n🧹 Cleaning Molecule state..."
rm -rf .molecule/ 2>/dev/null || true
rm -rf ~/.cache/molecule/ 2>/dev/null || true
rm -rf ~/.ansible/ 2>/dev/null || true

# Limpiar cache específico del proyecto
rm -rf ~/.cache/molecule/005-ansible-role-wordpress-webserver/ 2>/dev/null || true

echo -e "${GREEN}✅ Molecule state cleaned${NC}"

# 3. Verificar que no quedan contenedores
echo -e "\n🔍 Verifying no containers remain..."
REMAINING=$(docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep -E "(molecule|ubuntu-instance|debian-instance|rocky-instance)" || echo "None")
if [[ "$REMAINING" == "None" ]]; then
    echo -e "${GREEN}✅ No molecule containers remaining${NC}"
else
    echo -e "${YELLOW}⚠️  Remaining containers:${NC}"
    echo "$REMAINING"
fi

# 4. Limpiar scenarios individuales
echo -e "\n🎭 Resetting individual scenarios..."
SCENARIOS=("default" "ubuntu" "debian" "rocky")

for scenario in "${SCENARIOS[@]}"; do
    if [[ -d "molecule/$scenario" ]]; then
        echo "Resetting scenario: $scenario"
        molecule reset -s "$scenario" 2>/dev/null || echo "  (reset not needed for $scenario)"
    fi
done

# 5. Verificar estructura de scenarios
echo -e "\n📁 Verifying scenario structure..."
for scenario_dir in molecule/*/; do
    scenario=$(basename "$scenario_dir")
    
    if [[ -f "$scenario_dir/molecule.yml" ]]; then
        echo -e "${GREEN}✅ $scenario${NC}: molecule.yml found"
        
        # Verificar si tiene converge.yml
        if [[ -f "$scenario_dir/converge.yml" ]]; then
            echo -e "${GREEN}   ✅ converge.yml found${NC}"
        else
            echo -e "${RED}   ❌ converge.yml missing${NC}"
        fi
    else
        echo -e "${RED}❌ $scenario${NC}: molecule.yml missing"
    fi
done

# 6. Test de conectividad Docker limpia
echo -e "\n🐳 Testing clean Docker connectivity..."
python3 -c "
import docker
try:
    client = docker.from_env()
    version = client.version()
    print('✅ Docker connectivity: OK')
    print(f'   API Version: {version[\"ApiVersion\"]}')
except Exception as e:
    print(f'❌ Docker connectivity: {e}')
    exit(1)
"

# 7. Reinstalar dependencias Galaxy limpias
echo -e "\n📦 Installing clean Galaxy dependencies..."
if [[ -f "requirements.yml" ]]; then
    # Limpiar dependencias anteriores
    rm -rf geerlingguy.mysql/ 2>/dev/null || true
    rm -rf roles/ 2>/dev/null || true
    
    # Instalar limpias
    ansible-galaxy install -r requirements.yml --force
    echo -e "${GREEN}✅ Galaxy dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠️  requirements.yml not found${NC}"
fi

# 8. Test básico de Molecule
echo -e "\n🧪 Testing Molecule functionality..."
if molecule --version >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Molecule working${NC}"
    
    # Test de listado (debería estar limpio)
    echo -e "\n📋 Current molecule scenarios:"
    molecule list 2>/dev/null || echo "No scenarios ready (expected after cleanup)"
    
else
    echo -e "${RED}❌ Molecule not working${NC}"
fi

# 9. Crear un scenario test limpio
echo -e "\n🎯 Creating clean test scenario..."

# Elegir el scenario más simple para test
TEST_SCENARIO="ubuntu"

if [[ -d "molecule/$TEST_SCENARIO" ]] && [[ -f "molecule/$TEST_SCENARIO/molecule.yml" ]]; then
    echo "Testing scenario: $TEST_SCENARIO"
    
    # Test de creación limpia
    echo "Creating fresh instance..."
    if molecule create -s "$TEST_SCENARIO"; then
        echo -e "${GREEN}✅ $TEST_SCENARIO scenario creation: SUCCESS${NC}"
        
        # Verificar contenedor
        sleep 2
        if docker ps --filter "name=${TEST_SCENARIO}" | grep -q "Up"; then
            echo -e "${GREEN}✅ Container running successfully${NC}"
            
            # Cleanup del test
            echo "Cleaning up test instance..."
            molecule destroy -s "$TEST_SCENARIO" 2>/dev/null || docker rm -f "${TEST_SCENARIO}-instance" 2>/dev/null || true
        else
            echo -e "${YELLOW}⚠️  Container not running as expected${NC}"
        fi
    else
        echo -e "${RED}❌ $TEST_SCENARIO scenario creation: FAILED${NC}"
    fi
fi

echo -e "\n${GREEN}🎉 Complete Molecule reset finished!${NC}"
echo -e "\n📋 Next steps:"
echo "1. molecule list  # Should show clean state"
echo "2. molecule create -s ubuntu  # Create a fresh instance"
echo "3. molecule converge -s ubuntu  # Deploy the role"
echo "4. molecule verify -s ubuntu  # Run tests"
echo "5. molecule destroy -s ubuntu  # Clean up"

echo -e "\n💡 If issues persist:"
echo "- Check Docker daemon: sudo systemctl restart docker"
echo "- Check permissions: groups \$USER | grep docker"
echo "- Restart terminal/shell session"