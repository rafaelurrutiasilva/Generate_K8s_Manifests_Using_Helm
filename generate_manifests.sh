#!/bin/bash
#
# Bash script to generate Kubernetes manifests using Helm.
#
# ---------------------------------------------------------
#

PROGRAM=`basename $0`
VERSION="2023-03-25, Rafael.Urrutia.S@gmail.com"

# Return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3


# Source initial variables.
if [[ -f manifests.ini ]]; then
	. ./manifests.ini 
else
	echo "You are missing the 'manifests.ini' file"
	exit $STATE_CRITICAL
fi

printHelp() {
        echo $VERSION
        echo ""
        echo "This Bash script generates Kubernetes manifests using Helm and Kubeseal."
	echo "It will encrypt secrets using Kubeseal and remove the files that contain secrets in clear text."
	
	echo "If you are generating complete new secrets and want to sealed it then you have to use '--update n'."
        echo ""
        echo "Use of $PROGRAM:"
        echo ""
        echo "-h, --help                Shows help text"
        echo "-u, --update (y/n)        Tells if you are doing an update and will keep existing secrets or want to generate new ones. Default i yes."
        echo ""
        exit $STATE_UNKNOWN
}


checkBasics() {
	if [[ ! -f $VALUEFILE ]]; then echo "You are missing the '$VALUEFILE' file!"; exit $STATE_CRITICAL; fi 
	if [[ ! $(which kubeseal 2> /dev/null ) ]]; then echo "You have to have 'kubeseal' installed!"; exit $STATE_CRITICAL; fi
	if [[ ! $(which helm 2> /dev/null ) ]]; then echo "You have to have 'helm' installed!"; exit $STATE_CRITICAL; fi
}


helmWorkload() {
	[[ -d "$MANIFEST_DIR_NAME" ]] || mkdir -p $MANIFEST_DIR_NAME
	helm repo add $HELM_REPO_NAME $HELM_REPO_URL
	helm repo update
	helm template $HELM_APP_NAME $HELM_REPO_NAME/$HELM_CHART_NAME --namespace $HELM_APP_NAMESPACE \
		      --create-namespace --output-dir $MANIFEST_DIR_NAME --include-crds --values $VALUEFILE --debug
}

deleteSecret() {
	echo ""
	for FILE in $(grep -rw "kind:" $MANIFEST_DIR_NAME |grep -w Secret |awk -F":" '{print$1}')
	do
		echo "Deleting file: $FILE"
		rm $FILE
	done
}

genSealedSecret() {
	echo ""
	for FILE in $(grep -rw "kind:" $MANIFEST_DIR_NAME |grep -w Secret |awk -F":" '{print$1}')
	do
		SEALEDFILE="$(dirname $FILE)/sealed-$(basename $FILE)"
		echo "Sealing file: $FILE"
		cat $FILE |kubeseal --format yaml --cert $SEALED_SECRETS_PEM_FILE > $SEALEDFILE 
		echo "Sealed file: $SEALEDFILE" 
	done
}	

runUpdate() {
	checkBasics
	helmWorkload
	deleteSecret
}

runNewInstall() {
	if [[ $UPDATE = "y" || $UPDATE = "Y" ]]; then
		runUpdate
	else
		checkBasics
		helmWorkload
		genSealedSecret
		deleteSecret
	fi
}


[[ $# -eq 0 ]] && runUpdate 
while [ $# -gt 0 ]; do
	case "$1" in
        	-h | --help)
                	printHelp
                	exit $STATE_OK
                	;;
        	-u | --update)
                	UPDATE=$2
			runNewInstall
                	shift
                	;;
        	*)
                	printHelp
                	;;
	esac
shift
done
