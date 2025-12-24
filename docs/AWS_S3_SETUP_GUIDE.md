# AWS S3 Setup Guide for Medical Documents

## Prerequisites
- AWS Account
- AWS CLI installed (optional but recommended)
- Access to AWS Console

---

## Step 1: Create IAM User

1. **Login to AWS Console** → Navigate to **IAM Service**

2. **Create New User:**
   - Click "Users" → "Add users"
   - Username: `esante-medical-docs-user`
   - Access type: ✅ Programmatic access
   - Click "Next: Permissions"

3. **Attach Policies:**
   - Attach existing policy: `AmazonS3FullAccess`
   - Or create custom policy (see below)
   - Click "Next: Tags" → "Next: Review" → "Create user"

4. **Save Credentials:**
   - **Access Key ID:** `AKIAIOSFODNN7EXAMPLE`
   - **Secret Access Key:** `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
   - ⚠️ **IMPORTANT:** Save these securely! You won't see them again.

### Custom IAM Policy (Recommended)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowMedicalDocumentsBucket",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetObjectMetadata",
        "s3:HeadObject"
      ],
      "Resource": [
        "arn:aws:s3:::esante-medical-documents",
        "arn:aws:s3:::esante-medical-documents/*"
      ]
    },
    {
      "Sid": "AllowGeneratePresignedUrls",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::esante-medical-documents/*"
    }
  ]
}
```

---

## Step 2: Create S3 Bucket

1. **Navigate to S3 Service** in AWS Console

2. **Create Bucket:**
   - Bucket name: `esante-medical-documents`
   - Region: `us-east-1` (or your preferred region)
   - Block all public access: ✅ **KEEP ENABLED** (we'll use signed URLs)
   - Bucket Versioning: Optional (recommended for audit)
   - Default encryption: ✅ Enable
     - Encryption type: SSE-S3 (AES-256)
   - Click "Create bucket"

3. **Configure CORS (if needed for web uploads):**
   - Select bucket → Permissions → CORS
   - Add configuration:
   ```json
   [
     {
       "AllowedHeaders": ["*"],
       "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
       "AllowedOrigins": ["http://localhost:3000", "https://yourdomain.com"],
       "ExposeHeaders": ["ETag"],
       "MaxAgeSeconds": 3000
     }
   ]
   ```

4. **Configure Bucket Policy (Optional - for additional security):**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "DenyUnencryptedObjectUploads",
         "Effect": "Deny",
         "Principal": "*",
         "Action": "s3:PutObject",
         "Resource": "arn:aws:s3:::esante-medical-documents/*",
         "Condition": {
           "StringNotEquals": {
             "s3:x-amz-server-side-encryption": "AES256"
           }
         }
       }
     ]
   }
   ```

5. **Create Folder Structure (Optional):**
   - You can create folders via console or let the app create them:
     - medical-documents/lab_result/
     - medical-documents/imaging/
     - medical-documents/prescription/
     - medical-documents/insurance/
     - medical-documents/medical_report/
     - medical-documents/other/

---

## Step 3: Configure Environment Variables

1. **Navigate to your service directory:**
   ```bash
   cd backend/services/medical-records-service
   ```

2. **Update `.env` file:**
   ```env
   # Server Configuration
   PORT=3004
   NODE_ENV=development

   # MongoDB
   MONGODB_URI=mongodb://localhost:27017/esante-medical-records

   # Kafka
   KAFKA_BROKERS=localhost:9092

   # JWT
   JWT_SECRET=your_jwt_secret_key_here
   JWT_REFRESH_SECRET=your_refresh_secret_key_here

   # Other Services
   USER_SERVICE_URL=http://localhost:3002/api/v1/users
   RDV_SERVICE_URL=http://localhost:3003/api/v1/rdv

   # AWS S3 Configuration
   AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
   AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   AWS_REGION=us-east-1
   AWS_S3_BUCKET=esante-medical-documents
   ```

3. **Verify Configuration:**
   - Ensure no spaces around `=`
   - Keep secret keys secure
   - Use different credentials for production

---

## Step 4: Test S3 Connection

### Option 1: Using AWS CLI
```bash
# Configure AWS CLI
aws configure
# Enter Access Key ID
# Enter Secret Access Key
# Enter region: us-east-1
# Enter output format: json

# Test bucket access
aws s3 ls s3://esante-medical-documents

# Upload test file
echo "Test file" > test.txt
aws s3 cp test.txt s3://esante-medical-documents/test.txt

# List bucket contents
aws s3 ls s3://esante-medical-documents/

# Delete test file
aws s3 rm s3://esante-medical-documents/test.txt
```

### Option 2: Using Node.js Script
Create `test-s3.js` in service root:
```javascript
import AWS from 'aws-sdk';
import dotenv from 'dotenv';

dotenv.config();

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION
});

// Test connection
async function testS3Connection() {
  try {
    // List buckets
    const buckets = await s3.listBuckets().promise();
    console.log('✅ S3 connection successful!');
    console.log('Available buckets:', buckets.Buckets.map(b => b.Name));

    // Test bucket access
    const params = {
      Bucket: process.env.AWS_S3_BUCKET,
      Key: 'test.txt',
      Body: 'Test file content'
    };

    await s3.putObject(params).promise();
    console.log('✅ Test file uploaded successfully!');

    // List objects
    const objects = await s3.listObjectsV2({
      Bucket: process.env.AWS_S3_BUCKET
    }).promise();
    console.log('Bucket contents:', objects.Contents?.length || 0, 'objects');

    // Delete test file
    await s3.deleteObject({
      Bucket: process.env.AWS_S3_BUCKET,
      Key: 'test.txt'
    }).promise();
    console.log('✅ Test file deleted successfully!');

    console.log('\n✅ All S3 tests passed! Your configuration is correct.');
  } catch (error) {
    console.error('❌ S3 connection failed:', error.message);
    console.error('Check your AWS credentials and bucket configuration.');
  }
}

testS3Connection();
```

Run test:
```bash
node test-s3.js
```

---

## Step 5: Start Medical Records Service

1. **Start required services:**
   ```bash
   # Terminal 1: MongoDB
   mongod

   # Terminal 2: Kafka & Zookeeper
   cd backend
   docker-compose -f docker-compose.kafka.yml up

   # Terminal 3: Medical Records Service
   cd backend/services/medical-records-service
   npm run dev
   ```

2. **Verify service started:**
   ```
   ✅ Server running on port 3004
   ✅ Connected to MongoDB
   ✅ Connected to Kafka
   ✅ Prescription auto-lock job started
   ```

---

## Step 6: Test Document Upload

### Using Postman/Insomnia

1. **Upload Document:**
   ```
   POST http://localhost:3004/api/v1/medical/documents/upload
   Authorization: Bearer {your_jwt_token}
   Content-Type: multipart/form-data

   Form Data:
   - file: [Select PDF or image file]
   - documentType: lab_result
   - title: Test Blood Work
   - description: Annual checkup blood test
   - documentDate: 2024-01-15
   - tags: blood,annual,routine
   ```

2. **Get Document Details:**
   ```
   GET http://localhost:3004/api/v1/medical/documents/{documentId}
   Authorization: Bearer {your_jwt_token}
   ```

3. **Download Document:**
   ```
   GET http://localhost:3004/api/v1/medical/documents/{documentId}/download
   Authorization: Bearer {your_jwt_token}
   ```

4. **Get My Documents:**
   ```
   GET http://localhost:3004/api/v1/medical/documents/my-documents?page=1&limit=20
   Authorization: Bearer {your_jwt_token}
   ```

### Using cURL
```bash
# Upload document
curl -X POST http://localhost:3004/api/v1/medical/documents/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/document.pdf" \
  -F "documentType=lab_result" \
  -F "title=Test Document" \
  -F "description=Test upload"

# Get document
curl -X GET http://localhost:3004/api/v1/medical/documents/DOCUMENT_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Troubleshooting

### Error: "Access Denied"
- ✅ Check IAM user permissions
- ✅ Verify AWS credentials in `.env`
- ✅ Ensure bucket policy allows access
- ✅ Check bucket name is correct

### Error: "Bucket does not exist"
- ✅ Verify bucket name: `esante-medical-documents`
- ✅ Check region matches in `.env` and bucket settings
- ✅ Ensure bucket is created in correct AWS account

### Error: "InvalidAccessKeyId"
- ✅ Verify `AWS_ACCESS_KEY_ID` in `.env`
- ✅ Check for spaces or extra characters
- ✅ Ensure IAM user credentials are active

### Error: "SignatureDoesNotMatch"
- ✅ Verify `AWS_SECRET_ACCESS_KEY` is correct
- ✅ Check for newlines or spaces in secret key
- ✅ Ensure no special characters are escaped

### Error: "File too large"
- ✅ Check file size < 10MB
- ✅ Compress large files before upload
- ✅ Use supported formats: PDF, JPEG, PNG

### Upload works but signed URL fails
- ✅ Check S3 bucket permissions
- ✅ Verify server-side encryption is enabled
- ✅ Ensure object exists in bucket
- ✅ Check URL expiration time

---

## Security Best Practices

1. **Never commit AWS credentials to Git:**
   - Add `.env` to `.gitignore`
   - Use environment variables in production
   - Rotate credentials regularly

2. **Use IAM roles in production:**
   - Attach IAM role to EC2/ECS instances
   - No need to store credentials on server
   - Auto-rotated credentials

3. **Enable bucket encryption:**
   - Server-side encryption: AES-256
   - Enforce encryption on upload
   - Use AWS KMS for advanced encryption

4. **Block public access:**
   - Keep "Block all public access" enabled
   - Use signed URLs for temporary access
   - Never make bucket publicly readable

5. **Enable bucket logging:**
   - Track all access to documents
   - Monitor for suspicious activity
   - Integrate with CloudWatch

6. **Use lifecycle policies:**
   - Auto-delete deleted documents after 90 days
   - Move old documents to Glacier for archival
   - Reduce storage costs

7. **Enable versioning:**
   - Prevent accidental deletions
   - Maintain audit trail
   - Recover from ransomware

---

## Production Checklist

- [ ] Create separate S3 bucket for production
- [ ] Use IAM roles instead of access keys
- [ ] Enable bucket versioning
- [ ] Enable bucket logging
- [ ] Configure lifecycle policies
- [ ] Set up CloudWatch alarms
- [ ] Enable AWS CloudTrail
- [ ] Configure backup strategy
- [ ] Test disaster recovery
- [ ] Document bucket structure
- [ ] Set up monitoring dashboard
- [ ] Configure cost alerts
- [ ] Review security audit
- [ ] Implement least privilege access
- [ ] Rotate credentials regularly

---

## Cost Optimization

### Storage Pricing (us-east-1)
- Standard: $0.023 per GB/month
- 10GB storage ≈ $0.23/month
- 100GB storage ≈ $2.30/month
- 1TB storage ≈ $23/month

### Request Pricing
- PUT/POST: $0.005 per 1,000 requests
- GET: $0.0004 per 1,000 requests
- 10,000 uploads ≈ $0.05
- 100,000 downloads ≈ $0.04

### Data Transfer
- Upload: Free
- Download: First 100GB/month free, then $0.09/GB

### Tips to Reduce Costs
1. Compress files before upload
2. Use lifecycle policies to archive old documents
3. Delete test/temporary files regularly
4. Monitor storage usage
5. Use S3 Intelligent-Tiering for automated cost optimization

---

## Monitoring & Maintenance

### CloudWatch Metrics to Monitor
- Bucket size (bytes)
- Number of objects
- Upload/download request count
- Error rates
- Average latency

### Regular Maintenance Tasks
1. Review and delete test files weekly
2. Archive old documents monthly
3. Audit access logs quarterly
4. Rotate IAM credentials quarterly
5. Review bucket policies annually
6. Test disaster recovery annually

---

## Additional Resources

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS SDK for JavaScript](https://docs.aws.amazon.com/sdk-for-javascript/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [S3 Pricing Calculator](https://calculator.aws/)

---

**Last Updated:** January 2024  
**Service:** Medical Records Service  
**Component:** Medical Documents (PROMPT 7)
