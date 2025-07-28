# GitOps Operator Helm Chart

## Installation

```bash
helm repo add gitops-operator https://yourorg.github.io/helm-charts
helm install gitops-operator gitops-operator/gitops-operator -n gitops-system --create-namespace

Configuration
Parameter	Description	Default
operator.image.repository	Operator image repository	ghcr.io/yourorg/gitops-operator
argocd.enabled	Install ArgoCD dependency	true
defaultScans.enabled	Enable default GitRepoScan configurations	false

Dependencies
ArgoCD (optional)


## Key Features of This Chart:

1. **Integrated ArgoCD Support**  
   - Optional dependency on ArgoCD
   - Automatic server discovery

2. **Flexible Configuration**  
   - Pre-configured default scans
   - Customizable resource limits
   - Security context out of the box

3. **Monitoring Ready**  
   - Built-in metrics endpoint
   - ServiceMonitor support

4. **Production-Grade**  
   - Proper resource requests/limits
   - Security best practices
   - Helm hooks for CRD installation

To use this chart:
```bash
# Package the chart
helm package charts/gitops-operator

# Install with default values
helm install gitops-operator ./gitops-operator-0.1.0.tgz -n gitops-system


To deploy with custom RBAC:

helm install gitops-operator ./charts/gitops-operator \
  --set rbac.create=true \
  --set rbac.rules[0].resources={gitreposcans,gitreposcans/status} \
  --set serviceAccount.create=true