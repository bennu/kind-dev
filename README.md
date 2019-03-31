# kind-dev

A easy way to enabled [kubernetes addons](https://kubernetes.io/docs/concepts/cluster-administration/addons/) to a [Kind](https://github.com/kubernetes-sigs/kind) local cluster.

Addons | Version | 
| :--- | :---: |
| [Ingress-nginx](https://github.com/kubernetes/ingress-nginx)  | 0.23|
| [Metallb](https://metallb.universe.tf/) | v0.7.3 <br>*Deployed in layer 2 using the last 20 IPs used by docker bridge* |
| [Dashboard](https://github.com/kubernetes/dashboard) | v1.10.1 |
| [Metrics](https://github.com/kubernetes-incubator/metrics-server) | v0.3.1

## Getting started

```bash
$ make startup
```
