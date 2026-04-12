{{/*
Common labels
*/}}
{{- define "cloud-security-scanner.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.global.imageTag | quote }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/*
Fullname prefix
*/}}
{{- define "cloud-security-scanner.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}
