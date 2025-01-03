{{/*
Source: https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_capabilities.tpl
*/}}

{{/* vim: set filetype=mustache: */}}

{{/*
Return the target Kubernetes version
*/}}
{{- define "pvault-server.capabilities.kubeVersion" -}}
{{- default (default .Capabilities.KubeVersion.Version .Values.kubeVersion) ((.Values.global).kubeVersion) -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for poddisruptionbudget.
*/}}
{{- define "pvault-server.capabilities.policy.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.21-0" $kubeVersion) -}}
{{- print "policy/v1beta1" -}}
{{- else -}}
{{- print "policy/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "pvault-server.capabilities.networkPolicy.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.7-0" $kubeVersion) -}}
{{- print "extensions/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for cronjob.
*/}}
{{- define "pvault-server.capabilities.cronjob.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.21-0" $kubeVersion) -}}
{{- print "batch/v1beta1" -}}
{{- else -}}
{{- print "batch/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for daemonset.
*/}}
{{- define "pvault-server.capabilities.daemonset.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.14-0" $kubeVersion) -}}
{{- print "extensions/v1beta1" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "pvault-server.capabilities.deployment.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.14-0" $kubeVersion) -}}
{{- print "extensions/v1beta1" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for statefulset.
*/}}
{{- define "pvault-server.capabilities.statefulset.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.14-0" $kubeVersion) -}}
{{- print "apps/v1beta1" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "pvault-server.capabilities.ingress.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if (.Values.ingress).apiVersion -}}
{{- .Values.ingress.apiVersion -}}
{{- else if and (not (empty $kubeVersion)) (semverCompare "<1.14-0" $kubeVersion) -}}
{{- print "extensions/v1beta1" -}}
{{- else if and (not (empty $kubeVersion)) (semverCompare "<1.19-0" $kubeVersion) -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end }}
{{- end -}}

{{/*
Return the appropriate apiVersion for RBAC resources.
*/}}
{{- define "pvault-server.capabilities.rbac.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.17-0" $kubeVersion) -}}
{{- print "rbac.authorization.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for CRDs.
*/}}
{{- define "pvault-server.capabilities.crd.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.19-0" $kubeVersion) -}}
{{- print "apiextensions.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "apiextensions.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for APIService.
*/}}
{{- define "pvault-server.capabilities.apiService.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.10-0" $kubeVersion) -}}
{{- print "apiregistration.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "apiregistration.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for Horizontal Pod Autoscaler.
*/}}
{{- define "pvault-server.capabilities.hpa.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" .context -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.23-0" $kubeVersion) -}}
{{- if .beta2 -}}
{{- print "autoscaling/v2beta2" -}}
{{- else -}}
{{- print "autoscaling/v2beta1" -}}
{{- end -}}
{{- else -}}
{{- print "autoscaling/v2" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for Vertical Pod Autoscaler.
*/}}
{{- define "pvault-server.capabilities.vpa.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" .context -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.11-0" $kubeVersion) -}}
{{- print "autoscaling/v1beta1" -}}
{{- else if and (not (empty $kubeVersion)) (semverCompare "<1.25-0" $kubeVersion) -}}
{{- print "autoscaling/v1beta2" -}}
{{- else -}}
{{- print "autoscaling/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Returns true if PodSecurityPolicy is supported
*/}}
{{- define "pvault-server.capabilities.psp.supported" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if or (empty $kubeVersion) (semverCompare "<1.25-0" $kubeVersion) -}}
  {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Returns true if AdmissionConfiguration is supported
*/}}
{{- define "pvault-server.capabilities.admissionConfiguration.supported" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if or (empty $kubeVersion) (not (semverCompare "<1.23-0" $kubeVersion)) -}}
  {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for AdmissionConfiguration.
*/}}
{{- define "pvault-server.capabilities.admissionConfiguration.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.23-0" $kubeVersion) -}}
{{- print "apiserver.config.k8s.io/v1alpha1" -}}
{{- else if and (not (empty $kubeVersion)) (semverCompare "<1.25-0" $kubeVersion) -}}
{{- print "apiserver.config.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "apiserver.config.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for PodSecurityConfiguration.
*/}}
{{- define "pvault-server.capabilities.podSecurityConfiguration.apiVersion" -}}
{{- $kubeVersion := include "pvault-server.capabilities.kubeVersion" . -}}
{{- if and (not (empty $kubeVersion)) (semverCompare "<1.23-0" $kubeVersion) -}}
{{- print "pod-security.admission.config.k8s.io/v1alpha1" -}}
{{- else if and (not (empty $kubeVersion)) (semverCompare "<1.25-0" $kubeVersion) -}}
{{- print "pod-security.admission.config.k8s.io/v1beta1" -}}
{{- else -}}
{{- print "pod-security.admission.config.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Returns true if the used Helm version is 3.3+.
A way to check the used Helm version was not introduced until version 3.3.0 with .Capabilities.HelmVersion, which contains an additional "{}}"  structure.
This check is introduced as a regexMatch instead of {{ if .Capabilities.HelmVersion }} because checking for the key HelmVersion in <3.3 results in a "interface not found" error.
**To be removed when the catalog's minimun Helm version is 3.3**
*/}}
{{- define "pvault-server.capabilities.supportsHelmVersion" -}}
{{- if regexMatch "{(v[0-9])*[^}]*}}$" (.Capabilities | toString ) }}
  {{- true -}}
{{- end -}}
{{- end -}}
