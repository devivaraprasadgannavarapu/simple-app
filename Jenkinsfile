pipeline {
  agent none

  parameters {
    string(name: 'AWS_REGION', defaultValue: 'us-east-1')
    string(name: 'ECR_REPOSITORY', defaultValue: 'sample-app')
    string(name: 'CONTROL_PLANE_INSTANCE_ID', defaultValue: 'i-04606822174c00b13')
    string(name: 'IMAGE_TAG', defaultValue: '')
  }

  environment {
    AWS_DEFAULT_REGION = "${params.AWS_REGION}"
    SONAR_HOST_URL = 'http://10.0.103.192:9000'
  }

  stages {
    stage('Checkout') {
      agent { label 'sonarqube' }
      steps {
        checkout scm
        sh 'hostname; pwd; ls -la'
      }
    }

    stage('Test') {
      agent { label 'docker-build' }
      steps {
        checkout scm
        sh 'docker run --rm -v "$PWD:/app" -w /app maven:3.9-eclipse-temurin-21 mvn -q test'
      }
    }

    stage('SonarQube') {
      agent { label 'sonarqube' }
      steps {
        checkout scm
        withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
          sh '''
            set -eu
            sonar-scanner \
              -Dsonar.projectKey=sample-app \
              -Dsonar.sources=src \
              -Dsonar.host.url="$SONAR_HOST_URL" \
              -Dsonar.token="$SONAR_TOKEN"
          '''
        }
      }
    }

    stage('Build') {
      agent { label 'docker-build' }
      steps {
        checkout scm
        sh '''
          set -eu
          IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short=12 HEAD)}"
          docker build --tag "sample-app:$IMAGE_TAG" .
        '''
      }
    }

    stage('Scan') {
      agent { label 'docker-build' }
      steps {
        sh '''
          set -eu
          IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short=12 HEAD)}"
          if command -v trivy >/dev/null 2>&1; then
            trivy image \
              --db-repository ghcr.io/aquasecurity/trivy-db:2 \
              --severity HIGH,CRITICAL \
              --exit-code 0 \
              "sample-app:$IMAGE_TAG"
          else
            echo 'Trivy is not installed on the Docker agent; image scan skipped.'
          fi
        '''
      }
    }

    stage('Push to ECR') {
      agent { label 'docker-build' }
      steps {
        sh '''
          set -eu
          REGISTRY="$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
          IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short=12 HEAD)}"
          IMAGE_URI="$REGISTRY/${ECR_REPOSITORY}:$IMAGE_TAG"
          aws ecr get-login-password | docker login --username AWS --password-stdin "$REGISTRY"
          docker tag "sample-app:$IMAGE_TAG" "$IMAGE_URI"
          docker push "$IMAGE_URI"
        '''
      }
    }

    stage('Deploy to kubeadm cluster') {
      agent { label 'docker-build' }
      steps {
        sh '''
          set -eu
          test -n "$CONTROL_PLANE_INSTANCE_ID"
          REGISTRY="$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
          IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short=12 HEAD)}"
          IMAGE_URI="$REGISTRY/${ECR_REPOSITORY}:$IMAGE_TAG"
          ECR_PASSWORD=$(aws ecr get-login-password)
          DEPLOYMENT_B64=$(sed "s|IMAGE_URI|$IMAGE_URI|g" kubernetes/deployment.yaml | base64 -w0)
          NAMESPACE_B64=$(base64 -w0 kubernetes/namespace.yaml)
          REMOTE_SCRIPT=$(printf '%s\n' \
            'set -eu' \
            'export KUBECONFIG=/etc/kubernetes/admin.conf' \
            "AWS_DEFAULT_REGION=\"$AWS_DEFAULT_REGION\"" \
            "REGISTRY=\"$REGISTRY\"" \
            "ECR_PASSWORD=\"$ECR_PASSWORD\"" \
            'mkdir -p /tmp/sample-app' \
            "echo \"$NAMESPACE_B64\" | base64 -d > /tmp/sample-app/namespace.yaml" \
            "echo \"$DEPLOYMENT_B64\" | base64 -d > /tmp/sample-app/deployment.yaml" \
            'kubectl apply -f /tmp/sample-app/namespace.yaml' \
            'kubectl create secret docker-registry ecr-registry --docker-server="$REGISTRY" --docker-username=AWS --docker-password="$ECR_PASSWORD" --namespace sample-app --dry-run=client -o yaml | kubectl apply -f -' \
            'kubectl apply -f /tmp/sample-app/deployment.yaml' \
            'kubectl rollout status deployment/sample-app --namespace sample-app --timeout=180s')
          SCRIPT_B64=$(printf '%s' "$REMOTE_SCRIPT" | base64 -w0)
          COMMAND_ID=$(aws ssm send-command --instance-ids "$CONTROL_PLANE_INSTANCE_ID" --document-name AWS-RunShellScript --parameters "commands=echo $SCRIPT_B64 | base64 -d | bash" --query 'Command.CommandId' --output text)
          aws ssm wait command-executed --command-id "$COMMAND_ID" --instance-id "$CONTROL_PLANE_INSTANCE_ID"
          aws ssm get-command-invocation --command-id "$COMMAND_ID" --instance-id "$CONTROL_PLANE_INSTANCE_ID"
        '''
      }
    }
  }

  post {
    success { echo 'Pipeline completed successfully: test, scan, build, ECR push, and kubeadm deployment.' }
    failure { echo 'Pipeline failed. Check the failed stage in the Jenkins console.' }
    always { echo 'Pipeline execution completed.' }
  }
}
