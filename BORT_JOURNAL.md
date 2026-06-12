
---

## Сессия 2: 12 июня 2026, 04:30–06:30

### Выполненные работы
- [x] Обнаружена проблема: disk size 3.5GB (из шаблона) → расширен до 20GB
- [x] Установлен Kubernetes v1.30.14 на всех 6 узлах (kubeadm)
- [x] Проблема: одинаковый hostname `ubuntu-template` → исправлен через `hostnamectl set-hostname`
- [x] Проблема: `ip_forward` выключен → включён через sysctl
- [x] Проблема: containerd не запустился после reset → ручной перезапуск
- [x] Кластер инициализирован: 3 master + 3 worker, все Ready
- [x] Установлен Flannel CNI (10.244.0.0/16)
- [x] Создана схема K8s кластера
- [x] Репозиторий запушен на GitHub

### Текущее состояние K8s кластера
| Узел | IP | Роль | Статус |
|------|-----|------|--------|
| k8s-master1 | 192.168.0.126 | control-plane | Ready |
| k8s-master2 | 192.168.0.127 | control-plane | Ready |
| k8s-master3 | 192.168.0.128 | control-plane | Ready |
| k8s-worker1 | 192.168.0.129 | worker | Ready |
| k8s-worker2 | 192.168.0.130 | worker | Ready |
| k8s-worker3 | 192.168.0.131 | worker | Ready |

### Ключевые команды для восстановления
```bash
# Проверка кластера
ssh ubuntu@192.168.0.126 "kubectl get nodes"
ssh ubuntu@192.168.0.126 "kubectl get pods -A"

# Подключение нового узла (если токен истёк)
ssh ubuntu@192.168.0.126 "kubeadm token create --print-join-command"
```

### Следующие шаги
- Развернуть WordPress в K8s
- Настроить Ingress, ConfigMap, Secrets
- Подключить Patroni PostgreSQL
- Настроить Velero + MinIO для бэкапов

### WordPress развёрнут
- [x] Namespace, Secret, Deployment, Service созданы
- [x] Проблема: Flannel CrashLoopBackOff (br_netfilter) → modprobe br_netfilter
- [x] WordPress: 2 пода Running (worker2, worker3)
- [x] Ingress Controller устанавливается
