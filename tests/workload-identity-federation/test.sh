#!/usr/bin/env bash
# Simulates the Masthead backend: Google ID token for a Masthead SA -> STS
# federated token -> short-lived token for the customer's reader SA -> BigQuery call.
# Run after `terraform apply`. Needs roles/iam.serviceAccountTokenCreator on the Masthead SA.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

MASTHEAD_SA="${1:-masthead-data@masthead-prod.iam.gserviceaccount.com}"
PROJECT_ID="$(terraform output -raw reader_sa_email | sed -E 's/.*@([^.]+)\..*/\1/')"
READER_SA="$(terraform output -raw reader_sa_email)"
AUDIENCE="$(terraform output -raw provider_audience)"

echo "1. ID token for ${MASTHEAD_SA}"
ID_TOKEN="$(gcloud auth print-identity-token --quiet \
  --impersonate-service-account="${MASTHEAD_SA}" \
  --audiences="https:${AUDIENCE}" 2>/dev/null)"

echo "2. STS exchange"
FEDERATED_TOKEN="$(curl -sS https://sts.googleapis.com/v1/token \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
  --data-urlencode "audience=${AUDIENCE}" \
  --data-urlencode "scope=https://www.googleapis.com/auth/cloud-platform" \
  --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:access_token" \
  --data-urlencode "subject_token_type=urn:ietf:params:oauth:token-type:jwt" \
  --data-urlencode "subject_token=${ID_TOKEN}" | jq -er .access_token)"

echo "3. Access token for ${READER_SA}"
ACCESS_TOKEN="$(curl -sS -X POST \
  "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${READER_SA}:generateAccessToken" \
  -H "Authorization: Bearer ${FEDERATED_TOKEN}" -H "Content-Type: application/json" \
  -d '{"scope":["https://www.googleapis.com/auth/cloud-platform"]}' | jq -er .accessToken)"

echo "4. BigQuery datasets.list on ${PROJECT_ID} as ${READER_SA}"
curl -sS "https://bigquery.googleapis.com/bigquery/v2/projects/${PROJECT_ID}/datasets?maxResults=5" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" | jq '{datasets: [.datasets[]?.id], error: .error.message}'
