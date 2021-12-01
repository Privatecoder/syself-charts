
##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


helm: kustomize helmify
	# Cluster-api 
	$(KUSTOMIZE) build github.com/kubernetes-sigs/cluster-api/config/default?ref=v1.0.1 | $(HELMIFY) charts/cluster-api
	$(KUSTOMIZE) build github.com/kubernetes-sigs/cluster-api/controlplane/kubeadm/config/default?ref=v1.0.1 | $(HELMIFY) charts/cluster-api-controlplane-provider-kubeadm
	$(KUSTOMIZE) build github.com/kubernetes-sigs/cluster-api/bootstrap/kubeadm/config/default?ref=v1.0.1 | $(HELMIFY) charts/cluster-api-bootstrap-provider-kubeadm
	# Cluster-api Provider
	$(KUSTOMIZE) build github.com/syself/cluster-api-provider-hetzner/config/default?ref=v1.0.0-alpha.1 | $(HELMIFY) charts/cluster-api-provider-hetzner

KUSTOMIZE = $(shell pwd)/bin/kustomize
kustomize: ## Download kustomize locally if necessary.
	$(call go-get-tool,$(KUSTOMIZE),sigs.k8s.io/kustomize/kustomize/v3@v3.8.7)

HELMIFY = $(shell pwd)/bin/helmify
helmify: ## Download helmify locally if necessary.
	$(call go-get-tool,$(HELMIFY),github.com/arttor/helmify/cmd/helmify@v0.3.4)

# go-get-tool will 'go get' any package $2 and install it to $1.
PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
define go-get-tool
@[ -f $(1) ] || { \
set -e ;\
TMP_DIR=$$(mktemp -d) ;\
cd $$TMP_DIR ;\
go mod init tmp ;\
echo "Downloading $(2)" ;\
GOBIN=$(PROJECT_DIR)/bin go get $(2) ;\
rm -rf $$TMP_DIR ;\
}
endef