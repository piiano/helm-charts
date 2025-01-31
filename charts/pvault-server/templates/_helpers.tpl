{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "pvault-server.name" -}}
{{- default .Chart.Name (tpl .Values.nameOverride .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pvault-server.fullname" -}}
{{- $fullNameRendered := tpl .Values.fullnameOverride . -}}
{{- if $fullNameRendered -}}
{{- $fullNameRendered | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name (tpl .Values.nameOverride .) -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts.
*/}}
{{- define "pvault-server.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "pvault-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Source: https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_names.tpl
Kubernetes standard labels
{{ include "pvault-server.labels.standard" (dict "customLabels" .Values.commonLabels "context" $) -}}
*/}}
{{- define "pvault-server.labels.standard" -}}
{{- if and (hasKey . "customLabels") (hasKey . "context") -}}
{{- $default := dict "app.kubernetes.io/name" (include "pvault-server.name" .context) "helm.sh/chart" (include "pvault-server.chart" .context) "app.kubernetes.io/instance" .context.Release.Name "app.kubernetes.io/managed-by" .context.Release.Service -}}
{{- with .context.Chart.AppVersion -}}
{{- $_ := set $default "app.kubernetes.io/version" . -}}
{{- end -}}
{{ template "pvault-server.tplvalues.merge" (dict "values" (list .customLabels $default) "context" .context) }}
{{- else -}}
app.kubernetes.io/name: {{ include "pvault-server.name" . }}
helm.sh/chart: {{ include "pvault-server.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Chart.AppVersion }}
app.kubernetes.io/version: {{ . | quote }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Source: https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_names.tpl
Labels used on immutable fields such as deploy.spec.selector.matchLabels or svc.spec.selector
{{ include "pvault-server.labels.matchLabels" (dict "customLabels" .Values.podLabels "context" $) -}}

We don't want to loop over custom labels appending them to the selector
since it's very likely that it will break deployments, services, etc.
However, it's important to overwrite the standard labels if the user
overwrote them on metadata.labels fields.
*/}}
{{- define "pvault-server.labels.matchLabels" -}}
{{- if and (hasKey . "customLabels") (hasKey . "context") -}}
{{ merge (pick (include "pvault-server.tplvalues.render" (dict "value" .customLabels "context" .context) | fromYaml) "app.kubernetes.io/name" "app.kubernetes.io/instance") (dict "app.kubernetes.io/name" (include "pvault-server.name" .context) "app.kubernetes.io/instance" .context.Release.Name) | toYaml }}
{{- else -}}
app.kubernetes.io/name: {{ include "pvault-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "pvault-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "pvault-server.fullname" .) (tpl .Values.serviceAccount.name .) -}}
{{- else -}}
{{- default "default" (tpl .Values.serviceAccount.name .) -}}
{{- end -}}
{{- end -}}

{{/*
Get the name of an existing secret, or use default.
*/}}
{{- define "pvault-server.secrets.name" -}}
{{- default (include "pvault-server.fullname" .context) (tpl .existingSecret .context) -}}
{{- end -}}

{{/*
Get the key of an existing secret, or use default.
*/}}
{{- define "pvault-server.secrets.key" -}}
{{- default .defaultSecretKey (tpl .existingSecretKey .context) -}}
{{- end -}}

{{/*
Get the a volume template for a secret.
*/}}
{{- define "pvault-server.secrets.volume" -}}
- name: {{ .secretName }}
  secret:
    secretName: {{ include "pvault-server.secrets.name" . }}
    items:
    - key: {{ include "pvault-server.secrets.key" . }}
      path: content
{{- end -}}

{{/*
Source: https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_tplvalues.tpl
Renders a value that contains template perhaps with scope if the scope is present.
Usage:
{{ include "pvault-server.tplvalues.render" (dict "value" .Values.path.to.the.Value "context" $) }}
{{ include "pvault-server.tplvalues.render" (dict "value" .Values.path.to.the.Value "context" $ "scope" $app) }}
Borrowed from https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_tplvalues.tpl
*/}}
{{- define "pvault-server.tplvalues.render" -}}
{{- $value := typeIs "string" .value | ternary .value (.value | toYaml) }}
{{- if contains "{{" (toJson .value) }}
  {{- if .scope }}
      {{- tpl (cat "{{- with $.RelativeScope -}}" $value "{{- end }}") (merge (dict "RelativeScope" .scope) .context) }}
  {{- else }}
    {{- tpl $value .context }}
  {{- end }}
{{- else }}
    {{- $value }}
{{- end }}
{{- end -}}

{{/*
Source: https://github.com/bitnami/charts/blob/main/bitnami/common/templates/_tplvalues.tpl
Merge a list of values that contains template after rendering them.
Merge precedence is consistent with http://masterminds.github.io/sprig/dicts.html#merge-mustmerge
Usage:
{{ include "pvault-server.tplvalues.merge" (dict "values" (list .Values.path.to.the.Value1 .Values.path.to.the.Value2) "context" $) }}
*/}}
{{- define "pvault-server.tplvalues.merge" -}}
{{- $dst := dict -}}
{{- range .values -}}
{{- $dst = include "pvault-server.tplvalues.render" (dict "value" . "context" $.context "scope" $.scope) | fromYaml | merge $dst -}}
{{- end -}}
{{ $dst | toYaml }}
{{- end -}}
