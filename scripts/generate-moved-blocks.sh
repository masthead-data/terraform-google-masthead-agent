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

# Get all state resources
STATE_LIST=$(terraform state list)

# Extract enabled modules from state
MODULES=$(echo "$STATE_LIST" | grep "module.masthead_agent\[" || true)

if [ -z "$MODULES" ]; then
    echo -e "${RED}Error: No masthead_agent modules found in state${NC}"
    echo "This script is designed for migrating existing deployments"
    exit 1
fi

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

# Track generated blocks
GENERATED=0

# Generate moved blocks for each masthead_agent instance
for AGENT_KEY in $AGENT_KEYS; do
    # Extract the key value (e.g., "masthead-dev" from module.masthead_agent["masthead-dev"])
    KEY_VALUE=$(echo "$AGENT_KEY" | sed 's/module.masthead_agent\[\(.*\)\]/\1/')
    # Remove quotes for use in resource keys
    KEY_BARE=$(echo "$KEY_VALUE" | tr -d '"')

    echo "Processing instance: $AGENT_KEY (key: $KEY_BARE)"

    # =========================================================================
    # BIGQUERY MODULE
    # =========================================================================
    if echo "$STATE_LIST" | grep -qF "${AGENT_KEY}.module.bigquery[0]"; then
        echo "  - Generating moves for bigquery..."

        cat >> "$OUTPUT_FILE" << EOF

# ============================================================================
# BigQuery module moves for ${AGENT_KEY}
# ============================================================================

# Pub/Sub Topic
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_pubsub_topic.masthead_topic
  to   = ${AGENT_KEY}.module.bigquery[0].module.logging_infrastructure.google_pubsub_topic.logs_topic
}

# Pub/Sub Subscription
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_pubsub_subscription.masthead_agent_subscription
  to   = ${AGENT_KEY}.module.bigquery[0].module.logging_infrastructure.google_pubsub_subscription.logs_subscription
}

# Pub/Sub Subscriber IAM
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_pubsub_subscription_iam_member.masthead_subscription_subscriber
  to   = ${AGENT_KEY}.module.bigquery[0].module.logging_infrastructure.google_pubsub_subscription_iam_member.masthead_subscription_subscriber
}

# Pub/Sub API
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_project_service.required_apis["pubsub.googleapis.com"]
  to   = ${AGENT_KEY}.module.bigquery[0].module.logging_infrastructure.google_project_service.pubsub_api[0]
}

# Log Sink (project-level)
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_logging_project_sink.masthead_sink
  to   = ${AGENT_KEY}.module.bigquery[0].module.logging_infrastructure.google_logging_project_sink.project_sinks["${KEY_BARE}"]
}

# Log Sink Writer IAM (Pub/Sub publisher)
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_pubsub_topic_iam_member.logging_pubsub_publisher
  to   = ${AGENT_KEY}.module.bigquery[0].module.logging_infrastructure.google_pubsub_topic_iam_member.project_sinks_publisher["${KEY_BARE}"]
}

# IAM API
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_project_service.required_apis["iam.googleapis.com"]
  to   = ${AGENT_KEY}.module.bigquery[0].module.logging_infrastructure.google_project_service.monitored_project_apis["${KEY_BARE}:iam.googleapis.com"]
}

# Logging API
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_project_service.required_apis["logging.googleapis.com"]
  to   = ${AGENT_KEY}.module.bigquery[0].module.logging_infrastructure.google_project_service.monitored_project_apis["${KEY_BARE}:logging.googleapis.com"]
}

# BigQuery API
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_project_service.required_apis["bigquery.googleapis.com"]
  to   = ${AGENT_KEY}.module.bigquery[0].google_project_service.bigquery_api["${KEY_BARE}"]
}

# BigQuery IAM - metadataViewer
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_project_iam_member.masthead_bigquery_roles["roles/bigquery.metadataViewer"]
  to   = ${AGENT_KEY}.module.bigquery[0].google_project_iam_member.masthead_bigquery_project_roles["${KEY_BARE}-roles/bigquery.metadataViewer"]
}

# BigQuery IAM - resourceViewer
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_project_iam_member.masthead_bigquery_roles["roles/bigquery.resourceViewer"]
  to   = ${AGENT_KEY}.module.bigquery[0].google_project_iam_member.masthead_bigquery_project_roles["${KEY_BARE}-roles/bigquery.resourceViewer"]
}

# BigQuery Custom Role
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_project_iam_custom_role.masthead_bigquery_custom_role
  to   = ${AGENT_KEY}.module.bigquery[0].google_project_iam_custom_role.masthead_bigquery_custom_role_project["${KEY_BARE}"]
}

# BigQuery Custom Role IAM Member
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_project_iam_member.masthead_bigquery_custom_role_member
  to   = ${AGENT_KEY}.module.bigquery[0].google_project_iam_member.masthead_bigquery_project_custom_role["${KEY_BARE}"]
}

# Private Log Viewer IAM
moved {
  from = ${AGENT_KEY}.module.bigquery[0].google_project_iam_member.masthead_privatelogviewer_role[0]
  to   = ${AGENT_KEY}.module.bigquery[0].google_project_iam_member.masthead_privatelogviewer_project_role["${KEY_BARE}"]
}

EOF
        GENERATED=$((GENERATED + 1))
    fi

    # =========================================================================
    # DATAFORM MODULE
    # =========================================================================
    if echo "$STATE_LIST" | grep -qF "${AGENT_KEY}.module.dataform[0]"; then
        echo "  - Generating moves for dataform..."

        cat >> "$OUTPUT_FILE" << EOF

# ============================================================================
# Dataform module moves for ${AGENT_KEY}
# ============================================================================

# Pub/Sub Topic
moved {
  from = ${AGENT_KEY}.module.dataform[0].google_pubsub_topic.masthead_dataform_topic
  to   = ${AGENT_KEY}.module.dataform[0].module.logging_infrastructure.google_pubsub_topic.logs_topic
}

# Pub/Sub Subscription
moved {
  from = ${AGENT_KEY}.module.dataform[0].google_pubsub_subscription.masthead_dataform_subscription
  to   = ${AGENT_KEY}.module.dataform[0].module.logging_infrastructure.google_pubsub_subscription.logs_subscription
}

# Pub/Sub Subscriber IAM
moved {
  from = ${AGENT_KEY}.module.dataform[0].google_pubsub_subscription_iam_member.masthead_subscription_subscriber
  to   = ${AGENT_KEY}.module.dataform[0].module.logging_infrastructure.google_pubsub_subscription_iam_member.masthead_subscription_subscriber
}

# Pub/Sub API
moved {
  from = ${AGENT_KEY}.module.dataform[0].google_project_service.required_apis["pubsub.googleapis.com"]
  to   = ${AGENT_KEY}.module.dataform[0].module.logging_infrastructure.google_project_service.pubsub_api[0]
}

# Log Sink (project-level)
moved {
  from = ${AGENT_KEY}.module.dataform[0].google_logging_project_sink.masthead_dataform_sink
  to   = ${AGENT_KEY}.module.dataform[0].module.logging_infrastructure.google_logging_project_sink.project_sinks["${KEY_BARE}"]
}

# Log Sink Writer IAM (Pub/Sub publisher)
moved {
  from = ${AGENT_KEY}.module.dataform[0].google_pubsub_topic_iam_member.logging_pubsub_publisher
  to   = ${AGENT_KEY}.module.dataform[0].module.logging_infrastructure.google_pubsub_topic_iam_member.project_sinks_publisher["${KEY_BARE}"]
}

# Logging API
moved {
  from = ${AGENT_KEY}.module.dataform[0].google_project_service.required_apis["logging.googleapis.com"]
  to   = ${AGENT_KEY}.module.dataform[0].module.logging_infrastructure.google_project_service.monitored_project_apis["${KEY_BARE}:logging.googleapis.com"]
}

# Dataform API
moved {
  from = ${AGENT_KEY}.module.dataform[0].google_project_service.required_apis["dataform.googleapis.com"]
  to   = ${AGENT_KEY}.module.dataform[0].google_project_service.dataform_api["${KEY_BARE}"]
}

# Dataform IAM - viewer
moved {
  from = ${AGENT_KEY}.module.dataform[0].google_project_iam_member.masthead_dataform_roles["roles/dataform.viewer"]
  to   = ${AGENT_KEY}.module.dataform[0].google_project_iam_member.masthead_dataform_project_roles["${KEY_BARE}-roles/dataform.viewer"]
}

EOF
        GENERATED=$((GENERATED + 1))
    fi

    # =========================================================================
    # DATAPLEX MODULE
    # =========================================================================
    if echo "$STATE_LIST" | grep -qF "${AGENT_KEY}.module.dataplex[0]"; then
        echo "  - Generating moves for dataplex..."

        cat >> "$OUTPUT_FILE" << EOF

# ============================================================================
# Dataplex module moves for ${AGENT_KEY}
# ============================================================================

# Pub/Sub Topic
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_pubsub_topic.masthead_dataplex_topic
  to   = ${AGENT_KEY}.module.dataplex[0].module.logging_infrastructure.google_pubsub_topic.logs_topic
}

# Pub/Sub Subscription
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_pubsub_subscription.masthead_dataplex_subscription
  to   = ${AGENT_KEY}.module.dataplex[0].module.logging_infrastructure.google_pubsub_subscription.logs_subscription
}

# Pub/Sub Subscriber IAM
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_pubsub_subscription_iam_member.masthead_subscription_subscriber
  to   = ${AGENT_KEY}.module.dataplex[0].module.logging_infrastructure.google_pubsub_subscription_iam_member.masthead_subscription_subscriber
}

# Pub/Sub API
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_project_service.required_apis["pubsub.googleapis.com"]
  to   = ${AGENT_KEY}.module.dataplex[0].module.logging_infrastructure.google_project_service.pubsub_api[0]
}

# Log Sink (project-level)
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_logging_project_sink.masthead_dataplex_sink
  to   = ${AGENT_KEY}.module.dataplex[0].module.logging_infrastructure.google_logging_project_sink.project_sinks["${KEY_BARE}"]
}

# Log Sink Writer IAM (Pub/Sub publisher)
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_pubsub_topic_iam_member.logging_pubsub_publisher
  to   = ${AGENT_KEY}.module.dataplex[0].module.logging_infrastructure.google_pubsub_topic_iam_member.project_sinks_publisher["${KEY_BARE}"]
}

# Logging API
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_project_service.required_apis["logging.googleapis.com"]
  to   = ${AGENT_KEY}.module.dataplex[0].module.logging_infrastructure.google_project_service.monitored_project_apis["${KEY_BARE}:logging.googleapis.com"]
}

# Dataplex API
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_project_service.required_apis["dataplex.googleapis.com"]
  to   = ${AGENT_KEY}.module.dataplex[0].google_project_service.dataplex_apis["${KEY_BARE}:dataplex.googleapis.com"]
}

# BigQuery API (used by Dataplex)
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_project_service.required_apis["bigquery.googleapis.com"]
  to   = ${AGENT_KEY}.module.dataplex[0].google_project_service.dataplex_apis["${KEY_BARE}:bigquery.googleapis.com"]
}

# Dataplex IAM - dataProductsViewer
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_project_iam_member.masthead_dataplex_roles["roles/dataplex.dataProductsViewer"]
  to   = ${AGENT_KEY}.module.dataplex[0].google_project_iam_member.masthead_dataplex_project_roles["${KEY_BARE}-roles/dataplex.dataProductsViewer"]
}

# Dataplex IAM - dataScanDataViewer (default role when editing disabled)
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_project_iam_member.masthead_dataplex_roles["roles/dataplex.dataScanDataViewer"]
  to   = ${AGENT_KEY}.module.dataplex[0].google_project_iam_member.masthead_dataplex_project_roles["${KEY_BARE}-roles/dataplex.dataScanDataViewer"]
}

# Dataplex IAM - dataScanEditor (when editing enabled)
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_project_iam_member.masthead_dataplex_roles["roles/dataplex.dataScanEditor"]
  to   = ${AGENT_KEY}.module.dataplex[0].google_project_iam_member.masthead_dataplex_project_roles["${KEY_BARE}-roles/dataplex.dataScanEditor"]
}

# Dataplex IAM - bigquery.jobUser (when editing enabled)
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_project_iam_member.masthead_dataplex_roles["roles/bigquery.jobUser"]
  to   = ${AGENT_KEY}.module.dataplex[0].google_project_iam_member.masthead_dataplex_project_roles["${KEY_BARE}-roles/bigquery.jobUser"]
}

# Dataplex IAM - storageDataReader (when editing enabled)
moved {
  from = ${AGENT_KEY}.module.dataplex[0].google_project_iam_member.masthead_dataplex_roles["roles/dataplex.storageDataReader"]
  to   = ${AGENT_KEY}.module.dataplex[0].google_project_iam_member.masthead_dataplex_project_roles["${KEY_BARE}-roles/dataplex.storageDataReader"]
}

EOF
        GENERATED=$((GENERATED + 1))
    fi

    # =========================================================================
    # ANALYTICS HUB MODULE
    # =========================================================================
    if echo "$STATE_LIST" | grep -qF "${AGENT_KEY}.module.analytics_hub[0]"; then
        echo "  - Generating moves for analytics_hub..."

        cat >> "$OUTPUT_FILE" << EOF

# ============================================================================
# Analytics Hub module moves for ${AGENT_KEY}
# ============================================================================

# Analytics Hub API
moved {
  from = ${AGENT_KEY}.module.analytics_hub[0].google_project_service.required_apis["analyticshub.googleapis.com"]
  to   = ${AGENT_KEY}.module.analytics_hub[0].google_project_service.analyticshub_api["${KEY_BARE}"]
}

# Custom Role for Analytics Hub
moved {
  from = ${AGENT_KEY}.module.analytics_hub[0].google_project_iam_custom_role.masthead_analyticshub_custom_role
  to   = ${AGENT_KEY}.module.analytics_hub[0].google_project_iam_custom_role.analyticshub_custom_role_project["${KEY_BARE}"]
}

# Analytics Hub IAM - viewer
moved {
  from = ${AGENT_KEY}.module.analytics_hub[0].google_project_iam_member.masthead_analyticshub_roles["viewer"]
  to   = ${AGENT_KEY}.module.analytics_hub[0].google_project_iam_member.masthead_analyticshub_project_roles["${KEY_BARE}-viewer"]
}

# Analytics Hub IAM - custom role
moved {
  from = ${AGENT_KEY}.module.analytics_hub[0].google_project_iam_member.masthead_analyticshub_roles["subscription_viewer"]
  to   = ${AGENT_KEY}.module.analytics_hub[0].google_project_iam_member.masthead_analyticshub_project_roles["${KEY_BARE}-custom"]
}

EOF
        GENERATED=$((GENERATED + 1))
    fi

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
echo "2. Update your module source to v0.3.0"
echo "3. Run: terraform init -upgrade"
echo "4. Run: terraform plan (should show moves, minimal recreations)"
echo "5. Run: terraform apply"
echo "6. Delete $OUTPUT_FILE once migration is complete"
echo ""
echo -e "${YELLOW}Note: If you have additional monitored_project_ids beyond the for_each key,"
echo "you may need to manually add moved blocks for those projects.${NC}"
