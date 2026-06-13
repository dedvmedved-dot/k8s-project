#!/bin/bash
# ============================================
# Полный скрипт: создание .dot файлов и генерация SVG-схем
# Требование: установленный Graphviz (sudo apt install graphviz)
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Генерация схем: .dot -> .svg${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if ! command -v dot &> /dev/null; then
    echo -e "${YELLOW}Graphviz not found. Installing...${NC}"
    sudo apt-get update -qq && sudo apt-get install -y graphviz
fi

mkdir -p "$SCREENSHOTS_DIR"

# Counters
TOTAL=0
SUCCESS=0

generate_diagram() {
    local name="$1"
    local content="$2"
    local dot_file="$SCREENSHOTS_DIR/$name"
    local svg_file="${dot_file%.dot}.svg"
    
    TOTAL=$((TOTAL + 1))
    echo -e "${YELLOW}[$TOTAL] $name${NC}"
    
    echo "$content" > "$dot_file"
    
    if dot -Tsvg "$dot_file" -o "$svg_file" 2>/dev/null; then
        echo -e "    ${GREEN}OK: $svg_file ($(du -h "$svg_file" | cut -f1))${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "    ${RED}ERROR generating SVG${NC}"
    fi
    echo ""
}

# ============================================
# DIAGRAMS
# ============================================

generate_diagram "K8s_Architecture.dot" 'digraph K8s_Architecture {
    label="Архитектура Kubernetes кластера"; labelloc=t; fontsize=20;
    rankdir=TB; splines=ortho;
    node [shape=box, style=rounded, fontsize=10];
    
    subgraph cluster_masters {
        label="Control Plane (3 Master)"; style=filled; fillcolor="#FFD0D0";
        m1 [label="k8s-master1\n.132"]; m2 [label="k8s-master2\n.133"]; m3 [label="k8s-master3\n.134"];
        m1 -> m2 [dir=both]; m2 -> m3 [dir=both];
    }
    subgraph cluster_workers {
        label="Worker Nodes"; style=filled; fillcolor="#D0FFD0";
        w1 [label="worker1\n.137"]; w2 [label="worker2\n.135"]; w3 [label="worker3\n.136"];
    }
    subgraph cluster_svc {
        label="Services"; style=filled; fillcolor="#E0E0FF";
        wp [label="WordPress+MariaDB"]; mon [label="Prometheus+Grafana"]; bak [label="Velero+MinIO"];
    }
    m1 -> w1; m1 -> w2; m1 -> w3;
    w1 -> wp; w2 -> mon; w3 -> bak;
}'

generate_diagram "Calico_Network.dot" 'digraph Calico_Network {
    label="Calico CNI: IP-in-IP туннели"; labelloc=t; fontsize=18;
    rankdir=TB; splines=ortho;
    node [shape=box, style=rounded, fontsize=10];
    
    subgraph cluster_phys {
        label="Physical 192.168.0.0/24"; style=filled; fillcolor="#FFFFE0";
        n1 [label="master1\n.132"]; n2 [label="worker\n.137"]; n3 [label="worker2\n.135"];
    }
    subgraph cluster_overlay {
        label="Overlay 10.244.0.0/16"; style=filled; fillcolor="#E0FFFF";
        tunnel [label="IP-in-IP tunnels\nMTU 1440", shape=cylinder];
        pod1 [label="Pod A\n10.244.1.10"]; pod2 [label="Pod B\n10.244.254.20"];
    }
    n1 -> tunnel; n2 -> tunnel; n3 -> tunnel;
    tunnel -> pod1; tunnel -> pod2;
    pod1 -> pod2 [label="routed via tunnel", color="#CC6600"];
}'

generate_diagram "DNS_Resolution.dot" 'digraph DNS_Resolution {
    label="DNS Resolution in Kubernetes"; labelloc=t; fontsize=18;
    rankdir=TB; splines=ortho;
    node [shape=box, style=rounded, fontsize=10];
    
    subgraph cluster_ok {
        label="OK: glibc getaddrinfo"; style=filled; fillcolor="#E0FFE0";
        app [label="App (curl)" shape=component]; resolv [label="/etc/resolv.conf\nsearch svc.cluster.local", shape=note];
        coredns [label="CoreDNS\n10.96.0.10:53", shape=cylinder]; ok [label="IP resolved", style=bold];
        app -> resolv -> coredns -> ok;
    }
    subgraph cluster_fail {
        label="FAIL: Alpine nslookup"; style=filled; fillcolor="#FFE0E0";
        alpine [label="Alpine nslookup", shape=component]; fail [label="NXDOMAIN", style=bold];
        alpine -> fail;
    }
}'

generate_diagram "Backup_Flow.dot" 'digraph Backup_Flow {
    label="Backup Flow: Velero -> MinIO -> NFS"; labelloc=t; fontsize=18;
    rankdir=LR; splines=ortho;
    node [shape=box, style=rounded, fontsize=10];
    
    wp [label="WordPress Pod", fillcolor="#FFD0D0"];
    velero [label="Velero Controller", fillcolor="#D0D0FF"];
    minio [label="MinIO S3\nPVC 10Gi", fillcolor="#D0FFD0"];
    nfs [label="NFS Server\nskhome01", fillcolor="#FFE0FF"];
    
    wp -> velero [label="1. Backup"]; velero -> minio [label="2. Save S3"];
    minio -> nfs [label="3. Copy to NFS", style=bold];
    nfs -> minio [label="4. Restore", style=dashed];
}'

generate_diagram "Monitoring_Stack.dot" 'digraph Monitoring_Stack {
    label="Monitoring: Prometheus + Grafana"; labelloc=t; fontsize=18;
    rankdir=TB; splines=ortho;
    node [shape=box, style=rounded, fontsize=10];
    
    ne [label="Node Exporter\nx6 pods", fillcolor="#E0FFE0"];
    ksm [label="kube-state-metrics", fillcolor="#E0FFE0"];
    cad [label="cAdvisor\nx6 pods", fillcolor="#E0FFE0"];
    prom [label="Prometheus Server\n:9090", fillcolor="#E0E0FF"];
    graf [label="Grafana\nDashboard 315, 1860", fillcolor="#FFE0E0"];
    
    ne -> prom; ksm -> prom; cad -> prom;
    prom -> graf [label="PromQL", penwidth=2];
}'

generate_diagram "Deployment_Process.dot" 'digraph Deployment_Process {
    label="Deployment Process"; labelloc=t; fontsize=18;
    rankdir=TB; splines=ortho;
    node [shape=box, style=rounded, fontsize=10];
    
    subgraph s1 { label="Stage 1: Proxmox"; style=filled; fillcolor="#FFE8E8";
        a[label="Install VE 9.2"]; b[label="ZFS mirror"]; c[label="Ubuntu template"]; a->b->c; }
    subgraph s2 { label="Stage 2: VMs"; style=filled; fillcolor="#FFE8CC";
        d[label="Clone 6 VMs"]; e[label="Static IPs"]; f[label="ContainerD"]; d->e->f; }
    subgraph s3 { label="Stage 3: K8s"; style=filled; fillcolor="#FFFFCC";
        g[label="kubeadm init"]; h[label="Join masters"]; i[label="Join workers"]; g->h->i; }
    subgraph s4 { label="Stage 4: Services"; style=filled; fillcolor="#CCFFCC";
        j[label="Calico CNI"]; k[label="WordPress"]; l[label="Velero+MinIO"]; m[label="Prometheus"]; j->k->l->m; }
    s1->s2->s3->s4;
}'

generate_diagram "RoadmapPosition.dot" 'digraph RoadmapPosition {
    rankdir=LR; splines=ortho;
    node [style=filled, fontsize=11];
    labelloc="t"; label="Roadmap Position"; fontsize=16;
    
    subgraph cluster_dz { label="Homework (DONE)"; style=filled; fillcolor="#E0F2F1";
        dz [label="K8s + WordPress", shape=box, fillcolor="#FFFFFF"]; }
    subgraph cluster_pr { label="PROJECT (NOW)\nDeadline: Sep 1"; style=filled; fillcolor="#FFF3E0";
        db [label="Patroni DB", shape=box, fillcolor="#FFFFFF"];
        web [label="WordPress HA", shape=box, fillcolor="#FFFFFF"];
        fw [label="NetworkPolicy", shape=box, fillcolor="#FFFFFF"]; }
    subgraph cluster_ai { label="AIOps (FUTURE)"; style=filled; fillcolor="#FCE4EC";
        ai [label="ML + LLM", shape=box, style=dashed, fillcolor="#FFFFFF"]; }
    dz -> web [style=dashed]; web -> ai [style=dashed];
}'

generate_diagram "ProjectArchitecture.dot" 'digraph ProjectArchitecture {
    rankdir=TB; splines=ortho; compound=true;
    node [style=filled, fontsize=10];
    labelloc="t"; label="Project Architecture"; fontsize=16;
    
    subgraph cluster_iac { label="IaC"; style=filled; fillcolor="#ECEFF1";
        tf [label="Terraform", shape=box, fillcolor="#FFFFFF"]; }
    subgraph cluster_k8s { label="Kubernetes"; style=filled; fillcolor="#E3F2FD";
        m1 [label="Master", shape=box, fillcolor="#FFFFFF"];
        w1 [label="Workers", shape=box, fillcolor="#FFFFFF"]; }
    subgraph cluster_app { label="Apps"; style=filled; fillcolor="#E8F5E9";
        wp [label="WordPress\n3 replicas", shape=box, fillcolor="#FFFFFF"];
        pg [label="Patroni\n3 nodes", shape=cylinder, fillcolor="#FFFFFF"]; }
    subgraph cluster_obs { label="Observability"; style=filled; fillcolor="#FFF3E0";
        prom [label="Prometheus", shape=box, fillcolor="#FFFFFF"];
        logs [label="Kafka+ClickHouse", shape=box, fillcolor="#FFFFFF"]; }
    
    tf -> m1; w1 -> wp; w1 -> pg; wp -> pg [label="SQL", penwidth=2];
    wp -> logs [style=dashed]; wp -> prom [style=dashed];
}'

generate_diagram "DataFlow.dot" 'digraph DataFlow {
    rankdir=TB; splines=ortho;
    node [style=filled, fontsize=10];
    labelloc="t"; label="Data Flows"; fontsize=14;
    
    user [label="User", shape=oval, fillcolor="#BBDEFB"];
    ingress [label="Ingress :80", shape=box, fillcolor="#FFFFFF"];
    wp [label="WordPress", shape=box, fillcolor="#FFFFFF"];
    pg [label="PostgreSQL", shape=cylinder, fillcolor="#FFFFFF"];
    kafka [label="Kafka", shape=box, fillcolor="#FFFFFF"];
    prom [label="Prometheus", shape=box, fillcolor="#FFFFFF"];
    grafana [label="Grafana", shape=box, fillcolor="#FFFFFF"];
    
    user -> ingress -> wp [penwidth=2];
    wp -> pg [label="SQL", penwidth=2];
    wp -> kafka [label="Logs", style=dashed];
    wp -> prom [label="Metrics", style=dashed];
    kafka -> grafana; prom -> grafana [penwidth=2];
}'

generate_diagram "TechStack.dot" 'digraph TechStack {
    rankdir=TB; splines=ortho;
    node [style=filled, fontsize=11];
    labelloc="t"; label="Technology Stack"; fontsize=16;
    
    subgraph cluster_iac { label="IaC"; fillcolor="#ECEFF1";
        tf [label="Terraform", fillcolor="#FFFFFF"]; }
    subgraph cluster_orch { label="Orchestration"; fillcolor="#E3F2FD";
        k8s [label="Kubernetes", fillcolor="#FFFFFF"]; }
    subgraph cluster_app { label="Applications"; fillcolor="#E8F5E9";
        wp [label="WordPress", fillcolor="#FFFFFF"];
        pg [label="Patroni+PostgreSQL", fillcolor="#FFFFFF"]; }
    subgraph cluster_obs { label="Observability"; fillcolor="#FFF3E0";
        prom [label="Prometheus", fillcolor="#FFFFFF"];
        graf [label="Grafana", fillcolor="#FFFFFF"];
        kafka [label="Kafka", fillcolor="#FFFFFF"];
        ch [label="ClickHouse", fillcolor="#FFFFFF"]; }
    subgraph cluster_bkp { label="Backup"; fillcolor="#F3E5F5";
        velero [label="Velero", fillcolor="#FFFFFF"];
        minio [label="MinIO", fillcolor="#FFFFFF"]; }
    
    k8s -> wp; k8s -> pg; wp -> pg [penwidth=2];
    wp -> kafka; wp -> prom; prom -> graf;
    velero -> minio;
}'

generate_diagram "ImplementationPlan.dot" 'digraph ImplementationPlan {
    rankdir=TB; splines=ortho;
    node [shape=box, style=filled, fontsize=10];
    labelloc="t"; label="Implementation Plan"; fontsize=14;
    
    subgraph p1 { label="Phase 1: Infrastructure"; fillcolor="#E0F2F1";
        s1[label="1.1 Terraform VMs"]; s2[label="1.2 K8s install"]; s3[label="1.3 Ingress"]; s4[label="1.4 Patroni"];
        s1->s2->s3->s4; }
    subgraph p2 { label="Phase 2: Deploy"; fillcolor="#FFF3E0";
        s5[label="2.1 WordPress"]; s6[label="2.2 Ingress routes"]; s7[label="2.3 NetworkPolicy"];
        s4->s5->s6->s7; }
    subgraph p3 { label="Phase 3: Observability"; fillcolor="#FCE4EC";
        s8[label="3.1 Prometheus+Grafana"]; s9[label="3.2 ELK logs"]; s10[label="3.3 Backup"];
        s7->s8->s9->s10; }
}'

generate_diagram "ProjectToAIOps.dot" 'digraph ProjectToAIOps {
    rankdir=LR; splines=ortho;
    node [style=filled, fontsize=10];
    labelloc="t"; label="Project -> AIOps Evolution"; fontsize=14;
    
    subgraph cluster_now { label="Project (NOW)"; fillcolor="#FFF3E0";
        logs [label="Kafka+ClickHouse", shape=box, fillcolor="#FFFFFF"];
        metrics [label="Prometheus", shape=box, fillcolor="#FFFFFF"];
        wp [label="WordPress", shape=box, fillcolor="#FFFFFF"]; }
    subgraph cluster_future { label="AIOps (FUTURE)"; fillcolor="#FCE4EC";
        flink [label="Flink", shape=box, fillcolor="#FFFFFF"];
        ml [label="ML Models", shape=box, fillcolor="#FFFFFF"];
        llm [label="LLM Agent", shape=box, fillcolor="#FFFFFF"]; }
    
    logs -> flink [penwidth=2]; metrics -> ml [penwidth=2];
    flink -> ml; ml -> llm; wp -> llm [style=dashed];
}'

# ============================================
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Generated: $SUCCESS / $TOTAL diagrams${NC}"
echo -e "Location: $SCREENSHOTS_DIR"
echo -e "${BLUE}========================================${NC}"
