
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

---

## Сессия 4: 13 июня 2026, 10:00–15:00 (чистая установка)

### Выполненные работы
- [x] Полная переустановка Proxmox на 2TB диск (nvme0n1) с ZFS
- [x] Создано зеркало vm-pool из двух 1TB дисков (nvme1n1 + nvme2n1) для ВМ
- [x] Создан шаблон Ubuntu 24.04 с Cloud-init и Guest Agent
- [x] Развёрнуто 6 ВМ для K8s (3 master + 3 worker)
- [x] Kubernetes 1.30.14 установлен, кластер работает (6 узлов Ready)
- [x] WordPress + MariaDB развёрнуты (2 пода Running)
- [x] Ingress Controller (Nginx) работает
- [x] Prometheus + Grafana установлены (через Helm)

### Текущая конфигурация хранилищ
| Диск | Размер | Назначение | Тип |
|------|--------|------------|-----|
| nvme0n1 | 2TB | Система Proxmox | ZFS rpool |
| nvme1n1 + nvme2n1 | 1TB + 1TB | Зеркало для ВМ | ZFS vm-pool (mirror) |

### Текущее состояние K8s
| Узел | IP | Роль | Статус |
|------|-----|------|--------|
| k8s-master1 | 192.168.0.132 | control-plane | Ready |
| k8s-master2 | 192.168.0.133 | control-plane | Ready |
| k8s-master3 | 192.168.0.134 | control-plane | Ready |
| k8s-worker | 192.168.0.137 | worker | Ready |
| k8s-worker2 | 192.168.0.135 | worker | Ready |
| k8s-worker3 | 192.168.0.136 | worker | Ready |

### Ключевые уроки
- Установка K8s с `--node-name` решает проблему одинаковых hostname
- Подключение master-узлов по одному (с паузой 40 сек) — etcd успевает синхронизироваться
- После перезапуска kubelet нужно чистить cni0/flannel.1
- Образы лучше скачивать через `ctr image pull` на всех узлах
- ZFS зеркало создаётся одной командой `zpool attach`

### Восстановление после перерыва
```bash
ssh ubuntu@192.168.0.132 "kubectl get nodes"
ssh root@192.168.0.200 "zpool status vm-pool"


---

## Сессия 5: 13 июня 2026, 14:00–17:30 (DNS, Calico, Velero + MinIO)

### Выполненные работы
- [x] Диагностирована проблема DNS: `nslookup` не работает в Alpine-образах, но системный резолвер (glibc) работает
- [x] Обнаружен конфликт IP-адресов после перехода с Flannel на Calico
- [x] Flannel удалён, установлен Calico (CNI)
- [x] Calico межузловая маршрутизация работает (проверено curl-тестом между подами на разных узлах)
- [x] MinIO работает с Calico
- [x] Velero + MinIO: два успешных бэкапа Completed на разных узлах

### Ключевые находки
- **DNS работает:** `curl https://kubernetes.default.svc` → ok, но `nslookup` в Alpine выдаёт NXDOMAIN (не использует search-домены)
- **Переход Flannel → Calico:** старые поды сохраняют IP из диапазона Flannel, нужно пересоздавать ВСЕ поды
- **MinIO emptyDir:** данные теряются при пересоздании пода → нужно использовать PVC для production
- **Calico ipipMode: Always** — использует IP-in-IP туннели для межузловой маршрутизации
- **Velero требует bucket:** нужно создавать через `mkdir /data/velero` в MinIO

### Текущее состояние
| Компонент | Статус | Примечание |
|-----------|--------|------------|
| K8s кластер | ✅ Ready | 6 узлов |
| Calico CNI | ✅ Работает | ipipMode: Always |
| CoreDNS | ✅ Работает | curl резолвит имена |
| MinIO | ✅ Running | emptyDir (не продакшн) |
| Velero | ✅ Completed | 2 успешных бэкапа |
| WordPress | ✅ Running | 2 пода |
| MariaDB | ✅ Running | 1 под |

### Технические заметки
- **MinIO образ:** `quay.io/minio/minio:RELEASE.2022-04-12T06-55-35Z` (без x86-64-v2)
- **Calico манифест:** `https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml`
- **DNS для приложений:** использовать системный резолвер (getaddrinfo), не `nslookup`
- **После смены CNI:** пересоздать все поды (`kubectl delete pods --all -n <namespace>`)

### Восстановление
```bash
ssh ubuntu@192.168.0.132 "kubectl get nodes; kubectl get pods -A | grep -v Running | grep -v Completed"

