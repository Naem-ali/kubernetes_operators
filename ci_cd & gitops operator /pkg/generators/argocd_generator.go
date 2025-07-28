package generators

import (
	"context"

	argov1alpha1 "github.com/argoproj/argo-cd/v2/pkg/apis/application/v1alpha1"
	gitopsv1alpha1 "github.com/example/gitops-operator/api/v1alpha1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/controller-runtime/pkg/client"
)

type ArgoCDGenerator struct {
	Client client.Client
}

func (g *ArgoCDGenerator) GenerateApplication(
	ctx context.Context,
	scan *gitopsv1alpha1.GitRepoScan,
	spec gitopsv1alpha1.ApplicationSpec) error {
	
	app := &argov1alpha1.Application{
		ObjectMeta: metav1.ObjectMeta{
			Name:      generateAppName(scan.Name, spec.SourcePath),
			Namespace: "argocd",
			Labels: map[string]string{
				"generated-by": "gitops-operator",
				"source-repo":  scan.Spec.RepoUrl,
			},
		},
		Spec: argov1alpha1.ApplicationSpec{
			Project: "default",
			Source: &argov1alpha1.ApplicationSource{
				RepoURL:        scan.Spec.RepoUrl,
				Path:           spec.SourcePath,
				TargetRevision: scan.Spec.TargetRevision,
			},
			Destination: argov1alpha1.ApplicationDestination{
				Server:    spec.DestinationCluster,
				Namespace: spec.DestinationNamespace,
			},
			SyncPolicy: &argov1alpha1.SyncPolicy{
				Automated: &argov1alpha1.SyncPolicyAutomated{
					Prune:    true,
					SelfHeal: true,
				},
			},
		},
	}
	
	return g.Client.Create(ctx, app)
}

func generateAppName(scanName string, path string) string {
	return strings.ToLower(scanName + "-" + strings.ReplaceAll(path, "/", "-"))
}