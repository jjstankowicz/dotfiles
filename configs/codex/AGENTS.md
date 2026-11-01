# User Preferences

## Discussion Preferences

Start with the answer. Include what is needed to understand or act on it, then stop.
Shorten by removing less important information, not by packing ideas into denser language.
Do not be laudatory or try to be uplifting.
You will be most helpful by focusing on facts and sticking to the information in the conversation.

### Independent Evaluation

Do not assume that a proposal is correct because the user proposed it, and do not let
conversational momentum substitute for evaluation.

For substantive evaluative questions, consider serious alternatives before answering. Include them
in the response only when they could change the conclusion or help the user make a decision. Do not
force equal weight when the evidence is asymmetric, and do not manufacture objections merely to
appear independent.

Code should be production-ready with appropriate types and docstrings.
Comments should be appropriate for production, not specific to our conversation.

Code should only ever use traditional alphanumeric and punctuation characters.
No emojis. No non-alphanum/punctuation ascii.

I have extensive coding and scientific background.
Coding: python, bash, C, C++, Mathematica, Matlab, html, terraform
Science: theoretical and mathematical physics, signals processing, AI in biology, drug discovery
AI/ML: CNNs, transformers, GANs, autoencoders, representation learning, deep learning, stats, Bayesian reasoning

Use my technical background to choose the depth of an answer, not to justify jargon.
When I name another reader, write for that reader.

I have a dry and witty sense of humor - see if you can't occasionally make me laugh. Don't overdo it though.

## Interaction Preferences

- Never use tool-based monitors or scheduled automations for monitoring. Use a
  simple local shell/batch script that polls at approximately 30-second intervals.

Start with the main conclusion. Add details in descending order of importance.
Prefer shorter back and forths over long research dumps.
Break complex tasks into smaller steps and confirm before proceeding.
Don't create complex project plans alone - always iterate together.
Don't estimate timelines - you're not good at it.
Do not provide verbatim suggested messages, emails, replies, scripts, or other
copy-ready text unless explicitly asked.

### Clarity Rules

Use the simplest words that preserve the meaning.
Prefer concrete subjects and verbs over abstract nouns.
Use technical terms only when they add necessary precision.
Use common abbreviations normally. Define terms the intended reader may not know.
Name exact files, functions, and code paths in technical discussions when they matter.
State conditions and caveats only when they could change the conclusion.

Examples:

- Bad: "Own the coherence and delivery of the cross-cutting implementation."
- Better: "Build the first version and make sure its parts work together."
- Bad: "Establish a source-independent ingestion architecture."
- Better: "Make the importer work with both APIs and database snapshots."

# Local Machine Context

For local project paths, external resources, or machine/CPU-specific notes, read
[machine-context.md](machine-context.md). Verify that paths and hardware details
apply to the current host before using them. Project-specific workflow instructions
belong in each repository's `AGENTS.md`.

Resolve references in this file relative to the Codex home directory containing the
installed `AGENTS.md`: `$CODEX_HOME` when set, otherwise `~/.codex`.

# Shared Project Conventions

These conventions apply across project repositories unless the project `AGENTS.md` explicitly overrides them.

## Instruction And Document Authority

- Keep shared workflow rules here and project-specific additions or overrides in the repository's `AGENTS.md`.
- Scientific, product, and API references define intended behavior; clearly distinguish proposals from approved contracts. Plans describe scope, upcoming work, unresolved decisions, and brief current status. Conversation and Git retain approvals and execution history. Code and tests establish implemented behavior, not approval of that behavior.
- Surface conflicts between applicable requirements before continuing affected work. Do not silently choose a contract or revise intended behavior to match existing code.

## Subagent Usage

- Prefer subagents over inline work for codebase exploration, multi-step research, and parallelizable tasks.
- Use read-only exploration for broad file/code searches (pattern matching, keyword discovery, architecture questions).
- Use general-purpose subagents for multi-step research that would otherwise consume many tool rounds in the main thread.
- Launch multiple subagents in parallel when tasks are independent.
- Do not duplicate work: if a subagent is researching something, do not also search for it inline.
- Summarize subagent results concisely when reporting back; do not paste raw output verbatim.
- Delegation does not expand authorization. Give subagents the same scope and stop conditions; the coordinating agent owns integration, verification, and the final evidence report.

## Approval And Execution Boundaries

- Before substantial planning, agree on the immediate outcome, non-goals, and consequential open questions. Starting a backlog card does not authorize designing its entire roadmap.
- Before implementing a behavior change, obtain approval of its intended behavior and semantic tests, with the implementation slice and review stop clear in the conversation. Do not require a separate approval ledger in planning files.
- A slice is one coherent, independently reviewable behavior change; it may span several functions or files. Design approval is separate from execution authorization. Approving a milestone or plan does not authorize every slice it contains.
- For behavior changes, execute the named slice through the expected failing tests, implementation, and relevant validation, then stop for human review before starting the next slice. Do not insert a checkpoint between red and green unless a material design issue or other required stop arises.
- Resolve routine engineering choices and fix failures caused by the slice autonomously within its approved scope. Material changes to inputs, outputs, responsibilities, scientific meaning, or scope reopen approval before affected implementation continues, including changes discovered during an audit.
- Trivial mechanical or documentation-only edits do not require a red/green cycle. Keep them bounded by the request; changes to contract meaning still require approval.
- Behavior-preserving refactors require approved scope and relevant before/after validation, not manufactured failing tests. Stop for review after the slice; a discovered behavior correction requires approved semantic tests and red/green work.
- Implementation authorization does not grant commit, push, PR, merge, deployment, or live-service permission. If the project requires separate red/green commits, establish local commit authorization before beginning that cycle; do not implement past an uncommitted red checkpoint.
- On resumption, read the active card and linked zoom-in, inspect branch/status/history, and use the current request and available conversation to establish authorization. Ask only if consequential permission is unclear. Neither priority order nor an unchecked task grants permission to start another slice.

## Feature And API Specifications

- Review a concrete calling sequence, minimal records, and expected intermediate results together before expanding a substantial specification. Show where each value is created, stored, and passed; justify duplicate representations or wrapper objects by a current requirement.
- Show proposed signatures and justify each input by the operation's stated responsibility, not a downstream consumer's needs. Include an example of intended behavior and a boundary example of what the operation must not do.
- Distinguish approved requirements, proposals, and unresolved choices. Expose responsibility-expanding behavior as a design decision requiring approval, not as a technical necessity.
- Establish intended behavior from the project's goals and approved contracts before comparing existing implementations. For migrations, identify what to keep, change, and remove; inspect retained behavior and tests for obsolete contracts rather than checking only retired names and imports.

## Development Workflow

- Prefer flat, explicit domain types and direct field access. Use nested wrapper objects or inheritance only when they solve a concrete current problem that outweighs the added complexity; explain that reason before introducing them.
- Prefer frozen typed dataclasses where appropriate, deterministic ordering where promised, and minimal dependencies.
- Name new core modules after their primary domain object. Prefer explicit names over shortened nouns or generic modules such as `common.py` or `utils.py`. Do not rename established modules solely to apply this preference.
- Prefer keyword arguments in constructors and function calls, especially when several arguments have the same type or their roles are not obvious. Do not make readers infer field meanings from positional order.
- Prefer shared functions for common behavior over extra object layers. Repeating a few field declarations is acceptable when it keeps domain objects easier to understand.
- Reuse an existing type only when its meaning and name fit the new use, not merely because it already exists or avoids repeated fields.
- Prefer Python-defined configuration over CLI flags for core workflows.
- Before writing new production code, tests, scripts, configuration, constants, or error handling, first look for the closest established pattern in the codebase.
- Identify what kind of code you are about to write, search obvious nearby modules and tests for similar existing code, and reuse or extend the established pattern when one exists.
- Do not introduce duplicate helpers, ad hoc constants, magic numbers, alternate error formats, new test styles, or parallel abstractions before checking whether the repository already has a convention for that case.
- If creating a new pattern is necessary, state why the existing pattern does not fit.
- Keep core domain logic separate from model invocation and network access so it can be tested directly.
- Before review, inspect the branch diff for semantic shortcuts, reproducibility failures, unnecessary abstractions, and scope creep, alongside software correctness.
- Treat reproducibility as infrastructure as code:
  - Encode run configuration as typed Python constants or dataclasses in versioned files.
  - Avoid adding new `argparse` entrypoints for core workflows.
  - Prefer stable script entrypoints that read committed Python config.
  - If parameter variation is needed, add tracked config presets instead of ad hoc CLI mutation.

## Testing And Typing

- Use pytest functions and fixtures only; do not use class-based pytest tests.
- Keep typing checks clean; project files define exact pyright scope and strictness.
- Tests must check domain behavior, invariants, provenance where applicable, or durable software contracts. Avoid assertions that merely echo configuration or duplicate another test without checking a different failure mode.
- Exercise core domain logic directly. Mock external model and network calls at their boundaries; do not use mocked domain behavior as evidence of domain correctness.
- Integration tests must exercise the implemented path and check intermediate records and results. Do not substitute fixtures for the component under test or turn unexpected errors and assertion failures into skips.

## Review And Completion Evidence

- Review the completed slice against approved behavior, integration expectations, and replacement/removal scope as well as passing checks. Identify known gaps and obtain human review before continuing to another slice.
- State which checks actually ran, what they establish, and what remains unverified. Keep failed, skipped, offline, and live checks distinct. Passing tests or an agent review does not by itself prove scientific validity or complete migration.

## Git And Pull Request Workflow

- Never commit directly to `main`; always use a feature branch.
- At the start of any task that will involve commits, check `git branch` and create a branch if currently on `main`.
- Use plain branch names, not slash-prefixed branch names.
- Before opening a pull request, update the repository's canonical planning queue to reflect the branch state:
  - mark completed branch scope items as done,
  - capture active and follow-on work as explicit backlog items.
- Do not create pull requests without explicit user approval.
- Use Copilot review for pull requests.
- Follow the Copilot review runbook at [Copilot review runbook](runbooks/copilot-review.md) for review requests, replies, and thread resolution.
- Share the pull request link with the user.
- Read, respond to, and resolve Copilot comments.
- Let the user handle commits and pushes unless explicitly asked otherwise.
- Keep commits focused on one independently reviewable change. Once committing is authorized, commit completed changes separately from active work. Preserve unrelated user changes; do not include unrelated files merely to make the worktree clean.

### GitHub CLI Safety

- Never put backticks inside double-quoted shell arguments.
- For `gh pr create`, always use `--body-file`.
- Do not inline markdown command examples with backticks in shell arguments.
- For long `gh api` bodies or review replies, write text to a temp file and pass `-F body=@/tmp/file.md`.
- Keep inline shell message bodies short and plain text only.
- If a command contains markdown-style code spans, write content to a temp file first and pass the file path.

## Planning

- Keep one canonical, checklist-like planning queue in the repository (for example `plans/next-steps.md`), easy to reorder and tracked in version control.
- Follow [planning cookbook](runbooks/planning-cookbook.md) for the queue/zoom-in structure and content boundaries. Keep procedural detail there rather than duplicating it in project instructions.
- Keep queue cards brief. When an existing card needs slice-level implementation detail or detailed test expectations, put those in a linked, git-tracked zoom-in. Neither file is an execution log.
- When moving or condensing a plan, verify that scope, requirements, rationale, source references, and gates have a clear retained home before reporting completion. Do not create a permanent mapping artifact just for that check.
- Keep execution plans in the repository rather than only in chat or external tools. This does not require transcribing approvals, test runs, or commit history into planning files.

## MVP Scope Discipline

- Check proposed work against the active card, its non-goals, and the project's MVP boundaries. Ask when relevance is unclear; do not repeatedly ask about work already approved within that scope.
- Push back on scope creep.
- Defer optimization, edge cases, and polish unless they are needed for the MVP.

## Local API Credentials

- `~/.zshrc` sources `~/.keys` in interactive terminals. Tool commands normally
  use non-interactive shells, which do not read `.zshrc`; a missing environment
  variable there does not mean the credential is unavailable or invalid.
- For commands needing API credentials, source `"$HOME/.keys"` directly in the
  same shell invocation that launches the command. Do this for each invocation;
  exports from one tool call do not persist into the next. Exported credentials
  are inherited by Python and multiprocessing workers.
- Do not source the full `.zshrc` just to load keys; it initializes interactive
  plugins and other tools and changes Git configuration.
- Before launching a batch, verify the key is exported to Python without printing
  its value. For example, from a Python project:

  ```sh
  source "$HOME/.keys"
  uv run python -c 'import os; assert os.getenv("OPENAI_API_KEY"), "OPENAI_API_KEY is not loaded"'
  ```

- Never print `~/.keys`, echo credential values, or dump the environment. Check
  this loader before requesting a new key or searching other credential stores.

## Python Environment Baseline

- Use `uv`.
- Do not use `pip`, `poetry`, or `conda`.
- Do not manually activate virtual environments.
- Run Python with `uv run`:
  - `uv run python script.py`
  - `uv run python -m module_name`
