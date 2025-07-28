# Image URL to use all building/pushing image targets
IMG ?= gitops-operator:latest

all: build

# Run tests
test: generate fmt vet
	go test ./... -coverprofile cover.out

# Build manager binary
build: generate fmt vet
	go build -o bin/manager main.go

# Run against the configured Kubernetes cluster
run: export ARGOCD_SERVER=argocd-server.argocd.svc.cluster.local
run: export ARGOCD_AUTH_TOKEN=$(shell kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
run: generate fmt vet
	go run ./main.go

# Install CRDs into a cluster
install: manifests
	kustomize build config/crd | kubectl apply -f -

# Deploy controller in the configured Kubernetes cluster
deploy: manifests
	cd config/manager && kustomize edit set image controller=${IMG}
	kustomize build config/default | kubectl apply -f -

# Generate manifests e.g. CRD, RBAC etc.
manifests: controller-gen
	$(CONTROLLER_GEN) rbac:roleName=manager-role crd paths="./..." output:crd:artifacts:config=config/crd/bases

# Build the docker image
docker-build: test
	docker build . -t ${IMG}

# Push the docker image
docker-push:
	docker push ${IMG}