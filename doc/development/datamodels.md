---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Data model implementations

This document attempts to document the data model schemas used within the
chart.

It is important to understand that the data model is located within the context
where it is instantiated, not in `.Values`.

## PostgreSQL data model

The PostgreSQL data model is instantiated with the following:

```plaintext
{{- include "database.datamodel.prepare" . -}}
```

This would be needed to be called in any Helm template file that needs to
access the PostgreSQL data model. It will examine the computed `.Values` and
generate the PostgreSQL data model in the current context.

The data model can be dumped and viewed with the following command:

```shell
helm template . -f ... --set global.debugDatabaseDatamodel=true \
    -s charts/gitlab/charts/toolbox/templates/configmap.yaml | \
    yq -P '.data."database.yml.erb"'
```

### Traditional PostgreSQL configuration

Most installations use a single PostgreSQL database and will have the
configuration specified as:

```yaml
global:
  psql:
    host: pg-postgresql.pg.svc
    database: gitlabhq_production
    username: postgres
    preparedStatements: false
    password:
      secret: gitlab-postgres
      key: psql-password

postgresql:
  install: false
```

The resulting data model will be generated. Note that `main` is used for
the primary database connection. Additional database connections are
created under additional attributes as shown in the decomposed database
configuration later.

```yaml
<CONTEXT>:
  local:
    psql:
      main:
        Release:
          IsInstall: true
          IsUpgrade: false
          Name: test
          Namespace: kube-public
          Revision: 1
          Service: Helm
        Schema: main
        Values:
          global:
            psql:
              database: gitlabhq_production
              host: pg-postgresql.pg.svc
              password:
                key: psql-password
                secret: gitlab-postgres
              preparedStatements: false
              username: postgres
          psql: {}
```

### Decomposed PostgreSQL configuration

If one is using a decomposed database configuration, then the values for
the database configuration will be similar to:

```yaml
global:
  psql:
    main:
      host: pg-main-postgresql.pg.svc
      database: gitlabhq_production
      username: postgres
      preparedStatements: false
      password:
        secret: gitlab-main-postgres
        key: psql-main-password
    ci:
      host: pg-ci-postgresql.pg.svc
      database: gitlabhq_production
      username: postgres
      preparedStatements: false
      password:
        secret: gitlab-ci-postgres
        key: psql-ci-password

postgresql:
  install: false
```

The resulting data model for a decomposed database configuration is as
follows:

```yaml
<CONTEXT>:
  local:
    psql:
      ci:
        Release:
          IsInstall: true
          IsUpgrade: false
          Name: test
          Namespace: default
          Revision: 1
          Service: Helm
        Schema: ci
        Values:
          global:
            psql:
              database: gitlabhq_production
              host: pg-ci-postgresql.pg.svc
              password:
                key: psql-ci-password
                secret: gitlab-ci-postgres
              preparedStatements: false
              username: postgres
          psql: {}
      main:
        Release:
          IsInstall: true
          IsUpgrade: false
          Name: test
          Namespace: default
          Revision: 1
          Service: Helm
        Schema: main
        Values:
          global:
            psql:
              database: gitlabhq_production
              host: pg-main-postgresql.pg.svc
              password:
                key: psql-main-password
                secret: gitlab-main-postgres
              preparedStatements: false
              username: postgres
          psql: {}
```
