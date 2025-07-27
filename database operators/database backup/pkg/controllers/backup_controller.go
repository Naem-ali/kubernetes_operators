package controllers

import (
	"context"
	"fmt"
	"time"

	dbopsv1alpha1 "github.com/example/db-backup-operator/api/v1alpha1"
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"
)

const (
	backupContainerTemplate = `#!/bin/sh
set -ex
TIMESTAMP=$(date +%%Y%%m%%d-%%H%%M%%S)
FILENAME=%s-$TIMESTAMP.%s

# Perform backup based on database type
case "%s" in
    postgresql)
        export PGPASSWORD=$DB_PASSWORD
        pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME -Fc -f /tmp/$FILENAME
        ;;
    mysql)
        mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > /tmp/$FILENAME
        ;;
    mongodb)
        mongodump --uri="mongodb://$DB_USER:$DB_PASSWORD@$DB_HOST/$DB_NAME" --archive=/tmp/$FILENAME
        ;;
esac

# Upload to S3
aws s3 cp /tmp/$FILENAME s3://%s/$FILENAME --endpoint-url=%s

# Cleanup
rm /tmp/$FILENAME
`
)

// DatabaseBackupReconciler reconciles a DatabaseBackup object
type DatabaseBackupReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

func (r *DatabaseBackupReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	log := log.FromContext(ctx)
	
	var backup dbopsv1alpha1.DatabaseBackup
	if err := r.Get(ctx, req.NamespacedName, &backup); err != nil {
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	// Create or update the CronJob
	if err := r.ensureCronJob(ctx, &backup); err != nil {
		return ctrl.Result{}, err
	}

	return ctrl.Result{}, nil
}

func (r *DatabaseBackupReconciler) ensureCronJob(ctx context.Context, backup *dbopsv1alpha1.DatabaseBackup) error {
	log := log.FromContext(ctx)
	
	// Determine file extension based on database type
	var fileExt string
	switch backup.Spec.DatabaseType {
	case "postgresql":
		fileExt = "dump"
	case "mysql":
		fileExt = "sql"
	case "mongodb":
		fileExt = "archive"
	}

	cronJob := &batchv1.CronJob{
		ObjectMeta: metav1.ObjectMeta{
			Name:      fmt.Sprintf("backup-%s", backup.Name),
			Namespace: backup.Namespace,
			Labels:    map[string]string{"app": "db-backup", "backup": backup.Name},
		},
		Spec: batchv1.CronJobSpec{
			Schedule: backup.Spec.Schedule,
			JobTemplate: batchv1.JobTemplateSpec{
				Spec: batchv1.JobSpec{
					Template: corev1.PodTemplateSpec{
						Spec: corev1.PodSpec{
							RestartPolicy: corev1.RestartPolicyOnFailure,
							Containers: []corev1.Container{
								{
									Name:    "backup",
									Image:   "backup-helper:latest",
									Command: []string{"/bin/sh", "-c"},
									Args:    []string{fmt.Sprintf(backupContainerTemplate, 
										backup.Name, 
										fileExt,
										backup.Spec.DatabaseType,
										backup.Spec.Storage.S3.Bucket,
										backup.Spec.Storage.S3.Endpoint)},
									EnvFrom: []corev1.EnvFromSource{
										{
											SecretRef: &corev1.SecretEnvSource{
												LocalObjectReference: corev1.LocalObjectReference{
													Name: backup.Spec.Storage.S3.CredentialsSecret,
												},
											},
										},
										{
											SecretRef: &corev1.SecretEnvSource{
												LocalObjectReference: corev1.LocalObjectReference{
													Name: fmt.Sprintf("%s-db-creds", backup.Name),
												},
											},
										},
									},
								},
							},
						},
					},
				},
			},
		},
	}

	if err := ctrl.SetControllerReference(backup, cronJob, r.Scheme); err != nil {
		return err
	}

	existing := &batchv1.CronJob{}
	err := r.Get(ctx, client.ObjectKeyFromObject(cronJob), existing)
	if client.IgnoreNotFound(err) != nil {
		return err
	}

	if err != nil {
		log.Info("Creating new CronJob", "CronJob", cronJob.Name)
		return r.Create(ctx, cronJob)
	}

	log.Info("Updating existing CronJob", "CronJob", cronJob.Name)
	existing.Spec = cronJob.Spec
	return r.Update(ctx, existing)
}

func (r *DatabaseBackupReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&dbopsv1alpha1.DatabaseBackup{}).
		Owns(&batchv1.CronJob{}).
		Complete(r)
}