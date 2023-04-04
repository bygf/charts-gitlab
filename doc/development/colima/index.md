---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Developing for Kubernetes with colima

This guide is meant to serve as a resource for setting up a local Kubernetes development environment.
The setup described here is not meant to be used on production systems.

In this guide, we'll be using [colima](https://github.com/abiosoft/colima) which provides container runtimes on macOS, including `M1` and `M2` variants.
In addition, it comes with an optional support for a Kubernetes cluster.

## Preparation

Several parts need to be installed:

- [colima](https://github.com/abiosoft/colima). Follow the [official installation instructions](https://github.com/abiosoft/colima#installation).
- The docker runtime. Follow the [official installation instructions](https://github.com/abiosoft/colima#docker).
- kubectl. Follow the [official installation instructions](https://kubernetes.io/docs/tasks/tools/).
- [helm](https://helm.sh/). Again, we can follow the [official installation instructions](https://helm.sh/docs/intro/install/).

### (Optional) Loopback interface

To avoid, having different IPs each time the host machine boots, we suggest creating a _stable_ private address that maps to localhost.
Follow these [instructions](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/local_network.md#create-loopback-interface) from the [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit) project.

### Local hostname

To ease the access of the exposed GitLab application, we're going to create a local hostname that need to be mapped either to your current IP _or_ the [loopback interface](#optional-loopback-interface).

In `/etc/hosts`, add the following:

```
<ip address> gitlab.gdk.test
```

If you've been using the [loopback interface](#optional-loopback-interface), you will add the following:

```
172.16.123.1 gitlab.gdk.test
```

We used `gdk.test` as the host name but you can set it to anything. Keep in mind that an url ending with `.test` is recommended here.

## Starting the Kubernetes cluster

In this step, we're going to start `colima` which in turn will create a `qemu` VM on which the docker runtime will be running. In addition, we're going to ask `colima` to start the kubernetes support.

Start `colima`. The first execution of this command will take some time as it will need to create and initialize the `qemu` VM. We're going to use the minikube [recommended settings](../minikube/index.md#deploying-gitlab-with-recommended-settings) for the VM specs. Lastly, `colima` will properly set up `kubectl` to interact with the cluster.

```shell
colima start  --cpu 4 --memory 10 --disk 60 --kubernetes
```

Once the VM is created, confirm that you have everything working properly by checking the pods running in the cluster:

```shell
kubectl get pods -A

NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
kube-system   local-path-provisioner-79f67d76f8-ddccv   1/1     Running   0          16s
kube-system   coredns-597584b69b-skq9v                  1/1     Running   0          16s
kube-system   metrics-server-5c8978b444-v6948           0/1     Running   0          16s
```

## Deploying GitLab

For this part, we're going to clone the GitLab chart project and use it.

For the configuration of the charts, [here](https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/colima/values-minimum.yaml) is the provided minimum file.
This file will use the following:

- Host set to `gdk.test`.
- External IP set to `172.16.123.1`. If you're using the [loopback interface](#optional-loopback-interface), this is already the correct value.
- No https configured.
- No ingress configured. We're going to use a [port forward](#accessing-the-running-instance).
- Promotheus disabled.
- GitLab runner disabled.
- Sidekiq disabled.
- GitLab shell disabled.
- Larger `webservice` container probes delays and timeouts to give more time to the rails application to boot.
- Replicas count set to `1` to avoid using more resources than needed.

That file is meant to provide a base that you can customize for your needs. For example, you could connect an [external object storage](../../advanced/external-object-storage/index.md).

Deploy GitLab using:

```shell
helm dependency update
helm upgrade --install gitlab . \
  --timeout 600s \
  -f examples/colima/values-minimum.yaml
```

The very first deployment will take quite some time, up to 10 minutes.

You can monitor it with the following command:

```shell
kubectl get pods
```

The application is fully running when you see a pod named `gitlab-webservice` with status `Running`.

## Accessing the running instance

Now that GitLab is deployed locally, let's try to access it.

First, we will need to retrieve the default password for the `root` user:

```shell
kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

To expose the application, and allow us access it from a web browser, we're going to use the [kubectl port-forward](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/) command:

```shell
kubectl port-forward service/gitlab-webservice-default 7080:8181 --address 0.0.0.0 
```

This will run a small proxy in the foreground. You need to keep it running as long as you need to access the GitLab application with a web browser.

Now, you can browse http://gitlab.gdk.test:7080. You should land on the login page. 

Use `root` and the password from the previous step to log in. You should be able to proceed and see the list of packages.

## Tips

At any point, you can "reset" the kubernetes cluster. `colima` will basically stop it, remove it and a create a new one from scratch.

```shell
colima kubernetes reset
```

To browse the logs of any pod/container in the cluster, consider using https://github.com/boz/kail.

```shell
# all logs
kail

# logs of a given pod
kail -p <exact pod name>

# logs of a given container (located in any pod)
kail -c <container name>
kail -c gitlab-workhorse
kail -c webservice
```