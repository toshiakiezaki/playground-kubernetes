PWD=$(shell pwd -L)

ifneq (,$(wildcard .env))
    include .env
    export
endif

all: help

install: install-cilium install-hubble install-helm install-kubectl install-minikube install-terraform    ## Install all dependency binaries

install-cilium:                                                                                           ## Install cilium dependency binary
	@echo "Installing Cilium Command Line Tool..."
	@mkdir -p work
	@cd work && \
	 curl -s -Lo "cilium.tar.gz" https://github.com/cilium/cilium-cli/releases/download/$$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)/cilium-linux-amd64.tar.gz && \
	 tar -xf cilium.tar.gz && \
	 sudo install "cilium" "/usr/local/bin" && \
	 sudo chmod +x "/usr/local/bin/cilium"
	@rm -rf work


install-helm:                                                                                             ## Install helm dependency binary
	@echo "Installing Kubernetes Helm Development Tool..."
	@mkdir -p work
	@cd work && \
	 curl -s -Lo "helm.tar.gz" https://get.helm.sh/helm-v$$(curl -s https://api.github.com/repos/helm/helm/tags | jq -r '.[].name' | grep -E -v 'rc|beta|alpha|dev' | cut -d 'v' -f 2 | sort -t. -k 1,1n -k 2,2n -k 3,3n | tail -1)-linux-amd64.tar.gz && \
	 tar -xf helm.tar.gz && \
	 sudo install "linux-amd64/helm" "/usr/local/bin" && \
	 sudo chmod +x "/usr/local/bin/helm" && \
	 rm -rf "linux-amd64"
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


install-kubectl:                                                                                          ## Install kubectl dependency binary
	@echo "Installing Kubernetes Controller Development Tool..."
	@mkdir -p work
	@cd work && \
	 curl -s -Lo "kubectl" https://storage.googleapis.com/kubernetes-release/release/$$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
	 sudo install "kubectl" "/usr/local/bin" && \
	 sudo chmod +x "/usr/local/bin/kubectl"
	@rm -rf work

install-minikube:                                                                                         ## Install minikube dependency binary
	@echo "Installing Minikube Development Tool..."
	@mkdir -p work
	@cd work && \
	 curl -s -Lo "minikube" https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
	 sudo install "minikube" "/usr/local/bin" && \
	 sudo chmod +x "/usr/local/bin/minikube"
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

cluster-start:                                                                                            ## Start existing cluster
	@if [ "$$(minikube profile list -l -o json | jq -r '.valid[].Name' | grep playground)" == "" ]; then \
		echo "Cluster does not exists with profile '$${MINIKUBE_PROFILE:-minikube}'"; \
	 else \
		minikube start; \
	 fi

cluster-stop:                                                                                             ## Stop existing cluster
	@if [ "$$(minikube profile list -l -o json | jq -r '.valid[].Name' | grep playground)" == "" ]; then \
		echo "Cluster does not exists with profile '$${MINIKUBE_PROFILE:-minikube}'"; \
	 else \
		minikube stop; \
	 fi

cluster-config:                                                                                           ## Configure a new cluster
	@if [ "$$(minikube profile list -l -o json | jq -r '.valid[].Name' | grep playground)" == "" ]; then \
	 	echo "Creating cluster with profile '$${MINIKUBE_PROFILE:-minikube}'" && \
		minikube start --network-plugin=cni --cni=false --cpus=4 --memory=16000 --dns-domain="$${MINIKUBE_DOMAIN:-svc.local}" --extra-config="kubelet.cluster-domain=$${MINIKUBE_DOMAIN:-svc.local}" && \
		cilium install --set cluster.id=1 --set hubble.relay.enabled=true --set hubble.ui.enabled=true --set hubble.peerService.clusterDomain="$${MINIKUBE_DOMAIN:-svc.local}" --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}"  && \
		cilium hubble enable --ui ; \
	 else \
	 	echo "Cluster already exists with profile '$${MINIKUBE_PROFILE:-minikube}'"; \
	 fi

cluster-destroy:                                                                                          ## Destroy existing cluster
	@if [ "$$(minikube profile list -l -o json | jq -r '.valid[].Name' | grep playground)" != "" ]; then \
	 	echo "Destroying cluster with profile '$${MINIKUBE_PROFILE:-minikube}'" && \
		minikube delete; \
	 else \
		echo "Cluster does not exists with profile '$${MINIKUBE_PROFILE:-minikube}'"; \
	 fi

cluster-status:                                                                                           ## Show cluster status
	@if [ "$$(minikube profile list -l -o json | jq -r '.valid[].Name' | grep playground)" != "" ]; then \
	 	echo "Describing cluster with profile '$${MINIKUBE_PROFILE:-minikube}'" && \
		minikube status; \
	 else \
		echo "Cluster does not exists with profile '$${MINIKUBE_PROFILE:-minikube}'"; \
	 fi

help:                                                                                                     ## Display help screen
	@echo "Usage:"
	@echo "	 make [COMMAND]"
	@echo "	 make help \n"
	@echo "Commands: \n"
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
