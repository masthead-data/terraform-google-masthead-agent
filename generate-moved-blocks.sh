#!/bin/bash
# Script to generate Terraform 'moved' blocks for migrating from v0.2.x to v0.3.0
# This helps avoid resource recreation during the module restructuring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Terraform Masthead Agent Migration Helper${NC}"
echo "Generating 'moved' blocks to preserve existing resources..."
echo ""

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo -e "${RED}Error: terraform.tfstate not found in current directory${NC}"
    echo "Please run this script from your Terraform root directory"
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed${NC}"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

# Output file
OUTPUT_FILE="moved-blocks.tf"

# Check if output file already exists
if [ -f "$OUTPUT_FILE" ]; then
    echo -e "${YELLOW}Warning: $OUTPUT_FILE already exists${NC}"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted"
        exit 1
    fi
fi

# Initialize output file
cat > "$OUTPUT_FILE" << 'EOF'
# Generated moved blocks for v0.2.x to v0.3.0 migration
# This file helps preserve existing resources during module restructuring
#
# After applying these moved blocks:
# 1. Run: terraform plan (should show minimal changes)
# 2. Run: terraform apply
# 3. Delete this file once migration is complete

EOF

# Extract enabled modules from state
MODULES=$(terraform state list | grep "module.masthead_agent\[0\].module" | sed 's/\[.*//g' | sed 's/\..*//g' | sort -u)

if [ -z "$MODULES" ]; then
    echo -e "${RED}Error: No masthead_agent modules found in state${NC}"
    echo "This script is designed for migrating existing v0.2.x deployments"
    exit 1
fi

echo "Detected modules in state:"
echo "$MODULES" | sed 's/module.masthead_agent\[0\].module.//g'
echo ""

# Track if we generated any blocks
GENERATED=0

# Generate moved blocks for each module
for MODULE_PATH in $MODULES; do
    MODULE_NAME=$(echo "$MODULE_PATH" | sed 's/module.masthead_agent\[0\].module.//g')

    echo "Processing module: $MODULE_NAME"

    # Skip if it's already the new structure (contains logging_infrastructure)
    if echo "$MODULE_NAME" | grep -q "logging_infrastructure"; then
        continue
    fi

    case "$MODULE_NAME" in
        bigquery|dataform|dataplex)
            cat >> "$OUTPUT_FILE" << EOF

# ============================================================================
# ${MODULE_NAME} module moves
# ============================================================================

# Pub/Sub Topic
moved {
  from = module.masthead_agent[0].module.${MODULE_NAME}.google_pubsub_topic.logs_topic
  to   = module.masthead_agent[0].module.${MODULE_NAME}[0].module.logging_infrastructure.google_pubsub_topic.logs_topic
}

# Pub/Sub Subscription
moved {
  from = module.masthead_agent[0].module.${MODULE_NAME}.google_pubsub_subscription.logs_subscription
  to   = module.masthead_agent[0].module.${MODULE_NAME}[0].module.logging_infrastructure.google_pubsub_subscription.logs_subscription
}

# Pub/Sub API Enablement
moved {
  from = module.masthead_agent[0].module.${MODULE_NAME}.google_project_service.pubsub_api
  to   = module.masthead_agent[0].module.${MODULE_NAME}[0].module.logging_infrastructure.google_project_service.pubsub_api
}

# Log Sink Writer IAM (for each monitored project)
# Note: These will need manual adjustment if you have multiple projects
moved {
  from = module.masthead_agent[0].module.${MODULE_NAME}.google_project_iam_member.log_writer
  to   = module.masthead_agent[0].module.${MODULE_NAME}[0].module.logging_infrastructure.google_project_iam_member.log_writer
}

# Subscriber IAM
moved {
  from = module.masthead_agent[0].module.${MODULE_NAME}.google_pubsub_subscription_iam_member.subscriber
  to   = module.masthead_agent[0].module.${MODULE_NAME}[0].module.logging_infrastructure.google_pubsub_subscription_iam_member.subscriber
}

EOF

            # Add module-specific resources based on what's in state
            if terraform state list | grep -q "module.masthead_agent\[0\].module.${MODULE_NAME}.google_logging_project_sink"; then
                cat >> "$OUTPUT_FILE" << EOF
# Log Sinks (project-level)
moved {
  from = module.masthead_agent[0].module.${MODULE_NAME}.google_logging_project_sink.logs_sink
  to   = module.masthead_agent[0].module.${MODULE_NAME}[0].module.logging_infrastructure.google_logging_project_sink.logs_sink
}

EOF
            fi

            GENERATED=$((GENERATED + 1))
            ;;

        analytics_hub)
            # Analytics Hub doesn't use logging_infrastructure, just convert to indexed
            echo "# Analytics Hub uses different structure - manual review recommended" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            ;;
    esac
done

if [ $GENERATED -eq 0 ]; then
    echo -e "${YELLOW}Warning: No moved blocks generated${NC}"
    echo "Your state may already be migrated or structure is different than expected"
    rm "$OUTPUT_FILE"
    exit 1
fi

echo ""
echo -e "${GREEN}Success! Generated moved blocks in: $OUTPUT_FILE${NC}"
echo ""
echo "Next steps:"
echo "1. Review the generated $OUTPUT_FILE"
echo "2. If you have multiple monitored projects, you may need to adjust the 'for_each' moved blocks"
echo "3. Update your Terraform configuration to v0.3.0"
echo "4. Run: terraform init -upgrade"
echo "5. Run: terraform plan (should show moves, minimal recreations)"
echo "6. Run: terraform apply"
echo "7. Delete $OUTPUT_FILE once migration is complete"
echo ""
echo -e "${YELLOW}Note: This script generates basic moved blocks. Complex configurations may need manual adjustment.${NC}"
