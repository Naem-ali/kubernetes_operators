func (r *GitRepoScanReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    log := log.FromContext(ctx)
    
    // 1. Fetch GitRepoScan instance
    var scan gitopsv1alpha1.GitRepoScan
    if err := r.Get(ctx, req.NamespacedName, &scan); err != nil {
        return ctrl.Result{}, client.IgnoreNotFound(err)
    }

    // 2. Clone repository
    repo, err := r.cloneRepo(scan.Spec.RepoUrl, scan.Spec.TargetRevision)
    if err != nil {
        return ctrl.Result{}, err
    }

    // 3. Detect Kubernetes manifests
    apps, err := r.scanForApplications(repo, scan.Spec.PathMappings)
    if err != nil {
        return ctrl.Result{}, err
    }

    // 4. Generate ArgoCD Applications
    if err := r.syncApplications(ctx, apps); err != nil {
        return ctrl.Result{}, err
    }

    // 5. Update status
    scan.Status.LastScanTime = &metav1.Time{Time: time.Now()}
    if err := r.Status().Update(ctx, &scan); err != nil {
        return ctrl.Result{}, err
    }

    return ctrl.Result{RequeueAfter: scan.Spec.ScanInterval}, nil
}