.DEFAULT_GOAL := up

.PHONY: setup-repo up init build-app clean


up:
	./up.sh

init:
	pre-commit install --hook-type commit-msg
	pre-commit install

build:
	docker build -t hostaway ./apps/hostaway

clean:
	minikube delete --all
