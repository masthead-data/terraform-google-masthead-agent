import fs from 'fs';

// Retrieve configuration from env or arguments
const billingAccountId = process.env.BILLING_ACCOUNT_ID || process.argv[2];
const accessToken = process.env.GCP_ACCESS_TOKEN || process.env.ACCESS_TOKEN || process.argv[3];

if (!billingAccountId || !accessToken) {
  console.error('Error: Please provide both GCP Billing Account ID and Access Token.');
  console.error('Usage: GCP_ACCESS_TOKEN=$(gcloud auth print-access-token) BILLING_ACCOUNT_ID=012345-6789AB-CDEF01 node index.js');
  console.error('Alternatively: node index.js <BILLING_ACCOUNT_ID> <ACCESS_TOKEN>');
  process.exit(1);
}

// Helper for authenticated fetch requests
async function fetchGcp(url, params = {}) {
  const query = new URLSearchParams(params).toString();
  const fullUrl = query ? `${url}?${query}` : url;
  
  const res = await fetch(fullUrl, {
    headers: { 'Authorization': `Bearer ${accessToken}` }
  });
  
  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`HTTP ${res.status}: ${errorText}`);
  }
  
  return res.json();
}

try {
  // 1. Fetch SKU catalog and filter for BigQuery (GBQ) taxonomies
  console.log('Fetching SKUs...');
  const skus = {};
  let skuToken = null;
  do {
    const url = `https://cloudbilling.googleapis.com/v1beta/billingAccounts/${billingAccountId}/skus`;
    const data = await fetchGcp(url, { pageSize: 5000, pageToken: skuToken || '' });
    
    for (const sku of (data.billingAccountSkus || [])) {
      const cats = (sku.productTaxonomy?.taxonomyCategories || []).map(c => c.category);
      if (cats.includes('GBQ')) {
        skus[sku.skuId] = cats.join(' > ');
      }
    }
    skuToken = data.nextPageToken;
  } while (skuToken);

  // 2. Fetch prices and match with filtered GBQ SKUs
  console.log('Fetching prices...');
  const results = [];
  let priceToken = null;
  do {
    const url = `https://cloudbilling.googleapis.com/v2beta/billingAccounts/${billingAccountId}/skus/-/prices`;
    const data = await fetchGcp(url, { pageSize: 5000, pageToken: priceToken || '' });
    
    for (const price of (data.billingAccountPrices || [])) {
      const skuId = price.name.split('/')[3]; // Extract skuId from: billingAccounts/{acc}/skus/{skuId}/price
      const taxonomy = skus[skuId];
      if (!taxonomy) continue; // Skip if not a BigQuery SKU
      
      const currency = price.currencyCode || '';
      
      for (const skuPrice of (price.skuPrices || [])) {
        const tiers = skuPrice.rate?.tiers || [];
        const reason = skuPrice.priceReason || {};
        
        const groupPath = reason.fixedDiscount?.skuGroup || reason.floatingDiscount?.skuGroup || '';
        const skuGroup = groupPath.split('/').pop() || '';
        const fixedDate = (reason.fixedDiscount?.fixTime || '').split('T')[0];
        
        for (const tier of tiers) {
          const listPrice = Number(tier.listPrice?.units || 0) + (tier.listPrice?.nanos || 0) / 1e9;
          const contractPrice = Number(tier.contractPrice?.units || 0) + (tier.contractPrice?.nanos || 0) / 1e9;
          
          const discount = reason.fixedDiscount?.discountPercent?.value 
            || reason.floatingDiscount?.discountPercent?.value 
            || '0';
          
          const effectiveDiscount = tier.effectiveDiscountPercent?.value || '0';
            
          results.push({
            skuId,
            productTaxonomy: taxonomy,
            discount: Number(discount),
            discountFromSkuGroup: skuGroup,
            discountFixedDate: fixedDate,
            listPrice,
            contractPrice,
            effectiveDiscount: Number(effectiveDiscount),
            currency
          });
        }
      }
    }
    priceToken = data.nextPageToken;
  } while (priceToken);

  // 3. Write results directly to JSON
  fs.writeFileSync(
    'discounts.json', 
    JSON.stringify(results, null, 2),
    'utf8'
  );
  console.log('Export complete! Saved to discounts.json');
} catch (err) {
  console.error('Fatal error during export:', err.message);
  process.exit(1);
}
