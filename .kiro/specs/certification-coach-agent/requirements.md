# Requirements Document

## Introduction

The Certification Coach Agent is a Kiro CLI custom agent that acts as an AI-powered teacher and coach for AWS certification preparation. It provides interactive quiz sessions, adaptive feedback, progress tracking, and concept explanations using a knowledge base of exam materials. The initial implementation targets the AWS Certified AI Practitioner (AIP-C01) exam, with an extensible architecture supporting additional certifications. The agent communicates bilingually: English for technical terms and exam questions, Italian for conversational coaching.

## Glossary

- **Coach_Agent**: The Kiro CLI custom agent configured as an AWS certification coach
- **Knowledge_Base**: The Kiro CLI Knowledge feature storing exam guides, processed questions, and study materials indexed for semantic search
- **Quiz_Engine**: The component responsible for generating, presenting, and scoring quiz questions
- **Progress_Tracker**: The component responsible for recording and analyzing study performance over time
- **Domain**: A weighted topic area within a certification exam (e.g., "Fundamentals of Generative AI" at 20%)
- **Session**: A single interaction period between the student and the Coach_Agent
- **Weak_Area**: A domain where the student scores below the passing threshold of 75%
- **Question_Pool**: The collection of questions available from the Knowledge_Base for a given certification
- **Difficulty_Level**: The complexity tier of a question (beginner, intermediate, advanced)
- **Passing_Score**: The minimum percentage required to pass the certification exam (75% for AIP-C01)

## Requirements

### Requirement 1: Agent Configuration

**User Story:** As a student, I want a ready-to-use Kiro CLI agent configuration, so that I can start studying immediately without complex setup.

#### Acceptance Criteria

1. THE Coach_Agent SHALL be defined as a JSON configuration file compatible with Kiro CLI custom agent format.
2. THE Coach_Agent SHALL include a system prompt that defines the coaching persona, bilingual behavior, and interaction capabilities.
3. THE Coach_Agent SHALL declare tool integrations for web search, AWS documentation search, AWS blog search, and Knowledge_Base semantic search.
4. THE Coach_Agent SHALL be stored at a path within the workspace that Kiro CLI recognizes for custom agents.

### Requirement 2: Knowledge Base Setup

**User Story:** As a student, I want exam materials indexed in a searchable knowledge base, so that the agent can generate relevant questions and provide accurate explanations.

#### Acceptance Criteria

1. THE Knowledge_Base SHALL index the AIP-C01 exam guide PDF as a source document.
2. THE Knowledge_Base SHALL index the 208 processed questions from the QuizMaker pipeline (3 markdown files in the processed directory).
3. THE Knowledge_Base SHALL use the semantic index type for context-aware retrieval of exam content.
4. THE Knowledge_Base SHALL be isolated to the Coach_Agent, preventing conflicts with other agents.
5. WHEN a new certification is added, THE Knowledge_Base SHALL accept additional source documents without affecting existing indexed content.

### Requirement 3: Quiz Generation

**User Story:** As a student, I want to take quizzes that reflect the actual exam structure, so that I can practice under realistic conditions.

#### Acceptance Criteria

1. WHEN the student requests a quiz, THE Quiz_Engine SHALL generate questions based on content retrieved from the Knowledge_Base.
2. WHEN no domain is specified, THE Quiz_Engine SHALL select questions with domain-weighted distribution proportional to exam weights (Fundamentals 20%, Implementation 30%, Security 25%, Optimization 15%, Testing 10%).
3. WHEN a specific domain is specified, THE Quiz_Engine SHALL generate questions exclusively from that domain.
4. THE Quiz_Engine SHALL support configurable question count (default: 10 questions per quiz).
5. THE Quiz_Engine SHALL support configurable difficulty levels (beginner, intermediate, advanced).
6. THE Quiz_Engine SHALL generate Multiple Choice questions with exactly 1 correct answer and 3 distractors.
7. THE Quiz_Engine SHALL generate Multiple Response questions with 2 or 3 correct answers out of 5 or 6 options.
8. THE Quiz_Engine SHALL present questions one at a time and wait for the student response before proceeding.

### Requirement 4: Adaptive Feedback

**User Story:** As a student, I want detailed explanations after each answer, so that I can understand concepts deeply rather than just memorizing answers.

#### Acceptance Criteria

1. WHEN the student answers a question correctly, THE Coach_Agent SHALL confirm the answer and explain the underlying AWS concept.
2. WHEN the student answers a question incorrectly, THE Coach_Agent SHALL explain why the selected answer is wrong and why the correct answer is right, referencing specific AWS services or concepts.
3. WHEN a quiz is completed, THE Coach_Agent SHALL display a performance summary including: total score percentage, score per domain, pass/fail status against the 75% threshold, and specific recommendations for improvement.
4. WHILE the student demonstrates beginner-level understanding (scoring below 50% in a domain), THE Coach_Agent SHALL use simplified explanations with analogies and foundational concepts.
5. WHILE the student demonstrates advanced understanding (scoring above 85% in a domain), THE Coach_Agent SHALL provide deeper technical details and edge-case scenarios in explanations.
6. WHEN a quiz is completed, THE Coach_Agent SHALL proactively suggest a follow-up action (e.g., review weak areas, try a harder difficulty, focus on a specific domain).

### Requirement 5: Progress Tracking

**User Story:** As a student, I want my study progress saved between sessions, so that I can track improvement over time and focus on weak areas.

#### Acceptance Criteria

1. THE Progress_Tracker SHALL store progress data in a JSON file within the workspace directory.
2. WHEN a quiz is completed, THE Progress_Tracker SHALL record: date, certification, domains tested, score per domain, total score, difficulty level, and number of questions.
3. THE Progress_Tracker SHALL maintain cumulative statistics: total questions answered per domain, average score per domain, overall average score, and number of sessions completed.
4. THE Progress_Tracker SHALL identify weak areas as domains where the cumulative average score is below 75%.
5. WHEN the student requests progress information, THE Progress_Tracker SHALL display current scores per domain, improvement trends, and identified weak areas.
6. THE Progress_Tracker SHALL persist data across Kiro CLI sessions without data loss.

### Requirement 6: Multi-Certification Architecture

**User Story:** As a student preparing for multiple AWS certifications, I want the agent to support different exams, so that I can use the same tool for all my certification goals.

#### Acceptance Criteria

1. THE Coach_Agent SHALL organize certification data with separate Knowledge_Base entries per certification.
2. THE Coach_Agent SHALL define the AIP-C01 certification with 5 domains: Fundamentals of Generative AI (20%), Implementation and Integration (30%), Security Governance and Responsible AI (25%), Optimization and Monitoring (15%), Testing Validation and Troubleshooting (10%).
3. THE Coach_Agent SHALL store domain names and weights in a configuration structure that allows adding new certifications without modifying existing code.
4. WHEN a new certification is added, THE Coach_Agent SHALL require only new Knowledge_Base entries and a domain configuration, reusing the existing Quiz_Engine and Progress_Tracker logic.

### Requirement 7: Interaction Commands

**User Story:** As a student, I want clear commands to control the agent, so that I can efficiently navigate between quizzing, reviewing progress, and learning concepts.

#### Acceptance Criteria

1. WHEN the student sends `/quiz [domain] [difficulty] [count]`, THE Coach_Agent SHALL start a quiz session with the specified parameters (all parameters optional, using defaults when omitted).
2. WHEN the student sends `/score`, THE Coach_Agent SHALL display the current progress summary from the Progress_Tracker.
3. WHEN the student sends `/weak`, THE Coach_Agent SHALL display identified weak areas with specific study recommendations for each.
4. WHEN the student sends `/explain [topic]`, THE Coach_Agent SHALL provide a detailed explanation of the specified AWS concept using Knowledge_Base content and supplementary web search results.
5. WHEN the student sends a free-form question about AWS services, THE Coach_Agent SHALL answer using Knowledge_Base content, AWS documentation search, and web search as needed.
6. THE Coach_Agent SHALL respond to commands and coaching in Italian, while keeping technical terms, exam questions, and answer options in English.

### Requirement 8: Tools Integration

**User Story:** As a student, I want the agent to access current AWS information, so that explanations reflect the latest services and best practices.

#### Acceptance Criteria

1. THE Coach_Agent SHALL integrate web search capability for retrieving current AWS information not present in the Knowledge_Base.
2. THE Coach_Agent SHALL integrate AWS documentation search for official service documentation references.
3. THE Coach_Agent SHALL integrate AWS blog search for recent announcements and best practice articles.
4. THE Coach_Agent SHALL use Knowledge_Base semantic search as the primary source for exam-specific content retrieval.
5. WHEN answering a question or providing an explanation, THE Coach_Agent SHALL prioritize Knowledge_Base content over web search results for exam-specific topics.

### Requirement 9: Setup Automation

**User Story:** As a student, I want an automated setup process, so that I can get the agent running with minimal manual configuration.

#### Acceptance Criteria

1. THE Coach_Agent SHALL include a setup script that initializes the Knowledge_Base with the AIP-C01 exam guide and processed question files.
2. THE Coach_Agent SHALL include documentation with step-by-step instructions for enabling the Kiro CLI Knowledge experimental feature.
3. THE Coach_Agent SHALL include a ready-to-use agent configuration file that requires no modification for basic operation.
4. IF the Knowledge feature is not enabled in Kiro CLI, THEN THE Coach_Agent SHALL display a clear error message with instructions to enable it.
5. THE setup script SHALL validate that required source files (exam guide PDF, processed question markdown files) exist before attempting Knowledge_Base initialization.
