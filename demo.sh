#!/bin/bash

. ./etc/demo-magic.sh -n

clear
p "# install the Linkerd control plane..."
pe "linkerd install | kubectl apply -f -"
PROMPT_TIMEOUT=1
wait
PROMPT_TIMEOUT=0

clear
p "# check the control plane status..."
pe "linkerd check"
wait

clear
p "# install the emoji application..."
pe "kubectl apply -f etc/emojivoto-blue.yml"
pe "watch kubectl -n emojivoto-blue get po"

p "# using ksniff to sniff the web component..."
pe "pod=$(kubectl -n emojivoto-blue get po -l app=web-svc -ojsonpath='{.items[0].metadata.name}')"
pe "kubectl sniff -n emojivoto-blue ${pod} -f '(((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' &"
wait

clear
p "# inject the emoji application with Linkerd proxy..."
pe "kubectl -n emojivoto-blue get deploy -oyaml | linkerd inject - | kubectl apply -f -"

p "# to be continued..."
wait

clear
p "# install the OPA Gatekeeper..."
pe "kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml"

clear
p "omit the kube-system and gatekeeper-system namespaces from rules validation..."
pe "kubectl label ns kube-system config.linkerd.io/admission-webhooks=disabled"
pe "kubectl label ns gatekeeper-system config.linkerd.io/admission-webhooks=disabled"
