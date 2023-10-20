# kubernetes-copy-pvc
Effortlessly copy Kubernetes Persistent Volume Claims between same namespaces and clusters.

This repository contains a collection of scripts and tools for simplifying the process of copying Persistent Volume Claims (PVCs) between namespaces or clusters in a Kubernetes environment. It provides an interactive command-line interface for selecting source and destination PVCs, creating migration jobs, monitoring their progress, and executing the migrations.

# Features:

Select source and destination PVCs interactively.

Create Kubernetes Job resources for PVC data migration.

Monitor job progress and completion.

Supports copying PVCs within the same cluster or across different clusters.

Automatically handle PVC copying with minimal manual intervention.

This tool is especially useful when you need to move data between namespaces, clusters, or when you want to create backups of your PVC data.


