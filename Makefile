.DEFAULT_GOAL := up

.PHONY: up init build deploy clean


up:
	./up.sh

init:
	pre-commit install --hook-type commit-msg
	pre-commit install

build:
	docker build -t hostaway:$(version) ./apps/hostaway \
	&& minikube image load hostaway:$(version)

deploy: build
	cd gitops/tenants/hostaway/overlays/$(env) \
	&& kustomize edit set image "hostaway=hostaway:$(version)" \
	&& git commit -am "chore: Deploying hostaway:$(version) to $(env)"

clean:
	minikube delete --all
