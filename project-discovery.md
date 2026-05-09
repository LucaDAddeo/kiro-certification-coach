# 🧭 AWS Certification Coach — Project Discovery

> Documento di riferimento con tutto il contesto scoperto: risorse AWS esistenti, progetti locali, architettura di riferimento, e piano di evoluzione.
> Ultimo aggiornamento: 9 Maggio 2026

---

## 📌 Obiettivo del Progetto

Creare un **AI-powered Certification Coach** per la preparazione a **tutte le certificazioni AWS**, in due fasi:

1. **Fase 1 — POC Agent Locale**: Agente Kiro CLI per studio personale (AIP-C01 come prima certificazione)
2. **Fase 2 — Web App Cloud-Native Agentica**: App serverless con Bedrock Agents, Knowledge Base, AgentCore, Lambda, API Gateway, CloudFront, Cognito, etc.

### Caratteristiche chiave
- Generazione domande sia **statica** (JSON pre-generato) che **dinamica** (via LLM)
- Fonti multiple: Knowledge Base (exam guides), AWS Docs, AWS Blog, GitHub, web search
- Supporto tutte le certificazioni AWS (architettura estensibile)
- Quiz interattivi con feedback dettagliato e analisi per dominio
- Progress tracking per certificazione

---

## 🏗️ Architettura Esistente — `demo-serverless-agent-web-west2`

### Account AWS
- **Account ID**: `634848780747`
- **Profilo AWS CLI**: `Kiro`
- **Region principale**: `us-west-2`

### Frontend (S3 Static Hosting)
- **Bucket**: `demo-serverless-agent-web-west2`
- **File**: `index.html`, `app.js`, `style.css`
- **Website endpoint**: `http://demo-serverless-agent-web-west2.s3-website-us-west-2.amazonaws.com`
- Chat UI che invoca l'agente Bedrock tramite API Gateway → Lambda

### Flusso architetturale
```
Browser → S3 (static hosting)
       → API Gateway (REST, POST /chat)
       → Lambda Invoker
       → Bedrock Agent (MyBedrockAgent)
       → Action Groups (Lambda tools: AWSDocs, AWSBlog, Wikipedia, Weather, DateTime)
```

---

## 🤖 Bedrock Agents

### MyBedrockAgent (PRINCIPALE — riutilizzabile)
| Proprietà | Valore |
|-----------|--------|
| Agent ID | `LKX3E7Q5XZ` |
| Agent ARN | `arn:aws:bedrock:us-west-2:634848780747:agent/LKX3E7Q5XZ` |
| Modello | Nova Pro v1 (`us.amazon.nova-pro-v1:0`) |
| Istruzione | Assistente italiano con tools DateTime + Weather + AWSDocs + AWSBlog + Wikipedia |
| Alias | `TSTALIASID` (test) |
| Collaboration | DISABLED |
| Region | us-west-2 |

### DemoAgent (e-commerce — non riutilizzabile direttamente)
| Proprietà | Valore |
|-----------|--------|
| Agent ID | `BSSYCTDVLP` |
| Modello | Nova Pro v1 |
| Istruzione | Customer support e-commerce |
| Collaboration | **SUPERVISOR** (multi-agent) |
| Region | us-west-2 |

---

## 🛠️ Action Groups & Tools (OpenAPI Schemas)

### 1. AWSDocsTools ✅ RIUTILIZZABILE
- **Lambda**: `DemoServerlessAgent-AWSDocs` (Python 3.12)
- **Descrizione**: Search AWS official documentation for any AWS service or topic
```yaml
GET /search-aws-docs
  operationId: searchAWSDocs
  parameters:
    - query (required): string — "The AWS service or topic to search"
    - limit (optional): integer (default: 3)
  response: { query, results: [{title, url, excerpt}], search_url }
```

### 2. AWSBlogTools ✅ RIUTILIZZABILE
- **Lambda**: `DemoServerlessAgent-AWSBlog` (Python 3.12)
- **Descrizione**: Search recent AWS blog posts by topic
```yaml
GET /search-aws-blog
  operationId: searchAWSBlog
  parameters:
    - query (required): string — "Topic to search in AWS blog"
    - limit (optional): integer (default: 3)
  response: { query, results: [{title, url, date, excerpt}], feed_url }
```

### 3. WikipediaTools ✅ RIUTILIZZABILE
- **Lambda**: `DemoServerlessAgent-Wikipedia` (Python 3.12)
- **Descrizione**: Search Wikipedia for information about any topic
```yaml
GET /search-wikipedia
  operationId: searchWikipedia
  parameters:
    - query (required): string
    - lang (optional): "it" | "en" (default: it)
  response: { title, summary, language, url }
```

### 4. DateTime (action_group) ⚠️ OPZIONALE
- **Lambda**: `DateTimeFunction` (Python 3.13)
```yaml
GET /get-current-date-and-time
  operationId: getDateAndTime
  response: { date: string, time: string }
```

### 5. WeatherTools ❌ NON SERVE
- **Lambda**: `DemoServerlessAgent-Weather` (Python 3.12)

### 6. OrderActions ❌ NON SERVE
- **Lambda**: `OrderActions-f7q5p` (Python 3.12)
- Appartiene a DemoAgent (e-commerce)

---

## 📚 Knowledge Base

### demo-knowledge-base (us-east-1)
| Proprietà | Valore |
|-----------|--------|
| KB ID | `CTP5BOE6Q3` |
| KB ARN | `arn:aws:bedrock:us-east-1:634848780747:knowledge-base/CTP5BOE6Q3` |
| Status | ACTIVE |
| Storage | **S3 Vectors** (`bedrock-knowledge-base-1dbdmy`) |
| Embedding Model | Nova 2 Multimodal Embeddings v1 (FLOAT32) |
| Supplemental Data | `s3://embeddings-storage-bucket-634848780747` |
| Source Data | `s3://demo-knowledge-base-bucket-634848780747` |
| Region | us-east-1 |

---

## 🌐 API Gateway

| API | ID | Stage | Endpoint | Metodo |
|-----|-----|-------|----------|--------|
| DemoServerlessAgent-API | `zwwtzxahm9` | `prod` | `https://zwwtzxahm9.execute-api.us-west-2.amazonaws.com/prod/chat` | POST |
| DemoServerlessAgent-API (old) | `c7oif6x1ue` | — | Non deployato | — |

---

## ⚡ Lambda Functions

| Funzione | Runtime | Ruolo | Scopo |
|----------|---------|-------|-------|
| `DemoServerlessAgent-Invoker` | Python 3.12 | `DemoServerlessAgent-LambdaRole` | Gateway: invoca Bedrock Agent |
| `DemoServerlessAgent-AWSDocs` | Python 3.12 | `DemoServerlessAgent-LambdaRole` | Tool: documentazione AWS |
| `DemoServerlessAgent-AWSBlog` | Python 3.12 | `DemoServerlessAgent-LambdaRole` | Tool: blog AWS |
| `DemoServerlessAgent-Wikipedia` | Python 3.12 | `DemoServerlessAgent-LambdaRole` | Tool: Wikipedia |
| `DemoServerlessAgent-Weather` | Python 3.12 | `DemoServerlessAgent-LambdaRole` | Tool: meteo |
| `DemoServerlessAgent-DateTime` | Python 3.12 | `DemoServerlessAgent-LambdaRole` | Tool: data/ora |
| `DateTimeFunction` | Python 3.13 | — | Standalone datetime |
| `OrderActions-f7q5p` | Python 3.12 | — | Tool: ordini e-commerce |

### Env vars di DemoServerlessAgent-Invoker
```json
{
  "BEDROCK_AGENT_ID": "LKX3E7Q5XZ",
  "BEDROCK_AGENT_ALIAS_ID": "TSTALIASID",
  "AWS_REGION_NAME": "us-west-2"
}
```

---

## 🪣 S3 Buckets

| Bucket | Region | Uso |
|--------|--------|-----|
| `demo-serverless-agent-web-west2` | us-west-2 | Frontend web app agentica (static hosting) |
| `kiro-certification-coach` | us-west-2 | Frontend quiz app certificazioni |
| `certification-quiz` | us-west-2 | Vecchio frontend quiz |
| `demo-knowledge-base-bucket-634848780747` | us-east-1 | Dati sorgente per KB |
| `embeddings-storage-bucket-634848780747` | us-east-1 | Storage embeddings |
| `amazon-quick-knowledge-base` | us-west-2 | KB rapida |
| `amazon-quick-knowledge-base-usw2` | us-west-2 | KB rapida us-west-2 |

---

## 🔐 IAM Roles

| Ruolo | Scopo |
|-------|-------|
| `DemoServerlessAgent-LambdaRole` | Esecuzione Lambda tools |
| `DemoServerlessAgent-AgentRole` | Ruolo dell'agente |
| `DemoServerlessAgent-BedrockRole` | Accesso Bedrock |
| `AmazonBedrockExecutionRoleForAgents_EBJP1BDAUE8` | MyBedrockAgent |
| `AmazonBedrockExecutionRoleForAgents_QE19R9CTJ6L` | DemoAgent |
| `AmazonBedrockExecutionRoleForKnowledgeBase_yt2h9` | Knowledge Base |
| `AmazonBedrockExecutionRoleForKnowledgeBase_Quick` | Quick KB |
| `AWSServiceRoleForBedrockAgentCoreRuntimeIdentity` | **AgentCore abilitato** |
| `AmazonBedrockExecutionRoleForFlows_*` | Bedrock Flows |

---

## 📂 Progetti Locali (Workspace)

### 1. certification-quiz (Web App Quiz — POC completata)
- **Path**: `/Volumes/MAC-USB/certification-quiz/wio-professional-certification-quiz-generator/`
- **Repo**: `https://github.com/LucaDAddeo/kiro-certification-coach.git`
- **Tipo**: Static web app (HTML + CSS + vanilla JS)
- **Deploy**: S3 bucket `kiro-certification-coach` (us-west-2)
- **Contenuto**: Quiz interattivo per AIP-C01, 35 domande AI-generated, 5 domini
- **Struttura**: index.html, quiz.html, results.html, styles.css, js/, data/
- **Spec**: `.kiro/specs/aws-certification-quiz/` (requirements.md, design.md, tasks.md)

### 2. QuizMaker (Pipeline processamento quiz)
- **Path**: `/Volumes/MAC-USB/AWS/AIP-C01/QuizMaker/`
- **Tipo**: Pipeline Kiro-driven + Python scaffolding
- **Contenuto**: 208 domande TutorialsDojo processate (tradotte IT + analisi didattica)
- **Output**: `processed/AIP-C01_Set_1_Processato.md` (75), `Set_2` (75), `Bonus_Set_3` (58)
- **Python pipeline**: parser.py, processor.py, writer.py, models.py, prompts.py
- **Pattern**: Sub-agent delegation + checkpointing + auto-continue hook

### 3. AWS-Subject-Matter-Expert
- **Path**: `/Volumes/MAC-USB/AWS-Subject-Matter-Expert/`
- Da esplorare

### 4. AIP-C01 (Materiale studio)
- **Path**: `/Volumes/MAC-USB/AWS/AIP-C01/`
- Exam guide PDF, domande pratica (eBay), Exam Prep Plan, TutorialsDojo sets

---

## 🔗 Progetto di Riferimento

### anix-the-genai-certification-teacher (Anand Joshi)
- **Repo**: `https://github.com/anandxmj/anix-the-genai-certification-teacher`
- **Tipo**: Agente Kiro CLI per quiz GenAI certification
- **Funzionamento**: Custom agent con knowledge base (exam guide), genera quiz al volo via LLM
- **Features**: Adaptive learning, multiple question types, difficulty levels, domain focus, performance analysis
- **Limitazione**: Solo CLI, solo AIP-C01

---

## 🎯 Piano di Evoluzione

### Fase 1 — POC Agent Locale (Kiro CLI)
- Custom agent Kiro CLI per studio personale
- Knowledge base con: exam guides, domande processate (208 da QuizMaker), AWS docs
- Generazione quiz via LLM basata su KB
- Supporto iniziale: AIP-C01, poi estensibile
- Feedback adattivo basato su livello studente
- Progress tracking locale

### Fase 2 — Web App Cloud-Native Agentica
- **Compute**: Lambda (tools) + Bedrock Agents (orchestrazione)
- **AI**: Bedrock (Nova Pro), Knowledge Base (S3 Vectors), Guardrails
- **Storage**: S3 (frontend + dati), DynamoDB (progress, sessioni)
- **API**: API Gateway (REST)
- **CDN**: CloudFront
- **Auth**: Cognito
- **DNS**: Route 53
- **Orchestrazione**: AgentCore, Bedrock Flows
- **Tools**: AWSDocs, AWSBlog, Wikipedia (esistenti) + QuizGenerator, ExamGuideRetriever, ProgressTracker, QuestionScorer (nuovi)
- **Fonti**: KB (exam guides), AWS Docs, AWS Blog, GitHub, web search

### Tools nuovi da creare
| Tool | Scopo | Lambda |
|------|-------|--------|
| `QuizGenerator` | Genera domande basate su KB + LLM | Nuovo |
| `ExamGuideRetriever` | Cerca nella KB con exam guides per dominio | Nuovo |
| `ProgressTracker` | Salva/legge progresso studio (DynamoDB) | Nuovo |
| `QuestionScorer` | Valuta risposte e genera feedback dettagliato | Nuovo |
| `CertificationCatalog` | Lista certificazioni disponibili con domini/pesi | Nuovo |

---

## 📋 Risorse da creare (non ancora presenti)

| Risorsa | Tipo | Region | Note |
|---------|------|--------|------|
| Cognito User Pool | Auth | us-west-2 | Per la web app |
| DynamoDB Table | Storage | us-west-2 | Progress tracking |
| CloudFront Distribution | CDN | Global | HTTPS per frontend |
| Route 53 Record | DNS | Global | Dominio custom (opzionale) |
| Nuova Knowledge Base | AI | us-west-2 | Con exam guides per certificazioni |
| Nuovo Bedrock Agent | AI | us-west-2 | Certification Coach agent |
| Nuove Lambda (tools) | Compute | us-west-2 | QuizGenerator, Scorer, etc. |

---

## 🔑 Credenziali e Configurazione

### Profili AWS CLI (`~/.aws/config`)
| Profilo | Region | Account |
|---------|--------|---------|
| `default` | us-west-2 | ⚠️ Chiave invalida |
| `Kiro` | us-west-2 | `634848780747` ✅ Funzionante |
| `Luca-Daddeo@577284938472` | us-east-1 | `577284938472` |
| `Luca-Daddeo` | eu-south-1 | — |

### Git
- **Repo**: `https://github.com/LucaDAddeo/kiro-certification-coach.git`
- **Remote configurato** in `/Volumes/MAC-USB/certification-quiz/wio-professional-certification-quiz-generator/`

---

*Questo documento serve come contesto per qualsiasi sessione futura di sviluppo del progetto Certification Coach.*
