VENV 	?= venv
PYTHON 	= $(VENV)/bin/python3
PIP		= $(VENV)/bin/pip

# Variables used to configure
IMAGE_REGISTRY_DOCKERHUB 	?= docker.io
IMAGE_REGISTRY_GHCR			?= ghcr.io
IMAGE_ORG_GHCR				?= keepcodingclouddevops7
IMAGE_REPO					?= oscarmontes
IMAGE_NAME					?= liberando-productos-oscarmontes
VERSION						?= dev

# Variables used to configure docker images registries to build and push
##IMAGE 				= $(IMAGE_REGISTRY_DOCKERHUB)/$(IMAGE_NAME):$(VERSION)
IMAGE_DOCKER		= $(IMAGE_REGISTRY_DOCKERHUB)/$(IMAGE_REPO)/$(IMAGE_NAME)
IMAGE_DOCKER_LATEST	= $(IMAGE_REGISTRY_DOCKERHUB)/$(IMAGE_REPO)/$(IMAGE_NAME):latest
IMAGE_GHCR			= $(IMAGE_REGISTRY_GHCR)/$(IMAGE_ORG_GHCR)/$(IMAGE_REPO)/$(IMAGE_NAME)
IMAGE_GHCR_LATEST	= $(IMAGE_REGISTRY_GHCR)/$(IMAGE_ORG_GHCR)/$(IMAGE_REPO)/$(IMAGE_NAME):latest

.PHONY: run
run: $(VENV)/bin/activate
	$(PYTHON) src/app.py

.PHONY: unit-test
unit-test: $(VENV)/bin/activate
	pytest

.PHONY: unit-test-coverage
unit-test-coverage: $(VENV)/bin/activate
	pytest --cov

.PHONY: $(VENV)/bin/activate
$(VENV)/bin/activate: requirements.txt
	python3 -m venv $(VENV)
	$(PIP) install -r requirements.txt

.PHONY: docker-build
docker-build: ## Build image
	docker build -t $(IMAGE_DOCKER):$(VERSION) -t $(IMAGE_DOCKER_LATEST) 
	 -t $(IMAGE_GHCR):$(VERSION) -t $(IMAGE_GHCR_LATEST) .

##-t $(IMAGE_GHCR)

.PHONY: publish
publish: docker-build ## Publish image
	docker push $(IMAGE_DOCKER)
#	docker push $(IMAGE_DOCKER_LATEST)
	docker push $(IMAGE_GHCR)
#	docker push $(IMAGE_GHCR_LATEST)
