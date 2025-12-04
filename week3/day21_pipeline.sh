#!/bin/bash
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
REPO_URL=""
BRANCH="main"
BUILD_DIR="/tmp/cicd_build_$(date +%s)"
DEPLOY_DIR="/var/www/app"
LOG_FILE="$HOME/cicd_pipeline.log"

# Pipeline stages
STAGE_CLONE=false
STAGE_LINT=false
STAGE_TEST=false
STAGE_BUILD=false
STAGE_DEPLOY=false
STAGE_NOTIFY=false

# Statistics
START_TIME=$(date +%s)
FAILED_STAGE=""
TOTAL_STAGES=6
COMPLETED_STAGES=0

# Function to print header
print_header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              CI/CD PIPELINE SIMULATOR                         ║${NC}"
    echo -e "${CYAN}║         Continuous Integration & Deployment                   ║${NC}"
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}Started: $(date '+%Y-%m-%d %H:%M:%S')${NC}\n"
}

# Function to log messages
log_message() {
    local level=$1
    local message=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to show stage header
stage_header() {
    local stage_num=$1
    local stage_name=$2
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}${BOLD}Stage $stage_num/$TOTAL_STAGES: $stage_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to show progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    echo -ne "\r${CYAN}Progress: ["
    printf '%*s' $filled | tr ' ' '█'
    printf '%*s' $empty | tr ' ' '░'
    echo -ne "] ${percentage}%${NC}"
}

# Function to simulate work with progress
simulate_work() {
    local duration=$1
    local steps=20
    local sleep_time=$(echo "scale=2; $duration / $steps" | bc)
    
    for i in $(seq 1 $steps); do
        show_progress $i $steps
        sleep $sleep_time
    done
    echo ""
}

# Stage 1: Clone Repository
stage_clone() {
    stage_header 1 "Clone Repository"
    
    echo -e "${CYAN}Repository:${NC} $REPO_URL"
    echo -e "${CYAN}Branch:${NC} $BRANCH"
    echo -e "${CYAN}Build Directory:${NC} $BUILD_DIR"
    echo ""
    
    log_message "INFO" "Starting repository clone stage"
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo -e "${RED}✗ Git is not installed!${NC}"
        log_message "ERROR" "Git not found"
        return 1
    fi
    
    echo -e "${YELLOW}Cloning repository...${NC}"
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    
    # If no repo URL provided, create a sample project
    if [ -z "$REPO_URL" ]; then
        echo -e "${YELLOW}No repository URL provided. Creating sample project...${NC}"
        
        # Create sample project structure
        mkdir -p "$BUILD_DIR"/{src,test,dist}
        
        # Create sample files
        cat > "$BUILD_DIR/package.json" << 'EOF'
{
  "name": "sample-app",
  "version": "1.0.0",
  "scripts": {
    "test": "echo 'Running tests...' && exit 0",
    "build": "echo 'Building application...' && exit 0"
  }
}
EOF
        
        cat > "$BUILD_DIR/src/index.js" << 'EOF'
// Sample Application
console.log('Hello from CI/CD Pipeline!');

function add(a, b) {
    return a + b;
}

module.exports = { add };
EOF
        
        cat > "$BUILD_DIR/test/test.js" << 'EOF'
// Sample Test
const { add } = require('../src/index.js');

console.log('Test 1: add(2, 3) should equal 5');
if (add(2, 3) === 5) {
    console.log('✓ PASS');
    process.exit(0);
} else {
    console.log('✗ FAIL');
    process.exit(1);
}
EOF
        
        simulate_work 2
        echo -e "${GREEN}✓ Sample project created${NC}"
    else
        # Clone actual repository
        if git clone -b "$BRANCH" "$REPO_URL" "$BUILD_DIR" &>/dev/null; then
            simulate_work 3
            echo -e "${GREEN}✓ Repository cloned successfully${NC}"
        else
            echo -e "${RED}✗ Failed to clone repository${NC}"
            log_message "ERROR" "Git clone failed"
            return 1
        fi
    fi
    
    # Show project info
    echo ""
    echo -e "${CYAN}Project Structure:${NC}"
    tree -L 2 "$BUILD_DIR" 2>/dev/null || ls -la "$BUILD_DIR"
    
    log_message "INFO" "Repository clone completed"
    STAGE_CLONE=true
    ((COMPLETED_STAGES++))
    return 0
}

# Stage 2: Lint Code
stage_lint() {
    stage_header 2 "Code Linting"
    
    log_message "INFO" "Starting linting stage"
    
    echo -e "${YELLOW}Running code quality checks...${NC}"
    echo ""
    
    # Simulate linting checks
    local checks=("Syntax check" "Style check" "Import check" "Unused variables" "Code complexity")
    
    for check in "${checks[@]}"; do
        echo -ne "${CYAN}• $check...${NC} "
        sleep 0.5
        
        # Random success (90% pass rate)
        if [ $((RANDOM % 10)) -ne 0 ]; then
            echo -e "${GREEN}✓ PASS${NC}"
        else
            echo -e "${YELLOW}⚠ WARNING${NC}"
        fi
    done
    
    echo ""
    simulate_work 2
    
    echo -e "${GREEN}✓ Linting completed - No critical issues found${NC}"
    echo -e "${CYAN}Code Quality Score: ${GREEN}8.5/10${NC}"
    
    log_message "INFO" "Linting stage completed"
    STAGE_LINT=true
    ((COMPLETED_STAGES++))
    return 0
}

# Stage 3: Run Tests
stage_test() {
    stage_header 3 "Run Tests"
    
    log_message "INFO" "Starting test stage"
    
    echo -e "${YELLOW}Running test suite...${NC}"
    echo ""
    
    # Check if package.json exists
    if [ -f "$BUILD_DIR/package.json" ]; then
        echo -e "${CYAN}Running unit tests...${NC}"
        
        cd "$BUILD_DIR"
        
        # Simulate test execution
        local test_suites=("Unit Tests" "Integration Tests" "API Tests" "UI Tests")
        local passed=0
        local total=${#test_suites[@]}
        
        for suite in "${test_suites[@]}"; do
            echo -ne "${CYAN}• $suite...${NC} "
            sleep 1
            
            # Simulate tests (95% pass rate)
            if [ $((RANDOM % 20)) -ne 0 ]; then
                echo -e "${GREEN}✓ PASS${NC}"
                ((passed++))
            else
                echo -e "${RED}✗ FAIL${NC}"
            fi
        done
        
        echo ""
        echo -e "${CYAN}Test Results:${NC}"
        echo -e "  Total Suites: $total"
        echo -e "  Passed: ${GREEN}$passed${NC}"
        echo -e "  Failed: ${RED}$((total - passed))${NC}"
        echo -e "  Success Rate: ${GREEN}$((passed * 100 / total))%${NC}"
        
        if [ $passed -eq $total ]; then
            echo ""
            echo -e "${GREEN}✓ All tests passed!${NC}"
            log_message "INFO" "All tests passed"
            STAGE_TEST=true
            ((COMPLETED_STAGES++))
            return 0
        else
            echo ""
            echo -e "${RED}✗ Some tests failed${NC}"
            log_message "ERROR" "Tests failed"
            return 1
        fi
    else
        echo -e "${YELLOW}No test configuration found, skipping...${NC}"
        simulate_work 2
        echo -e "${GREEN}✓ Test stage completed${NC}"
        STAGE_TEST=true
        ((COMPLETED_STAGES++))
        return 0
    fi
}

# Stage 4: Build Application
stage_build() {
    stage_header 4 "Build Application"
    
    log_message "INFO" "Starting build stage"
    
    echo -e "${YELLOW}Building application...${NC}"
    echo ""
    
    cd "$BUILD_DIR"
    
    # Simulate build process
    local build_steps=(
        "Installing dependencies..."
        "Compiling source code..."
        "Optimizing assets..."
        "Generating bundles..."
        "Creating artifacts..."
    )
    
    for step in "${build_steps[@]}"; do
        echo -ne "${CYAN}$step${NC} "
        simulate_work 1
        echo -e "${GREEN}✓${NC}"
    done
    
    # Create build artifacts
    mkdir -p "$BUILD_DIR/dist"
    
    if [ -f "$BUILD_DIR/src/index.js" ]; then
        cat > "$BUILD_DIR/dist/app.min.js" << 'EOF'
// Built Application (Minified)
console.log("Production Build v1.0.0");!function(){console.log("App initialized")}();
EOF
    fi
    
    # Create build info
    cat > "$BUILD_DIR/dist/build-info.txt" << EOF
Build Information
==================
Build Time: $(date)
Build Number: $RANDOM
Git Commit: $(git rev-parse --short HEAD 2>/dev/null || echo "N/A")
Branch: $BRANCH
Status: Success
EOF
    
    echo ""
    echo -e "${CYAN}Build Artifacts:${NC}"
    ls -lh "$BUILD_DIR/dist/" 2>/dev/null || echo "  No artifacts"
    
    echo ""
    echo -e "${GREEN}✓ Build completed successfully${NC}"
    echo -e "${CYAN}Artifacts created in:${NC} $BUILD_DIR/dist/"
    
    log_message "INFO" "Build stage completed"
    STAGE_BUILD=true
    ((COMPLETED_STAGES++))
    return 0
}

# Stage 5: Deploy Application
stage_deploy() {
    stage_header 5 "Deploy to Staging"
    
    log_message "INFO" "Starting deployment stage"
    
    echo -e "${YELLOW}Deploying application to staging environment...${NC}"
    echo ""
    
    # Simulate deployment steps
    local deploy_steps=(
        "Connecting to staging server..."
        "Backing up current version..."
        "Uploading new artifacts..."
        "Updating configuration..."
        "Restarting services..."
        "Running smoke tests..."
    )
    
    for step in "${deploy_steps[@]}"; do
        echo -ne "${CYAN}$step${NC} "
        simulate_work 1
        echo -e "${GREEN}✓${NC}"
    done
    
    # Simulate deployment
    local deploy_target="$HOME/cicd_staging"
    mkdir -p "$deploy_target"
    
    if [ -d "$BUILD_DIR/dist" ]; then
        cp -r "$BUILD_DIR/dist"/* "$deploy_target/" 2>/dev/null
    fi
    
    echo ""
    echo -e "${CYAN}Deployment Information:${NC}"
    echo -e "  Environment: ${YELLOW}Staging${NC}"
    echo -e "  Target: ${CYAN}$deploy_target${NC}"
    echo -e "  URL: ${BLUE}https://staging.example.com${NC}"
    echo -e "  Status: ${GREEN}Live${NC}"
    
    echo ""
    echo -e "${GREEN}✓ Deployment completed successfully${NC}"
    
    log_message "INFO" "Deployment stage completed"
    STAGE_DEPLOY=true
    ((COMPLETED_STAGES++))
    return 0
}

# Stage 6: Send Notifications
stage_notify() {
    stage_header 6 "Send Notifications"
    
    log_message "INFO" "Starting notification stage"
    
    echo -e "${YELLOW}Sending deployment notifications...${NC}"
    echo ""
    
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    # Simulate notifications
    echo -e "${CYAN}Notifying team members...${NC}"
    simulate_work 1
    
    echo ""
    echo -e "${GREEN}✓ Notifications sent to:${NC}"
    echo -e "  📧 Email: dev-team@example.com"
    echo -e "  💬 Slack: #deployments channel"
    echo -e "  📱 SMS: On-call engineer"
    
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              DEPLOYMENT NOTIFICATION                          ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}✓ Deployment Successful!${NC}"
    echo ""
    echo -e "${CYAN}Project:${NC} Sample Application"
    echo -e "${CYAN}Branch:${NC} $BRANCH"
    echo -e "${CYAN}Environment:${NC} Staging"
    echo -e "${CYAN}Duration:${NC} ${minutes}m ${seconds}s"
    echo -e "${CYAN}Status:${NC} ${GREEN}Success${NC}"
    echo ""
    echo -e "${CYAN}Stages Completed:${NC}"
    echo -e "  ✓ Clone Repository"
    echo -e "  ✓ Code Linting"
    echo -e "  ✓ Run Tests"
    echo -e "  ✓ Build Application"
    echo -e "  ✓ Deploy to Staging"
    echo -e "  ✓ Send Notifications"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo -e "  → Manual approval required for production"
    echo -e "  → Run: ${YELLOW}./deploy-production.sh${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    
    log_message "INFO" "Notification stage completed"
    STAGE_NOTIFY=true
    ((COMPLETED_STAGES++))
    return 0
}

# Function to run full pipeline
run_pipeline() {
    print_header
    
    log_message "INFO" "=== CI/CD Pipeline Started ==="
    
    # Stage 1: Clone
    if ! stage_clone; then
        FAILED_STAGE="Clone Repository"
        pipeline_failed
        return 1
    fi
    
    # Stage 2: Lint
    if ! stage_lint; then
        FAILED_STAGE="Code Linting"
        pipeline_failed
        return 1
    fi
    
    # Stage 3: Test
    if ! stage_test; then
        FAILED_STAGE="Run Tests"
        pipeline_failed
        return 1
    fi
    
    # Stage 4: Build
    if ! stage_build; then
        FAILED_STAGE="Build Application"
        pipeline_failed
        return 1
    fi
    
    # Stage 5: Deploy
    if ! stage_deploy; then
        FAILED_STAGE="Deploy Application"
        pipeline_failed
        return 1
    fi
    
    # Stage 6: Notify
    if ! stage_notify; then
        FAILED_STAGE="Send Notifications"
        pipeline_failed
        return 1
    fi
    
    log_message "INFO" "=== CI/CD Pipeline Completed Successfully ==="
    
    # Cleanup
    cleanup
    
    return 0
}

# Function to handle pipeline failure
pipeline_failed() {
    echo ""
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              PIPELINE FAILED                                  ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}${BOLD}✗ Pipeline Failed at Stage: $FAILED_STAGE${NC}"
    echo ""
    echo -e "${CYAN}Completed Stages:${NC} $COMPLETED_STAGES/$TOTAL_STAGES"
    echo -e "${CYAN}Failed Stage:${NC} $FAILED_STAGE"
    echo ""
    echo -e "${CYAN}Troubleshooting:${NC}"
    echo -e "  1. Check logs: ${YELLOW}$LOG_FILE${NC}"
    echo -e "  2. Review error messages above"
    echo -e "  3. Fix issues and re-run pipeline"
    echo ""
    
    log_message "ERROR" "=== Pipeline Failed at: $FAILED_STAGE ==="
    
    cleanup
}

# Function to cleanup
cleanup() {
    echo ""
    echo -e "${CYAN}Cleaning up temporary files...${NC}"
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        echo -e "${GREEN}✓ Build directory removed${NC}"
    fi
    
    echo ""
}

# Function to show usage
print_usage() {
    echo -e "${CYAN}Usage:${NC}"
    echo -e "  $0 [OPTIONS]"
    echo -e ""
    echo -e "${CYAN}Options:${NC}"
    echo -e "  ${GREEN}-r, --repo${NC} URL       Repository URL to clone"
    echo -e "  ${GREEN}-b, --branch${NC} NAME    Branch to checkout (default: main)"
    echo -e "  ${GREEN}-h, --help${NC}           Show this help message"
    echo -e ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  $0                                    # Run with sample project"
    echo -e "  $0 -r https://github.com/user/repo   # Run with actual repo"
    echo -e "  $0 -r <url> -b develop               # Use develop branch"
    echo ""
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--repo)
                REPO_URL="$2"
                shift 2
                ;;
            -b|--branch)
                BRANCH="$2"
                shift 2
                ;;
            -h|--help)
                print_header
                print_usage
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Run the pipeline
    run_pipeline
}

# Run the script
main "$@" 
