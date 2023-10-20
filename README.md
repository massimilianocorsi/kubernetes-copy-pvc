# Kubernetes copy multiple pvc
Effortlessly copy multiple Kubernetes Persistent Volume Claims between the same namespaces and clusters.

This repository contains a collection of scripts and tools for simplifying the process of copying Persistent Volume Claims (PVCs) between namespaces or clusters in a Kubernetes environment. It provides an interactive command-line interface for selecting source and destination PVCs, creating migration jobs, monitoring their progress, and executing the migrations.

# Features:

- Select source and destination PVCs interactively.
- Create Kubernetes Job resources for PVC data migration.
- Monitor job progress and completion.
- Supports copying PVCs within the same namespace and cluster
- Automatically handle PVC copying with minimal manual intervention.
- This tool is especially useful when you need to move data between the same namespaces and clusters, create backups of your PVC data, or change the storage class in use.

**Usage:**

**Prerequisites:**
- Make sure you have created the destination PVC in the same namespace as the source PVC.

**Execution:**
1. Clone this repository to your local machine.
2. Navigate to the project directory.
4. Run the script:
    ```
    ./copy-pvc.sh
    ```
5. The script will prompt you to provide the following information:
    - Select the desired Kubernetes cli (kubectl, oc, mickrok8s kubectl, custom text).
    - Select the desired Kubernetes namespace.
    - Select the source PVC you want to copy.
    - Select the destination PVC where you want to copy the data.
7. Follow the on-screen instructions to initiate the PVC data migration.

This script facilitates the easy copying of PVC data within the same cluster and namespace, making it a helpful tool for managing your Kubernetes resources.

## Acknowledgments

This script was inspired by the following source:
- [Migrating Kubernetes PVC to Another PVC](https://justyn.io/til/migrate-kubernetes-pvc-to-another-pvc/) by Justyn Shull

A big thank you to Justyn Shull for the inspiration and guidance in creating this script.


