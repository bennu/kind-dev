.PHONY: startup
startup: bootstrap addons

.PHONY: bootstrap
bootstrap:
	@echo "+ $@"
	kind create cluster --config kind.config --name local

.PHONY: addons
addons:
	@echo "+ $@"
	./hack/enabled-addon.sh metrics-server
	./hack/enabled-addon.sh dashboard
	./hack/enabled-addon.sh ingress-nginx

.PHONY: clean
clean:
	@echo "+ $@"
	kind delete cluster --name local
