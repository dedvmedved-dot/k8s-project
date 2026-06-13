#!/bin/bash
# ============================================
# БЫСТРОЕ ВЫКЛЮЧЕНИЕ ВСЕЙ ИНФРАСТРУКТУРЫ
# Без бэкапа, без drain, без подтверждений
# Использование: ./shutdown-fast.sh [--force]
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROXMOX="192.168.0.200"
MASTER="192.168.0.132"

# Все узлы в порядке выключения (worker → master)
NODES=(
    "192.168.0.137"  # k8s-worker
    "192.168.0.135"  # k8s-worker2
    "192.168.0.136"  # k8s-worker3
    "192.168.0.134"  # k8s-master3
    "192.168.0.133"  # k8s-master2
    "192.168.0.132"  # k8s-master1
)

FORCE=0
if [ "$1" = "--force" ]; then
    FORCE=1
fi

echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
echo -e "${RED}║   БЫСТРОЕ ВЫКЛЮЧЕНИЕ ИНФРАСТРУКТУРЫ   ║${NC}"
echo -e "${RED}╚══════════════════════════════════════════╝${NC}"

if [ $FORCE -eq 0 ]; then
    echo -e "${RED}⚠️  Будет немедленно выключено:${NC}"
    echo "   • 6 узлов Kubernetes"
    echo "   • Proxmox (опционально)"
    echo ""
    echo -e "${YELLOW}Для пропуска подтверждения:${NC}"
    echo "   ./shutdown-fast.sh --force"
    echo ""
    read -p "Продолжить? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Отменено."
        exit 0
    fi
fi

echo ""
echo -e "${BLUE}[1/2] Выключение узлов K8s...${NC}"

# Параллельное выключение всех узлов
for ip in "${NODES[@]}"; do
    {
        ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no ubuntu@$ip "sudo shutdown -h now" 2>/dev/null &
    } &
done

# Ждём завершения всех shutdown
wait
echo "   ✅ Команды shutdown отправлены на все узлы"

echo ""
echo -e "${BLUE}[2/2] Выключение Proxmox...${NC}"

if [ $FORCE -eq 1 ]; then
    echo "   Выключаем Proxmox..."
    ssh -o ConnectTimeout=5 root@$PROXMOX "shutdown -h now" 2>/dev/null &
    echo "   ✅ Proxmox выключается"
else
    read -p "   Выключить Proxmox? (yes/no): " SHUT
    if [ "$SHUT" = "yes" ]; then
        ssh -o ConnectTimeout=5 root@$PROXMOX "shutdown -h now" 2>/dev/null &
        echo "   ✅ Proxmox выключается"
    else
        echo "   ⏭ Пропущено"
    fi
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ИНФРАСТРУКТУРА ВЫКЛЮЧАЕТСЯ...       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
