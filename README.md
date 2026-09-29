# Sample Application

This application shows where a request is running inside a three-node Kubernetes cluster. It displays the current pod name, namespace, pod IP, node name, and node IP.

## Public access

The application is exposed through a Kubernetes `LoadBalancer` service. After deployment, get the public address with:

```bash
kubectl get service sample-app --namespace sample-app
```

Open the value shown under `EXTERNAL-IP` or `HOSTNAME` in a browser. The address is assigned by the cloud load-balancer integration and may take a few minutes to appear.

The health endpoint is:

```text
http://PUBLIC_ADDRESS/health
```

## Cluster access from a workstation

The Kubernetes API is private. Use the included PowerShell helper to open an SSH tunnel and configure `kubectl`:

```powershell
. .\connect-kubectl.ps1
```

Keep that PowerShell session open while using `kubectl`. The helper connects to the control plane through SSH and forwards local port `6443` to the private cluster API.

## Architecture

```text
User browser
    |
    v
Public load balancer
    |
    v
Kubernetes Service: sample-app:80
    |
    +--> Pod replica 1: Node.js server on port 8080
    |
    +--> Pod replica 2: Node.js server on port 8080
```

The service selects pods using the label `app: sample-app`. Kubernetes distributes requests between the two replicas. Each pod gets its own IP and runs on one of the worker nodes. Refreshing the page can show a different pod or node.

## Runtime information

The page reads these values from environment variables supplied by Kubernetes:

- Pod name and namespace identify the running application instance.
- Pod IP identifies the network address of that pod.
- Node name and node IP identify the machine hosting the pod.
- The service hides pod changes behind one stable public endpoint.

## Delivery flow

1. Jenkins checks out the application source.
2. Jenkins builds the Node.js container image.
3. Jenkins pushes the image to the private container registry.
4. Jenkins connects to the cluster control plane and applies the namespace and application manifests.
5. Kubernetes downloads the image, starts two replicas, and exposes them through the public load balancer.

## Files

- `server.js`: HTTP server, health endpoint, and runtime information page.
- `Dockerfile`: small production container image.
- `kubernetes/deployment.yaml`: two replicas, runtime metadata, health check, and public service.
- `kubernetes/namespace.yaml`: application namespace.
- `Jenkinsfile`: build, registry push, and cluster deployment pipeline.
