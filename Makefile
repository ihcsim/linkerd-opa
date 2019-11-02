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

dashboard:
	@echo "$(COMMENT_COLOR)# launching Linkerd dashboard...$(NO_COLOR)"
	@sleep 1
	linkerd dashboard &

sniff-controller:
	@pod=`kubectl -n linkerd get po -l linkerd.io/control-plane-component=controller -ojsonpath='{.items[0].metadata.name}'` ; \
	echo "$(COMMENT_COLOR)# sniffing Linkerd controller...$(NO_COLOR)" ; \
	sleep 1 ; \
	kubectl sniff -n linkerd $${pod} -p -f "tcp and host not 127.0.0.1"

emoji:
	@echo "$(COMMENT_COLOR)# installing emoji application...$(NO_COLOR)"
	@sleep 1
	kubectl create ns emojivoto
	@sleep 1
	kubectl apply -f https://run.linkerd.io/emojivoto.yml

sniff-emoji:
	@pod=`kubectl -n emojivoto get po -l app=web-svc -ojsonpath='{.items[0].metadata.name}'`; \
	echo "$(COMMENT_COLOR)# sniffing emoji web...$(NO_COLOR)" ; \
	sleep 1 ; \
	kubectl sniff -n emojivoto $${pod} -f "tcp and host not 127.0.0.1"

emoji-inject:
	@echo "$(COMMENT_COLOR)# injecting Linkerd proxy into emoji appliction...$(NO_COLOR)"
	@sleep 1
	kubectl -n emojivoto get deploy -oyaml | linkerd inject - | kubectl apply -f -

sniff-emoji2: sniff-emoji

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
	kubectl label --overwrite ns kube-system config.linkerd.io/admission-webhooks=disabled
	kubectl apply -f template.yaml
	kubectl apply -f config.yaml

constraint:
	@echo "$(COMMENT_COLOR)# installing mTLS constaint...$(NO_COLOR)"
	@sleep 1
	kubectl apply -f constraint.yaml

emoji-rebuild:
	@echo "$(COMMENT_COLOR)# rebuilding emoji namespace...$(NO_COLOR)"
	@sleep 1
	kubectl delete ns emojivoto
	$(MAKE) emoji

opa-audit:
	kubectl describe linkerdmutualtls.constraints.gatekeeper.sh v0.0.1

proxy-injector-down:
	@echo "$(COMMENT_COLOR)# let's pretend the proxy injector is down...$(NO_COLOR)"
	@sleep 1
	kubectl -n linkerd scale deploy/linkerd-proxy-injector --replicas=0

emoji-rebuild2: emoji-rebuild

opa-audit2: opa-audit

.PHONY: alertmanager
alertmanager:
	linkerd inject --manual alertmanager | kubectl apply -f -

mkube:
	minikube start --profile demo --memory 8096m --vm-driver=kvm2
	minikube profile demo

clean:
	minikube delete

.PHONY: linkerd-%
linkerd-%:
	linkerd $*

test:
	opa test -v --explain=notes .
