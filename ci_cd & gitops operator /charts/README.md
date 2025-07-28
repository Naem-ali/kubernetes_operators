# ⎈ GitOps Operator Helm Chart

<div align="center">
  <table>
    <tr align="center">
      <td width="200">
        <img src="https://helm.sh/img/helm.svg" width="100" alt="Helm">
        <br>Helm
      </td>
      <td width="200">
        <img src="https://cdn.iconscout.com/icon/free/png-256/argo-3628736-3029959.png" width="100" alt="ArgoCD">
        <br>ArgoCD
      </td>
      <td width="200">
        <img src="https://cdn.iconscout.com/icon/free/png-256/kubernetes-3628739-3030165.png" width="100" alt="Kubernetes">
        <br>Kubernetes
      </td>
    </tr>
  </table>

  [![Helm](https://img.shields.io/badge/Helm-3.8+-0F1689?style=for-the-badge&logo=helm&logoColor=white)](https://helm.sh)
  [![ArgoCD](https://img.shields.io/badge/ArgoCD-2.4+-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argoproj.github.io/cd)
</div>

## 🚀 Quick Install

```bash
# Add the Helm repository
helm repo add gitops-operator https://yourorg.github.io/helm-charts

# Install the operator
helm install gitops-operator gitops-operator/gitops-operator \
  -n gitops-system \
  --create-namespace
```

## ⚙️ Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `operator.image.repository` | 🐳 Operator image repository | `ghcr.io/yourorg/gitops-operator` |
| `argocd.enabled` | 🔄 Install ArgoCD dependency | `true` |
| `defaultScans.enabled` | 🔍 Enable default GitRepoScan configs | `false` |

## 🎯 Key Features

### 🔄 Integrated ArgoCD Support
- 🔌 Optional ArgoCD dependency
- 🔍 Automatic server discovery
- 🔗 Seamless integration

### ⚡ Flexible Configuration
- 📋 Pre-configured default scans
- 🎛️ Customizable resource limits
- 🔒 Security context included

### 📊 Monitoring Ready
```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
```

### 🛡️ Production-Grade Security
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
```

## 🔧 Installation Examples

### Basic Installation
```bash
# Package the chart
helm package charts/gitops-operator

# Install with defaults
helm install gitops-operator ./gitops-operator-0.1.0.tgz \
  -n gitops-system
```

### Custom RBAC Setup
```bash
helm install gitops-operator ./charts/gitops-operator \
  --set rbac.create=true \
  --set rbac.rules[0].resources={gitreposcans,gitreposcans/status} \
  --set serviceAccount.create=true
```

## 📋 Dependencies

- **ArgoCD** (Optional)
  ```yaml
  dependencies:
    - name: argo-cd
      version: ">=4.9.0"
      repository: https://argoproj.github.io/argo-helm
      condition: argocd.enabled
  ```

## 🔍 Validation

```bash
# Validate chart
helm lint charts/gitops-operator

# Test installation
helm test gitops-operator -n gitops-system
```

## 💡 Pro Tips

> 💭 Use `--dry-run` to preview the installation:
```bash
helm install --dry-run --debug gitops-operator ./charts/gitops-operator
```

---
<div align="center">
  <sub>Powered by Helm ⎈ and ArgoCD 🔄</sub>
  <br>
  <sub>"Making Kubernetes deployments as smooth as sailing! ⛵"</sub>
</div>
