#!/bin/bash
#
# DESCRIPTION: ECS Deployment Script

ACCOUNT='<aws_account_number>'
ECS_REGION='<region>'
ECS_CLUSTER_NAME='<cluster_name>'
ECS_SERVICE_NAME='<service_name>'
ECS_TASK_DEFINITION_NAME='<task_definition_name>'
ECR_NAME='<ecr_name>'
ECR_URI='<ecr_uri>'
TASK_ROLE='<task_role>'
EXECUTION_ROLE='<execution_role>'
CPU='<task_cpu>'  # e.g. 256 Unit
MEMORY='<task_memory>' # e.g. 1024 MiB
CONTAINER_NAME='<container_name>'
HARD_SOFT_MEMORY='<hard_or_soft_memory>'
PORT='<port>'

VERSION=$(date +%s)

ENVIRONMENT='dev'
REVISION=%build.number%
IMAGE='$ECR_URI/$ECR_NAME:$ENVIRONMENT'
NEW_IMAGE="$IMAGE-$REVISION" 

TASK_ID=`aws ecs list-tasks --cluster $ECS_CLUSTER_NAME --desired-status RUNNING --family $ECS_TASK_DEFINITION_NAME | egrep "task" | tr "/" " " | tr "[" " " |  awk '{print $3}' | sed 's/"$//'`
echo $TASK_ID

aws ecs register-task-definition \
    --family $ECS_TASK_DEFINITION_NAME \
    --task-role-arn "arn:aws:iam::$ACCOUNT:role/$TASK_ROLE" \
    --execution-role-arn "arn:aws:iam::$ACCOUNT:role/$EXECUTION_ROLE" \
    --network-mode awsvpc \
    --cpu $CPU \
    --memory $MEMORY \
    --requires-compatibilities FARGATE \
    --container-definitions "[
        {
            \"name\":\"${CONTAINER_NAME}\", 
            \"image\":\"${NEW_IMAGE}\",
            \"memory\":\"${HARD_SOFT_MEMORY}\",
            \"essential\":true,
            \"portMappings\":[
                {
                    \"protocol\":\"tcp\",
                    \"containerPort\":\"${PORT}\",
                    \"hostPort\":\"${PORT}\"
                }
            ],
            \"logConfiguration\":
            {
                \"logDriver\":\"awslogs\",
                \"options\":
                {
                    \"awslogs-region\":\"${ECS_REGION}\",
                    \"awslogs-stream-prefix\":\"ecs\",
                    \"awslogs-group\":\"/ecs/${ECS_TASK_DEFINITION_NAME}\"
                } 
            }
        }
    ]"

sleep 5
aws ecs update-service --region $ECS_REGION --cluster $ECS_CLUSTER_NAME --service $ECS_SERVICE_NAME  --task-definition $ECS_TASK_DEFINITION_NAME --force-new-deployment

sleep 120
aws ecs stop-task --cluster $ECS_CLUSTER_NAME --task $TASK_ID
