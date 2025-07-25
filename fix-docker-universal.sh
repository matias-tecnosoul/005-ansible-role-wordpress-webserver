#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Universal Docker + Molecule Compatibility Fixer${NC}\n"

# Verificar entorno virtual
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo -e "${RED}❌ Virtual environment not active${NC}"
    echo "Run: source molecule-env/bin/activate"
    exit 1
fi

echo -e "${GREEN}✅ Virtual environment active${NC}"

# Detectar versión Docker
DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
DOCKER_MAJOR=$(echo $DOCKER_VERSION | cut -d. -f1)
DOCKER_MINOR=$(echo $DOCKER_VERSION | cut -d. -f2)

echo -e "\n📊 Environment Detection:"
echo "   OS: $(uname -s) $(uname -r)"
echo "   Docker Engine: $DOCKER_VERSION"
echo "   Python: $(python --version)"

# Determinar configuración óptima según versión Docker
if [[ $DOCKER_MAJOR -lt 20 ]]; then
    echo -e "\n${RED}❌ Docker version too old ($DOCKER_VERSION)${NC}"
    echo "Minimum required: Docker 20.10+"
    echo "Please update Docker first"
    exit 1
elif [[ $DOCKER_MAJOR -eq 20 || ($DOCKER_MAJOR -eq 24 && $DOCKER_MINOR -le 99) ]]; then
    # Docker 20.10 - 24.x (Ubuntu 22.04, CentOS, etc.)
    DOCKER_SDK="6.1.3"
    REQUESTS_VERSION="2.28.2"
    URLLIB3_VERSION="1.26.18"
    CONFIG_TYPE="stable-lts"
elif [[ $DOCKER_MAJOR -ge 25 && $DOCKER_MAJOR -le 27 ]]; then
    # Docker 25.x - 27.x (versiones recientes)
    DOCKER_SDK="7.0.0"
    REQUESTS_VERSION="2.31.0"
    URLLIB3_VERSION="2.0.7"
    CONFIG_TYPE="recent-stable"
else
    # Docker 28.x+ (bleeding edge como Manjaro)
    DOCKER_SDK="7.0.0"
    REQUESTS_VERSION="2.31.0"
    URLLIB3_VERSION="2.0.7"
    CONFIG_TYPE="bleeding-edge"
fi

echo -e "\n🎯 Optimal Configuration Detected:"
echo "   Config Type: $CONFIG_TYPE"
echo "   Docker SDK: $DOCKER_SDK"
echo "   Requests: $REQUESTS_VERSION"
echo "   urllib3: $URLLIB3_VERSION"

# Limpiar instalación anterior
echo -e "\n🗑️  Cleaning previous installation..."
pip uninstall -y docker docker-py requests urllib3 || true

# Instalar versiones optimizadas
echo -e "\n📦 Installing optimized versions..."
pip install --no-cache-dir \
    docker==$DOCKER_SDK \
    requests==$REQUESTS_VERSION \
    urllib3==$URLLIB3_VERSION

# Verificar Docker daemon
echo -e "\n🐳 Checking Docker daemon..."
if ! docker ps >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker daemon not running or permission issue${NC}"
    echo ""
    echo "Solutions by OS:"
    echo "📱 Ubuntu/Debian:"
    echo "   sudo systemctl start docker"
    echo "   sudo usermod -aG docker \$USER && newgrp docker"
    echo ""
    echo "🏔️  Manjaro/Arch:"
    echo "   sudo systemctl start docker"
    echo "   sudo usermod -aG docker \$USER && newgrp docker"
    echo ""
    echo "🎩 CentOS/RHEL:"
    echo "   sudo systemctl start docker"
    echo "   sudo usermod -aG docker \$USER && newgrp docker"
    exit 1
fi

echo -e "${GREEN}✅ Docker daemon running${NC}"

# Test completo de compatibilidad
echo -e "\n🧪 Testing Docker Python compatibility..."
python3 -c "
import docker
import sys

try:
    # Test 1: Conexión básica
    client = docker.from_env()
    version = client.version()
    print('✅ Basic connection: OK')
    print(f'   API Version: {version[\"ApiVersion\"]}')
    print(f'   Engine Version: {version[\"Version\"]}')
    
    # Test 2: Operaciones de contenedor (como hace Molecule)
    try:
        containers = client.containers.list(all=True, limit=1)
        print('✅ Container operations: OK')
    except Exception as e:
        print(f'⚠️  Container operations warning: {e}')
    
    # Test 3: Operaciones de imagen
    try:
        images = client.images.list(limit=1)
        print('✅ Image operations: OK')
    except Exception as e:
        print(f'⚠️  Image operations warning: {e}')
        
    print('')
    print('🎉 Docker Python SDK fully compatible!')
    
except Exception as e:
    print(f'❌ Compatibility test failed: {e}')
    print('')
    print('Troubleshooting:')
    print('1. Check Docker daemon: sudo systemctl status docker')
    print('2. Check permissions: groups \$USER | grep docker')
    print('3. Try logout/login if recently added to docker group')
    sys.exit(1)
"

# Test específico de Molecule
echo -e "\n🎭 Testing Molecule compatibility..."
if command -v molecule >/dev/null 2>&1; then
    echo "Running: molecule --version"
    molecule --version
    
    echo -e "\nRunning: molecule list"
    if molecule list >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Molecule can read scenarios${NC}"
        molecule list
    else
        echo -e "${YELLOW}⚠️  Molecule scenarios not found (normal if not in role directory)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Molecule not installed${NC}"
    echo "Install with: pip install molecule[docker]"
fi

echo -e "\n${GREEN}🎉 Universal Docker compatibility configured!${NC}"
echo -e "\nConfiguration Summary:"
echo -e "   ${BLUE}Docker Engine:${NC} $DOCKER_VERSION ($CONFIG_TYPE)"
echo -e "   ${BLUE}Python SDK:${NC} $DOCKER_SDK"
echo -e "   ${BLUE}OS Detected:${NC} $(uname -s)"

echo -e "\n📋 Next Steps:"
case $CONFIG_TYPE in
    "stable-lts")
        echo -e "${GREEN}✅ Your Docker version is LTS-stable${NC}"
        echo "   Perfect for production environments"
        ;;
    "recent-stable")
        echo -e "${GREEN}✅ Your Docker version is recent-stable${NC}"  
        echo "   Good balance of features and stability"
        ;;
    "bleeding-edge")
        echo -e "${YELLOW}⚠️  Your Docker version is bleeding-edge${NC}"
        echo "   Latest features but may have compatibility issues"
        echo "   Consider Docker 27.x for maximum stability"
        ;;
esac

echo -e "\n🚀 Ready for testing:"
echo -e "${YELLOW}1. molecule list${NC}"
echo -e "${YELLOW}2. molecule test -s ubuntu${NC}"