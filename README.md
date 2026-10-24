# Tenant GitOps

This repository bootstraps tenant `AppProject` and `Application` resources into an existing OpenShift GitOps installation.

## Ownership

- The OpenShift GitOps Operator owns the installation, the existing `ArgoCD` custom resource, and the `openshift-gitops` namespace.
- The one-time bootstrap creates the `platform` AppProject and `platform-tenants` root Application.
- The root Application manages tenant AppProjects and Applications.
- Argo CD deploys tenant applications.
- ACM/AutoShift remains responsible for cluster-level configuration and Operators.
- Tenant namespaces and application-controller Kubernetes permissions are managed outside this repository. This project does not create tenant namespaces or add tenant-controller RoleBindings.

## Repository layout

- `bootstrap/platform-project.yaml`: AppProject that limits the root Application.
- `bootstrap/root-app.yaml`: root Application for the `tenants/` directory.
- `argocd-operator/rbac-policy-fragment.yaml`: reference fragment for the existing Operator-managed `ArgoCD` CR.
- `tenants/farmers/`: Farmers AppProject, Application, and tenant-specific Kustomize configuration.
- `tenants/ranchers/`: Ranchers AppProject, Application, and tenant-specific Kustomize configuration.

Each tenant directory is self-contained: its `appproject.yaml` defines the tenant project and RBAC roles, `application.yaml` defines its application, and `kustomization.yaml` includes both. The parent `tenants/kustomization.yaml` includes each tenant directory.

## Before applying

1. Update `https://github.com/cziesman/tenant-gitops.git` in `bootstrap/platform-project.yaml` and `bootstrap/root-app.yaml` if this repository is hosted elsewhere.
2. Confirm `farmers-dev` and `ranchers-dev` already exist and that the existing Argo CD application-controller service account has sufficient permissions in those namespaces.
3. Replace the sample `https://github.com/argoproj/argocd-example-apps.git` repository/path with the actual tenant application sources when ready.
4. Merge `argocd-operator/rbac-policy-fragment.yaml` into `spec.rbac` on the existing Operator-managed `ArgoCD` custom resource. Do not apply the fragment as a standalone resource, and do not have this root Application manage the `ArgoCD` custom resource.

## Bootstrap

Run these commands from the repository root:

```bash
oc apply -f bootstrap/platform-project.yaml
oc apply -f bootstrap/root-app.yaml
```

Check reconciliation:

```bash
oc get appproject,application -n openshift-gitops
```

## Okta group naming and scope

Use this naming convention:

`OCP-(PROD|NONPROD)-<REGION>-<TEAM>-<SCOPE>`

- `OCP` identifies groups intended for OpenShift.
- `PROD` or `NONPROD` identifies the environment class. Use `NONPROD` without a hyphen.
- `<REGION>` identifies the region, for example `IA` or `WY`.
- `<TEAM>` identifies the tenant, for example `FARMERS` or `RANCHERS`.
- `<SCOPE>` is `ADMIN`, `DEVELOPER`, or `VIEWER`.

The example Applications target the non-production namespaces `farmers-dev` and `ranchers-dev`, so their AppProject roles are bound to `NONPROD` groups only. Do not map `PROD` groups to these non-production AppProjects: doing so would grant production-group members access to the non-production applications. When production AppProjects and destinations are defined, add their `PROD` group bindings to those production-specific AppProjects and the global RBAC policy.

## Example role mappings

| Okta group | AppProject role | Effective permissions |
|---|---|---|
| `OCP-NONPROD-IA-FARMERS-ADMIN` | `proj:farmers:admins` | Manage Farmers applications |
| `OCP-NONPROD-IA-FARMERS-DEVELOPER` | `proj:farmers:developers` | View and sync Farmers applications |
| `OCP-NONPROD-IA-FARMERS-VIEWER` | `proj:farmers:members` | View Farmers applications |
| `OCP-NONPROD-WY-RANCHERS-ADMIN` | `proj:ranchers:admins` | Manage Ranchers applications |
| `OCP-NONPROD-WY-RANCHERS-DEVELOPER` | `proj:ranchers:developers` | View and sync Ranchers applications |
| `OCP-NONPROD-WY-RANCHERS-VIEWER` | `proj:ranchers:members` | View Ranchers applications |

A group applies to all clusters matching its environment-class and region segments. The group name does not identify one individual cluster. Cluster access is still constrained by the relevant AppProject destinations and the Argo CD installation on each cluster. If memberships must differ between clusters that share the same environment class and region, the naming convention needs an additional cluster discriminator or separate groups.

The AppProject `sourceRepos` allowlist controls which Git repositories an Application may use; it does not grant Kubernetes permissions in the destination namespace. Each tenant AppProject is restricted to its sample repository and tenant namespace. The root AppProject allows only the root repository and resources needed to manage tenant AppProjects and Applications in `openshift-gitops`.
