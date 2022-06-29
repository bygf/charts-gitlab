{{- define "gitlab.checkConfig.ingress.alternatives" -}}
{{-   if and (index $.Values "nginx-ingress").enabled $.Values.haproxy.install -}}
ingress:
  HAProxy is also enabled via `haproxy.install=true`.
  Please disable NGINX via `nginx-ingress.enabled=false`.
{{-   end -}}
{{- end -}}

{{- define "gitlab.checkConfig.ingress.class" -}}
{{-   $defaultClass := printf "%s-nginx" $.Release.Name -}}
{{-   $current := $.Values.global.ingress.class -}}
{{-   if not $current -}}
{{-     $current = $defaultClass -}}
{{-   end -}}
{{-   $expected := $defaultClass -}}
{{-   if $.Values.haproxy.install -}}
{{-     $expected = "haproxy" -}}
{{-   end -}}
{{-   if or (index $.Values "nginx-ingress").enabled $.Values.haproxy.install -}}
{{-     if ne $current $expected -}}
ingress:
  Current ingress class is `{{ $current }}`.
  Ingress class should be set to `global.ingress.class={{ $expected }}`.
{{-     end -}}
{{-   end -}}
{{- end -}}
