#!/bin/bash
#
# Bash script to generate Kubernetes manifests using Helm.
#
# ---------------------------------------------------------
#
DEBUG=1

# Source initial variables.
. ./manifests.ini

# Create root-dir if it missing.
[ -d "$MANIFEST_DIR_NAME" ] || mkdir -p $MANIFEST_DIR_NAME

# Helm workload
function helmWorkload {
	[[ $DEBUG -eq 1 ]] && echo "DEBUGING... Running helmWorkload"

	helm repo add $HELM_REPO_NAME $HELM_REPO_URL
	helm repo update
	helm template $HELM_APP_NAME $HELM_REPO_NAME/$HELM_CHART_NAME --namespace $HELM_APP_NAMESPACE \
		      --create-namespace --output-dir $MANIFEST_DIR_NAME --include-crds --values $VALUEFILE --debug
}

function genSealedSecret {
	for FILE in $(grep -r "kind: Secret" $MANIFEST_DIR_NAME |awk -F":" '{print$1}')
	do
		SEALEDFILE="$(dirname $FILE)/sealed-$(basename $FILE)"
		if [[ $DEBUG -eq 1 ]];then
			echo "DEBUGING... Files to work with and generates"
			echo $FILE
			echo $SEALEDFILE
		fi
		cat $FILE |kubeseal --format yaml --cert $SEALED_SECRETS_PEM_FILE > $SEALEDFILE 
	done

	if [[ $FIRSTTIMEDEPLOY -eq 1 ]];then
		rm manifests/argo-cd/templates/argocd-secret.yaml
	fi
}	

# Run functions
helmWorkload
genSealedSecret 
