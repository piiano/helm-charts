{{/*
Expand the name of the chart.
*/}}
{{- define "pvault-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pvault-server.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "pvault-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pvault-server.labels" -}}
helm.sh/chart: {{ include "pvault-server.chart" . }}
{{ include "pvault-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pvault-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pvault-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "pvault-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "pvault-server.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the name of an existing secret, or use default.
*/}}
{{- define "pvault-server.secrets.name" }}
{{- default (include "pvault-server.fullname" .context) .existingSecret }}
{{- end }}

{{/*
Get the key of an existing secret, or use default.
*/}}
{{- define "pvault-server.secrets.key" }}
{{- default .defaultSecretKey .existingSecretKey }}
{{- end }}

{{/*
Get the a volume template for a secret.
*/}}
{{- define "pvault-server.secrets.volume" }}
- name: {{ .secretName }}
  secret:
    secretName: {{ include "pvault-server.secrets.name" . }}
    items:
    - key: {{ include "pvault-server.secrets.key" . }}
      path: content
{{- end }}