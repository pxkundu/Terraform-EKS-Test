# Interactive EKS Node Health Audit Script

## Overview
The `node_audit.sh` script provides an interactive interface to audit Amazon EKS cluster nodes. It allows users to select an EKS cluster, filter nodes by status (Ready/NotReady) or AMI age, and displays a colored report showing each node's name, status, and AMI age in days.

## Requirements
- `kubectl`: To interact with the EKS cluster
- AWS CLI: To query EC2 instance/AMI information and list EKS clusters
- `jq`: For JSON parsing
- Proper AWS credentials with permissions for `eks:ListClusters`, `ec2:DescribeInstances`, and `ec2:DescribeImages`
- Configured kubectl with access to EKS clusters

## Features
- **Interactive Cluster Selection**: Lists available EKS clusters and prompts the user to select one.
- **Dynamic Filtering**:
  - Filter nodes by status: All, Ready, or NotReady
  - Filter nodes by minimum AMI age (in days)
- **Colored Output**:
  - Red for NotReady status
  - Green for Ready status
  - Yellow for AMI age > 30 days
- **Formatted Report**: Displays NodeName, Status, and AMI Age (Days) in a tabular format.
- **Error Handling**: Robust checks for dependencies, permissions, and invalid inputs.

## Error Handling
- **Missing Dependencies**: Exits with an error if `kubectl`, `aws`, or `jq` is not installed.
- **No Clusters Found**: Exits if no EKS clusters are available or AWS credentials are invalid.
- **No Nodes Found**: Exits if the selected cluster has no nodes.
- **kubectl Failure**: Exits if `kubectl get nodes` fails (e.g., due to connectivity or permissions).
- **AWS API Issues**: Reports "N/A" for AMI age if AWS API calls fail (e.g., invalid instance ID or permissions).
- **Invalid AMI Data**: Reports "N/A" for AMI age if the creation date is unavailable or invalid.
- **Invalid User Input**: Prompts again for valid input during cluster selection or filter options.
- **No Matching Nodes**: Displays a warning if no nodes match the specified filters.

## Usage
```bash
chmod +x node_audit.sh
./node_audit.sh
```

### Example Interaction
```
EKS Node Health Audit Script
Available EKS Clusters:
1) dev-cluster
2) prod-cluster
3) Quit
Enter choice [1-3]: 1
Selected cluster: dev-cluster
Filter by node status?
1) All
2) Ready
3) NotReady
4) Quit
Enter choice [1-4]: 2
Filter by AMI age (days)? Enter number or press Enter for no filter: 30
Auditing nodes in cluster: dev-cluster
Status Filter: Ready
AMI Age Filter: 30
NodeName                       | Status     | AMI Age (Days)
-------------------------------------------------------------
node-1.example.com            | Ready      | 45
```

## Notes
- The script creates a temporary kubeconfig file (`~/.kube/config-<cluster-name>`) for the selected cluster.
- Ensure AWS credentials are configured correctly for the target region.
- AMI age is calculated based on the difference between the current UTC time and the AMI's creation date.
- The script highlights nodes with AMI age > 30 days in yellow to indicate potential outdated AMIs.