---
name: plan-it
description: Create, update, or audit repository execution queues and linked zoom-in plans using the project's planning conventions. Use for planning-document work, not implementation of the planned tasks.
---

Maintain a coherent execution queue and its linked implementation plans.

Before editing, read the applicable AGENTS.md instructions, the
[planning cookbook](../../runbooks/planning-cookbook.md), and the affected queue cards and
zoom-ins in full. The cookbook owns the structural and content rules; do not copy it into
project plans or create a parallel queue. Apply repository overrides where present.

1. Establish the requested outcome and existing scope from the conversation and references.
   Distinguish intended behavior, proposals, implemented behavior, and missing decisions.
   Do not expand the roadmap to make a document appear complete.
2. Keep the queue brief and put slice-level scope, calling examples, and test expectations in
   the linked zoom-in when needed. Follow the cookbook's required backlog structure and
   slice-local context/design rules, unless the repository specifies another format. Express work
   and completion conditions as checklists, not a mixture of prose cards and execution lists.
3. Reconcile the entire affected card and zoom-in when requirements change. Replace stale
   statements instead of appending contradictory instructions. Keep each requirement in one
   appropriate home; when moving or removing content, verify that required scope, rationale,
   references, and gates remain available. Preserve unrelated edits.
   Make test plans easy to assess: name the cases, give their concrete inputs or actions,
   and state observable expected results. Group related cases and separate offline evidence
   from live checks and their authorization. Prose, lists, or tables are all acceptable;
   category labels such as "test the mapper" are not a concrete test plan. Reuse established
   fixtures and state what new checks establish without duplicating their full setup.
4. Review the resulting documents in two passes:
   - Structural: check the cookbook's Priority/Backlog mapping, headings, checklist status,
     links, and queue-versus-zoom-in content boundaries.
   - Semantic: reread the complete affected documents for conflicting scope, permissions,
     status, dependencies, and completion gates. For example, a required authorized live
     check cannot coexist with an unconditional statement that live calls are excluded.
     Compare claims of implementation or verification with actual code and evidence.
5. Inspect the final diff. Report what changed, checks actually performed, and any remaining
   decision or contradiction. Mechanical validation does not establish semantic coherence.

Keep approval and execution history in conversation/Git rather than adding a ledger to plans.
Editing a plan does not authorize implementation, commits, pushes, or live-service calls.
