.DEFAULT_GOAL := up

.PHONY: up init build deploy clean


up: init
	$(MAKE) build version=latest
	$(MAKE) deploy version=latest env=stg sync=off
	$(MAKE) deploy version=latest env=prd sync=off
	./up.sh

init:
	pre-commit install --hook-type commit-msg
	pre-commit install

build:
	docker build -t hostaway:$(version) ./apps/hostaway \
	&& minikube image load hostaway:$(version)

argocd-login:
	password=$$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode) \
	&& argocd login localhost:20080 --skip-test-tls --insecure --username admin --password "$${password}"

deploy: build argocd-login
	cd gitops/tenants/hostaway/overlays/$(env) \
	&& kustomize edit set image "hostaway=*:$(version)" \
	&& git commit -am "chore: Deploying hostaway:$(version) to $(env)" \
	&& ([ $$(sync) -ne 'off' ] && argocd app sync hostaway-$(env) || true)

clean:
	minikube delete --all
