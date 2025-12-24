#!/bin/bash
# Day 29: AWS CLI Automation
# This script automates basic AWS tasks using AWS CLI:
# 1. Lists all EC2 instances
# 2. Shows stopped instances
# 3. Offers to start/stop instances
# 4. Creates S3 backup of important files
# 5. Shows simplified AWS cost info

set -e

# -----------------------------
# Prerequisites check
# -----------------------------
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: AWS CLI not configured. Run 'aws configure'."
    exit 1
fi

REGION=$(aws configure get region)
S3_BUCKET="day29-backup-$(date +%Y%m%d)"
BACKUP_DIR="$HOME/important_files"

echo "Using AWS region: ${REGION:-default}"

# -----------------------------
# 1. List all EC2 instances
# -----------------------------
echo
echo "All EC2 Instances:"
aws ec2 describe-instances \
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType}" \
  --output table

# -----------------------------
# 2. Show stopped instances
# -----------------------------
echo
echo "Stopped EC2 Instances:"
aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=stopped \
  --query "Reservations[].Instances[].InstanceId" \
  --output table

# -----------------------------
# 3. Offer to start/stop instance
# -----------------------------
echo
read -p "Do you want to start or stop an instance? (start/stop/skip): " ACTION

if [[ "$ACTION" == "start" || "$ACTION" == "stop" ]]; then
    read -p "Enter Instance ID: " INSTANCE_ID
    aws ec2 ${ACTION}-instances --instance-ids "$INSTANCE_ID"
    echo "Instance $INSTANCE_ID ${ACTION} command sent."
else
    echo "Skipping instance management."
fi

# -----------------------------
# 4. Create S3 backup
# -----------------------------
echo
echo "Creating S3 backup..."

if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "Backup directory '$BACKUP_DIR' not found. Creating sample directory."
    mkdir -p "$BACKUP_DIR"
    echo "Sample backup file" > "$BACKUP_DIR/sample.txt"
fi

aws s3 mb "s3://$S3_BUCKET" &> /dev/null || true
aws s3 sync "$BACKUP_DIR" "s3://$S3_BUCKET"

echo "Backup completed to bucket: $S3_BUCKET"

# -----------------------------
# 5. Show simplified AWS cost info
# -----------------------------
echo
echo "AWS Cost Summary (Last 30 Days):"
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '30 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --query "ResultsByTime[].Total.BlendedCost.Amount" \
  --output text | awk '{print "Estimated cost: $" $1}'

echo
echo "Day 29 AWS automation completed successfully."
