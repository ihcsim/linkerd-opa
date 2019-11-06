#!/bin/bash

kubectl delete ns emojivoto-blue &
kubectl delete ns emojivoto-green &
linkerd install --ignore-cluster | kubectl delete -f - &
kubectl label ns kube-system config.linkerd.io/admission-webhooks- &
kubectl delete crd configs.config.gatekeeper.sh constrainttemplates.templates.gatekeeper.sh
kubectl delete ns gatekeeper-system
