
Invalidation item in CloudFront
```sh
aws cloudfront create-invalidation --distribution-id "ETVUX1NQ3QHWW" --path "/error.html"
aws cloudfront create-invalidation --distribution-id "ETVUX1NQ3QHWW" --path "/*"

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




if you destory the cloudfront distribution.. still the cname alias domain will point to the old cloudfront distribution.
so if you do terraform apply again, it will through an error that the cname already exists.

so after doing terraform destory ... you need to delete the cname from cloudflare first and then apply again.




# Generate Public and Private Key Pair for CloudFront Signed URLs

Note: If Openssl not installed use `git bash`
# Generate 2048-bit private key
```sh
openssl genrsa -out ./private_key.pem 2048
```
# Extract the public key in PEM format

```sh
openssl rsa -in ./private_key.pem -pubout -out ./public_key.pem
```


What are Trusted Key Groups?
A key group is a set of public keys that CloudFront trusts.
You (or your app) will have the private key locally, and use it to sign URLs.
CloudFront uses the public key in the key group to verify the signed URL.
Only requests with valid signatures will get access.