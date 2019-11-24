# Enforcing Automatic mTLS with Linkerd and OPA Gatekeeper

This repository contains the demo scripts used in the
[_Enforcing Automatic mTLS with Linkerd and OPA Gatekeeper_ ](https://sched.co/UaY7)
session at KubeCon NA 2019.

[Linkerd](https://linkerd.io) is an ultralight service mesh for Kubernetes.
[OPA Gatekeeper](https://www.openpolicyagent.org/docs/latest/kubernetes-introduction/)
is a customizable Kubernetes admission webhook that helps enforce policies and
strengthen governance. This demo shows how you can use them to enable automatic
mTLS between your K8s services, and define and enforce policies to ensure
security compliance.

## Resources:

* Presentation slides - https://static.sched.com/hosted_files/kccncna19/c0/slides-v0.0.1.pdf
* Recording - https://youtu.be/gMaGVHnvNfs

## Prerequisites
The demo script is tested with the following software:

* Minikube v1.3.1
* Linkerd edge-19.10.5
* Gatekeeper v3.0.4-beta.2
* [ksniff](https://github.com/eldadru/ksniff) v1.3.1
* tcpdump v4.9.2
* wireshark 2.6.10

## Getting Started
Follow the instruction in the
[Linkerd documentation](https://linkerd.io/2/getting-started/#step-1-install-the-cli)
to obtain the Linkerd CLI.

To run the demo script,
```
./demo.sh
```

This demo consists of 2 parts:

1. Part 1 - use Linkerd mTLS to secure traffic between the micro services of the emoji application
1. Part 2 - use Gatekeeper to define and enforce mTLS policies among the live services

To remove all the demo artifacts from your k8s cluster,
```
./cleanup.sh
```

## Useful Links

* Linkerd - Getting Started: https://linkerd.io/2/getting-started/
* Gatekeeper: https://github.com/open-policy-agent/gatekeeper
* OPA: https://www.openpolicyagent.org
