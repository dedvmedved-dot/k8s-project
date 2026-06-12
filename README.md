# Kubernetes Project — Этап 1: Подготовка Proxmox

## Выполненные шаги

### 1. Очистка Proxmox
Удалены все старые ВМ, очищены хранилища ISO и snippets.

### 2. Настройка Cloud-init и Guest Agent
- Создан snippets storage для cloud-init
- Скачан Ubuntu 24.04 Cloud Image
- Создан шаблон ВМ (ID 9000) с предустановленным Guest Agent
- Cloud-init настроен на автоматическую установку пакетов и запуск сервисов

### 3. Тестовая ВМ
- Клонирована тестовая ВМ (ID 100) из шаблона
- Guest Agent работает
- Cloud-init успешно выполнил настройку

## Структура проекта
```
k8s-project/
├── README.md
├── screenshots/
├── terraform/
├── ansible/
└── k8s-manifests/
```
