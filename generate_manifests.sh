#!/bin/bash
#
# Bash script to generate Kubernetes manifests using Helm.
#
# ---------------------------------------------------------
#
DEBUG=1

PROGRAM=`basename $0`
VERSION="2023-03-25, Rafael.Urrutia.S@gmail.com"

# Return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Source initial variables.
if [[ -f manifests.ini ]];then
	. ./manifests.ini 
else
	echo "You are missing the 'manifests.ini' file"
	exit $STATE_CRITICAL
fi

checkBasics(){
	STATE=0
	[[ -f $VALUEFILE ]] || echo "You are missing the '$VALUEFILE' file!" 
	[[ $(which kubeseal 2> /dev/null ) ]] || echo "You have to have 'kubeseal' installed!"
	[[ $(which helm 2> /dev/null ) ]] || echo "You have to have 'helm' installed!"
	STATE=$?
	[[ $STATE -eq 1 ]] && exit $STATE_CRITICAL
}

printHelp() {
	clear
	echo $VERSION
        echo ""
        echo "This Bash script generates Kubernetes manifests using Helm and Kubeseal"
        echo ""
        echo "Use of $PROGRAM:"
	echo ""
	echo "-h, --help		Shows help text"
	echo "-u, --update (y/n) 	Tells if you are doing an update and will keep existing secrets or want to generate new ones. Default i yes."
        echo ""
        exit $STATE_UNKNOWN
}


# Helm workload
helmWorkload() {
	[[ $DEBUG -eq 1 ]] && echo "DEBUGING... Running helmWorkload"

	[[ -d "$MANIFEST_DIR_NAME" ]] || mkdir -p $MANIFEST_DIR_NAME
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
checkBasics
printHelp
#helmWorkload
#genSealedSecret
