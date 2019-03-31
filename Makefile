.PHONY: kind-dev
kind-dev: startup addons

.PHONY: startup
startup:
	@echo "+ $@"
	kind create cluster --config kind.config --name local

.PHONY: addons
addons:
	@echo "+ $@"
	./hack/enabled-addon.sh metric-server
	./hack/enabled-addon.sh metallb
	./hack/enabled-addon.sh ingress-nginx

.PHONY: clean
clean:
	@echo "+ $@"
	kind delete cluster --name local