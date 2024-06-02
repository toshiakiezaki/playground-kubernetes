PWD=$(shell pwd -L)

ifneq (,$(wildcard .env))
    include .env
    export
endif

all: help

install: install-cilium install-hubble install-helm install-kubectl install-kind install-terraform        ## Install all dependency binaries

install-cilium:                                                                                           ## Install cilium dependency binary
	@echo "Installing Cilium Command Line Tool..."
	@mkdir -p work
	@cd work && \
	 curl -s -Lo "cilium.tar.gz" https://github.com/cilium/cilium-cli/releases/download/$$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)/cilium-linux-amd64.tar.gz && \
	 tar -xf cilium.tar.gz && \
	 sudo install "cilium" "/usr/local/bin" && \
	 sudo chmod +x "/usr/local/bin/cilium"
	@rm -rf work

install-hubble:                                                                                           ## Install hubble dependency binary
	@echo "Installing Cilium Hubble Instrumentation Tool..."
	@mkdir -p work
	@cd work && \
	 curl -s -Lo "hubble.tar.gz" https://github.com/cilium/hubble/releases/download/$$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)/hubble-linux-amd64.tar.gz && \
	 tar -xf hubble.tar.gz && \
	 sudo install "hubble" "/usr/local/bin" && \
	 sudo chmod +x "/usr/local/bin/hubble"
	@rm -rf work

install-helm:                                                                                             ## Install helm dependency binary
	@echo "Installing Kubernetes Helm Development Tool..."
	@mkdir -p work
	@cd work && \
	 curl -s -Lo "helm.tar.gz" https://get.helm.sh/helm-v$$(curl -s https://api.github.com/repos/helm/helm/tags | jq -r '.[].name' | grep -E -v 'rc|beta|alpha|dev' | cut -d 'v' -f 2 | sort -t. -k 1,1n -k 2,2n -k 3,3n | tail -1)-linux-amd64.tar.gz && \
	 tar -xf helm.tar.gz && \
	 sudo install "linux-amd64/helm" "/usr/local/bin" && \
	 sudo chmod +x "/usr/local/bin/helm" && \
	 helm repo add argo          https://argoproj.github.io/argo-helm                       --force-update && \
	 helm repo add kong          https://charts.konghq.com                                  --force-update && \
	 helm repo add cilium        https://helm.cilium.io                                     --force-update && \
	 helm repo add grafana       https://grafana.github.io/helm-charts                      --force-update && \
	 helm repo add opentelemetry https://open-telemetry.github.io/opentelemetry-helm-charts --force-update && \
	 helm repo update && \
	 rm -rf "linux-amd64"
	@rm -rf work

install-kubectl:                                                                                          ## Install kubectl dependency binary
	@echo "Installing Kubernetes Controller Development Tool..."
	@mkdir -p work
	@cd work && \
	 curl -s -Lo "kubectl" https://storage.googleapis.com/kubernetes-release/release/$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
	 sudo install "kubectl" "/usr/local/bin" && \
	 sudo chmod +x "/usr/local/bin/kubectl"
	@rm -rf work

install-kind:                                                                                             ## Install kind dependency binary
	@echo "Installing Kubernetes Kind Development Tool..."
	@mkdir -p work
	@cd work && \
	 curl -s -Lo "kind" https://kind.sigs.k8s.io/dl/v$$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/tags | jq -r '.[].name' | grep -E -v 'rc|beta|alpha|dev' | cut -d 'v' -f 2 | sort -t. -k 1,1n -k 2,2n -k 3,3n | tail -1)/kind-linux-amd64 && \
	 sudo install "kind" "/usr/local/bin" && \
	 sudo chmod +x "/usr/local/bin/kind"
	@rm -rf work

install-terraform:                                                                                        ## Install terraform dependency binary
	@echo "Installing HashiCorp Terraform Development Tool..."
	@mkdir -p work
	@cd work && \
	 curl -s -Lo "terraform.zip" $$(curl -s https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].builds[].url' | sort -t. -k 3.15,3n -k 4,4n -k 5,5n | grep -E -v 'rc|beta|alpha' | grep -E 'linux.*amd64' | tail -1) && \
	 sudo unzip -qq -o "terraform.zip" -d "." && \
	 sudo install "terraform" "/usr/local/bin" && \
	 sudo chmod +x "/usr/local/bin/terraform"
	@rm -rf work

cluster: cluster-status                                                                                   ## Execute default task for cluster

cluster-create:                                                                                           ## Configure a new cluster
	@if [ "$$(kind get clusters --quiet | grep $${KIND_CLUSTER_NAME:-kind})" == "" ]; then \
	 	echo "Creating cluster with profile '$${KIND_CLUSTER_NAME:-kind}'" && \
		kind create cluster --config cluster/kind-cluster-settings.yaml && \
		helm install -n kube-system cilium cilium/cilium -f cluster/cilium-operator.yaml; \
	 else \
	 	echo "Cluster already exists with profile '$${KIND_CLUSTER_NAME:-kind}'"; \
	 fi

cluster-destroy:                                                                                          ## Destroy existing cluster
	@if [ "$$(kind get clusters --quiet | grep $${KIND_CLUSTER_NAME:-kind})" != "" ]; then \
	 	echo "Destroying cluster with profile '$${KIND_CLUSTER_NAME:-kind}'" && \
		kind delete cluster; \
	 else \
		echo "Cluster does not exists with profile '$${KIND_CLUSTER_NAME:-kind}'"; \
	 fi

cluster-status:                                                                                           ## Show cluster status
	@if [ "$$(kind get clusters --quiet | grep $${KIND_CLUSTER_NAME:-kind})" != "" ]; then \
	 	echo "Describing cluster with profile '$${KIND_CLUSTER_NAME:-kind}'" && \
		kubectl cluster-info --context kind-$${KIND_CLUSTER_NAME:-kind} && \
		echo && \
		kubectl get nodes; \
	 else \
		echo "Cluster does not exists with profile '$${KIND_CLUSTER_NAME:-kind}'"; \
	 fi

help:                                                                                                     ## Display help screen
	@echo "Usage:"
	@echo "	 make [COMMAND]"
	@echo "	 make help \n"
	@echo "Commands: \n"
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
