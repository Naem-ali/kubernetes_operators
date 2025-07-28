package scanners

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/go-git/go-git/v5"
	gitopsv1alpha1 "github.com/example/gitops-operator/api/v1alpha1"
)

type RepoScanner struct {
	TempDir string
}

func (s *RepoScanner) CloneRepository(url string, revision string) (string, error) {
	repoDir := filepath.Join(s.TempDir, "repo")
	_, err := git.PlainClone(repoDir, false, &git.CloneOptions{
		URL:           url,
		ReferenceName: plumbing.ReferenceName("refs/heads/" + revision),
		SingleBranch:  true,
		Depth:         1,
	})
	return repoDir, err
}

func (s *RepoScanner) FindKubernetesManifests(repoPath string) ([]gitopsv1alpha1.ApplicationSpec, error) {
	var apps []gitopsv1alpha1.ApplicationSpec
	
	err := filepath.Walk(repoPath, func(path string, info os.FileInfo, err error) error {
		if strings.HasSuffix(path, "kustomization.yaml") || 
		   strings.HasSuffix(path, "Chart.yaml") || 
		   strings.HasSuffix(path, "deployment.yaml") {
			relPath, _ := filepath.Rel(repoPath, path)
			apps = append(apps, gitopsv1alpha1.ApplicationSpec{
				SourcePath: filepath.Dir(relPath),
				Type:       detectManifestType(path),
			})
		}
		return nil
	})
	
	return apps, err
}

func detectManifestType(path string) string {
	if strings.Contains(path, "kustomization.yaml") {
		return "kustomize"
	}
	if strings.Contains(path, "Chart.yaml") {
		return "helm"
	}
	return "yaml"
}