# 🎓 AWS Certification Coach — Kiro CLI Custom Agent

An AI-powered study coach for AWS certification preparation, built as a Kiro CLI custom agent with persistent knowledge base, adaptive feedback, and bilingual coaching (Italian conversational, English technical).

**Current focus**: AWS Certified AI Practitioner (AIP-C01). Architecture is extensible to all AWS certifications.

---

## 📋 What This Agent Does

- **Generates exam-realistic quizzes** from a curated Knowledge Base (exam guide + 208 processed TutorialsDojo questions)
- **Adapts explanations** to your skill level per domain (beginner / intermediate / advanced)
- **Tracks your progress** persistently in a local JSON file across sessions
- **Identifies weak areas** and provides targeted study recommendations
- **Explains AWS concepts** using Knowledge Base + AWS documentation + AWS blog + web search
- **Supports multiple question types**: Multiple Choice (1 correct) and Multiple Response (2-3 correct)
- **Coaches bilingually**: Italian for conversation, English for technical terms and exam content

---

## 🔧 Prerequisites

1. **Kiro CLI** installed and configured  
   Install: https://kiro.dev/cli/
2. **Knowledge feature enabled** (experimental — Kiro CLI v1.23.1+)
   ```bash
   kiro-cli settings chat.enableKnowledge true
   ```
3. **Source materials available** on your system:
   - Exam guide: `/Volumes/MAC-USB/AWS/AIP-C01/AIP-C01  - Exam Guide.pdf`
   - Processed questions: `/Volumes/MAC-USB/AWS/AIP-C01/QuizMaker/processed/*.md` (3 files)

---

## 🚀 Quick Start

```bash
# 1. Enable the Knowledge feature (one-time)
kiro-cli settings chat.enableKnowledge true

# 2. Run the setup script (creates symlinks + initializes KB)
cd /Volumes/MAC-USB/kiro-certification-coach
./setup.sh

# 3. Launch the agent
kiro-cli --agent ./agent.json
```

Or, in the Kiro IDE: open the Agents panel and load `agent.json` as a custom agent.

---

## 📂 Project Structure

```
kiro-certification-coach/
├── agent.json                          # Kiro CLI agent configuration
├── system-prompt.md                    # Coaching logic (encoded as LLM instructions)
├── setup.sh                            # Setup script: validates prerequisites, initializes KB
├── README.md                           # This file
├── project-discovery.md                # Full context of the broader project
├── knowledge-feature.md                # Kiro CLI Knowledge feature reference
├── certifications/
│   └── aip-c01/
│       ├── config.json                 # Domain weights, topics, metadata
│       ├── exam-guide.pdf              # (symlink) Official exam guide
│       └── questions/                  # (symlinks) Processed question files
│           ├── AIP-C01_Set_1_Processato.md
│           ├── AIP-C01_Set_2_Processato.md
│           └── AIP-C01_Bonus_Set_3_Processato.md
├── progress/
│   └── progress.json                   # (created at runtime) Persistent progress
└── .kiro/
    └── specs/certification-coach-agent/  # Full spec (requirements, design, tasks)
```

---

## 💬 Available Commands

All commands are used inside the agent chat.

### `/quiz [domain] [difficulty] [count]`

Start a quiz session. All parameters are optional.

- **domain**: Domain ID (1-5) or name (partial match, e.g., `security`, `bedrock`). If omitted, questions are distributed proportionally by exam weights.
- **difficulty**: `beginner` / `intermediate` / `advanced` (abbreviations OK: `b`, `i`, `a`). Default: `intermediate`.
- **count**: Integer 1-50. Default: `10`.

**Examples:**
```
/quiz                       # All domains, intermediate, 10 questions
/quiz 3                     # Only Domain 3 (Security), 10 questions
/quiz security advanced 5   # Security domain, advanced, 5 questions
/quiz beg 20                # All domains, beginner, 20 questions
```

### `/score`

Show current progress: cumulative score, per-domain breakdown, weak areas, sessions completed.

### `/weak`

List weak domains (cumulative average < 75%) with targeted study recommendations.

### `/explain [topic]`

Detailed explanation of any AWS concept, sourced from Knowledge Base + AWS docs + web search. Adapted to your level in the topic's domain.

**Examples:**
```
/explain RAG
/explain Bedrock Knowledge Bases
/explain prompt injection
```

### Free-form questions

You can also ask anything in natural language — the agent detects intent and uses the appropriate tools.

---

## 📊 AIP-C01 Exam Structure

| Domain | Name | Weight |
|--------|------|--------|
| 1 | Fundamentals of Generative AI | 20% |
| 2 | Implementation and Integration | 30% |
| 3 | Security Governance and Responsible AI | 25% |
| 4 | Optimization and Monitoring | 15% |
| 5 | Testing Validation and Troubleshooting | 10% |

- **Passing score**: 75%
- **Total questions**: 85
- **Time limit**: 120 minutes (~1.4 min/question)
- **Question types**: Multiple Choice (4 options, 1 correct) + Multiple Response (5-6 options, 2-3 correct)

See `certifications/aip-c01/config.json` for per-domain topics.

---

## 🔄 Adding a New Certification

The architecture is extensible. To add (for example) SAA-C03:

1. Create `certifications/saa-c03/config.json` with domain weights and topics
2. Create `certifications/saa-c03/questions/` with processed question files (if available)
3. Add the exam guide to `certifications/saa-c03/exam-guide.pdf`
4. Add the materials to the Knowledge Base:
   ```bash
   kiro-cli /knowledge add --name "saa-c03-exam-guide" --path certifications/saa-c03/exam-guide.pdf
   kiro-cli /knowledge add --name "saa-c03-questions" --path certifications/saa-c03/questions
   ```
5. Start a quiz referencing the new certification (the agent will auto-detect the new config)

No code changes needed — only new data files.

---

## 🗂️ Progress Data

Progress is stored in `progress/progress.json`, one file for all certifications. Schema:

```json
{
  "version": "1.0",
  "student_id": "default",
  "certifications": {
    "aip-c01": {
      "sessions": [...],
      "cumulative": {...},
      "last_updated": "ISO 8601"
    }
  }
}
```

- **Persisted locally only** — never transmitted over the network
- Corrupted files are automatically backed up and regenerated
- Multi-certification support built in

---

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| `Knowledge feature not enabled` | Run `kiro-cli settings chat.enableKnowledge true` |
| `Command not found: kiro-cli` | Install Kiro CLI from https://kiro.dev/cli/ |
| `Source file missing` during setup | Verify USB drive is mounted and AIP-C01 materials are at the expected paths |
| Agent gives outdated answers | Re-run `setup.sh` to refresh KB content; use `/explain` to cross-reference with AWS docs |
| `Invalid model ID` error | Edit `agent.json` and change `"model"` to a supported value (e.g., `"auto"`) |
| Progress not persisting | Check `progress/progress.json` exists and is writable; check for `.backup-*` files indicating corruption |
| Quiz generation produces odd questions | KB coverage may be limited for that domain; the agent will flag this and use AWS docs as fallback |

---

## 🧭 Design Principles

- **Configuration-only**: No compiled code. All logic is in `system-prompt.md` as natural language instructions.
- **Symlinks over copies**: Exam materials stay in their original locations to avoid duplication.
- **Local-first**: All data (progress, KB) stays on your machine.
- **Bilingual by design**: Italian coaching reduces cognitive load; English for technical content preserves exam fidelity.
- **Adaptive**: Difficulty of explanation tracks your demonstrated skill per domain.
- **Extensible**: Adding a certification = adding data files, no code changes.

---

## 📚 References

- **Spec**: `.kiro/specs/certification-coach-agent/` (requirements.md, design.md, tasks.md)
- **Context**: `project-discovery.md`
- **Kiro CLI docs**: https://kiro.dev/docs/cli/
- **Kiro CLI custom agents**: https://kiro.dev/docs/cli/custom-agents/configuration-reference/
- **AIP-C01 official**: https://aws.amazon.com/certification/certified-generative-ai-developer-professional
- **Reference project**: [anix-the-genai-certification-teacher](https://github.com/anandxmj/anix-the-genai-certification-teacher) by Anand Joshi

---

## 🛣️ Roadmap

- ✅ **Phase 1 (current)**: Local Kiro CLI agent for AIP-C01
- 🔜 **Phase 2**: Cloud-native web app (Bedrock Agents + AgentCore + Knowledge Base + API Gateway + Lambda + CloudFront + Cognito)
- 🔜 **Phase 3**: Multi-certification coverage (SAA-C03, DVA-C02, GenAI Developer Professional, etc.)
- 🔜 **Phase 4**: Collaborative features (team study groups, shared progress)

See `project-discovery.md` for the full architectural plan.

---

*AWS Certification Coach — built with Kiro*
