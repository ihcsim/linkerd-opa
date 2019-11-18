#!/bin/bash

. ./etc/demo-magic.sh -n

clear
p "# install the blue emoji applications..."
pe "kubectl apply -f etc/emojivoto-blue.yml"
pe "kubectl -n emojivoto-blue get po"
wait

clear
p "# install the Linkerd control plane..."
pe "linkerd install | kubectl apply -f -"
PROMPT_TIMEOUT=3
wait

clear
p "# check the control plane status..."
pe "linkerd check"
PROMPT_TIMEOUT=0
wait

clear
p "# use ksniff to sniff the web component..."
pe "pod=$(kubectl -n emojivoto-blue get po -l app=web-svc -ojsonpath='{.items[0].metadata.name}')"
pe "kubectl sniff -n emojivoto-blue ${pod} -f '(((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'"

clear
p "# inject the blue emoji application with Linkerd proxy..."
pe "kubectl -n emojivoto-blue get deploy -oyaml | linkerd inject - | kubectl apply -f -"
PROMPT_TIMEOUT=5
wait
pe "watch kubectl -n emojivoto-blue get po"

p "# repeat sniffing action..."
pe "pod=$(kubectl -n emojivoto-blue get po -l app=web-svc -ojsonpath='{.items[0].metadata.name}')"
pe "kubectl sniff -n emojivoto-blue ${pod} -f 'tcp and host not 127.0.0.1'"
p "# 🔒🔒🔒...👍👍👍"
PROMPT_TIMEOUT=0
wait

clear
p "# install the green emoji applications..."
pe "kubectl apply -f etc/emojivoto-green.yml"
pe "kubectl -n emojivoto-green get po"
PROMPT_TIMEOUT=2
wait

clear
p "# install the OPA Gatekeeper..."
pe "kubectl apply -f gatekeeper.yaml"
pe "kubectl -n gatekeeper-system wait --for=condition=ready pod/gatekeeper-controller-manager-0"
wait

clear
p "# omit the kube-system and gatekeeper-system namespaces from rules validation..."
pe "kubectl label ns kube-system config.linkerd.io/admission-webhooks=disabled"
pe "kubectl label ns gatekeeper-system config.linkerd.io/admission-webhooks=disabled"
wait

clear
p "# install the mtls constraint template..."
pe "kubectl apply -f config.yaml -f template.yaml"
PROMPT_TIMEOUT=5
wait

pe "kubectl describe constrainttemplates.templates.gatekeeper.sh linkerdmutualtls | less"
wait

p "# install the mtls constraint..."
pe "kubectl apply -f constraint.yaml"
pe "kubectl describe linkerdmutualtls.constraints.gatekeeper.sh v0.0.1 | less"

clear
p "# let's see if Gatekeeper detected our insecure emoji application..."
pe "kubectl describe linkerdmutualtls.constraints.gatekeeper.sh v0.0.1 | less"

p "# inject the green emoji application with Linkerd proxy..."
pe "kubectl -n emojivoto-green get deploy -oyaml | linkerd inject - | kubectl apply -f -"
PROMPT_TIMEOUT=3
wait
PROMPT_TIMEOUT=0

pe "watch kubectl -n emojivoto-green get po"

p "# make sure all the violations are resolved..."
pe "kubectl describe linkerdmutualtls v0.0.1 | less"
p "# voila 🎉🎉🎉..."
wait
