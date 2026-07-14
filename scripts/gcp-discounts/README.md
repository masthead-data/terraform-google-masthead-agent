# GCP Custom Discounts Exporter to JSON

This utility fetches custom negotiated pricing and discounts from a GCP Billing Account using the Google Cloud Pricing API (`v2beta`) and exports the information to a clean JSON file.

It automatically filters the SKU catalog to keep only those containing **"GBQ"** in their product taxonomy.

## Requirements

- Node.js (version 18 or higher)
- Google Cloud SDK (`gcloud` CLI)

This script has **zero external dependencies** and uses native Node.js fetch.

## Usage

Run the script by retrieving your gcloud access token and providing your Billing Account ID:

```bash
GCP_ACCESS_TOKEN=$(gcloud auth print-access-token) node index.js <BILLING_ACCOUNT_ID>
```

Alternatively, you can pass the credentials as command line arguments:

```bash
node index.js <BILLING_ACCOUNT_ID> $(gcloud auth print-access-token)
```

> [!IMPORTANT]
> The authenticated principal must have the **Billing Account Viewer** (`roles/billing.viewer`) role on the target billing account.

## Output Format

The output is saved to `discounts.json` as a structured array of objects:

```json
[
  {
    "skuId": "0002-C3CC-1713",
    "productTaxonomy": "GCP > Analytics > GBQ > PhysicalStorage > LongTerm",
    "discount": 0,
    "discountFromSkuGroup": "",
    "discountFixedDate": "",
    "listPrice": 0.0311861
  }
]
```
