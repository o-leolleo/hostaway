.PHONY: init clean

init:
	minikube start
	cd terraform \
	&& terraform init \
	&& terraform apply -auto-approve

clean:
	minikube delete --all
