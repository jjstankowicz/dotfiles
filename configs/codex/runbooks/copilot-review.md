# Copilot Review Runbook

Use this runbook when a pull request should be reviewed by Copilot.

## Initiate Review

Choose the desired review effort in the pull request's Reviewers controls or
Copilot settings before requesting a review. Existing PR effort and user/repository
settings can take precedence over the organization default.

Request Copilot once as an explicit reviewer through the supported API:

```bash
gh api repos/OWNER/REPO/pulls/PR_NUM/requested_reviewers -X POST -f "reviewers[]=copilot-pull-request-reviewer[bot]"
```

Do not also post an `@copilot review` comment. Mentions start a separate cloud-agent
task; they are not required for Copilot Code Review and can consume additional usage.
Only start a cloud-agent task when the user explicitly requests that work.

Verify the completed review matches the requested commit and reports the intended
effort in its overview. An API response alone does not confirm the effort used.
The reviewer API was confirmed to run Lite on LABI PR #146 on 2026-10-12 after
Lite was selected in the UI, without a comment-triggered task.

GitHub's announcement says API requests support per-request effort, but the
published REST review-request parameters do not currently document an effort
field. Use verified settings rather than inventing a request parameter.

References:

- https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review
- https://docs.github.com/en/copilot/concepts/agents/code-review
- https://docs.github.com/en/rest/pulls/review-requests
- https://github.blog/changelog/2026-10-02-copilot-code-review-api-support-and-new-default-effort-level/

## Read Review Comments

```bash
gh api repos/OWNER/REPO/pulls/PR_NUM/comments | jq '.[] | {id, path, body: .body[0:80]}'
```

## Reply To A Review Comment

GitHub's working endpoint for replies is the PR-scoped replies path, not the older collection endpoint:

```bash
printf '%s\n' 'Fixed in COMMIT.' > /tmp/reply.md
gh api repos/OWNER/REPO/pulls/PR_NUM/comments/COMMENT_ID/replies -F body=@/tmp/reply.md
```

## Get Review Thread IDs

```bash
gh api graphql -f query='
query {
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: PR_NUM) {
      reviewThreads(first: 20) {
        nodes { id isResolved comments(first: 1) { nodes { body } } }
      }
    }
  }
}'
```

## Resolve Review Threads

```bash
gh api graphql -f query='
mutation {
  t1: resolveReviewThread(input: {threadId: "THREAD_ID_1"}) { thread { isResolved } }
  t2: resolveReviewThread(input: {threadId: "THREAD_ID_2"}) { thread { isResolved } }
}'
```
