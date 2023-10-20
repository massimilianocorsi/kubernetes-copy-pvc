#!/bin/bash

# Function to configure Kubernetes CLI
configure_kubecli() {
    read -p "Enter the Kubernetes CLI command (e.g., kubectl, oc, microk8s kubectl, or custom text): " custom_cli
    if [[ "$custom_cli" == "kubectl" || "$custom_cli" == "oc" || "$custom_cli" == "microk8s kubectl" ]]; then
        kubecli="$custom_cli"
        echo "Kubernetes CLI set to: $kubecli"
    else
        kubecli="$custom_cli"
        echo "Using custom text as Kubernetes CLI: $kubecli"
    fi
}


# Function to create a migration job
create_migration_job() {
    src=$1
    dst=$2
    ns=$3
    data=$(date '+%Y%m%d%H%M%S')

    echo "Creating job yaml"
    cat > migrate-job-$data.yaml << EOF
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: migrate-pv-$src-$data
    spec:
      template:
        spec:
          containers:
          - name: migrate
            image: debian
            command: [ "/bin/bash", "-c" ]
            args:
              -
                apt-get update && apt-get install -y rsync &&
                ls -lah /src_vol /dst_vol &&
                df -h &&
                rsync -avPS --delete /src_vol/ /dst_vol/ &&
                ls -lah /dst_vol/ &&
                du -shxc /src_vol/ /dst_vol/
            volumeMounts:
            - mountPath: /src_vol
              name: src
              readOnly: true
            - mountPath: /dst_vol
              name: dst
          restartPolicy: Never
          volumes:
          - name: src
            persistentVolumeClaim:
              claimName: $src
          - name: dst
            persistentVolumeClaim:
              claimName: $dst
EOF

    $kubecli -n $ns create -f migrate-job-$data.yaml
    $kubecli -n $ns get jobs -o wide
    $kubecli -n $ns get pods | grep migrate

    echo "Waiting for job completion for PVC $src in namespace $ns..."

    while true; do
        in_progress_jobs=$($kubecli get jobs -n $ns | grep -c '0/1     ContainerCreating')
        echo "There are $in_progress_jobs jobs in progress"
        if [[ $in_progress_jobs -eq 0 ]]; then
            while true; do
                complete_jobs=$($kubecli get jobs -n $ns | grep -c '1/1')
                total_jobs=$($kubecli get jobs -n $ns | grep -c 'migrate-pv' )
                if [[ $complete_jobs -eq $total_jobs ]]; then
                    echo "All jobs have completed successfully"
                    echo "Deleting job in progress"
                    $kubecli -n $ns delete -f migrate-job-$data.yaml
                    break
                else
                    echo "Job in progress..."
                fi
            done
            break
        else
            echo "Job in progress..."
        fi
        sleep 5  # Wait for 5 seconds before checking again
    done
}

# Array to store PVC pairs
pvc_pairs=()

# Function to check if a PVC pair has already been selected
is_duplicate_pair() {
    local check_pair="$1 $2 $1 $3"  # Format: "src_namespace src_pvc dest_namespace dest_pvc"
    for pair in "${pvc_pairs[@]}"; do
        if [ "$pair" == "$check_pair" ]; then
            return 0  # The pair is a duplicate
        fi
    done
    return 1  # The pair is not a duplicate
}

configure_kubecli()

while true; do
    # Run the kubectl command to get the list of namespaces, extract them with awk, and number them
    namespaces=$($kubecli get ns --no-headers | awk '{print $1}' | uniq | nl)

    # Check if the list of namespaces is empty
    if [ -z "$namespaces" ]; then
        echo "No namespaces found."
        exit 1
    fi

    # Show the numbered list of available namespaces
    echo "List of available namespaces:"
    echo "$namespaces"

    # Ask the user to enter the number of the desired namespace
    read -p "Enter the number of the desired namespace: " selected_number

    # Extract the name of the selected namespace based on the entered number
    selected_namespace=$(echo "$namespaces" | awk -v num="$selected_number" '$1 == num {print $2}')

    # Check if the selected number is valid
    if [ -z "$selected_namespace" ]; then
        echo "The selected number is not valid."
        exit 1
    fi

    # Show the selected namespace
    echo "You have selected the namespace: $selected_namespace"

    # Example: Show the PVCs in the selected namespace
    pvc_list=$($kubecli get pvc -n $selected_namespace --no-headers | awk '{print $1}' | uniq | nl)

    # Check if the list of PVCs is empty
    if [ -z "$pvc_list" ]; then
        echo "No PVCs found in namespace $selected_namespace."
        exit 1
    fi

    # Show the numbered list of available PVCs
    echo "List of available PVCs in namespace $selected_namespace:"
    echo "$pvc_list"

    # Ask the user to enter the number of the source PVC
    read -p "Enter the number of the source PVC: " source_number

    # Extract the name of the source PVC based on the entered number
    source_pvc=$(echo "$pvc_list" | awk -v num="$source_number" '$1 == num {print $2}')

    # Check if the selected number is valid
    if [ -z "$source_pvc" ]; then
        echo "The selected number is not valid for the available PVCs."
        exit 1
    fi

    # Remove the source PVC from the list of available PVCs
    pvc_list=$(echo "$pvc_list" | awk -v num="$source_number" '$1 != num')

    # Show the selected source PVC
    echo "You have selected the source PVC: $source_pvc in the namespace: $selected_namespace"

    # Ask the user to enter the number of the destination PVC
    read -p "Enter the number of the destination PVC: " dest_number

    # Extract the name of the destination PVC based on the entered number
    dest_pvc=$(echo "$pvc_list" | awk -v num="$dest_number" '$1 == num {print $2}')

    # Check if the selected number is valid
    if [ -z "$dest_pvc" ]; then
        echo "The selected number is not valid for the available PVCs."
        exit 1
    fi

    # Remove the destination PVC from the list of available PVCs
    pvc_list=$(echo "$pvc_list" | awk -v num="$dest_number" '$1 != num')

    # Show the selected destination PVC
    echo "You have selected the destination PVC: $dest_pvc in the namespace: $selected_namespace"

    # Check if the pair has already been selected
    if is_duplicate_pair "$selected_namespace" "$source_pvc" "$dest_pvc"; then
        echo "This PVC pair has been selected previously."
    else
        # Store the selected PVC pair in the array
        pvc_pairs+=("$selected_namespace $source_pvc $selected_namespace $dest_pvc")
    fi

    # Ask the user if they want to select another PVC pair or exit
    read -p "Do you want to select another PVC pair? (y/n): " choice
    if [ "$choice" != "y" ]; then
        break
    fi
done

# Summary of the selected PVC pairs
echo "You have selected the following PVC pairs:"
echo "-------------------------------------------------------------------------------------------------------------------"
printf "%-20s %-40s %-20s %-40s\n" "Source Namespace" "Source PVC" "Destination Namespace" "Destination PVC"
echo "-------------------------------------------------------------------------------------------------------------------"

for pair in "${pvc_pairs[@]}"; do
    source_namespace=$(echo $pair | awk '{print $1}')
    source_pvc=$(echo $pair | awk '{print $2}')
    dest_namespace=$(echo $pair | awk '{print $3}')
    dest_pvc=$(echo $pair | awk '{print $4}')
    printf "%-20s %-40s %-20s %-40s\n" "$source_namespace" "$source_pvc" "$dest_namespace" "$dest_pvc"
done

echo "-------------------------------------------------------------------------------------------------------------------"

# Ask the user if they want to proceed with the PVC migration
read -p "Do you want to proceed with the PVC migration? (y/n): " migration_choice

if [ "$migration_choice" = "y" ]; then
    # Execute the migration commands for each PVC pair
    for pair in "${pvc_pairs[@]}"; do
        src=$(echo $pair | awk '{print $2}')
        dst=$(echo $pair | awk '{print $4}')
        ns=$(echo $pair | awk '{print $1}')
        create_migration_job "$src" "$dst" "$ns"
    done
else
    echo "Migration operation canceled."
fi
