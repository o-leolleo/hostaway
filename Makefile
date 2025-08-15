.PHONY: init clean

init:
	./init.sh

build-app:
	docker build -t hostaway ./apps/hostaway

clean:
	minikube delete --all
