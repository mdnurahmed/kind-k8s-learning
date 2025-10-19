#!/bin/bash

# Helm Deployment Script for Linux/Mac
# This script deploys the echo-server Helm chart to kind clusters

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if a kind cluster exists
cluster_exists() {
    kind get clusters 2>/dev/null | grep -q "^$1$"
}

# Function to check if kubectl context exists
context_exists() {
    kubectl config get-contexts -o name 2>/dev/null | grep -q "^kind-$1$"
}

# Function to deploy to an environment
deploy_environment() {
    local ENV=$1
    local CLUSTER_NAME=$2
    local VALUES_FILE=$3
    local NAMESPACE=$4

    print_info "Deploying to ${ENV} environment on cluster ${CLUSTER_NAME}..."

    # Check if cluster exists
    if ! cluster_exists "$CLUSTER_NAME"; then
        print_error "Cluster ${CLUSTER_NAME} does not exist!"
        print_info "Creating cluster ${CLUSTER_NAME}..."
        kind create cluster --name "$CLUSTER_NAME"
    else
        print_info "Cluster ${CLUSTER_NAME} already exists"
    fi

    # Switch context
    print_info "Switching to cluster context..."
    kubectl config use-context "kind-${CLUSTER_NAME}"

    # Create namespace if it doesn't exist
    if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
        print_info "Creating namespace ${NAMESPACE}..."
        kubectl create namespace "$NAMESPACE"
    else
        print_info "Namespace ${NAMESPACE} already exists"
    fi

    # Check if Helm release exists
    if helm list -n "$NAMESPACE" | grep -q "echo-server-${ENV}"; then
        print_warning "Release echo-server-${ENV} already exists. Upgrading..."
        helm upgrade "echo-server-${ENV}" . \
            -f "$VALUES_FILE" \
            --namespace "$NAMESPACE" \
            --wait
        print_info "Upgrade completed successfully!"
    else
        print_info "Installing new release..."
        helm install "echo-server-${ENV}" . \
            -f "$VALUES_FILE" \
            --namespace "$NAMESPACE" \
            --wait
        print_info "Installation completed successfully!"
    fi

    # Display deployment status
    print_info "Deployment status:"
    kubectl get deployments -n "$NAMESPACE" -l "environment=${ENV}"
    echo ""
    kubectl get pods -n "$NAMESPACE" -l "environment=${ENV}"
    echo ""
    kubectl get services -n "$NAMESPACE" -l "environment=${ENV}"
    echo ""
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTION]

Deploy echo-server Helm chart to kind clusters

Options:
    dev         Deploy to development environment (kind-nur-dev cluster)
    prd         Deploy to production environment (kind-nur-prd cluster)
    all         Deploy to both dev and prd environments
    status      Show status of all deployments
    clean       Uninstall all releases
    help        Show this help message

Examples:
    $0 dev              # Deploy to dev only
    $0 prd              # Deploy to prd only
    $0 all              # Deploy to both environments
    $0 status           # Check deployment status
    $0 clean            # Remove all deployments

EOF
}

# Function to show status
show_status() {
    print_info "Checking deployment status..."
    echo ""

    for ENV in dev prd; do
        CLUSTER="kind-nur-${ENV}"
        NAMESPACE="${ENV}"

        if cluster_exists "nur-${ENV}"; then
            print_info "=== ${ENV^^} Environment (${CLUSTER}) ==="
            kubectl config use-context "${CLUSTER}" 2>/dev/null

            if helm list -n "$NAMESPACE" | grep -q "echo-server-${ENV}"; then
                helm list -n "$NAMESPACE" | grep "echo-server-${ENV}"
                echo ""
                kubectl get pods -n "$NAMESPACE" -l "environment=${ENV}"
                echo ""
            else
                print_warning "No Helm release found in ${ENV}"
            fi
        else
            print_warning "Cluster ${CLUSTER} does not exist"
        fi
        echo ""
    done
}

# Function to clean up deployments
clean_deployments() {
    print_warning "Cleaning up all deployments..."

    for ENV in dev prd; do
        CLUSTER="kind-nur-${ENV}"
        NAMESPACE="${ENV}"

        if cluster_exists "nur-${ENV}"; then
            print_info "Cleaning ${ENV} environment..."
            kubectl config use-context "${CLUSTER}" 2>/dev/null

            if helm list -n "$NAMESPACE" | grep -q "echo-server-${ENV}"; then
                helm uninstall "echo-server-${ENV}" -n "$NAMESPACE"
                print_info "${ENV} release uninstalled"
            else
                print_warning "No release found in ${ENV}"
            fi
        fi
    done

    print_info "Cleanup completed!"
}

# Main script logic
main() {
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install Helm first."
        exit 1
    fi

    # Check if kind is installed
    if ! command -v kind &> /dev/null; then
        print_error "kind is not installed. Please install kind first."
        exit 1
    fi

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi

    case "${1:-help}" in
        dev)
            deploy_environment "dev" "nur-dev" "values-dev.yaml" "dev"
            ;;
        prd)
            deploy_environment "prd" "nur-prd" "values-prd.yaml" "prd"
            ;;
        all)
            deploy_environment "dev" "nur-dev" "values-dev.yaml" "dev"
            echo ""
            print_info "=========================================="
            echo ""
            deploy_environment "prd" "nur-prd" "values-prd.yaml" "prd"
            ;;
        status)
            show_status
            ;;
        clean)
            clean_deployments
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
