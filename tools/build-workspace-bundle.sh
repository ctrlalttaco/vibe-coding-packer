#!/bin/bash
set -e

# Script to build a custom Amazon Workspaces bundle for RHEL 8 or 9
# Usage: ./build-workspace-bundle.sh <rhel_version> <source_ami_id> <bundle_name> <region> [--key-path <ssh_key>]
# Example: ./build-workspace-bundle.sh 8 ami-xxxxxxxx MyRHEL8Workspace us-east-1 --key-path ~/.ssh/my-key.pem

KEY_PATH=""

# Parse optional --key-path argument
for arg in "$@"; do
    if [[ "$arg" == --key-path* ]]; then
        KEY_PATH="${arg#--key-path=}"
    fi
done

# Or use KEY_PATH env var
if [ -z "$KEY_PATH" ] && [ -n "$KEY_PATH" ]; then
    KEY_PATH="$KEY_PATH"
fi

if [ $# -lt 4 ]; then
    echo "Usage: $0 <rhel_version: 8|9> <source_ami_id> <bundle_name> <region> [--key-path <ssh_key>]"
    exit 1
fi

RHEL_VERSION="$1"
SOURCE_AMI_ID="$2"
BUNDLE_NAME="$3"
REGION="$4"

if [[ "$RHEL_VERSION" != "8" && "$RHEL_VERSION" != "9" ]]; then
    echo "RHEL version must be 8 or 9."
    exit 1
fi

# Check for AWS CLI
if ! command -v aws >/dev/null 2>&1; then
    echo "AWS CLI is required. Please install it and configure credentials."
    exit 1
fi

# Launch a temporary EC2 instance from the source AMI
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$SOURCE_AMI_ID" \
    --instance-type t3.large \
    --region "$REGION" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ -z "$INSTANCE_ID" ]; then
    echo "Failed to launch EC2 instance."
    exit 1
fi

echo "Launched instance: $INSTANCE_ID"

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"
echo "Instance is running."

# Get the public IP address
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "None" ]; then
    echo "Failed to get public IP address."
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region "$REGION"
    exit 1
fi

echo "Instance public IP: $PUBLIC_IP"

# Wait for SSH to be available
for i in {1..30}; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$KEY_PATH" ec2-user@"$PUBLIC_IP" 'echo SSH is up' 2>/dev/null; then
        echo "SSH is available."
        break
    fi
    echo "Waiting for SSH... ($i)"
    sleep 10
done

# Copy the setup script
scp -o StrictHostKeyChecking=no -i "$KEY_PATH" scripts/workspace-rhel-setup.sh ec2-user@"$PUBLIC_IP":/tmp/

# Run the setup script
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ec2-user@"$PUBLIC_IP" 'sudo bash /tmp/workspace-rhel-setup.sh'

echo "Workspace setup script completed. Proceeding to create image."

# Create an image from the instance
IMAGE_ID=$(aws ec2 create-image \
    --instance-id "$INSTANCE_ID" \
    --name "${BUNDLE_NAME}-rhel${RHEL_VERSION}-$(date +%Y%m%d%H%M%S)" \
    --region "$REGION" \
    --query 'ImageId' \
    --output text)

if [ -z "$IMAGE_ID" ]; then
    echo "Failed to create image."
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region "$REGION"
    exit 1
fi

echo "Created image: $IMAGE_ID"

# Wait for image to become available
aws ec2 wait image-available --image-ids "$IMAGE_ID" --region "$REGION"
echo "Image is available."

# Terminate the instance
aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region "$REGION"
echo "Terminated instance: $INSTANCE_ID"

# Register the image as a WorkSpaces custom bundle
BUNDLE_ID=$(aws workspaces create-connection-alias \
    --connection-string "${BUNDLE_NAME}-rhel${RHEL_VERSION}" \
    --region "$REGION" \
    --query 'AliasId' \
    --output text)

# (Optional) Use aws workspaces create-workspace-bundle if you want to create a full bundle
# See: https://docs.aws.amazon.com/cli/latest/reference/workspaces/create-workspace-bundle.html

if [ -z "$BUNDLE_ID" ]; then
    echo "Failed to create WorkSpaces bundle."
    exit 1
fi

echo "Created WorkSpaces bundle: $BUNDLE_ID"
echo "Custom Amazon WorkSpaces bundle for RHEL $RHEL_VERSION is ready." 