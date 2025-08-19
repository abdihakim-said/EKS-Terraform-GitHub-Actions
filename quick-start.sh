#!/bin/bash

# =============================================================================
# EKS Quick Start Script
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_warning "kubectl is not installed. You'll need it to manage the cluster."
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Main menu
show_menu() {
    echo ""
    echo "=========================================="
    echo "🚀 EKS Infrastructure Quick Start"
    echo "=========================================="
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "1) 🏗️  Set up backend infrastructure (S3 + DynamoDB)"
    echo "2) 🔐 Set up GitHub OIDC for secure CI/CD"
    echo "3) 🚀 Deploy EKS cluster (dev environment)"
    echo "4) ⚙️  Configure kubectl for cluster access"
    echo "5) 🧪 Deploy sample application"
    echo "6) 🌍 Deploy to staging/production"
    echo "7) 🧹 Destroy infrastructure"
    echo "8) 📋 Show deployment status"
    echo "9) ❓ Help and documentation"
    echo "0) 🚪 Exit"
    echo ""
}

# Set up backend
setup_backend() {
    print_status "Setting up backend infrastructure..."
    if [ -f "./setup-backend.sh" ]; then
        ./setup-backend.sh
    else
        print_error "setup-backend.sh not found. Please ensure you're in the project root directory."
        exit 1
    fi
}

# Set up GitHub OIDC
setup_github_oidc() {
    print_status "Setting up GitHub OIDC..."
    if [ -f "./setup-github-oidc.sh" ]; then
        ./setup-github-oidc.sh
    else
        print_error "setup-github-oidc.sh not found. Please ensure you're in the project root directory."
        exit 1
    fi
}

# Deploy EKS cluster
deploy_eks() {
    print_status "Deploying EKS cluster to dev environment..."
    
    cd eks
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Create and select dev workspace
    print_status "Setting up dev workspace..."
    terraform workspace new dev 2>/dev/null || terraform workspace select dev
    
    # Plan deployment
    print_status "Creating deployment plan..."
    terraform plan -var-file=dev.tfvars
    
    # Confirm deployment
    echo ""
    read -p "Do you want to proceed with the deployment? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        print_status "Deploying infrastructure..."
        terraform apply -var-file=dev.tfvars -auto-approve
        print_success "EKS cluster deployed successfully!"
        
        # Show outputs
        echo ""
        print_status "Deployment outputs:"
        terraform output
    else
        print_status "Deployment cancelled."
    fi
    
    cd ..
}

# Configure kubectl
configure_kubectl() {
    print_status "Configuring kubectl..."
    
    cd eks
    
    # Get cluster name from Terraform output
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
    
    if [ -z "$CLUSTER_NAME" ]; then
        print_error "Could not get cluster name. Make sure the cluster is deployed."
        cd ..
        return 1
    fi
    
    # Update kubeconfig
    print_status "Updating kubeconfig for cluster: $CLUSTER_NAME"
    aws eks --region us-east-1 update-kubeconfig --name "$CLUSTER_NAME"
    
    # Test connection
    print_status "Testing cluster connection..."
    if kubectl get nodes &>/dev/null; then
        print_success "kubectl configured successfully!"
        echo ""
        kubectl get nodes
    else
        print_error "Failed to connect to cluster. Please check your AWS credentials and cluster status."
    fi
    
    cd ..
}

# Deploy sample application
deploy_sample_app() {
    print_status "Deploying sample nginx application..."
    
    # Check if kubectl is configured
    if ! kubectl get nodes &>/dev/null; then
        print_error "kubectl is not configured or cluster is not accessible."
        print_status "Please run option 4 first to configure kubectl."
        return 1
    fi
    
    # Deploy nginx
    print_status "Creating nginx deployment..."
    kubectl create deployment nginx --image=nginx:latest --dry-run=client -o yaml | kubectl apply -f -
    
    # Expose service
    print_status "Exposing nginx service..."
    kubectl expose deployment nginx --port=80 --type=LoadBalancer --dry-run=client -o yaml | kubectl apply -f -
    
    print_success "Sample application deployed!"
    print_status "Checking service status..."
    kubectl get services nginx
    
    echo ""
    print_status "To get the external IP address, run:"
    echo "kubectl get service nginx -w"
}

# Multi-environment deployment
deploy_multi_env() {
    echo ""
    echo "Available environments:"
    echo "1) Staging"
    echo "2) Production"
    echo ""
    read -p "Select environment (1-2): " env_choice
    
    case $env_choice in
        1)
            ENV="staging"
            TFVARS="staging.tfvars"
            ;;
        2)
            ENV="prod"
            TFVARS="prod.tfvars"
            ;;
        *)
            print_error "Invalid choice"
            return 1
            ;;
    esac
    
    print_status "Deploying to $ENV environment..."
    
    cd eks
    
    # Create and select workspace
    terraform workspace new "$ENV" 2>/dev/null || terraform workspace select "$ENV"
    
    # Plan deployment
    terraform plan -var-file="$TFVARS"
    
    # Confirm deployment
    echo ""
    read -p "Do you want to proceed with $ENV deployment? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        terraform apply -var-file="$TFVARS" -auto-approve
        print_success "$ENV environment deployed successfully!"
    else
        print_status "Deployment cancelled."
    fi
    
    cd ..
}

# Destroy infrastructure
destroy_infrastructure() {
    echo ""
    print_warning "This will destroy ALL infrastructure in the selected environment!"
    echo ""
    echo "Available environments:"
    cd eks
    terraform workspace list
    cd ..
    echo ""
    
    read -p "Enter environment to destroy: " env_name
    read -p "Type 'destroy' to confirm: " confirm
    
    if [ "$confirm" = "destroy" ]; then
        cd eks
        terraform workspace select "$env_name"
        
        # Determine tfvars file
        case $env_name in
            dev)
                TFVARS="dev.tfvars"
                ;;
            staging)
                TFVARS="staging.tfvars"
                ;;
            prod)
                TFVARS="prod.tfvars"
                ;;
            *)
                TFVARS="dev.tfvars"
                ;;
        esac
        
        terraform destroy -var-file="$TFVARS" -auto-approve
        print_success "Infrastructure destroyed successfully!"
        cd ..
    else
        print_status "Destruction cancelled."
    fi
}

# Show deployment status
show_status() {
    print_status "Checking deployment status..."
    
    cd eks
    
    # Show workspaces
    echo ""
    print_status "Terraform workspaces:"
    terraform workspace list
    
    # Show current workspace status
    CURRENT_WORKSPACE=$(terraform workspace show)
    print_status "Current workspace: $CURRENT_WORKSPACE"
    
    # Show outputs if available
    if terraform output &>/dev/null; then
        echo ""
        print_status "Current workspace outputs:"
        terraform output
    fi
    
    # Check kubectl connection
    echo ""
    if kubectl get nodes &>/dev/null; then
        print_status "Kubernetes cluster status:"
        kubectl get nodes
        echo ""
        kubectl get pods --all-namespaces | head -10
    else
        print_warning "kubectl not configured or cluster not accessible"
    fi
    
    cd ..
}

# Show help
show_help() {
    echo ""
    echo "📚 Help and Documentation"
    echo "========================="
    echo ""
    echo "📋 Available documentation:"
    echo "  • DEPLOYMENT.md - Complete deployment guide"
    echo "  • setup-github-oidc.md - GitHub OIDC setup guide"
    echo "  • README.md - Project overview and features"
    echo ""
    echo "🔗 Useful commands:"
    echo "  • terraform workspace list - Show all environments"
    echo "  • kubectl get nodes - Show cluster nodes"
    echo "  • kubectl get pods --all-namespaces - Show all pods"
    echo "  • aws eks list-clusters - Show EKS clusters"
    echo ""
    echo "🆘 Troubleshooting:"
    echo "  • Check AWS credentials: aws sts get-caller-identity"
    echo "  • Update kubeconfig: aws eks update-kubeconfig --name CLUSTER_NAME --region us-east-1"
    echo "  • Check cluster status: aws eks describe-cluster --name CLUSTER_NAME --region us-east-1"
    echo ""
}

# Main loop
main() {
    check_prerequisites
    
    while true; do
        show_menu
        read -p "Enter your choice (0-9): " choice
        
        case $choice in
            1)
                setup_backend
                ;;
            2)
                setup_github_oidc
                ;;
            3)
                deploy_eks
                ;;
            4)
                configure_kubectl
                ;;
            5)
                deploy_sample_app
                ;;
            6)
                deploy_multi_env
                ;;
            7)
                destroy_infrastructure
                ;;
            8)
                show_status
                ;;
            9)
                show_help
                ;;
            0)
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please enter 0-9."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main "$@"
