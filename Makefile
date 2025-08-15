.PHONY: setup-repo init build-app clean


init:
	./init.sh

setup-repo:
	pre-commit install --hook-type commit-msg
	pre-commit install

build-app:
	docker build -t hostaway ./apps/hostaway

clean:
	minikube delete --all
