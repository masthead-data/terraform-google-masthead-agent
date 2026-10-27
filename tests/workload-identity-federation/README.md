# Workload Identity Federation test

Temporary test of the setup in [docs/workload-identity-federation.md](../../docs/workload-identity-federation.md). Remove this folder once the module supports customer-owned service accounts.

It deploys to `masthead-test-client`:

- `masthead-wif-test`: the customer-owned service account, with `roles/bigquery.metadataViewer` on the project.
- A workload identity pool and an OIDC provider that trust `https://accounts.google.com` tokens from the Masthead service accounts.

State is in `gs://masthead-dev-tfstate/terraform-google-masthead-agent/tests/workload-identity-federation`.

## Run

```bash
terraform init
terraform apply
```

Run the token exchange as a Masthead service account:

```bash
./test.sh masthead-data@masthead-prod.iam.gserviceaccount.com
```

The script gets an ID token for the Masthead service account, exchanges it with STS, gets an access token for `masthead-wif-test` and lists BigQuery datasets in the project. It needs `roles/iam.serviceAccountTokenCreator` on the Masthead service account.

## Clean up

```bash
terraform destroy
```

APIs stay enabled. The pool ID stays reserved for 30 days after deletion; change `pool_id` to re-create it within that period.
