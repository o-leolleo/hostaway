.PHONY: init clean

init:
	./init.sh

build-app:
	docker build -t my-nginx-app ./app

clean:
	minikube delete --all
