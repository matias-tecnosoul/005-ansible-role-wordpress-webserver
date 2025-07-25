#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 Quick Molecule Check"
echo "======================"

# 1. Verificar estructura básica
echo -e "\n📁 Directory structure:"
echo "Current dir: $(pwd)"
echo "Molecule dir exists: $(test -d molecule && echo "✅ YES" || echo "❌ NO")"

# 2. Verificar cada scenario
echo -e "\n🎭 Scenario validation:"
for scenario in ubuntu debian rocky default; do
    if [[ -f "molecule/$scenario/molecule.yml" ]]; then
        echo -e "${GREEN}✅ $scenario${NC}: molecule.yml exists"
        
        # Verificar que el YAML es válido
        if python3 -c "import yaml; yaml.safe_load(open('molecule/$scenario/molecule.yml'))" 2>/dev/null; then
            echo -e "   ${GREEN}✅ Valid YAML${NC}"
        else
            echo -e "   ${RED}❌ Invalid YAML${NC}"
        fi
    else
        echo -e "${RED}❌ $scenario${NC}: molecule.yml missing"
    fi
done

# 3. Test directo de Molecule
echo -e "\n🧪 Direct Molecule tests:"

echo "Test 1: molecule --version"
molecule --version

echo -e "\nTest 2: molecule list (all scenarios)"
molecule list 2>&1 | head -10

echo -e "\nTest 3: molecule list -s ubuntu (specific)"
molecule list -s ubuntu

echo -e "\nTest 4: Check for conflicts"
# Verificar si hay conflictos de nombres o paths
find . -name "molecule.yml" -exec echo "Found: {}" \;

echo -e "\n🎯 Recommendation:"
if molecule list -s ubuntu >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Molecule is working fine!${NC}"
    echo "The warning in fix-docker-universal.sh is a false positive."
    echo -e "\n🚀 Ready to test:"
    echo "molecule create -s ubuntu"
else
    echo -e "${RED}❌ There are real Molecule issues${NC}"
    echo "Need to investigate further."
fi