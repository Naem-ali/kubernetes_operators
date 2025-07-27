package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// DatabaseBackupSpec defines the desired state of DatabaseBackup
type DatabaseBackupSpec struct {
	DatabaseType string `json:"databaseType"` // postgresql, mysql, mongodb
	Schedule     string `json:"schedule"`     // Cron schedule
	Retention    int32  `json:"retention"`    // Days to retain backups
	
	Storage StorageConfig `json:"storage"`
	
	Resources ResourceRequirements `json:"resources,omitempty"`
}

type StorageConfig struct {
	S3 S3StorageConfig `json:"s3"`
}

type S3StorageConfig struct {
	Bucket            string `json:"bucket"`
	Endpoint          string `json:"endpoint"`
	CredentialsSecret string `json:"credentialsSecret"`
}

type ResourceRequirements struct {
	Requests ResourceList `json:"requests,omitempty"`
}

type ResourceList struct {
	CPU    string `json:"cpu,omitempty"`
	Memory string `json:"memory,omitempty"`
}

// DatabaseBackupStatus defines the observed state of DatabaseBackup
type DatabaseBackupStatus struct {
	LastBackupTime      *metav1.Time `json:"lastBackupTime,omitempty"`
	LastBackupStatus    string       `json:"lastBackupStatus,omitempty"`
	ObservedGeneration  int64        `json:"observedGeneration,omitempty"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status

// DatabaseBackup is the Schema for the databasebackups API
type DatabaseBackup struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   DatabaseBackupSpec   `json:"spec,omitempty"`
	Status DatabaseBackupStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// DatabaseBackupList contains a list of DatabaseBackup
type DatabaseBackupList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []DatabaseBackup `json:"items"`
}

func init() {
	SchemeBuilder.Register(&DatabaseBackup{}, &DatabaseBackupList{})
}