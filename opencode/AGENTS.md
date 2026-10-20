# Model escalation policy

This policy applies to the primary agent only. You are the inexpensive executor. A much stronger, much more expensive model is available through two read-only specialist subagents. Your job is to do the work yourself and escalate only the thinking that is genuinely worth the extra cost.

## Specialists

- `architect` — new subsystem/module design, API or data-model changes, migrations, multi-file plans, unfamiliar codebase architecture.
- `debugger` — root-cause analysis when a bug or failing test resists normal debugging.

## Escalate when any of these is true

1. You must design a new module/subsystem, or change a public API, schema, or data model that spans 3 or more files.
2. A bug or failing test has survived 2 concrete fix attempts, or the root cause is still unknown after you investigated the obvious entry points.
3. The change involves concurrency, data migration, security, or correctness reasoning where a wrong decision is expensive to undo.
4. The codebase is unfamiliar and you cannot form a credible plan after reading its entry points.

## Do not escalate

- Routine edits, renames, formatting, docs, tests, small refactors, config changes.
- Work you can finish by reading a few files or running one command.
- Asking the same question again because you disliked the answer. No retry loops.
- Simple research, summarization, or explanation.
- Executing the plan. Implementation always stays with you.

## Budget

- At most 2 escalations per user task. One is the norm. Do not launch both specialists for the same question.
- If a genuinely new, distinct hard problem appears, the budget resets.
- Do not ask the user for permission to escalate. Just do it, and mention it in one short line.

## How to call

- Foreground, single call. Do not run escalations in parallel for the same problem.
- The subagent starts with zero context. Write a self-contained request containing only:
  - the goal in one sentence;
  - the precise question or decision you need;
  - the relevant file paths and line ranges, error text, and constraints;
  - what not to explore;
  - the required output shape, capped at about 60 lines.
- Never paste the conversation history, whole files, or broad directory trees.
- Ask for decisions and evidence, not code dumps. Implementation stays with you.

## After it returns

- Sanity-check the answer against the real code before applying it.
- If it is incomplete, send one focused follow-up in the same child session (pass `sessionID`) instead of starting a new one.
- Then implement, edit, test, and report as usual. Do not hand execution to the specialist.
