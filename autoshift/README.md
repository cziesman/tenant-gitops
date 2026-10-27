# Tenant GitOps via AutoShift/ACM Policy

This repository layout replaces the one-time `platform-tenants` bootstrap Application with an AutoShift-compatible ACM `PolicyGenerator`.

## Behavior
- ACM policy reconciles Farmers and Ranchers `AppProject` and `Application` objects into `openshift-gitops`.
- Argo CD continues to reconcile tenant workloads.
- The policy also enforces the group-to-role mappings on the existing `openshift-gitops/openshift-gitops` `ArgoCD` custom resource.
- The existing operator-managed ArgoCD instance and namespace are not created or replaced by this policy.

## Integration
Copy `policy/` into the AutoShift policy tree following the same directory placement/conventions as `policies/stable/gitops-dev`.
The policy assumes `${POLICY_NAMESPACE}`, `${REMEDIATION}`, `${EVAL_COMPLIANT}`, and `${EVAL_NONCOMPLIANT}` are substituted by the same repo-server CMP used by the AutoShift deployment.

Before enabling enforcement:
1. Confirm the cluster-selection label `autoshift.io/tenant-gitops: 'true'` is assigned only to clusters that should receive these tenant resources. Adjust `policy/placement.yaml` if your intended selector differs.
2. Confirm the `openshift-gitops` namespace exists and the OpenShift GitOps operator owns the `ArgoCD` CR named `openshift-gitops`.
3. Confirm `farmers-dev` and `ranchers-dev` exist and the Argo CD application-controller has the required Kubernetes permissions there.
4. Replace the sample workload repository/path if needed.
5. Review `policy/manifests/tenant-gitops.yaml` and validate with the same AutoShift `kustomize build`/policy generation pipeline used for `gitops-dev`.

## Files
- `placement.yaml`: managed-cluster selector.
- `kustomization.yaml`: invokes the PolicyGenerator.
- `policy-generator-config.yaml`: AutoShift policy generation defaults.
- `manifests/tenant-gitops.yaml`: hub-template policy manifest with desired objects.

The former `bootstrap/platform-project.yaml` and `bootstrap/root-app.yaml` are intentionally not included; they are no longer part of the deployment path.
