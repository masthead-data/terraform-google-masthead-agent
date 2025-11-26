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

# Check if we can access terraform state (local or remote)
if ! terraform state list &> /dev/null; then
    echo -e "${RED}Error: Cannot access Terraform state${NC}"
    echo "Please ensure:"
    echo "  1. You're in your Terraform root directory"
    echo "  2. Terraform is initialized (run 'terraform init')"
    echo "  3. You have access to the remote backend (if using remote state)"
    exit 1
fi

echo -e "${GREEN}✓${NC} Successfully connected to Terraform state"
echo ""

# Check for jq (not strictly required anymore, but good to have)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq is not installed${NC}"
    echo "The script will work without it, but jq is recommended for advanced state analysis"
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    echo ""
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
# Handle both count format [0] and for_each format ["key"]
MODULES=$(terraform state list | grep "module.masthead_agent\[")

if [ -z "$MODULES" ]; then
    echo -e "${RED}Error: No masthead_agent modules found in state${NC}"
    echo "This script is designed for migrating existing deployments"
    exit 1
fi

echo "Sample resources from state:"
echo "$MODULES" | head -5
echo ""

# Check if state is already in v0.3.0 format (has logging_infrastructure)
if echo "$MODULES" | grep -q "module.logging_infrastructure"; then
    echo -e "${GREEN}✓ Your state appears to already be in v0.3.0 format!${NC}"
    echo ""
    echo "Detected logging_infrastructure module, which indicates you're already using v0.3.0."
    echo "No migration needed - your resources are already in the correct structure."
    exit 0
fi

# Detect the masthead_agent keys being used (for_each keys or count index)
AGENT_KEYS=$(echo "$MODULES" | grep -o 'module.masthead_agent\[[^]]*\]' | sort -u)

if [ -z "$AGENT_KEYS" ]; then
    echo -e "${RED}Error: Could not detect masthead_agent module keys${NC}"
    exit 1
fi

echo "Detected masthead_agent instances:"
echo "$AGENT_KEYS" | sed 's/module.masthead_agent/  - /'
echo ""

# Detect which service modules are being used
SERVICE_MODULES=$(echo "$MODULES" | grep -o 'module\.\(bigquery\|dataform\|dataplex\|analytics_hub\)\[0\]' | sed 's/module.//;s/\[0\]//' | sort -u)

if [ -z "$SERVICE_MODULES" ]; then
    echo -e "${RED}Error: No service modules (bigquery, dataform, dataplex, analytics_hub) found${NC}"
    echo "Cannot generate moved blocks without detecting which modules are enabled"
    exit 1
fi

echo "Detected service modules:"
echo "$SERVICE_MODULES" | sed 's/^/  - /'
echo ""

# Track if we generated any blocks
GENERATED=0

# Generate moved blocks for each masthead_agent instance and each service module
for AGENT_KEY in $AGENT_KEYS; do
    # Extract the key value (e.g., "max-ostapenko" from module.masthead_agent["max-ostapenko"])
    KEY_VALUE=$(echo "$AGENT_KEY" | sed 's/module.masthead_agent\[\(.*\)\]/\1/')

    echo "Processing instance: $AGENT_KEY"

    for MODULE_NAME in $SERVICE_MODULES; do
        echo "  - Generating moves for $MODULE_NAME..."

        case "$MODULE_NAME" in
            bigquery|dataform|dataplex)
                cat >> "$OUTPUT_FILE" << EOF

# ============================================================================
# ${MODULE_NAME} module moves for ${AGENT_KEY}
# ============================================================================

# Pub/Sub Topic
moved {
  from = ${AGENT_KEY}.module.${MODULE_NAME}[0].google_pubsub_topic.masthead_topic
  to   = ${AGENT_KEY}.module.${MODULE_NAME}[0].module.logging_infrastructure.google_pubsub_topic.logs_topic
}

# Pub/Sub Subscription
moved {
  from = ${AGENT_KEY}.module.${MODULE_NAME}[0].google_pubsub_subscription.masthead_agent_subscription
  to   = ${AGENT_KEY}.module.${MODULE_NAME}[0].module.logging_infrastructure.google_pubsub_subscription.logs_subscription
}

# Pub/Sub API Enablement
moved {
  from = ${AGENT_KEY}.module.${MODULE_NAME}[0].google_project_service.required_apis["pubsub.googleapis.com"]
  to   = ${AGENT_KEY}.module.${MODULE_NAME}[0].module.logging_infrastructure.google_project_service.pubsub_api
}

EOF

                # Check if project-level sinks exist in state
                if terraform state list | grep -q "${AGENT_KEY}.module.${MODULE_NAME}\[0\].google_logging_project_sink.masthead_sink"; then
                    cat >> "$OUTPUT_FILE" << EOF
# Log Sink (project-level)
moved {
  from = ${AGENT_KEY}.module.${MODULE_NAME}[0].google_logging_project_sink.masthead_sink
  to   = ${AGENT_KEY}.module.${MODULE_NAME}[0].module.logging_infrastructure.google_logging_project_sink.logs_sink[${KEY_VALUE}]
}

# Log Sink Writer IAM
moved {
  from = ${AGENT_KEY}.module.${MODULE_NAME}[0].google_pubsub_topic_iam_member.logging_pubsub_publisher
  to   = ${AGENT_KEY}.module.${MODULE_NAME}[0].module.logging_infrastructure.google_project_iam_member.log_writer[${KEY_VALUE}]
}

EOF
                fi

                # Subscriber IAM
                cat >> "$OUTPUT_FILE" << EOF
# Subscriber IAM
moved {
  from = ${AGENT_KEY}.module.${MODULE_NAME}[0].google_pubsub_subscription_iam_member.masthead_subscription_subscriber
  to   = ${AGENT_KEY}.module.${MODULE_NAME}[0].module.logging_infrastructure.google_pubsub_subscription_iam_member.subscriber
}

EOF

                GENERATED=$((GENERATED + 1))
                ;;

            analytics_hub)
                echo "# Analytics Hub structure is different - review manually" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
                ;;
        esac
    done
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
