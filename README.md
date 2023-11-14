# Deletion Ordering with Usage API

This repo demonstrates how to use the Usage API to control the order in which
deletions are processed for resources that are part of the same composite/claim.

## Prerequisites

* A fresh Kubernetes cluster with nothing installed.
  * A kind cluster is recommended.
* `up` CLI is installed from https://github.com/upbound/up#install

## Steps

1. Run `./setup.sh` which will take care of the below, the end result is visualized in [arch.png](./arch.png):
   1. Installs UXP with the Usage API enabled, e.g. `--enable-usages`
   2. Applies the manifests under `setup` directory which install the required providers
   as well as the `Compositions` and `CompositeResourceDefinitions` including the one that we just modified.
   3. Configures the `provider-kubernetes` and `provider-helm` to work within the same Kubernetes cluster.

2. Create the claim with `kubectl apply -f claim.yaml` and wait for the resources to become ready (e.g., `kubectl get managed`)

3. Check the `Usage` resource that is created as part of the claim:

```bash
❯ kubectl get usages
NAME                       DETAILS                                                                       READY   AGE
example-user-t56ng-rg8q7   User/example-user-t56ng-z7s6j uses XDatabaseServer/example-user-t56ng-jgv4j   True    5s
```

4. Try deleting the resource in use with `kubectl` and observe that it is prevented:

```bash
❯ kubectl delete XDatabaseServer --all # using --all for convenience, but you can also specify the name
Error from server (This resource is in-use by 1 Usage(s), including the Usage "example-user-t56ng-rg8q7" by resource User/example-user-t56ng-z7s6j.): admission webhook "nousages.apiextensions.crossplane.io" denied the request: This resource is in-use by 1 Usage(s), including the Usage "example-user-t56ng-rg8q7" by resource User/example-user-t56ng-z7s6j.
```

5. Delete the claim and verify that no managed resources are left behind:

```bash
❯ kubectl delete -f claim.yaml
databasewithuser.example.io "example-user" deleted
❯ kubectl get managed
No resources found
```

Without the Usage resource, the deletion of the SQL User resource could have
failed since either `database-connection-secret` or the `MariaDB Server` itself
may have gone before SQL User is successfully cleaned up. The Usage resource ensures
that any resources that are part of the `XDatabaseServer` are not deleted until the
SQL User resource is deleted.

## Acknowledgements

* Thanks to [@turkenh](https://github.com/turkenh) for building this demo content (as well as the `Usage` feature)!