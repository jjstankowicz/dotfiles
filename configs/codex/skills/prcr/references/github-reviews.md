# GitHub review mechanics

Use authenticated GitHub tools or `gh api`; the authenticated account determines
the author. Label content instead of attempting to spoof a bot identity. A review
of the account's own PR should use `COMMENT`; do not rely on approval or
request-changes capabilities for self-review or imply a merge protection exists.

Read existing reviews, inline comments, and review threads before each pass.
Paginate all collections; a truncated response is not evidence of no findings.
For thread state and replies, use supported REST/GraphQL APIs. Resolve only PRCR
threads with verified fixes or explicit user dispositions, never unrelated reviews.

Create one grouped review using `POST /repos/{owner}/{repo}/pulls/{number}/reviews`
with `commit_id` set to the exact reviewed head, `event: COMMENT`, a summary in
`body`, and an optional `comments` array. Each inline comment needs `path`, `body`,
`line`, and `side`; optional `start_line` and `start_side` describe multiline
findings. Use actual one-based diff coordinates, `RIGHT` for additions/current
code and `LEFT` for deletions. Avoid legacy diff `position` calculations.

Use a structured tool argument or write a JSON request file and pass it through
`gh api --input`. For `gh pr create`, use `--body-file`. Never interpolate review
Markdown into shell command strings. Keep temporary request files outside the repo.

Before retrying a failed or timed-out mutation, read the remote state to determine
whether it succeeded. Do not duplicate reviews, replies, or PRs on an ambiguous
response. Record the returned review URL or ID and confirm the published head.
If publication fails, retain the findings and report the failure accurately.

Official API references, consult when the installed tools need clarification:
- [Pull-request reviews](https://docs.github.com/en/rest/pulls/reviews)
- [Review comments](https://docs.github.com/en/rest/pulls/comments)
- [GraphQL mutations](https://docs.github.com/en/graphql/reference/mutations)
