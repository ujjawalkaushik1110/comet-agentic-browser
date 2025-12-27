#!/bin/bash
# AWS ECS deployment script for Comet Agentic Browser

set -e

# Configuration
CLUSTER_NAME="comet-browser-cluster"
SERVICE_NAME="comet-browser-service"
REGION="us-east-1"
ECR_REPO="comet-browser"

echo "🚀 Deploying Comet Agentic Browser to AWS ECS"
echo "=============================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install: https://aws.amazon.com/cli/"
    exit 1
fi

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO"

echo "📝 Using AWS Account: $ACCOUNT_ID"
echo "📦 ECR Repository: $ECR_URI"

# Create ECR repository if it doesn't exist
echo "🏗️  Creating ECR repository..."
aws ecr describe-repositories --repository-names $ECR_REPO --region $REGION 2>/dev/null || \
    aws ecr create-repository --repository-name $ECR_REPO --region $REGION

# Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region $REGION | \
    docker login --username AWS --password-stdin $ECR_URI

# Build and push Docker image
echo "🔨 Building Docker image..."
docker build -t $ECR_REPO:latest .
docker tag $ECR_REPO:latest $ECR_URI:latest

echo "📤 Pushing to ECR..."
docker push $ECR_URI:latest

# Create ECS cluster
echo "🏗️  Creating ECS cluster..."
aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $REGION 2>/dev/null || true

# Register task definition
echo "📋 Registering task definition..."
sed "s|YOUR_ECR_REPO|$ECR_URI|g; s|YOUR_ACCOUNT_ID|$ACCOUNT_ID|g; s|REGION|$REGION|g" \
    aws/task-definition.json > /tmp/task-definition.json
aws ecs register-task-definition \
    --cli-input-json file:///tmp/task-definition.json \
    --region $REGION

# Create or update service
echo "🚀 Creating/updating ECS service..."
aws ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --region $REGION \
    --query 'services[0].serviceName' \
    --output text 2>/dev/null | grep -q $SERVICE_NAME && \
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --force-new-deployment \
        --region $REGION || \
    aws ecs create-service \
        --cluster $CLUSTER_NAME \
        --service-name $SERVICE_NAME \
        --task-definition comet-browser \
        --desired-count 1 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
        --region $REGION

echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Configure VPC, subnets, and security groups"
echo "2. Set up Application Load Balancer (optional)"
echo "3. Configure domain and SSL certificate"
echo "4. Store OpenAI API key in AWS Secrets Manager"
