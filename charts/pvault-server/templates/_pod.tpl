{{/*
Pod labels.
*/}}
{{- define "pvault-server.pod.labels" }}
{{- include "pvault-server.tplvalues.merge" ( dict "values" ( list .Values.podLabels .Values.commonLabels ) "context" . ) }}
{{- end }}
