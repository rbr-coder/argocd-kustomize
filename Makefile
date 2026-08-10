# Variables

NAMESPACE_SECRET_PRINTER = webserver
NAMESPACE_ARGOCD = argocd

KUBECONFIG = $(HOME)/.kube/config

ARGOCD_RELEASE_NAME = argocd
ARGOCD_CHART_VERSION = 10.2.1


# Common Helm options

HELM_OPTS = --kubeconfig $(KUBECONFIG) --create-namespace


.PHONY: help \
        add-argo-repo \
        install-argo \
        uninstall-argo \
        apply-webserver-app \
        uninstall-webserver-app \
        install-all \
        clean


# Default target: shows usage information

help:
	@echo "Available targets:"
	@echo "  install-argo             - Install ArgoCD"
	@echo "  uninstall-argo           - Uninstall ArgoCD"
	@echo "  apply-webserver-app      - Create ArgoCD Application for the Webserver"
	@echo "  uninstall-webserver-app  - Delete ArgoCD Application for the Webserver"
	@echo "  install-all              - Install ArgoCD and Webserver"
	@echo "  clean                    - Remove Webserver and ArgoCD"


# Add Argo Helm repository

add-argo-repo:
	@echo "Adding Argo Helm repository..."
	helm repo add argo https://argoproj.github.io/argo-helm --force-update
	helm repo update


# Install ArgoCD using the official Helm chart and custom values

install-argo: add-argo-repo
	@echo "Installing ArgoCD..."
	helm upgrade --install $(ARGOCD_RELEASE_NAME) argo/argo-cd \
		--version $(ARGOCD_CHART_VERSION) \
		--namespace $(NAMESPACE_ARGOCD) \
		#--values argocd/values.yaml \
		$(HELM_OPTS)


# Uninstall ArgoCD

uninstall-argo:
	@echo "Uninstalling ArgoCD..."
	helm uninstall $(ARGOCD_RELEASE_NAME) \
		--namespace $(NAMESPACE_ARGOCD) \
		--kubeconfig $(KUBECONFIG) || true


# Create ArgoCD Application for the Webserver

apply-webserver-app:
	@echo "Applying ArgoCD Webserver application..."
	kubectl apply \
		-f argocd/secret_printer_webserver_app.yaml \
		--namespace $(NAMESPACE_ARGOCD) \
		--kubeconfig $(KUBECONFIG)


# Remove ArgoCD Application for the Webserver

uninstall-webserver-app:
	@echo "Removing ArgoCD Webserver application..."
	kubectl delete \
		-f argocd/secret_printer_webserver_app.yaml \
		--namespace $(NAMESPACE_ARGOCD) \
		--kubeconfig $(KUBECONFIG) \
		--ignore-not-found=true


# Install ArgoCD and deploy Webserver application

install-all: install-argo apply-webserver-app
	@echo "Installation complete."


# Remove Webserver application and ArgoCD

clean: uninstall-webserver-app uninstall-argo
	@echo "Cleaning up namespaces..."

	kubectl delete namespace $(NAMESPACE_SECRET_PRINTER) \
		--kubeconfig $(KUBECONFIG) \
		--ignore-not-found=true

	kubectl delete namespace $(NAMESPACE_ARGOCD) \
		--kubeconfig $(KUBECONFIG) \
		--ignore-not-found=true

	@echo "Cleanup complete."