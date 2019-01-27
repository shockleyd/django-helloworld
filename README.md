## Introduction

This repository contains a simple implementation of a CI/CD pipeline using
[CircleCI](https://circleci.com), and deploying to a GCP Kubernetes cluster,
which is managed via [Terraform](https://www.terraform.io/).

## Demo project

The demo application is created following the
[Django for beginners tutorial](https://djangoforbeginners.com/hello-world/).
The only deviation from the tutorial, is that this project uses `virtualenv`
rather than `pipenv` for dependency management, and consequently the project
contains a `requirements.txt` file instead of `Pipfile`.

### Demo app code

The demo app code is in [helloworld_project](./helloworld_project) and
[pages](./pages).

### Running the demo app in production

The demo app is built for production with docker (see the [Dockerfile](./Dockerfile)).
The Dockerfile configuration is nearly identical to
[docker's example Django Dockerfile](https://docs.docker.com/compose/django/), with
the addition of a `CMD` statement, which runs the application via the Django development
server. In a real production application, we would likely use `gunicorn`, `wsgi`, or similar,
but in order to focus on the CI/CD pipeline, we use the simplest approach to run the demo app.

## GCP K8s cluster configuration

The Kubernetes cluster is managed via Terraform, so that infrastructure management can easily be
reviewed before changes are applied (via pull requests), infrastructure provisioning is repeatable,
and new environments (e.g., staging) can be provisioned with limited effort.

Terraform configuration is in [/terraform](./terraform). The cluster is configured mostly
with the default values for a GCP K8s cluster, with two notable exceptions:

* the cluster is configured with native-VPC enabled
* the cluster is configured with basic authentication and client certificate disabled, for
improved security

To keep things simple, we use the default network, and manually manage the
service accounts.

### Terraform config organization

Since we are only configuring a single resource (the K8s cluster), it would be
quite reasonable to keep all the Terraform config in a single file. However, for
ease of future improvements (such as adding a staging environment or other GCP services),
the Terraform configuration is organized into a module, and uses a variable file for
configuration.

### Terraform config deployment

Because of time constraints, the Terraform config is applied manually from a
local environment. Ideally we would also add continuous delivery (with manual
approval) for the Terraform config, likely using CircleCI, similarly to
[this example](https://github.com/fedekau/terraform-with-circleci-example/blob/staging/.circleci/config.yml).

## K8s configuration

The [K8s configuration](./k8s.yml) includes a `LoadBalancer` service, and a `Deployment` for the
demo application. It is modified from
[this tutorial](https://medium.com/@admm/ci-cd-using-circleci-and-google-kubernetes-engine-gke-7ed3a5ad57e).

## Docker registry

We use the Google Cloud [Container Registry](https://cloud.google.com/container-registry/)
to store the docker images we build in order to deploy to Kubernetes. Other
registry solutions exist, but this is the simplest solution considering we are
using GCP Kubernetes.

## CircleCI access to GCloud

In order to deploy to the Google Cloud Kubernetes Engine, CircleCI needs
access to the Google Cloud account. A service account is manually created
for CircleCI, with the `container.developer` role, and the access key is
stored in an environment variable in CircleCI.

## CI/CD pipeline

We use CircleCI to implement continuous integration and deployment.
We do not require manual approval for deploys; a deploy happens automatically
for every `master` branch commit. The decision whether to require manual approval
depends primarily on the specific application, and the level of risks associated
with a deployment. Continuous deployment (that is, automatic) is a good default,
but for many applications we would require manual approval, or schedule nightly
deploys in order to minimize risk of interrupting service for users where a very
high level of reliability is required.

### Docker image tags

We use the commit hash as the docker image tag, because it's the simplest solution.
In case we decide we want more human-readable tags, it might make sense to switch to
using the commit timestamp (or a combination of the commit hash and timestamp).
Other ideas could work too, like requiring developers to update a semver version
in some way, and using this to tag, but an automated solution is easier and less
error-prone.

### Build job

The build job configuration is (with very minor changes) generated automatically by CircleCI
on project creation. It uses the CircleCI python3.6 docker image, and:

* checkout
* Restore previously cached dependencies
* Install dependencies
* Run tests (using `manage.py test`)
* Save dependencies to cache

### Deploy job:

* checkout
* Setup Google Cloud SDK
  * Activate the service account
  * Set project and zone
  * Get credentials for the K8s cluster
* Setup remote docker in order to be able to build the docker image for deployment
* Docker build and push
  * Build the Dockerfile
  * Tag appropriately for GCP Container Registry
  * Docker login to the GCP Container Registry
  * Push to the docker registry
* Deploy to Kubernetes
  * Replace env variables (commit hash/docker image tag) in k8s.yml
  * Apply the new config with `kubectl`
  * Use `kubectl rollout status` to monitor status of deploy, and wait
  for it to complete.
