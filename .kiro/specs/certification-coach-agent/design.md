# Design Document: Certification Coach Agent

## Introduction

This document describes the architecture and design of the Certification Coach Agent — a Kiro CLI custom agent that serves as an AI-powered teacher for AWS certification preparation. The agent is configured entirely through static files (JSON config, markdown system prompt, shell script) and leverages Kiro CLI's built-in Knowledge feature for persistent semantic search over exam materials.

The design targets Phase 1 (POC Agent Locale): a local CLI agent for personal study, initially supporting the AWS Certified AI Practitioner (AIP-C01) exam with an extensible architecture for additional certifications.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Kiro CLI Runtime                          │
│                                                              │
│  ┌──────────────┐    ┌──────────────────────────────────┐   │
│  │  agent.json  │───▶│         LLM Engine                │   │
│  │  (config)    │    │  (system-prompt.md loaded)         │   │
│  └──────────────┘    └──────────┬───────────────────────┘   │
│                                  │                            │
│         ┌────────────────────────┼────────────────────┐      │
│         │                        │                    │      │
│         ▼                        ▼                    ▼      │
│  ┌─────────────┐    ┌──────────────────┐    ┌────────────┐  │
│  │  Knowledge  │    │   MCP Servers    │    │  Progress  │  │
│  │    Base     │    │  (web, aws docs) │    │   Tracker  │  │
│  │  (semantic) │    └──────────────────┘    │  (JSON)    │  │
│  └─────────────┘                            └────────────┘  │
│         │                                          │         │
│         ▼                                          ▼         │
│  ~/.aws/amazonq/                          progress/          │
│  knowledge_bases/                         progress.json      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    File System (Workspace)                    │
│                                                              │
│  agent.json              — Agent configuration               │
│  system-prompt.md        — Coaching persona & logic          │
│  setup.sh                — KB initialization script          │
│  certifications/                                             │
│    └── aip-c01/                                              │
│        ├── config.json   — Domain weights, metadata          │
│        ├── exam-guide.pdf                                    │
│        └── questions/    — Processed question files (.md)    │
│  progress/                                                   │
│    └── progress.json     — Persistent progress data          │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Agent Configuration (`agent.json`)

The entry point for the Kiro CLI custom agent. Defines the agent identity, prompt source, tool integrations, and MCP server connections.

```json
{
  "name": "certification-coach",
  "description": "AWS Certification Coach - AI-powered teacher for exam preparation",
  "prompt": "./system-prompt.md",
  "tools": [],
  "allowedTools": [
    "knowledge_search",
    "web_search",
    "aws_docs_search",
    "aws_blog_search"
  ],
  "mcpServers": {},
  "resources": [],
  "hooks": [],
  "includeMcpJson": true,
  "model": "claude-sonnet",
  "welcomeMessage": "🎓 Ciao! Sono il tuo Coach per le certificazioni AWS.\n\nComandi disponibili:\n- /quiz [dominio] [difficoltà] [numero] — Inizia un quiz\n- /score — Mostra il tuo progresso\n- /weak — Mostra le aree deboli\n- /explain [argomento] — Spiega un concetto AWS\n\nCon quale certificazione vuoi iniziare? (default: AIP-C01)"
}
```

**Design decisions:**
- `prompt` references an external markdown file for maintainability (system prompts are long)
- `includeMcpJson` is `true` to inherit workspace-level MCP server configurations
- `allowedTools` declares the tool categories the agent can use
- `model` uses Claude Sonnet for strong reasoning on quiz generation and explanations

### 2. System Prompt (`system-prompt.md`)

The system prompt is the core "logic" of the agent. It defines:

**Sections:**
1. **Identity & Persona** — Bilingual coach (Italian conversational, English technical)
2. **Certification Context** — Loaded from `certifications/aip-c01/config.json`
3. **Command Handling** — Parsing logic for `/quiz`, `/score`, `/weak`, `/explain`
4. **Quiz Generation Protocol** — How to generate questions from KB content
5. **Scoring & Feedback Protocol** — How to calculate scores and adapt explanations
6. **Progress Management Protocol** — How to read/write `progress/progress.json`
7. **Tool Usage Guidelines** — Priority order: KB > AWS Docs > Web Search

**Key behavioral rules encoded in the prompt:**
- Questions are presented one at a time; wait for student response
- After each answer, provide immediate feedback with explanation
- At quiz end, compute scores and update progress file
- Adapt explanation depth based on student's domain score history
- Always reference specific AWS services/concepts in explanations

### 3. Certification Configuration (`certifications/aip-c01/config.json`)

```json
{
  "certification_id": "aip-c01",
  "name": "AWS Certified AI Practitioner",
  "code": "AIP-C01",
  "passing_score": 75,
  "total_questions_exam": 85,
  "time_limit_minutes": 120,
  "domains": [
    {
      "id": 1,
      "name": "Fundamentals of Generative AI",
      "weight": 20,
      "topics": [
        "Foundation models",
        "Large Language Models",
        "Transformer architecture",
        "Training and fine-tuning",
        "Prompt engineering"
      ]
    },
    {
      "id": 2,
      "name": "Implementation and Integration",
      "weight": 30,
      "topics": [
        "Amazon Bedrock",
        "Amazon SageMaker",
        "RAG patterns",
        "Agent architectures",
        "API integration"
      ]
    },
    {
      "id": 3,
      "name": "Security Governance and Responsible AI",
      "weight": 25,
      "topics": [
        "Data privacy",
        "Model governance",
        "Guardrails",
        "Bias detection",
        "Compliance frameworks"
      ]
    },
    {
      "id": 4,
      "name": "Optimization and Monitoring",
      "weight": 15,
      "topics": [
        "Model evaluation metrics",
        "Cost optimization",
        "Performance tuning",
        "CloudWatch monitoring",
        "A/B testing"
      ]
    },
    {
      "id": 5,
      "name": "Testing Validation and Troubleshooting",
      "weight": 10,
      "topics": [
        "Model validation",
        "Hallucination detection",
        "Debugging techniques",
        "Load testing",
        "Error handling"
      ]
    }
  ],
  "question_types": ["multiple_choice", "multiple_response"],
  "difficulty_levels": ["beginner", "intermediate", "advanced"],
  "knowledge_base_sources": [
    "certifications/aip-c01/exam-guide.pdf",
    "certifications/aip-c01/questions/"
  ]
}
```

**Design decisions:**
- Domain weights are integers summing to 100 for easy percentage calculation
- Topics list per domain guides the LLM's question generation scope
- `knowledge_base_sources` lists paths relative to workspace root for the setup script
- Configuration is pure data — no logic, enabling new certifications by adding a new JSON file

### 4. Progress Tracking (`progress/progress.json`)

```json
{
  "version": "1.0",
  "student_id": "default",
  "certifications": {
    "aip-c01": {
      "sessions": [
        {
          "date": "2026-01-15T10:30:00Z",
          "difficulty": "intermediate",
          "question_count": 10,
          "total_score": 70,
          "domains_tested": {
            "1": { "correct": 2, "total": 2 },
            "2": { "correct": 2, "total": 3 },
            "3": { "correct": 1, "total": 3 },
            "4": { "correct": 1, "total": 1 },
            "5": { "correct": 1, "total": 1 }
          }
        }
      ],
      "cumulative": {
        "total_questions": 10,
        "total_correct": 7,
        "sessions_completed": 1,
        "domains": {
          "1": { "total_questions": 2, "total_correct": 2, "average_score": 100 },
          "2": { "total_questions": 3, "total_correct": 2, "average_score": 66.67 },
          "3": { "total_questions": 3, "total_correct": 1, "average_score": 33.33 },
          "4": { "total_questions": 1, "total_correct": 1, "average_score": 100 },
          "5": { "total_questions": 1, "total_correct": 1, "average_score": 100 }
        },
        "overall_average_score": 70,
        "weak_areas": [3]
      },
      "last_updated": "2026-01-15T10:45:00Z"
    }
  }
}
```

**Design decisions:**
- `version` field enables future schema migrations
- Sessions array preserves full history for trend analysis
- Cumulative stats are pre-computed on each write to avoid recalculation on read
- `weak_areas` is derived (domains with average < 75%) and cached for quick access
- Domain IDs (integers) are keys, mapping to the certification config
- ISO 8601 timestamps for unambiguous date handling

### 5. Setup Script (`setup.sh`)

```bash
#!/bin/bash
# Certification Coach Agent - Knowledge Base Setup
# This script initializes the Knowledge Base with exam materials

set -e

WORKSPACE_DIR="$(cd "$(dirname "$0")" && pwd)"
CERT_DIR="$WORKSPACE_DIR/certifications/aip-c01"

echo "🎓 Certification Coach Agent - Setup"
echo "======================================"

# Check if Knowledge feature is enabled
if ! kiro-cli settings chat.enableKnowledge 2>/dev/null | grep -q "true"; then
  echo "❌ Error: Knowledge feature is not enabled."
  echo ""
  echo "To enable it, run:"
  echo "  kiro-cli settings chat.enableKnowledge true"
  echo ""
  echo "Then re-run this setup script."
  exit 1
fi

# Validate source files exist
echo "📋 Validating source files..."

if [ ! -f "$CERT_DIR/exam-guide.pdf" ]; then
  echo "❌ Error: Exam guide not found at: $CERT_DIR/exam-guide.pdf"
  exit 1
fi

QUESTION_FILES=$(find "$CERT_DIR/questions" -name "*.md" 2>/dev/null | wc -l)
if [ "$QUESTION_FILES" -eq 0 ]; then
  echo "❌ Error: No question files (.md) found in: $CERT_DIR/questions/"
  exit 1
fi

echo "✅ Found exam guide PDF"
echo "✅ Found $QUESTION_FILES question file(s)"

# Initialize Knowledge Base
echo ""
echo "📚 Initializing Knowledge Base..."

# Add exam guide
echo "  Adding exam guide..."
kiro-cli /knowledge add --name "aip-c01-exam-guide" --path "$CERT_DIR/exam-guide.pdf"

# Add processed questions
echo "  Adding processed questions..."
kiro-cli /knowledge add --name "aip-c01-questions" --path "$CERT_DIR/questions"

echo ""
echo "✅ Knowledge Base initialized successfully!"
echo ""
echo "You can now start the agent with:"
echo "  kiro-cli --agent ./agent.json"
```

**Design decisions:**
- `set -e` for fail-fast behavior on any error
- Validates prerequisites before attempting KB operations
- Clear error messages with remediation instructions
- Uses `kiro-cli /knowledge add` with semantic index (default)
- Separate KB entries per content type for organizational clarity

### 6. Knowledge Base Integration

The Knowledge Base leverages Kiro CLI's built-in `/knowledge` feature:

- **Index type**: Semantic (AI-powered embeddings for context-aware retrieval)
- **Storage**: `~/.aws/amazonq/knowledge_bases/` (managed by Kiro CLI)
- **Isolation**: Agent-specific — the certification-coach agent's KB is separate from other agents
- **Sources**:
  - `aip-c01-exam-guide`: The official exam guide PDF
  - `aip-c01-questions`: Directory of processed question markdown files (208 questions across 3 files)

**Retrieval strategy** (encoded in system prompt):
1. For quiz generation: Search KB with domain-specific queries to find relevant questions/concepts
2. For explanations: Search KB first, then supplement with AWS docs/web search
3. For weak area recommendations: Search KB for topics in the weak domain

## Data Models

### Quiz Session (in-memory, managed by system prompt logic)

```typescript
interface QuizSession {
  certification_id: string;       // e.g., "aip-c01"
  difficulty: "beginner" | "intermediate" | "advanced";
  question_count: number;         // default: 10
  target_domain: number | null;   // null = weighted distribution
  questions: Question[];
  current_index: number;
  answers: Answer[];
}

interface Question {
  id: number;
  type: "multiple_choice" | "multiple_response";
  domain_id: number;
  difficulty: "beginner" | "intermediate" | "advanced";
  stem: string;                   // Question text
  options: Option[];
  correct_answers: number[];      // indices of correct options
  explanation: string;            // Why the correct answer is correct
  aws_concepts: string[];         // Related AWS services/concepts
}

interface Option {
  index: number;
  text: string;
}

interface Answer {
  question_id: number;
  selected: number[];             // indices selected by student
  is_correct: boolean;
  domain_id: number;
}
```

### Progress Data (persisted to JSON)

```typescript
interface ProgressData {
  version: string;
  student_id: string;
  certifications: Record<string, CertificationProgress>;
}

interface CertificationProgress {
  sessions: SessionRecord[];
  cumulative: CumulativeStats;
  last_updated: string;           // ISO 8601
}

interface SessionRecord {
  date: string;                   // ISO 8601
  difficulty: string;
  question_count: number;
  total_score: number;            // percentage 0-100
  domains_tested: Record<string, DomainResult>;
}

interface DomainResult {
  correct: number;
  total: number;
}

interface CumulativeStats {
  total_questions: number;
  total_correct: number;
  sessions_completed: number;
  domains: Record<string, DomainCumulative>;
  overall_average_score: number;
  weak_areas: number[];           // domain IDs with avg < 75%
}

interface DomainCumulative {
  total_questions: number;
  total_correct: number;
  average_score: number;          // percentage 0-100
}
```

### Certification Configuration

```typescript
interface CertificationConfig {
  certification_id: string;
  name: string;
  code: string;
  passing_score: number;          // percentage threshold
  total_questions_exam: number;
  time_limit_minutes: number;
  domains: Domain[];
  question_types: string[];
  difficulty_levels: string[];
  knowledge_base_sources: string[];
}

interface Domain {
  id: number;
  name: string;
  weight: number;                 // percentage, all weights sum to 100
  topics: string[];
}
```

## Interfaces

### Command Parsing (System Prompt Logic)

The system prompt implements command parsing as natural language instructions to the LLM:

| Command | Pattern | Parameters | Defaults |
|---------|---------|------------|----------|
| `/quiz` | `/quiz [domain] [difficulty] [count]` | domain: domain name or ID, difficulty: beginner/intermediate/advanced, count: 1-50 | all domains (weighted), intermediate, 10 |
| `/score` | `/score` | none | — |
| `/weak` | `/weak` | none | — |
| `/explain` | `/explain [topic]` | topic: any AWS concept string | — |

**Parsing rules:**
- Parameters are positional and optional
- Domain can be specified by name (partial match) or ID number
- Difficulty accepts abbreviations: `b`/`beg`, `i`/`int`, `a`/`adv`
- Count must be a positive integer between 1 and 50

### Score Calculation Algorithm

```
total_score = (total_correct / total_questions) * 100

domain_score[d] = (domain_correct[d] / domain_total[d]) * 100

pass_status = total_score >= passing_score (75%)

student_level[d] =
  if domain_cumulative_avg[d] < 50  → "beginner"
  if domain_cumulative_avg[d] >= 85 → "advanced"
  otherwise                         → "intermediate"

weak_areas = [d for d in domains if domain_cumulative_avg[d] < 75]
```

### Domain-Weighted Question Distribution

When no specific domain is requested, questions are distributed proportionally:

```
For a quiz of N questions:
  domain_count[d] = round(N * domain_weight[d] / 100)

Adjustment: if sum(domain_count) != N, add/remove from largest domain
```

Example for N=10, AIP-C01:
- Domain 1 (20%): 2 questions
- Domain 2 (30%): 3 questions
- Domain 3 (25%): 2-3 questions
- Domain 4 (15%): 1-2 questions
- Domain 5 (10%): 1 question

### Progress Update Protocol

When a quiz session completes:

1. **Record session**: Append new `SessionRecord` to `sessions` array
2. **Update cumulative stats**:
   - Increment `total_questions` and `total_correct`
   - Increment `sessions_completed`
   - For each domain tested: update `total_questions`, `total_correct`, recalculate `average_score`
   - Recalculate `overall_average_score`
   - Recompute `weak_areas` (domains with average < 75%)
3. **Write to file**: Serialize entire `ProgressData` to `progress/progress.json`

## Error Handling

| Scenario | Handling |
|----------|----------|
| Knowledge Base not initialized | System prompt instructs agent to suggest running `setup.sh` |
| Progress file doesn't exist | Create with empty structure on first quiz completion |
| Progress file corrupted/invalid JSON | Log warning, create backup, start fresh |
| No questions found for domain | Inform student, suggest different domain or broader quiz |
| Invalid command parameters | Show usage hint with correct syntax |
| KB search returns no results | Fall back to web search, inform student of limited KB coverage |
| Source files missing during setup | Exit with specific error message listing missing files |

## Security Considerations

- No credentials stored in configuration files
- Progress data is local-only (no network transmission)
- Knowledge Base uses Kiro CLI's built-in security model
- Setup script validates file paths to prevent directory traversal
- No user authentication needed (single-user local agent)

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Agent Configuration Schema Validity

For any valid agent configuration file, parsing it as JSON SHALL produce an object containing all required keys (`name`, `description`, `prompt`, `allowedTools`) and the `prompt` field SHALL reference an existing file path.

**Validates: Requirements 1.1**

### Property 2: Domain-Weighted Question Distribution

For any quiz of N questions with no domain filter, and for any certification configuration with domain weights summing to 100, the number of questions assigned to each domain SHALL be within ±1 of the expected count `round(N * weight / 100)`, and the total number of questions SHALL equal exactly N.

**Validates: Requirements 3.2**

### Property 3: Domain Filtering Exclusivity

For any quiz with a specified target domain D, all generated questions SHALL have `domain_id` equal to D, and no question SHALL belong to any other domain.

**Validates: Requirements 3.3**

### Property 4: Question Count Invariant

For any requested question count N (where 1 ≤ N ≤ 50), the generated quiz SHALL contain exactly N questions.

**Validates: Requirements 3.4**

### Property 5: Question Format Structural Validity

For any generated question, if the type is `multiple_choice` then there SHALL be exactly 4 options with exactly 1 correct answer; if the type is `multiple_response` then there SHALL be 5 or 6 options with exactly 2 or 3 correct answers.

**Validates: Requirements 3.6, 3.7**

### Property 6: Score Calculation Correctness

For any set of quiz answers, the computed `total_score` SHALL equal `(total_correct / total_questions) * 100`, each `domain_score` SHALL equal `(domain_correct / domain_total) * 100`, and `pass_status` SHALL be `true` if and only if `total_score >= 75`.

**Validates: Requirements 4.3**

### Property 7: Student Level Classification

For any domain cumulative average score S: if S < 50 the student level SHALL be "beginner"; if S >= 85 the student level SHALL be "advanced"; otherwise the student level SHALL be "intermediate".

**Validates: Requirements 4.4, 4.5**

### Property 8: Progress Record Completeness

For any completed quiz session, the recorded `SessionRecord` SHALL contain all required fields: `date` (valid ISO 8601), `difficulty` (one of beginner/intermediate/advanced), `question_count` (positive integer), `total_score` (0-100), and `domains_tested` (non-empty map with valid domain IDs as keys).

**Validates: Requirements 5.2**

### Property 9: Cumulative Statistics Correctness

For any sequence of N session records, the cumulative `total_questions` SHALL equal the sum of all session question counts, `total_correct` SHALL equal the sum of all session correct answers, `sessions_completed` SHALL equal N, and each domain's `average_score` SHALL equal `(domain_total_correct / domain_total_questions) * 100`.

**Validates: Requirements 5.3**

### Property 10: Weak Area Identification

For any set of domain cumulative scores, the `weak_areas` array SHALL contain exactly those domain IDs where `average_score < 75`, and SHALL NOT contain any domain ID where `average_score >= 75`.

**Validates: Requirements 5.4**

### Property 11: Progress Data Persistence Round-Trip

For any valid `ProgressData` object, serializing it to JSON and then deserializing it back SHALL produce an object equal to the original.

**Validates: Requirements 5.6**

### Property 12: Domain Weights Sum Invariant

For any certification configuration, the sum of all domain `weight` values SHALL equal exactly 100.

**Validates: Requirements 6.2**

### Property 13: Command Parsing Correctness

For any valid command string matching the pattern `/quiz [domain] [difficulty] [count]` or `/explain [topic]`, the parser SHALL extract the correct parameter values; for `/quiz`, omitted parameters SHALL use defaults (all domains, intermediate, 10); for `/explain`, the topic SHALL be the complete text following the command.

**Validates: Requirements 7.1, 7.4**

### Property 14: Setup File Validation

For any set of file paths provided to the setup validation function, the function SHALL return success if and only if all required files exist, and SHALL return a specific error identifying each missing file otherwise.

**Validates: Requirements 9.5**
