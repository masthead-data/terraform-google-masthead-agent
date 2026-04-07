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

The BigQuery module supports opt-in PII redaction via a [Pub/Sub message transform (SMT)](https://cloud.google.com/pubsub/docs/message-transforms). A JavaScript UDF runs at the **topic level**, so all subscribers receive redacted messages before they are stored in the subscription backlog.

The SMT is disabled by default. It is enabled only when `pii_redaction.custom_code` is set.

### Email address redaction (starter template)

The following UDF redacts email addresses from BigQuery audit log SQL query fields (`jobInsertRequest`, `jobUpdateRequest`, `jobQueryResponse`). Copy and customise as needed.

```hcl
pii_redaction = {
  custom_code = <<-JAVASCRIPT
    function redactPii(message, metadata) {
      if (!message.data) return message;
      try {
        var bytes = message.data;
        var text = '';
        for (var bi = 0; bi < bytes.length; bi++) {
          text += String.fromCharCode(bytes[bi]);
        }
        var log = JSON.parse(text);
        var emailRegex = /[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/g;
        var paths = [
          ['protoPayload', 'serviceData', 'jobInsertRequest', 'resource', 'jobConfiguration', 'query', 'query'],
          ['protoPayload', 'serviceData', 'jobUpdateRequest', 'resource', 'jobConfiguration', 'query', 'query'],
          ['protoPayload', 'serviceData', 'jobQueryResponse', 'resource', 'jobConfiguration', 'query', 'query']
        ];
        for (var pi = 0; pi < paths.length; pi++) {
          var obj = log;
          var path = paths[pi];
          for (var ki = 0; ki < path.length - 1; ki++) {
            if (obj == null || typeof obj !== 'object') { obj = null; break; }
            obj = obj[path[ki]];
          }
          var key = path[path.length - 1];
          if (obj != null && typeof obj === 'object' && typeof obj[key] === 'string') {
            obj[key] = obj[key].replace(emailRegex, '[REDACTED]');
          }
        }
        var encoded = JSON.stringify(log);
        var result = new Uint8Array(encoded.length);
        for (var ei = 0; ei < encoded.length; ei++) {
          result[ei] = encoded.charCodeAt(ei);
        }
        message.data = result;
      } catch (e) {}
      return message;
    }
  JAVASCRIPT
}
```

### Behaviour details

- Disabled by default. The SMT is enabled only when `custom_code` is provided.
- The UDF must export a function named `redactPii(message, metadata)` matching the [Pub/Sub SMT UDF signature](https://cloud.google.com/pubsub/docs/message-transforms#javascript-udf).
- The transform runs on the **topic**, so all subscribers automatically receive redacted messages.
- Only applies to the BigQuery module. Other modules (Dataform, Dataplex) are unaffected.
