# AWS ECS Fargate Deployment with Bitbucket Pipelines

This repository demonstrates an end-to-end **CI/CD pipeline** using **Bitbucket Pipelines** to build, publish, and deploy Docker images on **AWS ECS Fargate** with support for **staging** and **production** environments.

---

## 🚀 Features
- Build and publish Docker images to **Amazon ECR**.
- Automated deployments to **AWS ECS Fargate**.
- Separate pipelines for **staging** and **production**.
- Manual deployment triggers for controlled releases.
- Support for **autoscaling ECS services**.

---

## 📂 Pipeline Workflow
1. **Build & Push Docker Image**
   - Builds Docker image using Bitbucket pipeline.
   - Tags with Bitbucket build number.
   - Pushes image to **Amazon ECR**.

2. **Deploy to Staging**
   - Updates ECS task definition with new image.
   - Deploys to ECS cluster/service for staging.
   - Triggered manually.

3. **Deploy to Production**
   - Updates ECS task definition with production image.
   - Deploys to ECS cluster/service for production.
   - Triggered manually.

---

## ⚙️ Prerequisites
- AWS Account with ECS, ECR, IAM configured.
- ECS Cluster(s) created for staging and production.
- ECR Repository for storing Docker images.
- Bitbucket repository with Pipelines enabled.
- The following **repository variables** set in Bitbucket:
  - `AWS_ECR_IMAGE`
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_DEFAULT_REGION`
  - `NODE_NPM_TOKEN`
  - `NODE_PORT`
  - `ECS_AWS_ACCESS_KEY_ID`
  - `ECS_AWS_SECRET_ACCESS_KEY`
  - `AWS_ECR_PRODUCTION_IMAGE_TAG`

---

## 🛠️ Example Pipeline File (`bitbucket-pipelines.yml`)
```yaml
image:
  name: atlassian/default-image:3

pipelines:
  default:
    - step:
        name: Build and publish docker image.
        services:
          - docker
        script:
          - add-apt-repository universe
          - apt-get update
          - apt install -y python3-pip
          - pip3 install awscli
          - IMAGE="${AWS_ECR_IMAGE}"
          - TAG="${BITBUCKET_BUILD_NUMBER}"
          - aws configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}"
          - aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}"
          - eval $(aws ecr get-login --no-include-email --region "${AWS_DEFAULT_REGION}" | sed 's;https://;;g')
          - docker build -t $IMAGE:$TAG --build-arg NPM_TOKEN="${NODE_NPM_TOKEN}" --build-arg PORT="${NODE_PORT}" .
          - docker push $IMAGE:$TAG

    - step:
        name: Deploy to ECS in Staging Environment
        deployment: staging
        trigger: manual
        script:
          - export IMAGE_NAME="${AWS_ECR_IMAGE}:${BITBUCKET_BUILD_NUMBER}"
          - envsubst < task-definition-template.json > task-definition.json
          - pipe: atlassian/aws-ecs-deploy:1.0.0
            variables:
              AWS_ACCESS_KEY_ID: $ECS_AWS_ACCESS_KEY_ID
              AWS_SECRET_ACCESS_KEY: $ECS_AWS_SECRET_ACCESS_KEY
              AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION
              CLUSTER_NAME: 'staging-cluster'
              SERVICE_NAME: 'staging-service'
              TASK_DEFINITION: 'task-definition.json'

    - step:
        name: Deploy to ECS in Production Environment
        deployment: production
        trigger: manual
        script:
          - export IMAGE_NAME="${AWS_ECR_IMAGE}:${AWS_ECR_PRODUCTION_IMAGE_TAG}"
          - envsubst < task-definition-production-template.json > task-definition.json
          - pipe: atlassian/aws-ecs-deploy:1.0.0
            variables:
              AWS_ACCESS_KEY_ID: $ECS_AWS_ACCESS_KEY_ID
              AWS_SECRET_ACCESS_KEY: $ECS_AWS_SECRET_ACCESS_KEY
              AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION
              CLUSTER_NAME: 'production-cluster'
              SERVICE_NAME: 'production-service'
              TASK_DEFINITION: 'task-definition.json'


```

📊 Deployment Flow

-- flowchart TD
--  A[Bitbucket Commit] --> B[Build & Push Docker Image]
--  B -->|ECR| C[Amazon Elastic Container Registry]
--  C --> D[Staging Deployment Manual Trigger]
--  D -->|Update Task Definition| E[AWS ECS Staging Service]
--  C --> F[Production Deployment Manual Trigger]
--  F -->|Update Task Definition| G[AWS ECS Production Service]

<img width="1193" height="367" alt="image" src="https://github.com/user-attachments/assets/3a9bb13f-d65c-4c5d-bbdf-c1f7c0f4cd1c" />
<img width="1041" height="717" alt="image" src="https://github.com/user-attachments/assets/2bd4d825-2b8d-470c-be12-3e10401cbcb2" />


