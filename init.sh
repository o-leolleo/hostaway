#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

main() {
    # Returns non-zero if not running
    # See more at https://minikube.sigs.k8s.io/docs/commands/status/
    if ! minikube status &>/dev/null; then
        minikube start
    else
        echo "Minikube is already running."
    fi

    nohup minikube tunnel &> /dev/null &

	cd terraform
	terraform init
	terraform apply -auto-approve
    cd -

	password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode)
    echo "---"
	echo "ArgoCD is running!"
    echo "Access http://localhost:20080"
    echo "Initial admin password: ${password}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
