pipeline {
  agent any

  parameters {
    string(name: 'AWS_REGION', defaultValue: 'us-east-1')
    string(name: 'ECR_REPOSITORY', defaultValue: 'sample-app')
    string(name: 'CONTROL_PLANE_INSTANCE_ID', defaultValue: 'i-04606822174c00b13')
    string(name: 'IMAGE_TAG', defaultValue: '')
  }

  environment {
    AWS_DEFAULT_REGION = "${params.AWS_REGION}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Set image tag') {
      steps {
        script {
          env.IMAGE_TAG = params.IMAGE_TAG?.trim() ?: sh(
            script: 'git rev-parse --short=12 HEAD',
            returnStdout: true
          ).trim()
        }
      }
    }

    stage('Build and push image') {
      steps {
        sh '''
          set -eu
          REGISTRY="$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
          IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short=12 HEAD)}"
          IMAGE_URI="$REGISTRY/${ECR_REPOSITORY}:$IMAGE_TAG"
          aws ecr get-login-password | docker login --username AWS --password-stdin "$REGISTRY"
          docker build --tag "$IMAGE_URI" .
          docker push "$IMAGE_URI"
        '''
      }
    }

    stage('Deploy to kubeadm cluster') {
      steps {
        sh '''
          set -eu
          test -n "$CONTROL_PLANE_INSTANCE_ID"
          REGISTRY="$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
          IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short=12 HEAD)}"
          IMAGE_URI="$REGISTRY/${ECR_REPOSITORY}:$IMAGE_TAG"
          DEPLOYMENT_B64=$(sed "s|IMAGE_URI|$IMAGE_URI|g" kubernetes/deployment.yaml | base64 -w0)
          NAMESPACE_B64=$(base64 -w0 kubernetes/namespace.yaml)
          REMOTE_SCRIPT=$(cat <<EOF
          set -eu
          REGISTRY="$REGISTRY"
          mkdir -p /tmp/sample-app
          echo "$NAMESPACE_B64" | base64 -d > /tmp/sample-app/namespace.yaml
          echo "$DEPLOYMENT_B64" | base64 -d > /tmp/sample-app/deployment.yaml
          kubectl apply -f /tmp/sample-app/namespace.yaml
          ECR_PASSWORD=\$(aws ecr get-login-password --region "\$AWS_DEFAULT_REGION")
          kubectl create secret docker-registry ecr-registry --docker-server="\$REGISTRY" --docker-username=AWS --docker-password="\$ECR_PASSWORD" --namespace sample-app --dry-run=client -o yaml | kubectl apply -f -
          kubectl apply -f /tmp/sample-app/deployment.yaml
          kubectl rollout status deployment/sample-app --namespace sample-app --timeout=180s
          EOF
          )
          SCRIPT_B64=$(printf '%s' "$REMOTE_SCRIPT" | base64 -w0)
          COMMAND_ID=$(aws ssm send-command --instance-ids "$CONTROL_PLANE_INSTANCE_ID" --document-name AWS-RunShellScript --parameters "commands=echo $SCRIPT_B64 | base64 -d | bash" --query 'Command.CommandId' --output text)
          aws ssm wait command-executed --command-id "$COMMAND_ID" --instance-id "$CONTROL_PLANE_INSTANCE_ID"
          aws ssm get-command-invocation --command-id "$COMMAND_ID" --instance-id "$CONTROL_PLANE_INSTANCE_ID"
        '''
      }
    }
  }

  post {
    always { sh 'docker image prune --force || true' }
  }
}
