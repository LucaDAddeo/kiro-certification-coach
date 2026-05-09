# Implementation Plan: Certification Coach Agent

## Overview

Create a Kiro CLI custom agent that serves as an AI-powered AWS certification coach. The implementation consists of configuration files (JSON, Markdown, Bash) — no compiled code. The system prompt encodes all coaching logic as natural language instructions to the LLM. The agent targets the AWS Certified AI Practitioner (AIP-C01) exam with an extensible architecture for additional certifications.

## Tasks

- [x] 1. Set up directory structure and placeholder files
  - [x] 1.1 Create the workspace directory structure
    - Create `certifications/aip-c01/questions/` directory
    - Create `progress/` directory with `.gitkeep`
    - This establishes the file layout for all subsequent tasks
    - _Requirements: 1.4, 6.1, 6.3_

- [x] 2. Create certification configuration
  - [x] 2.1 Create `certifications/aip-c01/config.json`
    - Define all 5 domains with weights summing to 100 (Fundamentals 20%, Implementation 30%, Security 25%, Optimization 15%, Testing 10%)
    - Include topics list per domain, question types, difficulty levels, passing score (75%), exam metadata
    - Follow the exact schema from the design document's Certification Configuration section
    - _Requirements: 6.2, 6.3, 3.2, 3.5_

- [x] 3. Create agent configuration
  - [x] 3.1 Create `agent.json`
    - Define agent name, description, prompt path (`./system-prompt.md`), model (`claude-sonnet`)
    - Declare `allowedTools`: knowledge_search, web_search, aws_docs_search, aws_blog_search
    - Set `includeMcpJson: true` to inherit workspace MCP servers
    - Include Italian welcome message with available commands
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 8.1, 8.2, 8.3, 8.4_

- [x] 4. Create the system prompt (core coaching logic)
  - [x] 4.1 Write `system-prompt.md` — Identity, Persona, and Language Rules
    - Define bilingual behavior: Italian for coaching/conversation, English for technical terms and exam content
    - Establish the coaching persona: supportive, knowledgeable, adaptive
    - Reference `certifications/aip-c01/config.json` for domain context
    - _Requirements: 1.2, 7.6, 4.4, 4.5_

  - [x] 4.2 Write `system-prompt.md` — Command Handling section
    - Define parsing logic for `/quiz [domain] [difficulty] [count]` with defaults (all domains, intermediate, 10)
    - Define `/score` command to display progress summary
    - Define `/weak` command to show weak areas with recommendations
    - Define `/explain [topic]` command for concept explanations
    - Define free-form question handling
    - Include parameter validation rules and abbreviation support
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [x] 4.3 Write `system-prompt.md` — Quiz Generation Protocol
    - Encode domain-weighted question distribution algorithm: `round(N * weight / 100)` with adjustment
    - Define question format rules: MC (4 options, 1 correct) and MR (5-6 options, 2-3 correct)
    - Instruct one-at-a-time presentation with wait for student response
    - Define KB search strategy for finding relevant questions/concepts per domain
    - Support configurable difficulty and domain filtering
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

  - [x] 4.4 Write `system-prompt.md` — Scoring and Adaptive Feedback Protocol
    - Define score calculation: `total_score = (correct / total) * 100`, per-domain scores
    - Define pass/fail threshold at 75%
    - Encode adaptive explanation depth: beginner (<50%), intermediate, advanced (>85%)
    - Define correct-answer feedback format (confirm + explain concept)
    - Define incorrect-answer feedback format (explain why wrong + why correct + AWS concepts)
    - Define end-of-quiz summary format with recommendations
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

  - [x] 4.5 Write `system-prompt.md` — Progress Management Protocol
    - Define `progress/progress.json` schema and read/write instructions
    - Encode session recording: date, certification, domains, scores, difficulty, count
    - Encode cumulative stats update: totals, averages, weak area identification
    - Define weak area threshold: domain average < 75%
    - Handle first-run case (create file if not exists)
    - Handle corrupted file case (backup and restart)
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

  - [x] 4.6 Write `system-prompt.md` — Tool Usage Guidelines
    - Define priority order: Knowledge Base > AWS Docs > Web Search
    - Instruct KB search as primary source for exam-specific content
    - Define when to use web search (current info, recent announcements)
    - Define when to use AWS docs search (official service documentation)
    - _Requirements: 8.4, 8.5_

- [x] 5. Checkpoint - Review system prompt completeness
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Create setup automation
  - [x] 6.1 Create `setup.sh` — Knowledge Base initialization script
    - Add shebang and `set -e` for fail-fast
    - Validate Knowledge feature is enabled (check `kiro-cli settings`)
    - Validate source files exist (exam guide PDF, question markdown files)
    - Create symlinks for exam materials from source locations:
      - Exam guide: `/Volumes/MAC-USB/AWS/AIP-C01/AIP-C01  - Exam Guide.pdf` → `certifications/aip-c01/exam-guide.pdf`
      - Questions: `/Volumes/MAC-USB/AWS/AIP-C01/QuizMaker/processed/*.md` → `certifications/aip-c01/questions/`
    - Initialize KB with `kiro-cli /knowledge add` commands
    - Display clear error messages with remediation steps on failure
    - Make script executable (`chmod +x`)
    - _Requirements: 9.1, 9.4, 9.5, 2.1, 2.2, 2.3, 2.4_

- [x] 7. Create documentation
  - [x] 7.1 Create `README.md` with usage instructions
    - Document prerequisites (Kiro CLI, Knowledge feature enabled)
    - Document setup steps (run `setup.sh`)
    - Document available commands with examples
    - Document the multi-certification extensibility approach
    - Include troubleshooting section for common issues
    - _Requirements: 9.2, 9.3_

- [x] 8. Wire components together and validate
  - [x] 8.1 Link exam materials into the workspace
    - Create symlinks from source locations to `certifications/aip-c01/`
    - Verify symlinks resolve correctly
    - Ensure all paths referenced in `config.json` and `setup.sh` are consistent
    - _Requirements: 2.1, 2.2, 2.5_

  - [x] 8.2 Validate all file cross-references
    - Verify `agent.json` → `system-prompt.md` path resolves
    - Verify `system-prompt.md` references to `certifications/aip-c01/config.json` are correct
    - Verify `system-prompt.md` references to `progress/progress.json` are correct
    - Verify `setup.sh` source file paths exist
    - Verify `config.json` `knowledge_base_sources` paths match actual file locations
    - _Requirements: 1.1, 1.2, 9.5_

- [x] 9. Final checkpoint - Validate agent is ready to use
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- This is a configuration-only project — no compiled code, no build step, no traditional tests
- The system prompt (task 4) is the most complex deliverable and encodes all coaching logic as LLM instructions
- Symlinks are preferred over copies to avoid data duplication across the USB drive
- The agent should work immediately after running `setup.sh` — no additional configuration needed
- Task 4 subtasks (4.1–4.6) build the system prompt incrementally; each section can be appended to the same file
- Validation in task 8 is manual file inspection, not automated testing

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["2.1", "3.1"] },
    { "id": 2, "tasks": ["4.1"] },
    { "id": 3, "tasks": ["4.2", "4.3"] },
    { "id": 4, "tasks": ["4.4", "4.5", "4.6"] },
    { "id": 5, "tasks": ["6.1", "7.1"] },
    { "id": 6, "tasks": ["8.1"] },
    { "id": 7, "tasks": ["8.2"] }
  ]
}
```
