# Helm Templating Learning Guide

This Helm chart demonstrates templating concepts using an echo server with environment-specific configurations.

## Chart Structure

```
helm-learning/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Base/default values
├── values-dev.yaml         # Development environment overrides
├── values-prd.yaml         # Production environment overrides
├── deploy.sh               # Deployment script for Linux/Mac
├── deploy.ps1              # Deployment script for Windows PowerShell
├── README.md               # This file
└── templates/
    ├── deployment.yaml     # Deployment template
    ├── service.yaml        # Service template
    ├── hpa.yaml           # HorizontalPodAutoscaler template
    └── ingress.yaml       # Ingress template
```

## Key Templating Concepts

### 1. Environment Suffixes
- **Dev environment**: Resources are suffixed with `-dev`
- **Prd environment**: Resources are suffixed with `-prd`

### 2. Replica Differences
- **Dev**: 1 replica (for cost savings)
- **Prd**: 2 replicas (for high availability)

### 3. Template Variables
The templates use Helm's Go templating syntax:
- `{{ .Values.name }}` - The application name
- `{{ .Values.environment }}` - The environment (dev/prd)
- `{{ .Values.replicaCount }}` - Number of replicas
- And more...

## Quick Start with Deployment Scripts

The easiest way to deploy to kind clusters is using the provided deployment scripts.

### Linux/Mac - Using deploy.sh

```bash
# Make the script executable (if not already)
chmod +x deploy.sh

# Deploy to dev environment (kind-nur-dev cluster)
./deploy.sh dev

# Deploy to prd environment (kind-nur-prd cluster)
./deploy.sh prd

# Deploy to both environments
./deploy.sh all

# Check deployment status
./deploy.sh status

# Clean up all deployments
./deploy.sh clean

# Show help
./deploy.sh help
```

### Windows - Using deploy.ps1

```powershell
# Deploy to dev environment (kind-nur-dev cluster)
.\deploy.ps1 dev

# Deploy to prd environment (kind-nur-prd cluster)
.\deploy.ps1 prd

# Deploy to both environments
.\deploy.ps1 all

# Check deployment status
.\deploy.ps1 status

# Clean up all deployments
.\deploy.ps1 clean

# Show help
.\deploy.ps1 help
```

### What the Scripts Do

Both scripts automatically:
1. Check if required tools (helm, kind, kubectl) are installed
2. Create kind clusters if they don't exist:
   - `kind-nur-dev` for development
   - `kind-nur-prd` for production
3. Switch to the appropriate kubectl context
4. Create namespaces (`dev` and `prd`)
5. Install or upgrade the Helm release
6. Display deployment status

### Target Clusters

- **Dev environment**: Deployed to `kind-nur-dev` cluster in `dev` namespace
- **Prd environment**: Deployed to `kind-nur-prd` cluster in `prd` namespace

## Helm Commands

### 1. View Generated YAML for Development Environment

```bash
helm template echo-server ./helm-learning -f ./helm-learning/values-dev.yaml
```

This command shows the rendered YAML for dev environment without installing.

### 2. View Generated YAML for Production Environment

```bash
helm template echo-server ./helm-learning -f ./helm-learning/values-prd.yaml
```

This command shows the rendered YAML for production environment.

### 3. View Specific Template

To see just the deployment template for dev:

```bash
helm template echo-server ./helm-learning -f ./helm-learning/values-dev.yaml -s templates/deployment.yaml
```

### 4. Dry Run Installation (Shows What Would Be Created)

For dev environment:
```bash
helm install echo-server-dev ./helm-learning -f ./helm-learning/values-dev.yaml --dry-run --debug
```

For production environment:
```bash
helm install echo-server-prd ./helm-learning -f ./helm-learning/values-prd.yaml --dry-run --debug
```

### 5. Using Helm Diff Plugin

First, install the helm diff plugin if you haven't already:
```bash
helm plugin install https://github.com/databus23/helm-diff
```

#### Compare Dev vs Base Values
```bash
helm diff upgrade echo-server-dev ./helm-learning -f ./helm-learning/values-dev.yaml
```

#### Compare Prd vs Base Values
```bash
helm diff upgrade echo-server-prd ./helm-learning -f ./helm-learning/values-prd.yaml
```

#### Compare Dev vs Prd Directly
First generate both manifests, then use standard diff:
```bash
helm template echo-server ./helm-learning -f ./helm-learning/values-dev.yaml > /tmp/dev-manifest.yaml
helm template echo-server ./helm-learning -f ./helm-learning/values-prd.yaml > /tmp/prd-manifest.yaml
diff /tmp/dev-manifest.yaml /tmp/prd-manifest.yaml
```

Or use a better diff tool like `colordiff` or `git diff`:
```bash
git diff --no-index /tmp/dev-manifest.yaml /tmp/prd-manifest.yaml
```

### 6. Actual Installation (When Ready)

For dev environment:
```bash
helm install echo-server-dev ./helm-learning -f ./helm-learning/values-dev.yaml --namespace dev --create-namespace
```

For production environment:
```bash
helm install echo-server-prd ./helm-learning -f ./helm-learning/values-prd.yaml --namespace prd --create-namespace
```

### 7. Upgrade Existing Release

For dev:
```bash
helm upgrade echo-server-dev ./helm-learning -f ./helm-learning/values-dev.yaml --namespace dev
```

For production:
```bash
helm upgrade echo-server-prd ./helm-learning -f ./helm-learning/values-prd.yaml --namespace prd
```

### 8. Uninstall

```bash
helm uninstall echo-server-dev --namespace dev
helm uninstall echo-server-prd --namespace prd
```

## Key Differences Between Environments

| Aspect | Dev | Prd |
|--------|-----|-----|
| Resource Suffix | `-dev` | `-prd` |
| Replicas | 1 | 2 |
| CPU Request | 100m | 200m |
| Memory Request | 100Mi | 200Mi |
| CPU Limit | 100m | 500m |
| Memory Limit | 100Mi | 500Mi |
| HPA Min Replicas | 1 | 2 |
| HPA Max Replicas | 3 | 10 |
| Ingress Host | echo-dev.local | echo-prd.local |

## Learning Exercises

1. **View the templates**: Check the generated YAML for both environments
2. **Compare outputs**: Use the diff commands to see exactly what changes between environments
3. **Modify values**: Try changing values in the values files and see how it affects the output
4. **Add new resources**: Try adding a ConfigMap or Secret template
5. **Use conditionals**: Add `{{ if }}` statements to conditionally include resources

## Useful Tips

- Always use `helm template` or `--dry-run` before actual deployment
- Use `-f` flag to specify values files (you can use multiple `-f` flags)
- Use `--debug` flag to see more detailed information
- Use `helm lint ./helm-learning` to validate your chart structure
- Use `helm get values <release-name>` to see what values are currently deployed

## Next Steps

- Learn about Helm hooks
- Explore helper templates in `_helpers.tpl`
- Study chart dependencies
- Understand Helm lifecycle management
