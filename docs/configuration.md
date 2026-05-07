# Configuration

Configuration example with all available options:

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.4.0"

  # Choose ONE mode:

  # PROJECT MODE: Set project_id only
  project_id = var.project_id

  # ORGANIZATION MODE: Set deployment_project_id + folders and/or projects
  deployment_project_id = var.deployment_project_id
  monitored_folder_ids  = ["folders/123456789"]  # Optional: monitor folders
  monitored_project_ids = ["project-1", "project-2"]  # Optional: monitor specific projects
  organization_id       = "123456789"  # Required when using folders

  # Module configuration
  enable_modules = {
    bigquery      = true
    dataform      = true
    dataplex      = true
    analytics_hub = true
  }

  # Optional features
  enable_apis                  = true
  enable_privatelogviewer_role = true  # For retrospective log export
  enable_datascan_editing      = false # Dataplex DataScan editing permissions
  create_organization_custom_roles          = true  # Create the organization level custom roles (relevant only for monitored folders). Set to false if the organization level custom IAM roles are managed outside of this module.

  # PII redaction (optional) — provide a UDF to enable SMT on the BigQuery topic
  # See ## PII Redaction below for a ready-to-use email redaction example
  pii_redaction = {
    custom_code = <<-JAVASCRIPT
      function redactPii(message, metadata) { ... }
    JAVASCRIPT
  }

  # Labels for governance and cost management
  labels = {
    environment = "production"
    team        = "data"
    cost_center = "engineering"
    monitoring  = "masthead"
  }
}
```

## PII Redaction

The BigQuery module supports opt-in PII redaction via a [Pub/Sub message transform (SMT)](https://docs.cloud.google.com/pubsub/docs/smts/smts-overview). A JavaScript UDF runs at the **topic level**, so all subscribers receive redacted messages before they are stored in the subscription backlog.

The SMT is disabled by default. It is enabled only when `pii_redaction.custom_code` is set.

### PII redaction starter template

The following UDF redacts PII patterns from BigQuery audit log SQL query fields. Copy and customise as needed.

```hcl
pii_redaction = {
  custom_code = <<-JAVASCRIPT
    function redactPii(message, metadata) {
      try {
        var data = JSON.parse(message.data);

        function safeGet(obj, keys) {
          var current = obj;
          for (var i = 0; i < keys.length; i++) {
            if (current == null || typeof current !== "object") return null;
            current = current[keys[i]];
          }
          return current != null ? current : null;
        }

        function maskText(text) {
          if (!text) return text;
          text = text.replace(/[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/g, "[EMAIL_ADDRESS]");

          // Add more regex patterns for other PII types as needed

          return text;
        }

        function maskFields(config) {
          if (config == null) return;
          if (typeof config.query === "string") config.query = maskText(config.query);
        }

        maskFields(safeGet(data, ["protoPayload", "metadata", "jobChange", "job", "jobConfig", "queryConfig"]));
        maskFields(safeGet(data, ["protoPayload", "metadata", "jobInsertion", "job", "jobConfig", "queryConfig"]));

        message.data = JSON.stringify(data);
        return message;
      } catch (e) {
        return message;
      }
    }
  JAVASCRIPT
}
```

### Behaviour details

- Disabled by default. The SMT is enabled only when `custom_code` is provided.
- The UDF must export a function named `redactPii(message, metadata)` matching the [Pub/Sub SMT UDF signature](https://docs.cloud.google.com/pubsub/docs/smts/udfs-overview).
- The transform runs on the **topic**, so all subscribers automatically receive redacted messages.
- Only applies to the BigQuery module. Other modules (Dataform, Dataplex) are unaffected.


### Externally managed custom IAM roles (folder mode only)

By default the module creates two custom roles and binds them to the Masthead service account:

- `mastheadBigQueryCustomRole` — `bigquery.datasets.listSharedDatasetUsage`
- `mastheadAnalyticsHubCustomRole` — `analyticshub.listings.viewSubscriptions`

In **folder mode** these roles are created at the organization scope, which requires `iam.roles.create` on the org. If your security policy forbids the deployment principal from holding that permission, set `create_organization_custom_roles = false`. The module then skips both the role definition and the SA binding for the two roles above; you are responsible for creating the roles at the organization level and granting them to the Masthead service account at folder scope.

In **project mode** (`monitored_project_ids` only, no folders) the flag has no effect: the roles are project-level, scoped to the deployment project, and always created by the module.

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.4.0"

  monitored_folder_ids  = ["folders/111111111"]
  deployment_project_id = "project-3"

  create_organization_custom_roles = false  # org admin manages the custom roles manually
}
```

Manual setup (run once, by an org admin):

```bash
gcloud iam roles create mastheadCustomRole \
  --organization=<ORG_ID> \
  --title="Masthead Custom Role" \
  --description="Permissions required by the Masthead agent (BigQuery shared dataset usage + Analytics Hub subscription viewing)" \
  --permissions=bigquery.datasets.listSharedDatasetUsage,analyticshub.listings.viewSubscriptions

# Grant the role to the Masthead BigQuery SA at the folder level (per monitored folder)
gcloud resource-manager folders add-iam-policy-binding <FOLDER_ID> \
  --member=serviceAccount:<MASTHEAD_BIGQUERY_SA> \
  --role=organizations/<ORG_ID>/roles/mastheadCustomRole
```

Or, equivalently, as a standalone Terraform configuration. The module does not reference the role names when `create_organization_custom_roles = false`, so the two permissions can be combined into a single custom role for simpler administration. Apply this once with an org-admin principal that holds `iam.roles.create`; afterwards your main configuration can run with `create_organization_custom_roles = false` under a more restricted principal.

```hcl
variable "organization_id" {
  type        = string
  description = "GCP organization ID (numeric, no organizations/ prefix)."
}

variable "folder_ids" {
  type        = list(string)
  description = "Folders where the Masthead service account should receive the custom role. Each entry can be 'folders/123456789' or just the numeric ID."
}

variable "masthead_bigquery_sa" {
  type        = string
  description = "Email of the Masthead BigQuery service account that the custom role is granted to."
  default     = "masthead-data@masthead-prod.iam.gserviceaccount.com"
}

variable "custom_role_id" {
  type        = string
  description = "Role ID for the combined Masthead custom role at the org level."
  default     = "mastheadCustomRole"
}

resource "google_organization_iam_custom_role" "masthead" {
  org_id      = var.organization_id
  role_id     = var.custom_role_id
  title       = "Masthead Custom Role"
  description = "Permissions required by the Masthead agent (BigQuery shared dataset usage + Analytics Hub subscription viewing)"
  permissions = [
    "bigquery.datasets.listSharedDatasetUsage",
    "analyticshub.listings.viewSubscriptions",
  ]
}

resource "google_folder_iam_member" "masthead_custom_role" {
  for_each = toset(var.folder_ids)

  folder = each.value
  role   = google_organization_iam_custom_role.masthead.id
  member = "serviceAccount:${var.masthead_bigquery_sa}"
}
```

Example `terraform.tfvars`:

```hcl
organization_id = "123456789"
folder_ids = [
  "folders/111111111",
  "folders/222222222",
]
```

