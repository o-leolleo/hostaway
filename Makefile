.DEFAULT_GOAL := up

.PHONY: up init build deploy clean


up:
	./up.sh

init:
	pre-commit install --hook-type commit-msg
	pre-commit install

build:
	docker build -t hostaway:$(version) ./apps/hostaway \
	&& minikube cache add hostaway:$(version) \
	&& minikube cache reload

deploy: build
	cd gitops/tenants/hostaway/overlays/$(env) \
	&& kustomize edit set image "hostaway=hostaway:$(version)" \
	&& git commit -am "Deploying hostaway:$(version) to $(env)"

clean:
	minikube delete --all
