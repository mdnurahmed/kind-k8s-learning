https://kind.sigs.k8s.io/docs/user/ingress

# Create Cluster
### Create Cluster[](https://kind.sigs.k8s.io/docs/user/ingress#create-cluster)

#### Option 1: LoadBalancer[](https://kind.sigs.k8s.io/docs/user/ingress#option-1-loadbalancer)

Create a kind cluster and run [Cloud Provider KIND](https://kind.sigs.k8s.io/docs/user/loadbalancer/) to enable the loadbalancer controller which ingress-nginx will use through the loadbalancer API.
```
kind create cluster --name nur
```
#### Option 2: extraPortMapping[](https://kind.sigs.k8s.io/docs/user/ingress#option-2-extraportmapping)

Create a single node kind cluster with `extraPortMappings` to allow the local host to make requests to the Ingress controller over ports 80/443.
```
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
```
# Install Ingress Controller
```
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
```
# Metric Server

kubectl apply -f metric-server.yaml

kubectl apply -f echo.yaml
