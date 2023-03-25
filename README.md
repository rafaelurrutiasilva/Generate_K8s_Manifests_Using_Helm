# Generate Kubernetes Manifests Using Helm

<img width="220" alt="kubeAcademy-vappliance" src="https://github.com/rafaelurrutiasilva/Generate_K8s_Manifests_Using_Helm/blob/main/helm_bash_kubeseal_logo.png" align=left> <br>

Generate Kubernetes manifests using Helm and Kubeseal.

## Introduction
This Bash script can be used to generate Kubernetes manifests using Helm and Kubeseal.
The script will generate manifest files using the Helm and the values you put in the values.yaml file and it will encrypt secrets using Kubeseal and remove the files that contain secrets in clear text.

## How to use
Get help from the script by using:
`$ generate_manifests.sh --help`

## Exampel
You will find here an example for generate Kubernetes manifest for the application **Argo CD**.<br>
See the manifests.ini and values.yaml files for more details.
