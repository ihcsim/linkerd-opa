NO_COLOR=\033[0m
COMMENT_COLOR=\033[92m
CODE_COLOR=\033[94m

linkerd:
	@echo "$(COMMENT_COLOR)# installing Linkerd...$(NO_COLOR)"
	@sleep 1
	linkerd install | kubectl apply -f -

check:
	@echo "$(COMMENT_COLOR)# checking Linkerd...$(NO_COLOR)"
	@sleep 1
	linkerd check
	linkerd version

emoji-blue:
	@echo "$(COMMENT_COLOR)# installing emoji to 'emoji-blue' namespace...$(NO_COLOR)"
	kubectl create ns emojivoto-blue # trigger gatekeeper cache
	@sleep 1
	kubectl apply -f etc/emojivoto-blue.yml

emoji-blue-sniff:
	@pod=`kubectl -n emojivoto-blue get po -l app=web-svc -ojsonpath='{.items[0].metadata.name}'`; \
	echo "$(COMMENT_COLOR)# sniffing emoji web...$(NO_COLOR)" ; \
	sleep 1 ; \
	kubectl sniff -n emojivoto-blue $${pod} -f "tcp and host not 127.0.0.1"

emoji-blue-inject:
	@echo "$(COMMENT_COLOR)# injecting Linkerd proxy into emoji appliction...$(NO_COLOR)"
	@sleep 1
	kubectl -n emojivoto-blue get deploy -oyaml | linkerd inject - | kubectl apply -f -

alertmanager:
	@echo "$(COMMENT_COLOR)# port-forward to alertmanager console... $(NO_COLOR)"
	@sleep 1
	kubectl -n linkerd port-forward svc/linkerd-alertmanager 9093 &

opa:
	@echo "$(COMMENT_COLOR)# installing OPA Gatekeeper...$(NO_COLOR)"
	@sleep 1
	kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
	kubectl label ns gatekeeper-system config.linkerd.io/admission-webhooks=disabled
	kubectl label ns kube-system config.linkerd.io/admission-webhooks=disabled

policy:
	@echo "$(COMMENT_COLOR)# installing mTLS constaint template...$(NO_COLOR)"
	@sleep 1
	kubectl -n gatekeeper-system wait --for=condition=ready pod/gatekeeper-controller-manager-0
	kubectl apply -f template.yaml
	kubectl apply -f config.yaml
	@echo "$(COMMENT_COLOR)# installing mTLS constaint...$(NO_COLOR)"
	@sleep 15
	kubectl apply -f constraint.yaml

emoji-green:
	@echo "$(COMMENT_COLOR)# installing emoji to 'emoji-green' namespace...$(NO_COLOR)"
	kubectl create ns emojivoto-green # trigger gatekeeper cache
	@sleep 1
	kubectl apply -f etc/emojivoto-green.yml

emoji-green-inject:
	@echo "$(COMMENT_COLOR)# injecting Linkerd proxy into emoji appliction...$(NO_COLOR)"
	@sleep 1
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
	kubectl delete crd configs.config.gatekeeper.sh constrainttemplates.templates.gatekeeper.sh
	kubectl delete ns gatekeeper-system

purge:
	minikube delete

test:
	opa test -v --explain=notes .
