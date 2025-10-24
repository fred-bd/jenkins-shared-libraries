#!/bin/bash

gitrepo_exists=$(kubectl get gitrepo cluster-apps -n flux-system --ignore-not-found)

if [ ! -z "$APPROLE_EXISTS" ]; then
  flux suspend source git cluster-apps
  flux suspend source git flux-system
fi

kubectl delete --all Kustomization -A --ignore-not-found
kubectl wait --for=delete --all Kustomization -n flux-system

flux uninstall --silent

kubectl delete ns flux-system  --ignore-not-found
kubectl wait --for=delete namespace/flux-system --timeout=60s --ignore-not-found

kubectl delete ns vault  --ignore-not-found
