# charts/gitops-operator/templates/_helpers.tpl

{{/* Expand the name of the chart */}}
{{- define "gitops-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Create a default fully qualified app name */}}
{{- define "gitops-operator.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Create chart name and version as used by the chart label */}}
{{- define "gitops-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels */}}
{{- define "gitops-operator.labels" -}}
helm.sh/chart: {{ include "gitops-operator.chart" . }}
{{ include "gitops-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels */}}
{{- define "gitops-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gitops-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* Service account name */}}
{{- define "gitops-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "gitops-operator.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/* ArgoCD server address */}}
{{- define "gitops-operator.argocdServer" -}}
{{- if .Values.argocd.server -}}
{{- .Values.argocd.server -}}
{{- else -}}
argocd-server.{{ .Values.argocd.namespace }}.svc.cluster.local:443
{{- end -}}
{{- end -}}

{{/* Create the name of the service account to use */}}
{{- define "gitops-operator.rbacName" -}}
{{- if .Values.rbac.create -}}
{{- include "gitops-operator.fullname" . -}}
{{- else -}}
{{- default "default" .Values.rbac.name -}}
{{- end -}}
{{- end -}}

{{/* Generate RBAC rules */}}
{{- define "gitops-operator.rbacRules" -}}
{{- if .Values.rbac.rules -}}
{{- toYaml .Values.rbac.rules -}}
{{- else -}}
- apiGroups: ["gitops.example.com"]
  resources: ["gitreposcans"]
  verbs: ["*"]
- apiGroups: ["argoproj.io"]
  resources: ["applications"]
  verbs: ["*"]
{{- end -}}
{{- end -}}

{{/* Network policy pod selector */}}
{{- define "gitops-operator.networkPolicyPodSelector" -}}
{{- if semverCompare ">=1.21-0" .Capabilities.KubeVersion.GitVersion -}}
matchLabels:
  {{- include "gitops-operator.selectorLabels" . | nindent 2 }}
{{- else -}}
podSelector:
  matchLabels:
    {{- include "gitops-operator.selectorLabels" . | nindent 4 }}
{{- end -}}
{{- end -}}