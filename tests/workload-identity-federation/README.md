# Workload Identity Federation test

Temporary test of [docs/workload-identity-federation.md](../../docs/workload-identity-federation.md) in `masthead-test-client`. Remove this folder once the module supports customer-owned service accounts.

- `main.tf` is step 1 of the doc: the `masthead-wif-test` service account, and a workload identity pool and OIDC provider that trust `https://accounts.google.com` tokens from the four Masthead service accounts. Only the service account and pool IDs differ from the doc.
- Step 2 (deploying the module with `masthead_service_accounts` set to `masthead-wif-test`) isn't part of this test. Until then, `masthead-wif-test` has no roles in the project and `test.sh` can't list datasets.

State is in `gs://masthead-dev-tfstate/terraform-google-masthead-agent/tests/workload-identity-federation`.

## Run

```bash
terraform init
terraform apply
terraform output -json masthead_federation
```

Run the token exchange as a Masthead service account:

```bash
./test.sh masthead-data@masthead-prod.iam.gserviceaccount.com bigquery_sa
```

The script gets an ID token for the Masthead service account, exchanges it with STS, gets an access token for the service account under that key in `masthead_federation` and lists BigQuery datasets in the project. It needs `roles/iam.serviceAccountTokenCreator` on the Masthead service account, and the module roles from step 2.

## Clean up

```bash
terraform destroy
```

APIs stay enabled. The pool ID stays reserved for 30 days after deletion; change the pool ID to re-create it within that period.
