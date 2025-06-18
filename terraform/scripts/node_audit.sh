#!/bin/bash

# node_audit.sh - Interactive EKS Node Health Audit Script
# Audits EKS cluster nodes with user-selected options and colored output

# Exit on error
set -e

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if required commands are available
check_requirements() {
    local missing=0
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl is not installed${NC}"
        missing=1
    fi
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}Error: AWS CLI is not installed${NC}"
        missing=1
    fi
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is not installed${NC}"
        missing=1
    fi
    if [ $missing -eq 1 ]; then
        exit 1
    fi
}

# Function to list available EKS clusters
list_eks_clusters() {
    aws --profile exam3 eks list-clusters --query 'clusters[]' --output text 2>/dev/null | sort
}

# Function to prompt user to select a cluster
select_cluster() {
    local clusters
    clusters=$(list_eks_clusters)
    
    if [ -z "$clusters" ]; then
        echo -e "${RED}Error: No EKS clusters found or AWS credentials invalid for profile exam3${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Available EKS Clusters:${NC}"
    select cluster in $clusters "Quit"; do
        if [ "$cluster" == "Quit" ]; then
            echo "Exiting..."
            exit 0
        fi
        if [ -n "$cluster" ]; then
            echo -e "${GREEN}Selected cluster: $cluster${NC}"
            export KUBECONFIG=~/.kube/config-$cluster
            aws --profile exam3 eks update-kubeconfig --name "$cluster" >/dev/null
            break
        else
            echo -e "${RED}Invalid selection, try again${NC}"
        fi
    done
    echo "$cluster"
}

# Function to prompt for filter options
get_filter_options() {
    local status_filter ami_age_filter
    echo -e "${YELLOW}Filter by node status?${NC}"
    select status in "All" "Ready" "NotReady" "Quit"; do
        case $status in
            All|Ready|NotReady) status_filter=$status; break;;
            Quit) echo "Exiting..."; exit 0;;
            *) echo -e "${RED}Invalid option${NC}";;
        esac
    done
    
    echo -e "${YELLOW}Filter by AMI age (days)? Enter number or press Enter for no filter:${NC}"
    read -r ami_age_input
    if [[ "$ami_age_input" =~ ^[0-9]+$ ]]; then
        ami_age_filter=$ami_age_input
    else
        ami_age_filter=""
    fi
    
    echo "$status_filter|$ami_age_filter"
}

# Function to calculate days since AMI creation
get_ami_age() {
    local ami_id=$1
    local creation_date=$(aws --profile exam3 ec2 describe-images --image-ids "$ami_id" --query 'Images[0].CreationDate' --output text 2>/dev/null)
    
    if [ -z "$creation_date" ]; then
        echo "N/A"
        return
    fi
    
    local current_time=$(date -u +%s)
    local ami_time=$(date -u -d "$creation_date" +%s 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "N/A"
        return
    fi
    
    local diff=$(( (current_time - ami_time) / 86400 ))
    echo $diff
}

# Function to audit nodes with filters
audit_nodes() {
    local status_filter=$1
    local ami_age_filter=$2
    
    local nodes
    nodes=$(kubectl get nodes -o json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to get nodes from kubectl${NC}"
        exit 1
    fi
    
    local node_count
    node_count=$(echo "$nodes" | jq '.items | length')
    
    if [ "$node_count" -eq 0 ]; then
        echo -e "${RED}Error: No nodes found in the cluster${NC}"
        exit 1
    fi
    
    # Print report header
    printf "%-30s | %-10s | %-10s\n" "NodeName" "Status" "AMI Age (Days)"
    printf "%s\n" "-------------------------------------------------------------"
    
    # Process each node
    local printed=0
    echo "$nodes" | jq -c '.items[]' | while read -r node; do
        local node_name status ami_id ami_age
        
        node_name=$(echo "$node" | jq -r '.metadata.name')
        status=$(echo "$node" | jq -r '.status.conditions[] | select(.type=="Ready") | .status')
        
        if [ "$status" == "True" ]; then
            status="Ready"
        else
            status="NotReady"
        fi
        
        # Apply status filter
        if [ "$status_filter" != "All" ] && [ "$status" != "$status_filter" ]; then
            continue
        fi
        
        instance_id=$(echo "$node" | jq -r '.spec.providerID' | awk -F'/' '{print $NF}')
        
        if [ -n "$instance_id" ]; then
            ami_id=$(aws --profile exam3 ec2 describe-instances \
                --instance-ids "$instance_id" \
                --query 'Reservations[0].Instances[0].ImageId' \
                --output text 2>/dev/null || echo "N/A")
            
            if [ "$ami_id" != "N/A" ]; then
                ami_age=$(get_ami_age "$ami_id")
            else
                ami_age="N/A"
            fi
        else
            ami_age="N/A"
        fi
        
        # Apply AMI age filter
        if [ -n "$ami_age_filter" ] && [ "$ami_age" != "N/A" ]; then
            if [ "$ami_age" -lt "$ami_age_filter" ]; then
                continue
            fi
        fi
        
        # Color-code output
        if [ "$status" == "NotReady" ]; then
            status_color="${RED}$status${NC}"
        else
            status_color="${GREEN}$status${NC}"
        fi
        
        if [ "$ami_age" != "N/A" ] && [ "$ami_age" -gt 30 ]; then
            ami_age_color="${YELLOW}$ami_age${NC}"
        else
            ami_age_color="$ami_age"
        fi
        
        printf "%-30s | %-10s | %-10s\n" "$node_name" "$status_color" "$ami_age_color"
        printed=$((printed + 1))
    done
    
    if [ $printed -eq 0 ]; then
        echo -e "${YELLOW}No nodes match the specified filters${NC}"
    fi
}

# Main execution
main() {
    check_requirements
    echo -e "${GREEN}EKS Node Health Audit Script (Using AWS Profile: exam3)${NC}"
    local cluster
    cluster=$(select_cluster)
    local filters
    filters=$(get_filter_options)
    local status_filter ami_age_filter
    IFS='|' read -r status_filter ami_age_filter <<< "$filters"
    
    echo -e "${GREEN}Auditing nodes in cluster: $cluster${NC}"
    echo -e "Status Filter: $status_filter"
    echo -e "AMI Age Filter: ${ami_age_filter:-None}"
    audit_nodes "$status_filter" "$ami_age_filter"
}

# Execute main
main