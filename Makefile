.PHONY: init clean

init:
	./init.sh

clean:
	minikube delete --all
