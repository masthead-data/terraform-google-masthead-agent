# Configuration

Configuration example with all available options:

```hcl
module "masthead_agent" {
  source  = "masthead-data/masthead-agent/google"
  version = ">=0.3.1"

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
