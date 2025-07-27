package utils

import (
	"context"
	"time"

	dbopsv1alpha1 "github.com/example/db-backup-operator/api/v1alpha1"
	batchv1 "k8s.io/api/batch/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/controller-runtime/pkg/client"
)

func CleanupOldBackups(ctx context.Context, c client.Client, backup *dbopsv1alpha1.DatabaseBackup) error {
	// Implementation for cleaning up old backups based on retention policy
	return nil
}

func GetBackupImage(dbType string) string {
	switch dbType {
	case "postgresql":
		return "postgres-backup-helper:latest"
	case "mysql":
		return "mysql-backup-helper:latest"
	case "mongodb":
		return "mongodb-backup-helper:latest"
	default:
		return "generic-backup-helper:latest"
	}
}

func ShouldRunBackup(backup *dbopsv1alpha1.DatabaseBackup, lastRun *metav1.Time) bool {
	if lastRun == nil {
		return true
	}
	
	// Only run if the schedule has changed or it's time for a new backup
	schedule, err := cron.ParseStandard(backup.Spec.Schedule)
	if err != nil {
		return false
	}
	
	nextRun := schedule.Next(lastRun.Time)
	return time.Now().After(nextRun)
}