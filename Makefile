linkerd:
	linkerd install | kubectl apply -f -

check:
	linkerd check

emoji-blue:
	kubectl apply -f etc/emojivoto-blue.yml

emoji-blue-sniff:
	@pod=`kubectl -n emojivoto-blue get po -l app=web-svc -ojsonpath='{.items[0].metadata.name}'`; \
	kubectl sniff -n emojivoto-blue $${pod} -f "(((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)"

emoji-blue-inject:
	kubectl -n emojivoto-blue get deploy -oyaml | linkerd inject - | kubectl apply -f -

opa:
	kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
	kubectl label ns kube-system config.linkerd.io/admission-webhooks=disabled
	kubectl label ns gatekeeper-system config.linkerd.io/admission-webhooks=disabled

policy:
	kubectl -n gatekeeper-system wait --for=condition=ready pod/gatekeeper-controller-manager-0
	kubectl apply -f template.yaml -f config.yaml
	sleep 10
	kubectl apply -f constraint.yaml

emoji-green:
	kubectl create ns emojivoto-green # trigger gatekeeper cache
	sleep 2
	kubectl apply -f etc/emojivoto-green.yml

emoji-green-inject:
	kubectl -n emojivoto-green get deploy -oyaml | linkerd inject - | kubectl apply -f -

opa-audit:
	kubectl describe linkerdmutualtls.constraints.gatekeeper.sh v0.0.1

mkube:
	minikube start --profile demo --memory 8096m --vm-driver=kvm2
	minikube profile demo

clean:
	kubectl delete ns emojivoto-green &
	kubectl delete ns emojivoto-blue &
	linkerd install --ignore-cluster| kubectl delete -f - &
	kubectl label ns kube-system config.linkerd.io/admission-webhooks-
	kubectl delete crd configs.config.gatekeeper.sh constrainttemplates.templates.gatekeeper.sh
	kubectl delete ns gatekeeper-system

purge:
	minikube delete
