{{/* ######### Registry related templates */}}

{{/*
Returns the Registry hostname.
If the hostname is set in `global.hosts.registry.name`, that will be returned,
otherwise the hostname will be assembed using `registry` as the prefix, and the `gitlab.assembleHost` function.
*/}}
{{- define "gitlab.registry.hostname" -}}
{{- coalesce .Values.global.registry.host .Values.global.hosts.registry.name (include "gitlab.assembleHost"  (dict "name" "registry" "context" . )) -}}
{{- end -}}

{{/*
Return the registry external hostname
If the chart registry host is provided, it will use that, otherwise it will fallback
to the global registry host name.
*/}}
{{- define "gitlab.registry.host" -}}
{{-   if .Values.global.registry.host -}}
{{-     .Values.global.registry.host -}}
{{-   else -}}
{{-     template "gitlab.registry.hostname" . -}}
{{-   end -}}
{{- end -}}

{{/*
Return the registry api hostname
If the registry api host is provided, it will use that, otherwise it will fallback
to the service name
*/}}
{{- define "gitlab.registry.api.host" -}}
{{-   if .Values.global.registry.api.host -}}
{{-     .Values.global.registry.api.host -}}
{{-   else -}}
{{-     $name := default .Values.global.hosts.registry.serviceName .Values.global.registry.api.serviceName -}}
{{-     $name = printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{-     printf "%s.%s.svc" $name .Release.Namespace -}}
{{-   end -}}
{{- end -}}

{{/*
Return the registry api port
If the registry api port is provided, it will use that, otherwise it will fallback
to the service default
*/}}
{{- define "gitlab.registry.api.port" -}}
{{- coalesce .Values.global.hosts.registry.servicePort .Values.global.registry.api.port "5000" -}}
{{- end -}}

{{/*
Return the registry api protocol
If the registry api protocol is provided, it will use that, otherwise it will fallback
to the service default
*/}}
{{- define "gitlab.registry.api.protocol" -}}
{{- coalesce .Values.global.hosts.registry.protocol .Values.global.registry.api.protocol "http" -}}
{{- end -}}


{{/*
Return the registry api url
*/}}
{{- define "gitlab.registry.api.url" -}}
{{- $scheme := include "gitlab.registry.api.protocol" . -}}
{{- $host   := include "gitlab.registry.api.host" . -}}
{{- $port   := include "gitlab.registry.api.port" . -}}
{{ printf "%s://%s:%s" $scheme $host $port }}
{{- end -}}

{{- define "gitlab.appConfig.registry.configuration" -}}
{{/* TODO: gitlab.appConfig.registry.configuration adjust for use with globals*/}}
registry:
  enabled: {{ or (not (kindIs "bool" .Values.global.registry.enabled)) .Values.global.registry.enabled }}
  host: {{ template "gitlab.registry.host" . }}
  {{- if .Values.global.registry.port }}
  port: {{ .Values.global.registry.port }}
  {{- end }}
  api_url: {{ template "gitlab.registry.api.url" . }}
  key: /etc/gitlab/registry/gitlab-registry.key
  issuer: {{ .Values.global.registry.tokenIssuer }}
  notification_secret: <%= YAML.load_file("/etc/gitlab/registry/notificationSecret").flatten.first %>
{{- end -}}{{/* "gitlab.appConfig.registry.configuration" */}}
