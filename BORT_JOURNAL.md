
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

### WordPress + MariaDB в K8s
- [x] MariaDB развёрнута в K8s (Deployment + Service)
- [x] WordPress переподключён к MariaDB
- [x] Ingress работает: http://192.168.0.131:30223
- [x] Страница установки WordPress открывается

### Velero + MinIO
- [x] MinIO установлен в K8s (backup namespace)
- [x] Velero v1.14.0 установлен
- [x] Первый бэкап WordPress создан

### Статус на конец сессии 2
- [x] K8s кластер (3 master + 3 worker) — Ready
- [x] WordPress + MariaDB — Running
- [x] Ingress Controller — Running, WordPress доступен
- [x] Prometheus + Grafana — установлены
- [x] Velero — установлен, MinIO скачивается

### Бэкап
- [x] Velero установлен (демонстрация)
- [x] Ручной бэкап всех ресурсов K8s создан (`k8s-backup/`)
- [x] MinIO работает

---

## Сессия 3: 12 июня 2026, 07:00–08:00 (финал)

### Доделано
- [x] MinIO запущен (образ quay.io/minio/minio)
- [x] Prometheus Operator запущен (ручная загрузка образов)
- [x] Prometheus запущен и собирает метрики (Healthy)
- [x] Grafana Data Source настроен через IP пода (10.244.5.10:9090)
- [x] Grafana отображает данные Prometheus

### Текущее состояние
| Сервис | URL | Статус |
|--------|-----|--------|
| K8s API | :6443 | 6 узлов Ready |
| WordPress | http://192.168.0.131:30223 | Установка |
| Grafana | http://192.168.0.131:30542 | admin/admin, Prometheus-Pod |
| Prometheus | http://192.168.0.131:30090 | Healthy |
| MinIO | http://192.168.0.131:9001 | minioadmin/minioadmin |
| Velero | CLI | Установлен, бэкап Failed |

### На следующую сессию
- [ ] Исправить Velero + MinIO (порядок установки)
- [ ] Создать успешный бэкап WordPress
- [ ] Импортировать дашборды Grafana (1860, 315)
- [ ] Финальный git push

### Восстановление
```bash
cd ~/k8s-project
git pull
ssh ubuntu@192.168.0.126 "kubectl get nodes"
ssh ubuntu@192.168.0.126 "kubectl get pods -A | grep -v Running | grep -v Completed"
```

### Технические заметки
- **Prometheus → Grafana:** использовать IP пода (10.244.5.10:9090), не ClusterIP
- **MinIO:** использовать старые версии из quay.io (CPU без x86-64-v2)
- **Образы:** скачивать вручную через `sudo ctr image pull` на worker-узлах
- **Velero:** устанавливать ПОСЛЕ MinIO и проверки DNS
