# Local Development - Simple Steps

## Quick Start (5 Steps)

### 1. Create Virtual Environment

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

### 2. Install Dependencies

```powershell
pip install -r requirements.txt
pip install uvicorn[standard]
```

### 3. Setup Environment Variables

```powershell
Copy-Item .env.example .env
notepad .env
```

Edit `.env` and add your OpenAI API key:

```
OPENAI_API_KEY=sk-your-actual-key-here
```

### 4. Process Documents (One-Time)

```powershell
python ingestion/ingest_docs.py --skip-upload
```

This creates a `vector_store/` folder with your embedded documents (~$0.01 cost)

### 5. Start the Server

```powershell
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Test the API

**Open browser:** http://localhost:8000/docs

**Available endpoints:**

- Health Check: http://localhost:8000/health
- Interactive Docs: http://localhost:8000/docs
- System Info: http://localhost:8000/info

## Example Query (Browser)

1. Go to http://localhost:8000/docs
2. Click on `POST /query`
3. Click "Try it out"
4. Paste this:

```json
{
  "question": "What does Medicare Part A cover?"
}
```

5. Click "Execute"

## Example Query (PowerShell)

```powershell
$body = @{
    question = "What does Medicare Part A cover?"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/query" -Method Post -Body $body -ContentType "application/json"
```

## Folder Structure After Setup

```
health-assistant/
├── venv/              (created by step 1)
├── vector_store/      (created by step 4)
│   ├── index.faiss
│   └── index.pkl
├── .env               (created by step 3)
└── ...
```

## Troubleshooting

**Issue:** "Module not found"

```powershell
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

**Issue:** "OpenAI API key not found"

- Check `.env` file has your key

**Issue:** "Vector store not loaded"

```powershell
python ingestion/ingest_docs.py --skip-upload
```

**Issue:** "Port already in use"

```powershell
python -m uvicorn app.main:app --reload --port 8001
```

## Stop the Server

Press `Ctrl + C` in the terminal

## Cost for Local Testing

- Document processing: ~$0.01 (one-time)
- Per query: ~$0.002-$0.005
- 100 queries: ~$0.20-$0.50

---

That's it! Simple and straightforward.
