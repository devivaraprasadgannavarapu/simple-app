pipeline {
  agent any

  parameters {
    string(name: 'AWS_REGION', defaultValue: 'us-east-1')
    string(name: 'ECR_REPOSITORY', defaultValue: 'sample-app')
    string(name: 'CONTROL_PLANE_INSTANCE_ID', defaultValue: '')
    string(name: 'IMAGE_TAG', defaultValue: '')
  }

  environment {
    AWS_DEFAULT_REGION = "${params.AWS_REGION}"
    REGISTRY = ""
    IMAGE_URI = ""
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
        withAWS(credentials: 'aws-jenkins', region: "${params.AWS_REGION}") {
          script {
            env.REGISTRY = sh(
              script: "aws sts get-caller-identity --query Account --output text",
              returnStdout: true
            ).trim() + ".dkr.ecr.${params.AWS_REGION}.amazonaws.com"
            env.IMAGE_URI = "${env.REGISTRY}/${params.ECR_REPOSITORY}:${params.IMAGE_TAG}"
          }
          sh 'aws ecr get-login-password | docker login --username AWS --password-stdin "$REGISTRY"'
          sh 'docker build --tag "$IMAGE_URI" .'
          sh 'docker push "$IMAGE_URI"'
        }
      }
    }

    stage('Deploy to kubeadm cluster') {
      steps {
        withAWS(credentials: 'aws-jenkins', region: "${params.AWS_REGION}") {
          sh '''
            set -eu
            test -n "$CONTROL_PLANE_INSTANCE_ID"
            DEPLOYMENT_B64=$(sed "s|IMAGE_URI|$IMAGE_URI|g" kubernetes/deployment.yaml | base64 -w0)
            NAMESPACE_B64=$(base64 -w0 kubernetes/namespace.yaml)
            REMOTE_SCRIPT=$(cat <<EOF
            set -eu
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
  }

  post {
    always { sh 'docker image prune --force || true' }
  }
}
