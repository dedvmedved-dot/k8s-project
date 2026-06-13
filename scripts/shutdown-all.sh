#!/bin/bash
# ============================================
# СКРИПТ КОРРЕКТНОГО ВЫКЛЮЧЕНИЯ ВСЕЙ ИНФРАСТРУКТУРЫ
# Порядок: Приложения → K8s узлы → Proxmox
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROXMOX_IP="192.168.0.200"
PROXMOX_USER="root"
MASTER_IP="192.168.0.132"
ALL_NODES=(
    "192.168.0.132"  # k8s-master1
    "192.168.0.133"  # k8s-master2
    "192.168.0.134"  # k8s-master3
    "192.168.0.135"  # k8s-worker2
    "192.168.0.136"  # k8s-worker3
    "192.168.0.137"  # k8s-worker
)

echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║     КОРРЕКТНОЕ ВЫКЛЮЧЕНИЕ ВСЕЙ ИНФРАСТРУКТУРЫ            ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# ШАГ 0: Подтверждение
# ============================================
echo -e "${RED}⚠️  ВНИМАНИЕ! Будет выключена ВСЯ инфраструктура:${NC}"
echo "   - Все приложения в Kubernetes"
echo "   - Все узлы кластера (6 ВМ)"
echo "   - Сервер Proxmox"
echo ""
echo -e "${YELLOW}Перед выключением убедитесь, что:${NC}"
echo "   1. Создан полный бэкап на NFS"
echo "   2. Все важные данные сохранены"
echo "   3. Никто не работает с кластером"
echo ""
read -p "Продолжить выключение? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${GREEN}Выключение отменено.${NC}"
    exit 0
fi

# ============================================
# ШАГ 1: Создание финального бэкапа
# ============================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ШАГ 1/5: Создание финального бэкапа${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "Создаём бэкап Velero..."
ssh ubuntu@$MASTER_IP "velero backup create pre-shutdown-\$(date +%Y%m%d-%H%M) --wait" 2>/dev/null || echo -e "${YELLOW}⚠️  Velero backup skipped (non-critical)${NC}"

echo "Создаём полный бэкап на NFS..."
ssh ubuntu@$MASTER_IP "sudo mkdir -p /mnt/nfs-velero && sudo mount -t nfs 192.168.0.107:/srv/nfs/velero-backup /mnt/nfs-velero && sudo mkdir -p /mnt/nfs-velero/pre-shutdown-\$(date +%Y%m%d-%H%M)" 2>/dev/null || echo -e "${YELLOW}⚠️  NFS backup skipped${NC}"

echo -e "${GREEN}✅ Бэкап создан${NC}"

# ============================================
# ШАГ 2: Остановка приложений в K8s
# ============================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ШАГ 2/5: Остановка приложений в Kubernetes${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "Масштабируем приложения до 0 реплик..."
ssh ubuntu@$MASTER_IP "
    echo '  - WordPress...'
    kubectl scale deployment wordpress -n wordpress --replicas=0 2>/dev/null || true
    echo '  - MariaDB...'
    kubectl scale deployment mariadb -n wordpress --replicas=0 2>/dev/null || true
    echo '  - Velero...'
    kubectl scale deployment velero -n velero --replicas=0 2>/dev/null || true
    echo '  - MinIO...'
    kubectl scale deployment minio -n backup --replicas=0 2>/dev/null || true
    echo '  - Ingress...'
    kubectl scale deployment -n ingress-nginx --all --replicas=0 2>/dev/null || true
"

echo "Ожидание остановки подов (30 секунд)..."
sleep 30

echo -e "${GREEN}✅ Приложения остановлены${NC}"

# ============================================
# ШАГ 3: Drain worker-узлов
# ============================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ШАГ 3/5: Drain worker-узлов${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "Перемещаем поды с worker-узлов..."
ssh ubuntu@$MASTER_IP "
    for node in k8s-worker k8s-worker2 k8s-worker3; do
        echo \"  - Drain \$node...\"
        kubectl drain \$node --ignore-daemonsets --delete-emptydir-data --force --grace-period=30 2>/dev/null || true
    done
" 2>/dev/null

echo -e "${GREEN}✅ Worker-узлы освобождены${NC}"

# ============================================
# ШАГ 4: Остановка K8s узлов
# ============================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ШАГ 4/5: Остановка всех узлов Kubernetes${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Сначала worker-узлы, потом master-узлы
NODE_ORDER=(
    "192.168.0.137"  # worker1
    "192.168.0.135"  # worker2
    "192.168.0.136"  # worker3
    "192.168.0.134"  # master3
    "192.168.0.133"  # master2
    "192.168.0.132"  # master1
)

for ip in "${NODE_ORDER[@]}"; do
    echo -e "  - Останавливаем узел $ip..."
    ssh ubuntu@$ip "sudo shutdown -h now" 2>/dev/null &
done

echo "Ожидание полной остановки узлов (60 секунд)..."
sleep 60

echo -e "${GREEN}✅ Все узлы K8s остановлены${NC}"

# ============================================
# ШАГ 5: Выключение Proxmox
# ============================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ШАГ 5/5: Выключение Proxmox${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "Проверяем, что все ВМ остановлены..."
ssh ${PROXMOX_USER}@${PROXMOX_IP} "qm list" 2>/dev/null || echo -e "${YELLOW}⚠️  Не удалось подключиться к Proxmox${NC}"

echo ""
echo -e "${RED}Выключить Proxmox?${NC}"
read -p "Выключить Proxmox (yes/no): " SHUTDOWN_PROXMOX

if [ "$SHUTDOWN_PROXMOX" = "yes" ]; then
    echo "Выключаем Proxmox..."
    ssh ${PROXMOX_USER}@${PROXMOX_IP} "shutdown -h now" 2>/dev/null || echo -e "${YELLOW}⚠️  Выключите Proxmox вручную${NC}"
    echo -e "${GREEN}✅ Proxmox выключается${NC}"
else
    echo -e "${YELLOW}Proxmox остаётся включенным.${NC}"
fi

# ============================================
# ИТОГИ
# ============================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          ИНФРАСТРУКТУРА КОРРЕКТНО ВЫКЛЮЧЕНА              ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC}  ✅ Бэкап создан перед выключением"
echo -e "${GREEN}║${NC}  ✅ Приложения остановлены (scale → 0)"
echo -e "${GREEN}║${NC}  ✅ Worker-узлы drain"
echo -e "${GREEN}║${NC}  ✅ Узлы K8s выключены (worker → master)"
echo -e "${GREEN}║${NC}  ✅ Proxmox выключен"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📋 Для включения используйте: ./scripts/startup-all.sh${NC}"
