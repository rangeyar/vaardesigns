# Health Insurance Assistant API

A serverless RAG (Retrieval-Augmented Generation) application for answering health insurance questions using Medicare and health insurance documents. Built with FastAPI, LangChain, OpenAI, and deployed on AWS Lambda.

## 🏗️ Architecture

```
Frontend (S3/CloudFront)
    ↓
API Gateway (HTTP API)
    ↓
Lambda Function (Container)
    ↓
FAISS Vector Store (loaded from S3)
    ↓
OpenAI API (GPT-4o-mini)
```

## 💰 Cost Estimate

For **5-10 requests/day** (learning/personal use):

- **AWS Lambda**: ~$0.00 (Free tier)
- **API Gateway**: ~$0.00 (Free tier: 1M requests/month)
- **S3**: ~$0.01/month
- **CloudWatch**: ~$0.50/month
- **OpenAI API**: ~$0.50-1.00/month

**Total: ~$1-2/month** ☕

## 🚀 Features

- ✅ Serverless architecture (AWS Lambda + API Gateway)
- ✅ RAG-based question answering with source citations
- ✅ PDF document processing and embedding
- ✅ FAISS vector store for semantic search
- ✅ OpenAI GPT-4o-mini for cost-effective responses
- ✅ CORS support for frontend integration
- ✅ Docker containerization
- ✅ Infrastructure as Code (Terraform)
- ✅ Local development environment

## 📁 Project Structure

```
health-assistant/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app with endpoints
│   ├── rag.py               # RAG pipeline with LangChain + FAISS
│   ├── models.py            # Pydantic models
│   └── config.py            # Configuration settings
├── ingestion/
│   ├── __init__.py
│   └── ingest_docs.py       # Document processing script
├── health-doc/              # PDF documents folder
│   ├── 10050-medicare-and-you.pdf
│   ├── 11575-Getting-Started-Medicare-Supplement-Insurance.pdf
│   ├── mc5500-05.pdf
│   └── PI-047.pdf
├── deploy/
│   ├── terraform/           # Terraform IaC files
│   │   ├── main.tf
│   │   ├── s3.tf
│   │   ├── iam.tf
│   │   ├── lambda.tf
│   │   ├── api_gateway.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   ├── deploy.sh            # Deployment script (Linux/Mac)
│   └── deploy.ps1           # Deployment script (Windows)
├── Dockerfile               # Lambda container image
├── Dockerfile.dev           # Local development image
├── docker-compose.yml       # Local testing
├── requirements.txt         # Python dependencies
├── .env.example             # Environment variables template
├── .gitignore
└── README.md
```

## 📋 Prerequisites

- **Python 3.11+**
- **Docker Desktop**
- **AWS CLI** configured with credentials
- **Terraform** (v1.0+)
- **OpenAI API Key**
- **AWS Account** (Free tier eligible)

## 🔧 Setup Instructions

### 1. Clone and Setup Environment

```powershell
# Navigate to project directory
cd health-assistant

# Create virtual environment
python -m venv venv

# Activate virtual environment (Windows PowerShell)
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Environment Variables

```powershell
# Copy example env file
cp .env.example .env

# Edit .env with your values
```

Update `.env` with:

```env
OPENAI_API_KEY=sk-your-openai-api-key-here
S3_BUCKET_NAME=health-assistant-vectors-dev
AWS_REGION=us-east-1
CORS_ORIGINS=https://yourdomain.com,http://localhost:3000
```

### 3. Process Documents and Create Vector Store

```powershell
# Run document ingestion
python ingestion/ingest_docs.py

# This will:
# 1. Load PDFs from health-doc/
# 2. Split into chunks
# 3. Generate embeddings
# 4. Create FAISS index
# 5. Upload to S3
```

**Note**: Make sure your AWS credentials are configured and the S3 bucket exists or will be created.

### 4. Test Locally (Optional)

```powershell
# Using Docker Compose
docker-compose up

# Or run directly
python -m uvicorn app.main:app --reload

# Test the API
curl http://localhost:8000/health
```

### 5. Deploy to AWS

#### Option A: Using PowerShell Script (Windows)

```powershell
cd deploy
.\deploy.ps1 -AwsRegion "us-east-1" -Environment "dev"
```

#### Option B: Using Bash Script (Linux/Mac)

```bash
cd deploy
chmod +x deploy.sh
./deploy.sh
```

#### Option C: Manual Terraform Deployment

```powershell
# Navigate to terraform directory
cd deploy/terraform

# Copy and edit terraform variables
cp terraform.tfvars.example terraform.tfvars

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (create infrastructure)
terraform apply

# Get ECR repository URL
$ECR_REPO = terraform output -raw ecr_repository_url

# Build and push Docker image
cd ..\..
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REPO
docker build -t health-assistant:latest .
docker tag health-assistant:latest ${ECR_REPO}:latest
docker push ${ECR_REPO}:latest

# Update Lambda function
$LAMBDA_FUNCTION = cd deploy/terraform; terraform output -raw lambda_function_name
aws lambda update-function-code --function-name $LAMBDA_FUNCTION --image-uri ${ECR_REPO}:latest
```

## 🧪 Testing the API

### Health Check

```powershell
curl https://your-api-gateway-url.amazonaws.com/health
```

Response:

```json
{
  "status": "healthy",
  "message": "Service is running",
  "vector_store_loaded": true
}
```

### Query Health Insurance Questions

```powershell
curl -X POST https://your-api-gateway-url.amazonaws.com/query `
  -H "Content-Type: application/json" `
  -d '{
    "question": "What does Medicare Part A cover?",
    "conversation_id": "user-123"
  }'
```

Response:

```json
{
  "answer": "Medicare Part A covers inpatient hospital care, skilled nursing facility care...",
  "sources": [
    {
      "content": "Medicare Part A (Hospital Insurance) covers...",
      "source": "medicare-and-you.pdf",
      "page": 15
    }
  ],
  "conversation_id": "user-123"
}
```

### Get System Info

```powershell
curl https://your-api-gateway-url.amazonaws.com/info
```

## 🔗 Frontend Integration

Update your frontend to call the API:

```javascript
// Example using fetch
async function askQuestion(question) {
  const response = await fetch("https://your-api-url.amazonaws.com/query", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      question: question,
      conversation_id: userId,
    }),
  });

  const data = await response.json();
  return data;
}
```

## 📊 API Endpoints

| Endpoint  | Method | Description                      |
| --------- | ------ | -------------------------------- |
| `/`       | GET    | Root endpoint with API info      |
| `/health` | GET    | Health check                     |
| `/query`  | POST   | Query health insurance questions |
| `/info`   | GET    | System information               |
| `/docs`   | GET    | Interactive API documentation    |

## 🔄 Updating Documents

To add or update documents:

1. Add new PDFs to `health-doc/` folder
2. Run ingestion script:
   ```powershell
   python ingestion/ingest_docs.py
   ```
3. The vector store will be automatically uploaded to S3
4. Lambda will load the new index on next cold start

## 🛠️ Development

### Local Development with Hot Reload

```powershell
# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Run with auto-reload
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Run Tests

```powershell
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests (when you add them)
pytest tests/
```

## 📈 Monitoring and Logs

### View Lambda Logs

```powershell
# View logs
aws logs tail /aws/lambda/health-assistant-dev --follow

# View specific time range
aws logs tail /aws/lambda/health-assistant-dev --since 1h
```

### View API Gateway Logs

```powershell
aws logs tail /aws/apigateway/health-assistant-dev --follow
```

### CloudWatch Dashboard

View metrics in AWS Console:

- Lambda invocations
- API Gateway requests
- Error rates
- Response times

## 🧹 Cleanup / Destroy Resources

To remove all AWS resources:

```powershell
cd deploy/terraform

# Destroy all infrastructure
terraform destroy

# Manually delete S3 bucket if needed (if it has contents)
aws s3 rm s3://health-assistant-vectors-dev --recursive
aws s3 rb s3://health-assistant-vectors-dev
```

## 💡 Cost Optimization Tips

1. **Use GPT-4o-mini** instead of GPT-4 (save 95% on OpenAI costs)
2. **Cache embeddings** - Only generate once per document
3. **Adjust Lambda memory** - Start with 512MB, increase if needed
4. **Use HTTP API** instead of REST API (50% cheaper)
5. **Set CloudWatch log retention** to 7 days
6. **Use S3 Intelligent-Tiering** for document storage
7. **Enable Lambda function URL** instead of API Gateway if you don't need advanced features

## 🔒 Security Best Practices

- ✅ API keys stored in environment variables (not in code)
- ✅ S3 bucket has encryption enabled
- ✅ S3 bucket blocks public access
- ✅ IAM roles follow least privilege principle
- ✅ CloudWatch logs enabled for auditing
- ✅ CORS properly configured

## 🐛 Troubleshooting

### Issue: Vector store not loading

**Solution**: Check S3 bucket permissions and ensure files are uploaded

```powershell
aws s3 ls s3://health-assistant-vectors-dev/faiss_index/health_insurance.index/
```

### Issue: Lambda timeout

**Solution**: Increase Lambda timeout in `lambda.tf`

```hcl
timeout = 90  # Increase from 60 to 90 seconds
```

### Issue: Cold start takes too long

**Solution**: Increase Lambda memory (more memory = faster CPU)

```hcl
memory_size = 1536  # Increase from 1024 to 1536 MB
```

### Issue: OpenAI API errors

**Solution**: Check API key and rate limits

```powershell
# Verify API key is set
echo $env:OPENAI_API_KEY
```

## 📚 Technology Stack

- **Backend**: Python 3.11, FastAPI, Mangum
- **AI/ML**: LangChain, OpenAI GPT-4o-mini, text-embedding-3-small
- **Vector Store**: FAISS
- **Document Processing**: PyPDF, unstructured
- **Cloud**: AWS Lambda, API Gateway, S3, ECR, CloudWatch
- **IaC**: Terraform
- **Containerization**: Docker

## 🤝 Contributing

This is a learning project. Feel free to:

- Add more document types
- Improve RAG pipeline
- Add conversation memory
- Implement caching
- Add authentication

## 📄 License

This project is for learning purposes.

## 🆘 Support

For issues or questions:

1. Check CloudWatch logs
2. Review Terraform outputs
3. Test locally with docker-compose
4. Verify environment variables

## 🎯 Next Steps

- [ ] Add authentication (API keys or Cognito)
- [ ] Implement conversation memory with DynamoDB
- [ ] Add document upload endpoint
- [ ] Create admin dashboard
- [ ] Add response caching with ElastiCache
- [ ] Implement A/B testing for prompts
- [ ] Add analytics and usage tracking
- [ ] Set up CI/CD pipeline
- [ ] Add integration tests
- [ ] Create custom domain with Route53

---

**Built with ❤️ for learning serverless RAG applications**
