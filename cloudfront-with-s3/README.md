
Invalidation item in CloudFront
```sh
aws cloudfront create-invalidation --distribution-id "ETVUX1NQ3QHWW" --path "/error.html"
```

Only 1000 path can be invalidated in free tier of aws 






# CloudFront + Cloudflare + SSL Setup (Short Steps)

1. **Request ACM Certificate**
   - Region: `us-east-1`
   - Domain: `cdn.iamrishabh.tech`
   - Validation: DNS

2. **Add ACM CNAME in Cloudflare**
   - Type: CNAME
   - Name / Value: as provided by ACM
   - Proxy: DNS only (gray cloud)
   - Wait until **Issued**

3. **Create CloudFront Distribution**
   - Origin: S3 / ALB / etc.
   - Aliases: `cdn.iamrishabh.tech`
   - Viewer Certificate: attach ACM cert
   - SSL Support Method: `sni-only`

4. **Add CloudFront CNAME in Cloudflare**
   - Type: CNAME
   - Name: `cdn`
   - Value: `your-cloudfront-domain.cloudfront.net`
   - Proxy: DNS only (gray cloud) for testing

5. **Cloudflare SSL/TLS Settings**
   - Mode: Full or Full (Strict)

6. **Test HTTPS**
   - Visit `https://cdn.iamrishabh.tech`
   - Should load without handshake errors
