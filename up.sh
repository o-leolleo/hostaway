#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

main() {
    # Returns non-zero if not running
    # See more at https://minikube.sigs.k8s.io/docs/commands/status/
    if ! minikube status &>/dev/null; then
        minikube start
        nohup minikube mount $PWD:/mnt/source &
    else
        echo "Minikube is already running."
    fi

    nohup minikube tunnel &> /dev/null &

	cd terraform
	terraform init
	terraform apply -auto-approve
    cd -

    kustomize build gitops/bootstrap/overlays/default | kubectl apply -f -

	password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode)
    echo -e "\n---"
	echo -e "All set:\n"
    echo "Argocd:"
    echo "  url: http://localhost:20080"
    echo "  username: admin"
    echo "  password: ${password}"
    echo "Prometheus:"
    echo "  url: http://localhost:9090"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
