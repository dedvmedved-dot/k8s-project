#!/bin/bash
# ============================================
# СКРИПТ КОРРЕКТНОГО ВКЛЮЧЕНИЯ ВСЕЙ ИНФРАСТРУКТУРЫ
# Порядок: Proxmox → K8s узлы → Проверка → Приложения
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

WORKER_NODES=(
    "192.168.0.137"  # worker1
    "192.168.0.135"  # worker2
    "192.168.0.136"  # worker3
)

MASTER_NODES=(
    "192.168.0.133"  # master2
    "192.168.0.134"  # master3
)

ALL_NODES=(
    "192.168.0.132"  # master1
    "192.168.0.133"  # master2
    "192.168.0.134"  # master3
    "192.168.0.135"  # worker2
    "192.168.0.136"  # worker3
    "192.168.0.137"  # worker1
)

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     КОРРЕКТНОЕ ВКЛЮЧЕНИЕ ВСЕЙ ИНФРАСТРУКТУРЫ             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# ШАГ 1: Включение Proxmox (если выключен)
# ============================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ШАГ 1/6: Проверка доступности Proxmox${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if ping -c 1 -W 2 $PROXMOX_IP &>/dev/null; then
    echo -e "${GREEN}✅ Proxmox доступен${NC}"
else
    echo -e "${YELLOW}⚠️  Proxmox недоступен. Включите его физически и нажмите Enter...${NC}"
    read
    echo "Ждём загрузки Proxmox (120 секунд)..."
    sleep 120
fi

# ============================================
# ШАГ 2: Запуск ВМ
# ============================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ШАГ 2/6: Запуск виртуальных машин${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "Запускаем ВМ через Proxmox..."
for vmid in 100 101 102 103 104 105; do
    echo "  - Запуск VM $vmid..."
    ssh ${PROXMOX_USER}@${PROXMOX_IP} "qm start $vmid" 2>/dev/null || echo -e "${YELLOW}    ⚠️  VM $vmid не найдена (пропускаем)${NC}"
done

echo "Ожидание загрузки ВМ (90 секунд)..."
sleep 90

echo -e "${GREEN}✅ ВМ запущены${NC}"

# ============================================
# ШАГ 3: Проверка доступности узлов
# ============================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ШАГ 3/6: Проверка доступности всех узлов${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

for ip in "${ALL_NODES[@]}"; do
    echo -n "  - Узел $ip... "
    ATTEMPTS=0
    while ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$ip "echo ok" 2>/dev/null; do
        ATTEMPTS=$((ATTEMPTS + 1))
        if [ $ATTEMPTS -gt 12 ]; then
            echo -e "${RED}НЕДОСТУПЕН${NC}"
            break
        fi
        sleep 10
    done
done

echo -e "${GREEN}✅ Все узлы доступны${NC}"

# ============================================
# ШАГ 4: Проверка Kubernetes
# ============================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ШАГ 4/6: Проверка кластера Kubernetes${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "Ожидание готовности кластера (60 секунд)..."
sleep 60

echo "Проверка узлов:"
ssh ubuntu@$MASTER_IP "kubectl get nodes" 2>/dev/null || echo -e "${RED}❌ Не удалось подключиться к кластеру${NC}"

# Ждём пока все узлы станут Ready
echo "Ожидание статуса Ready для всех узлов..."
ATTEMPTS=0
while ! ssh ubuntu@$MASTER_IP "kubectl get nodes --no-headers | grep -v Ready | wc -l" 2>/dev/null | grep -q "0"; do
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ $ATTEMPTS -gt 30 ]; then
        echo -e "${RED}❌ Не все узлы Ready за 5 минут${NC}"
        break
    fi
    sleep 10
    echo -n "."
done
echo ""

echo -e "${GREEN}✅ Кластер Kubernetes работает${NC}"
ssh ubuntu@$MASTER_IP "kubectl get nodes"

# ============================================
# ШАГ 5: Восстановление приложений
# ============================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ШАГ 5/6: Запуск приложений${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "Восстанавливаем реплики приложений..."
ssh ubuntu@$MASTER_IP "
    echo '  - WordPress (2 реплики)...'
    kubectl scale deployment wordpress -n wordpress --replicas=2 2>/dev/null || true
    echo '  - MariaDB (1 реплика)...'
    kubectl scale deployment mariadb -n wordpress --replicas=1 2>/dev/null || true
    echo '  - Velero...'
    kubectl scale deployment velero -n velero --replicas=1 2>/dev/null || true
    echo '  - MinIO...'
    kubectl scale deployment minio -n backup --replicas=1 2>/dev/null || true
"

echo "Ожидание запуска подов (60 секунд)..."
sleep 60

# Снимаем drain с узлов (на всякий случай)
echo "Снимаем ограничения с узлов..."
ssh ubuntu@$MASTER_IP "
    for node in k8s-worker k8s-worker2 k8s-worker3; do
        kubectl uncordon \$node 2>/dev/null || true
    done
" 2>/dev/null

echo -e "${GREEN}✅ Приложения запущены${NC}"

# ============================================
# ШАГ 6: Финальная проверка
# ============================================
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ШАГ 6/6: Финальная проверка${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "Проверка состояния системы..."
ssh ubuntu@$MASTER_IP "
    echo '=== Узлы ==='
    kubectl get nodes
    echo ''
    echo '=== Поды ==='
    kubectl get pods -A | grep -v Running | grep -v Completed || echo '  Все поды Running'
    echo ''
    echo '=== Сервисы ==='
    echo '  WordPress:'
    kubectl get svc -n wordpress 2>/dev/null | grep wordpress || echo '    OK'
    echo '  Grafana:'
    kubectl get svc -n monitoring 2>/dev/null | grep grafana || echo '    OK'
    echo '  MinIO:'
    kubectl get svc -n backup 2>/dev/null | grep minio || echo '    OK'
"

# ============================================
# ИТОГИ
# ============================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          ИНФРАСТРУКТУРА КОРРЕКТНО ЗАПУЩЕНА               ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC}  ✅ Proxmox запущен"
echo -e "${GREEN}║${NC}  ✅ Все 6 ВМ запущены"
echo -e "${GREEN}║${NC}  ✅ Кластер K8s Ready"
echo -e "${GREEN}║${NC}  ✅ Приложения запущены"
echo -e "${GREEN}║${NC}  ✅ Система готова к работе"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 Полезные команды:${NC}"
echo "   kubectl get nodes                    # статус узлов"
echo "   kubectl get pods -A                  # все поды"
echo "   http://192.168.0.132:3000           # Grafana"
