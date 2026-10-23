# Domain Restricted Sharing

If your organization enforces the `iam.allowedPolicyMemberDomains` constraint, IAM bindings for Masthead service accounts fail with `One or more users named in the policy do not belong to a permitted customer`.

To allow them, add Masthead's Google Cloud customer ID `C02gzdy9v` to the constraint. This permits only identities from Masthead's organization; the module binds just the service accounts listed in `masthead_service_accounts`.

Scope the exception to the monitored projects (or folders in Organization Mode) and keep `inheritFromParent: true`, so your own customer ID stays allowed:

```bash
cat > policy.yaml <<EOF
name: projects/PROJECT_ID/policies/iam.allowedPolicyMemberDomains
spec:
  inheritFromParent: true
  rules:
    - values:
        allowedValues:
          - C02gzdy9v
EOF
gcloud org-policies set-policy policy.yaml --quiet
```

Or with Terraform:

```hcl
resource "google_org_policy_policy" "allow_masthead" {
  name   = "projects/${var.project_id}/policies/iam.allowedPolicyMemberDomains"
  parent = "projects/${var.project_id}"

  spec {
    inherit_from_parent = true
    rules {
      values {
        allowed_values = ["C02gzdy9v"]
      }
    }
  }
}
```

For folders, use `folders/FOLDER_ID` in `name` and `parent`. Setting the policy requires `orgpolicy.policies.create` and `orgpolicy.policies.update` (for example, `roles/orgpolicy.policyAdmin` granted at the organization level).
