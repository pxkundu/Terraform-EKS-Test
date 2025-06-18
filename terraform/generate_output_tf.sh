#!/bin/bash

# Define the output.tf file path
OUTPUT_FILE="$PROJECT_DIR/outputs.tf"

# Create or overwrite outputs.tf with the required content
cat << 'EOF' > "$OUTPUT_FILE"
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "kubeconfig" {
  description = "Kubeconfig file for cluster access"
  value       = module.eks.kubeconfig
  sensitive   = true
}
EOF

# Verify the file was created
if [ -f "$OUTPUT_FILE" ]; then
  echo "outputs.tf has been successfully created at $OUTPUT_FILE"
  cat "$OUTPUT_FILE"
else
  echo "Error: Failed to create outputs.tf"
  exit 1
fi

# Set appropriate permissions
chmod 644 "$OUTPUT_FILE"

echo "Script completed successfully!"