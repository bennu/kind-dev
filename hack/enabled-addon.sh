#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_PATH=$(dirname "$(readlink -f "$BASH_SOURCE")")
TMP_ROOT=$SCRIPT_PATH/_tmp
TMP_GIT=$TMP_ROOT/git
TMP_MANIFESTS=$TMP_ROOT/manifests
KUBECONFIG=$(kind get kubeconfig-path --name="local")

sh_c='sh -c'

cd $SCRIPT_PATH

cleanup() {
  rm -rf $TMP_ROOT
}

trap cleanup EXIT SIGINT

metallb_config() {
	mkdir -p ${TMP_MANIFESTS}
	local DOCKER_BRIDGE=$(docker network inspect bridge --format='{{(index .IPAM.Config 0).Subnet}}')
	local OLDIFS="$IFS"
	local SUB=${DOCKER_BRIDGE/\/*/}
    local MASK=$(( 1 << ( 32 - ${DOCKER_BRIDGE/*\//} )))

	IFS="."
	set -- $SUB
	IPS=$((0x$(printf "%02x%02x%02x%02x\n" $1 $2 $3 $4)))
	IFS="$OLDIFS"
    VAL=$((IPS|MASK-21))
    FROM="$(( (VAL >> 24) & 255 )).$(( (VAL >> 16) & 255 )).$(( (VAL >> 8 ) & 255 )).$(( (VAL) & 255 ))"
	VAL=$((IPS|MASK-2))
    TO="$(( (VAL >> 24) & 255 )).$(( (VAL >> 16) & 255 )).$(( (VAL >> 8 ) & 255 )).$(( (VAL) & 255 ))"


cat <<-EOF > ${TMP_MANIFESTS}/metallb-config.yml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - ${FROM}-${TO}

EOF
}

check_addons(){
	case "$1" in
		ingress-nginx|metallb|metric-server|dashboard)
		;;
		*)
		usage
	esac
}

check_metallb(){
	set +o errexit
	kubectl get deployments/controller -n metallb-system > /dev/null 2>&1
	e=$?
	set -o errexit

	if [ $e -eq 1 ]; then
		metallb
	fi
}

metric_server() {
	mkdir -p $TMP_GIT

	cd $TMP_GIT

	git clone https://github.com/kubernetes-incubator/metrics-server.git
    cd metrics-server/deploy/1.8+
	sed -e "\$a\        args:\n\        - --kubelet-insecure-tls\n\        - --kubelet-preferred-address-types=InternalIP" metrics-server-deployment.yaml > metrics-server-deployment-patch.yaml
	rm metrics-server-deployment.yaml
	cd ..
	$sh_c "KUBECONFIG=${KUBECONFIG} kubectl apply -f 1.8+"

}

metallb() {
	metallb_config
	$sh_c "KUBECONFIG=${KUBECONFIG} kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml"
	$sh_c "KUBECONFIG=${KUBECONFIG} kubectl apply -f ${TMP_MANIFESTS}/metallb-config.yml"
}

ingress_nginx(){
	check_metallb

	$sh_c "KUBECONFIG=${KUBECONFIG} kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml"
	$sh_c "KUBECONFIG=${KUBECONFIG} kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/cloud-generic.yaml"
}

run() {
	if [ $# -ne 1 ]; then
		usage
	fi

	check_addons $1

	${1//-/_}

	exit 0
}

usage() {
	echo 1>&2 "Usage: $0 one of [ingress-nginx, metallb, metric-server]"
	exit 1
}

run "$@"
