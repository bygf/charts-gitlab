{{/*
Returns parts for a Gitlab configuration to setup a mutual TLS connection
with the PostgreSQL database.
*/}}
{{- define "gitlab.psql.ssl.config" -}}
{{- if or .ssl .Values.global.psql.ssl }}
sslmode: verify-ca
sslrootcert: '/etc/gitlab/postgres/ssl/server-ca.pem'
sslcert: '/etc/gitlab/postgres/ssl/client-certificate.pem'
sslkey: '/etc/gitlab/postgres/ssl/client-key.pem'
{{- end -}}
{{- end -}}

{{/*
Returns volume definition of a secret containing information required for
a mutual TLS connection.
*/}}
{{- define "gitlab.psql.ssl.volume" -}}
{{/* TODO: Need to pull ssl values from data model */}}
{{-   include "database.datamodel.prepare" . -}}
{{-   $sslenabled := include "gitlab.psql.ssl.enabled" . -}}
{{-   if .Values.global.psql.ssl.secret }}
- name: postgresql-ssl-secrets
  projected:
    defaultMode: 400
    sources:
    - secret:
        name: {{ .Values.global.psql.ssl.secret | required "Missing required secret containing SQL SSL certificates and keys. Make sure to set `global.psql.ssl.secret` or `.ssl.secret` in database settings" }}
        items:
          - key: {{ include "gitlab.psql.ssl.serverCA" . | required "Missing required key name of SQL server certificate. Make sure to set `global.psql.ssl.serverCA` or `.ssl.serverCA` in database settings" }}
            path: server-ca.pem
          - key: {{ include "gitlab.psql.ssl.clientCertificate" . | required "Missing required key name of SQL client certificate. Make sure to set `global.psql.ssl.clientCertificate` or `.ssl.clientCertificate` in database settings" }}
            path: client-certificate.pem
          - key: {{ include "gitlab.psql.ssl.clientKey" . | required "Missing required key name of SQL client key file. Make sure to set `global.psql.ssl.clientKey` or `.ssl.clientKey` in database settings" }}
            path: client-key.pem
{{-   end -}}
{{- end -}}

{{/*
Returns mount definition for the volume mount definition above.
*/}}
{{- define "gitlab.psql.ssl.volumeMount" -}}
{{- if or .ssl .Values.global.psql.ssl }}
- name: postgresql-ssl-secrets
  mountPath: '/etc/postgresql/ssl/'
  readOnly: true
{{- end -}}
{{- end -}}

{{/*
Returns a shell script snippet, which extends the script of a configure
container to copy the mutual TLS files to the proper location. Further
it sets the permissions correctly.
*/}}
{{- define "gitlab.psql.ssl.initScript" -}}
{{- if or .ssl .Values.global.psql.ssl }}
if [ -d /etc/postgresql/ssl ]; then
  mkdir -p /${secret_dir}/postgres/ssl
  cp -v -r -L /etc/postgresql/ssl/* /${secret_dir}/postgres/ssl/
  chmod 600 /${secret_dir}/postgres/ssl/*
  chmod 700 /${secret_dir}/postgres/ssl
fi
{{- end -}}
{{- end -}}
{{/*
Returns the K8s Secret definition for the PostgreSQL password.
*/}}
{{- define "gitlab.psql.secret" -}}
{{- $useSecret := include "gitlab.boolean.local" (dict "local" (pluck "useSecret" (index .Values.psql "password") | first) "global" .Values.global.psql.password.useSecret "default" true) -}}
{{- if $useSecret -}}
- secret:
    name: {{ template "gitlab.psql.password.secret" . }}
    items:
      - key: {{ template "gitlab.psql.password.key" . }}
        path: postgres/psql-password-{{ .Schema }}
{{- end -}}
{{- end -}}

{{/*
Returns the single-quoted path to the file where the PostgreSQL password is stored.
*/}}
{{- define "gitlab.psql.password.file" -}}
{{- $useSecret := include "gitlab.boolean.local" (dict "local" (pluck "useSecret" (index .Values.psql "password") | first) "global" .Values.global.psql.password.useSecret "default" true) -}}
{{- if not $useSecret -}}
{{- pluck "file" (index .Values.psql "password") (.Values.global.psql.password) | first | squote -}}
{{- else -}}
{{- printf "/etc/gitlab/postgres/psql-password-%s" .Schema | squote -}}
{{- end -}}
{{- end -}}
