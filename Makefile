.DEFAULT_GOAL := up

.PHONY: up show-infos init build argocd-login deploy clean

.SILENT: show-infos

up: init
	./up.sh
	$(MAKE) build version=latest
	$(MAKE) show-infos

show-infos:
	password=$$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode) \
    && echo -e "\n---" \
	&& echo -e "All set:\n" \
    && echo "Argocd:" \
    && echo "  url: http://localhost:20080" \
    && echo "  username: admin" \
    && echo "  password: $${password}" \
    && echo "Prometheus:" \
    && echo "  url: http://localhost:9090" \
	&& echo "Hostaway NGINX app:" \
	&& echo "  url (stg): http://localhost:8080" \
	&& echo "  url (prd): http://localhost:8090"


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
	&& argocd app sync hostaway-$(env)

clean:
	minikube delete --all
