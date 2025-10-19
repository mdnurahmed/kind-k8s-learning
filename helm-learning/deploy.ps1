# Helm Deployment Script for Windows PowerShell
# This script deploys the echo-server Helm chart to kind clusters

# Enable strict mode
$ErrorActionPreference = "Stop"

# Function to print colored output
function Print-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Print-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Print-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

# Function to check if a kind cluster exists
function Test-ClusterExists {
    param([string]$ClusterName)

    $clusters = kind get clusters 2>$null
    return $clusters -contains $ClusterName
}

# Function to check if a namespace exists
function Test-NamespaceExists {
    param([string]$Namespace)

    try {
        kubectl get namespace $Namespace 2>$null | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Function to check if a Helm release exists
function Test-HelmReleaseExists {
    param(
        [string]$ReleaseName,
        [string]$Namespace
    )

    $releases = helm list -n $Namespace -o json | ConvertFrom-Json
    return ($releases | Where-Object { $_.name -eq $ReleaseName }) -ne $null
}

# Function to deploy to an environment
function Deploy-Environment {
    param(
        [string]$Env,
        [string]$ClusterName,
        [string]$ValuesFile,
        [string]$Namespace
    )

    Print-Info "Deploying to $Env environment on cluster $ClusterName..."

    # Check if cluster exists
    if (-not (Test-ClusterExists $ClusterName)) {
        Print-Error "Cluster $ClusterName does not exist!"
        Print-Info "Creating cluster $ClusterName..."
        kind create cluster --name $ClusterName
    }
    else {
        Print-Info "Cluster $ClusterName already exists"
    }

    # Switch context
    Print-Info "Switching to cluster context..."
    kubectl config use-context "kind-$ClusterName"

    # Create namespace if it doesn't exist
    if (-not (Test-NamespaceExists $Namespace)) {
        Print-Info "Creating namespace $Namespace..."
        kubectl create namespace $Namespace
    }
    else {
        Print-Info "Namespace $Namespace already exists"
    }

    # Check if Helm release exists
    $releaseName = "echo-server-$Env"
    if (Test-HelmReleaseExists $releaseName $Namespace) {
        Print-Warning "Release $releaseName already exists. Upgrading..."
        helm upgrade $releaseName . `
            -f $ValuesFile `
            --namespace $Namespace `
            --wait
        Print-Info "Upgrade completed successfully!"
    }
    else {
        Print-Info "Installing new release..."
        helm install $releaseName . `
            -f $ValuesFile `
            --namespace $Namespace `
            --wait
        Print-Info "Installation completed successfully!"
    }

    # Display deployment status
    Print-Info "Deployment status:"
    kubectl get deployments -n $Namespace -l "environment=$Env"
    Write-Host ""
    kubectl get pods -n $Namespace -l "environment=$Env"
    Write-Host ""
    kubectl get services -n $Namespace -l "environment=$Env"
    Write-Host ""
}

# Function to show usage
function Show-Usage {
    Write-Host @"
Usage: .\deploy.ps1 [OPTION]

Deploy echo-server Helm chart to kind clusters

Options:
    dev         Deploy to development environment (kind-nur-dev cluster)
    prd         Deploy to production environment (kind-nur-prd cluster)
    all         Deploy to both dev and prd environments
    status      Show status of all deployments
    clean       Uninstall all releases
    help        Show this help message

Examples:
    .\deploy.ps1 dev              # Deploy to dev only
    .\deploy.ps1 prd              # Deploy to prd only
    .\deploy.ps1 all              # Deploy to both environments
    .\deploy.ps1 status           # Check deployment status
    .\deploy.ps1 clean            # Remove all deployments

"@
}

# Function to show status
function Show-Status {
    Print-Info "Checking deployment status..."
    Write-Host ""

    foreach ($Env in @("dev", "prd")) {
        $ClusterName = "nur-$Env"
        $Namespace = $Env
        $FullClusterName = "kind-$ClusterName"

        if (Test-ClusterExists $ClusterName) {
            Print-Info "=== $($Env.ToUpper()) Environment ($FullClusterName) ==="
            kubectl config use-context $FullClusterName 2>$null

            $releaseName = "echo-server-$Env"
            if (Test-HelmReleaseExists $releaseName $Namespace) {
                helm list -n $Namespace | Select-String $releaseName
                Write-Host ""
                kubectl get pods -n $Namespace -l "environment=$Env"
                Write-Host ""
            }
            else {
                Print-Warning "No Helm release found in $Env"
            }
        }
        else {
            Print-Warning "Cluster $FullClusterName does not exist"
        }
        Write-Host ""
    }
}

# Function to clean up deployments
function Clean-Deployments {
    Print-Warning "Cleaning up all deployments..."

    foreach ($Env in @("dev", "prd")) {
        $ClusterName = "nur-$Env"
        $Namespace = $Env
        $FullClusterName = "kind-$ClusterName"

        if (Test-ClusterExists $ClusterName) {
            Print-Info "Cleaning $Env environment..."
            kubectl config use-context $FullClusterName 2>$null

            $releaseName = "echo-server-$Env"
            if (Test-HelmReleaseExists $releaseName $Namespace) {
                helm uninstall $releaseName -n $Namespace
                Print-Info "$Env release uninstalled"
            }
            else {
                Print-Warning "No release found in $Env"
            }
        }
    }

    Print-Info "Cleanup completed!"
}

# Check prerequisites
function Test-Prerequisites {
    $missing = @()

    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        $missing += "helm"
    }

    if (-not (Get-Command kind -ErrorAction SilentlyContinue)) {
        $missing += "kind"
    }

    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        $missing += "kubectl"
    }

    if ($missing.Count -gt 0) {
        Print-Error "Missing required tools: $($missing -join ', ')"
        Print-Error "Please install the missing tools before running this script."
        exit 1
    }
}

# Main script logic
function Main {
    param([string]$Action)

    # Check prerequisites
    Test-Prerequisites

    # Change to script directory
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    if ($scriptPath) {
        Set-Location $scriptPath
    }

    switch ($Action) {
        "dev" {
            Deploy-Environment -Env "dev" -ClusterName "nur-dev" -ValuesFile "values-dev.yaml" -Namespace "dev"
        }
        "prd" {
            Deploy-Environment -Env "prd" -ClusterName "nur-prd" -ValuesFile "values-prd.yaml" -Namespace "prd"
        }
        "all" {
            Deploy-Environment -Env "dev" -ClusterName "nur-dev" -ValuesFile "values-dev.yaml" -Namespace "dev"
            Write-Host ""
            Print-Info "=========================================="
            Write-Host ""
            Deploy-Environment -Env "prd" -ClusterName "nur-prd" -ValuesFile "values-prd.yaml" -Namespace "prd"
        }
        "status" {
            Show-Status
        }
        "clean" {
            Clean-Deployments
        }
        { $_ -in @("help", "-h", "--help", "") } {
            Show-Usage
        }
        default {
            Print-Error "Unknown option: $Action"
            Write-Host ""
            Show-Usage
            exit 1
        }
    }
}

# Run main function
Main -Action $args[0]
