.PHONY: install test run image kind-up kind-load deploy port-forward clean terraform-fmt

IMAGE ?= sre-platform-api:local
CLUSTER ?= sre-platform-lab

install:
	python -m venv .venv
	.venv/bin/pip install -r requirements.txt

test:
	.venv/bin/pytest -q

run:
	.venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

image:
	docker build -t $(IMAGE) .

kind-up:
	kind create cluster --name $(CLUSTER) --config infra/local/kind-config.yaml

kind-load: image
	kind load docker-image $(IMAGE) --name $(CLUSTER)

deploy: kind-load
	helm upgrade --install platform-api helm/platform-api \
		--namespace platform-api --create-namespace \
		--set image.repository=sre-platform-api \
		--set image.tag=local \
		--set image.pullPolicy=IfNotPresent

port-forward:
	kubectl -n platform-api port-forward svc/platform-api 8000:80

terraform-fmt:
	terraform -chdir=infra/oci fmt -recursive

clean:
	kind delete cluster --name $(CLUSTER)
