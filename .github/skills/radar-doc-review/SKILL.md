---
name: radar-doc-review
description: Manually invoked documentation reviewer. Do NOT load this skill automatically. Only load when the user explicitly runs /radar-doc-review. Reviews documentation files for correct format, style guide compliance, and content quality.
---

# Documentation Review Skill

## Purpose

Review documentation files against the project's style guide, doc-type format requirements, and the established example doc.

## Invocation

This skill is manually invoked only via `/radar-doc-review`. Do not auto-load this skill based on context.

---

## Step-by-Step Review Process

### Step 1 — Read the Reference Files

Before doing anything else, read these three files in full:

1. **Style guide**: `/docs/style-guide` for `.md` files in all directories.
2. **Example doc**: `/content/hcp-docs/content/docs/vault-radar/get-started/add-data-source/slack.mdx`
   - This is a generally well-formatted doc. Note its frontmatter fields, heading hierarchy, tone, code block usage, admonition style, link formatting, and overall structure.

Do not proceed until you have read both files.

### Step 2 — Identify the Doc Type

Determine which of the four doc types the file belongs to:

| Doc Type | Primary Goal | Audience Assumption |
|---|---|---|
| **Tutorial / Get Started** | Guide a new user to a working outcome end-to-end | No prior knowledge assumed |
| **How-to Guide** | Help a practitioner complete a specific task | Some prior knowledge assumed |
| **Conceptual / Overview** | Explain what something is and why it exists | Curious, not necessarily doing a task |
| **Reference** | Provide complete, structured, scannable facts | User knows what they're looking for |

If you cannot determine the doc type from the file content or frontmatter, ask the user before continuing.

### Step 3 — Check Format for the Doc Type

Use the checklist for the identified doc type below. Use the slack.mdx example as a concrete model for what correct formatting looks like.

#### Tutorial / Get Started

- [ ] Frontmatter includes: `title`, `description`, and any required metadata per the style guide
- [ ] Starts with a brief intro explaining what the user will accomplish and any prerequisites
- [ ] Numbered steps throughout — no bullet points for procedural content
- [ ] Step numbers render in the correct order. If steps under a single section reset to 1, identify the offending component that is not indented properly.
- [ ] Each step has exactly one action; compound steps are split unless it is navigating a menu with multiple levels.
- [ ] Ends with a "Next steps" or "What's next" section

#### How-to Guide

- [ ] Frontmatter includes: `title`, `description`, and any required metadata
- [ ] Title follows "How to [verb] [noun]" pattern or equivalent
- [ ] Brief intro states the goal and any prerequisites
- [ ] Numbered steps for any procedural content
- [ ] Does not over-explain concepts — stays task-focused
- [ ] Optional but encouraged: troubleshooting section at the end

#### Conceptual / Overview

- [ ] Frontmatter includes: `title`, `description`, and any required metadata
- [ ] Opens with a clear definition or "what is X" statement
- [ ] Uses prose paragraphs, not numbered steps
- [ ] Explains *why* something exists or works the way it does
- [ ] Links to related tutorials or how-to guides for hands-on follow-up
- [ ] Does not include step-by-step instructions (those belong in tutorials/how-tos)

#### Reference

- [ ] Frontmatter includes: `title`, `description`, and any required metadata
- [ ] Highly structured: uses consistent heading hierarchy and tables where applicable
- [ ] Each item/entry is complete and self-contained
- [ ] No prose narrative — scannable by design
- [ ] Parameters, flags, or fields include: name, type, required/optional, description, and default value (where applicable)
- [ ] No tutorial-style steps or conceptual explanations inline

#### All Doc Types (universal checks)

- [ ] Heading hierarchy is correct: H1 → H2 → H3, no skipped levels
- [ ] Code blocks have a language identifier (` ```bash `, ` ```hcl `, ` ```json `, etc.)
- [ ] No orphaned H1s — only one H1 per file (the page title)
- [ ] Images (if any) have descriptive alt text
- [ ] Links use the correct format per the style guide (relative vs. absolute)
- [ ] Admonitions/callouts use the correct syntax and are used appropriately (note, warning, tip)
- [ ] No broken links or references to non-existent sections
- [ ] Optimized for SEO including action oriented headings, titles, and descriptions

### Step 4 — Check Style Guide Compliance

Using the style guide you read in Step 1, check for:

- **Voice and tone**: Second person ("you"), active voice, present tense where possible
- **Terminology**: Flag any terms the style guide marks as preferred, avoided, or with specific casing
- **UI element formatting**: Bold for UI labels (e.g., **Save**), code formatting for commands, values, and file paths
- **Capitalization**: Sentence case for headings unless the style guide specifies otherwise
- **Sentence length**: Flag sentences over ~30 words as candidates for splitting
- **Oxford commas** and any other punctuation rules called out in the style guide
- **Inclusive language**: Flag any terms the style guide identifies as non-inclusive

### Step 5 — Compare to the Example Doc

With the slack.mdx example in mind, note any structural or stylistic patterns present in the example that are missing or handled differently in the file under review. Call these out explicitly.

---

## Scoring System

Calculate a weighted score out of 100% based on three categories:

### Content Quality (50% of total score)

- Accuracy and completeness of information
- Clear, logical flow and structure
- Appropriate level of detail for the doc type
- Correct procedural steps (if applicable)
- Useful examples and context

### Format Compliance (40% of total score)

- Doc type format checklist adherence
- Heading hierarchy and structure
- Code block formatting and language identifiers
- Image alt text and formatting
- Link formatting and validity
- Component usage (admonitions, tabs, etc.)
- Frontmatter completeness

### SEO & Discoverability (10% of total score)

- Action-oriented, descriptive headings
- Optimized page title and description
- Appropriate keyword usage
- Scannable structure

**Scoring guidance:**

- **90-100%**: Ready to publish with no changes
- **75-89%**: Ready for review, minor fixes needed
- **60-74%**: Needs revision before review
- **Below 60%**: Work required before review

**Minimum threshold**: Documents must score **75% or higher** to proceed to formal review.

---

## Output Format

Return your review as a structured report with the following sections:

### 📄 Doc Info
- **File**: `[filename]`
- **Doc type identified**: `[type]`
- **Style guide path read**: `[path]`

### 📊 Quality Score

**Overall Score: [XX]%** — [Ready to publish / Ready for review / Needs revision / Significant work required]

| Category | Score | Weight | Weighted Score |
|---|---|---|---|
| Content Quality | [XX/100] | 50% | [XX/50] |
| Format Compliance | [XX/100] | 40% | [XX/40] |
| SEO & Discoverability | [XX/100] | 10% | [XX/10] |
| **Total** | | | **[XX/100]** |

**Status**: [✅ Passes 75% threshold / ❌ Below 75% threshold — not ready for review]


### ✅ What Looks Good
List what the doc does correctly — be specific, not generic.

### ⚠️ Issues Found
For each issue, provide:

| # | Location | Issue | Rule / Convention | Suggested Fix |
|---|---|---|---|---|
| 1 | [heading or line ref] | [what's wrong] | [style guide rule or format checklist item] | [how to fix it] |

If there are no issues, say so explicitly.

### 📋 Overall Assessment

One short paragraph: is this doc **ready to publish**, **needs minor fixes**, or **needs significant revision**? Include the top 1–2 priorities if fixes are needed.

---

## Behavioral Rules

- Do not rewrite the entire document unless the user explicitly asks.
- If the style guide and the slack.mdx example appear to contradict each other, flag the conflict and do not guess which takes precedence.
- If the style guide is silent on something, note the gap rather than inventing a rule.
- If the doc type is ambiguous (e.g., a hybrid tutorial/reference), flag this and apply the checklist for the closest match.
- Ask before making large edits — default to reporting and suggesting, not rewriting.
