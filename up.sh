#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

main() {
    # Returns non-zero if not running
    # See more at https://minikube.sigs.k8s.io/docs/commands/status/
    if ! minikube status &>/dev/null; then
        minikube start
        # Keeps running after the script exits
        nohup minikube mount $PWD:/mnt/source &
    else
        echo "Minikube is already running."
    fi

    # Keeps running after the script exits
    nohup minikube tunnel &> /dev/null &

	cd terraform
	terraform init
	terraform apply -auto-approve
    cd -

    kustomize build gitops/bootstrap/overlays/default | kubectl apply -f -
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
