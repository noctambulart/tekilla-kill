# Issue tracker: GitHub

Issues and specifications live in noctambulart/tequila-kill.
Use the gh CLI with --repo noctambulart/tequila-kill.

## Operations

- Read: gh issue view <number> --json number,title,body,labels,comments
- List: gh issue list --state open --json number,title,labels
- Create: gh issue create --title "..." --body-file <file>
- Comment: gh issue comment <number> --body-file <file>
- Label: gh issue edit <number> --add-label "..."
- Remove label: gh issue edit <number> --remove-label "..."
- Close: post the explanation in a comment, then gh issue close <number>.

Use body files for multiline content.
Check the target with gh repo view --json nameWithOwner
before creating the first issue of a session.

## Relationships

Use native sub-issues and blocking dependencies.
If unavailable, record "Part of #<parent>" or "Blocked by: #<number>"
at the top of the issue body.
A ticket is startable when all blockers are closed.

## Skill conventions

"Publish to the issue tracker" means create a GitHub issue.
"Fetch the relevant ticket" means read its body, labels and comments.

For wayfinding, use a map issue labeled wayfinder:map and child
issues labeled wayfinder:research, wayfinder:prototype,
wayfinder:grilling or wayfinder:task.

## Wayfinding operations

Find open maps with:

```sh
gh issue list --repo noctambulart/tequila-kill --state open --label wayfinder:map --json number,title,url
```

Use native relationships with issue numbers or URLs:

```sh
gh issue edit <child> --repo noctambulart/tequila-kill --parent <map>
gh issue edit <dependent> --repo noctambulart/tequila-kill --add-blocked-by <blocker>
gh issue view <map> --repo noctambulart/tequila-kill --json number,title,body,subIssues
gh issue view <child> --repo noctambulart/tequila-kill --json number,title,body,labels,comments,assignees,state,blockedBy
```

Create all issues before wiring parent and blocking relationships.
The frontier consists of open, unassigned children whose blockers
are all closed. Claim a decision before working on it:

```sh
gh issue edit <child> --repo noctambulart/tequila-kill --add-assignee @me
```

Maps and decision tickets carry only `wayfinder:*` labels.
Triage and discipline labels apply to execution work according
to its workflow. Record a decision in a resolution comment,
close its ticket, and add a named link with a one-line gist to
the map's Decisions-so-far. Discover open tickets through native
sub-issues rather than duplicating their list in the map body.

## Pull requests as a triage surface

PRs as a request surface: no.
