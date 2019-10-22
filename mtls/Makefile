.PHONY: linkerd-%
linkerd-%:
	linkerd $*

linkerd:
	linkerd install  | kubectl apply -f -
	linkerd check
	linkerd version

opa:
	kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

policy:
	kubectl -n gatekeeper-system wait --for=condition=ready pod/gatekeeper-controller-manager-0
	kubectl apply -f template.yaml
	kubectl apply -f config.yaml
	sleep 20s
	kubectl apply -f constraint.yaml

test:
	opa test -v --explain=notes .

clean:
	kubectl delete constraint,constrainttemplates -l policy.linkerd.io
	kubectl delete crd -l controller-tools.k8s.io=1.0
	kubectl delete ns gatekeeper-system
	$(MAKE) linkerd-install | kubectl delete -f -
