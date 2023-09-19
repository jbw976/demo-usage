#!/usr/bin/env bash

set -aeuo pipefail

up uxp install --set "args={--debug,--enable-usages}"
kubectl -n upbound-system wait deploy crossplane --for condition=Available

kubectl apply -R -f setup/
kubectl wait provider.pkg --all --for condition=healthy --timeout 2m
kubectl wait xrd --all --for condition=established --timeout 2m

kubectl apply -f configure/
SA=$(kubectl -n upbound-system get sa -o name | grep provider-helm | sed -e 's|serviceaccount\/|upbound-system:|g')
kubectl create clusterrolebinding provider-helm-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}"
SA=$(kubectl -n upbound-system get sa -o name | grep provider-kubernetes | sed -e 's|serviceaccount\/|upbound-system:|g')
kubectl create clusterrolebinding provider-kubernetes-admin-binding --clusterrole cluster-admin --serviceaccount="${SA}"