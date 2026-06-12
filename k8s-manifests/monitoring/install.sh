#!/bin/bash
# Установка Prometheus + Grafana через Helm

# Добавляем репозиторий
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Устанавливаем kube-prometheus-stack
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=admin \
  --set prometheus.service.type=NodePort \
  --set prometheus.service.nodePort=30900 \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30300
