# Workload Identity Federation test

Temporary test of the setup in [docs/workload-identity-federation.md](../../docs/workload-identity-federation.md). Remove this folder once the module supports customer-owned service accounts.

It deploys to `masthead-test-client`:

- `masthead-reader`: the customer-owned service account, with `roles/bigquery.metadataViewer` on the project.
- A workload identity pool and an OIDC provider that trust `https://accounts.google.com` tokens from the Masthead service accounts and from a stand-in.
- `masthead-standin`: stands in for a Masthead service account, because personal accounts can't impersonate the `masthead-prod` ones.

State is in `gs://masthead-dev-tfstate/terraform-google-masthead-agent/tests/workload-identity-federation`.

## Run

Add yourself to `testers` so you can mint ID tokens for the stand-in, then apply:

```bash
terraform init
terraform apply -var='testers=["user:max.ostapenko@mastheadata.com","user:you@mastheadata.com"]'
```

Keep existing testers in the list, or their access is removed. IAM changes can take a minute or two to propagate.

Run the token exchange as the stand-in:

```bash
./test.sh masthead-standin@masthead-test-client.iam.gserviceaccount.com
```

The script gets an ID token for the stand-in, exchanges it with STS, gets an access token for `masthead-reader` and lists BigQuery datasets in the project.

To test a real Masthead service account, run `./test.sh` with its email. This needs `roles/iam.serviceAccountTokenCreator` on that service account.

## Clean up

```bash
terraform destroy
```

APIs stay enabled. The pool ID stays reserved for 30 days after deletion; change `pool_id` to re-create it within that period.
