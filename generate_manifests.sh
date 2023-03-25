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
helmWorkload() {
	[[ $DEBUG -eq 1 ]] && echo "DEBUGING... Running helmWorkload"

	helm repo add $HELM_REPO_NAME $HELM_REPO_URL
	helm repo update
	helm template $HELM_APP_NAME $HELM_REPO_NAME/$HELM_CHART_NAME --namespace $HELM_APP_NAMESPACE \
		      --create-namespace --output-dir $MANIFEST_DIR_NAME --include-crds --values $VALUEFILE --debug
}

genSealedSecret() {
	for FILE in $(grep -rw "kind:" $MANIFEST_DIR_NAME |grep -w Secret |awk -F":" '{print$1}')
	do
		SEALEDFILE="$(dirname $FILE)/sealed-$(basename $FILE)"
		[[ $DEBUG -eq 1 ]] && echo "DEBUGING... Sealing $FILE"
		cat $FILE |kubeseal --format yaml --cert $SEALED_SECRETS_PEM_FILE > $SEALEDFILE 

		[[ $DEBUG -eq 1 ]] && echo "DEBUGING... Deleting $SEALEDFILE"
		rm $SEALEDFILE
	done
}	

# Run functions
helmWorkload
genSealedSecret 
