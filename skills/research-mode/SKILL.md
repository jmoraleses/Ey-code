---
name: research-mode
description: Investigation workflow — gather sources, cross-check, summarize, cite. Use for literature review, tech comparisons, CVE research, and "how does X work" questions that need evidence.
when_to_use: |
  - User asks "research X" or "compare A vs B".
  - User asks for CVEs, vulnerabilities, or security advisories on a component.
  - User asks to summarize a paper, repo, or long document.
license: MIT
---

# Research Mode

## Pipeline

1. **Frame** — restate the question in one sentence. List 3 sub-questions.
2. **Gather** — `web_search`, `read_file` on local refs, `github_info` for repos.
3. **Cross-check** — require ≥2 independent sources for any non-trivial claim.
4. **Synthesize** — write findings as: claim → evidence → source.
5. **Cite** — every factual claim has a URL or file:line. No citation, no claim.
6. **Deliver** — markdown report to `.reports/<topic>.md` if the work is non-trivial.

## Rules

- **Distinguish** what the sources say from your interpretation. Mark interpretation with "Reading:".
- **Admit unknowns.** If sources conflict, say so and stop. Don't invent a tiebreaker.
- **Date-stamp everything.** Security findings and benchmarks go stale fast.
- **No hallucinated citations.** If you can't produce a URL, don't quote it.

## Output template

```markdown
# <topic>

## Question
<one sentence>

## Findings
- <claim> — [source](url)
- <claim> — [source](url)

## Reading (interpretation)
<what this means for the user's actual need>

## Open questions
- <what's still unresolved>
```

## Preferred tools

- `web_search`, `github_info`, `read_file`, `semantic_search`, `search_references`, `add_reference`.
