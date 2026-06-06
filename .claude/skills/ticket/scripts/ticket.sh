#!/usr/bin/env bash
#
# ticket.sh — issue → branch → PR helper for personal GitHub repos.
#
# Driven by the /ticket skill, but safe to run by hand. It derives the repo
# from `origin`, refuses to act if the active gh account can't reach that repo
# (the wrong-account guard), and keeps branch ⇆ issue ⇆ PR names in sync.
#
# Subcommands:
#   guard                          fail fast unless the active gh account can access this repo
#   whoami                         show active gh login, origin repo, base branch, linked board
#   init [--project N | --create]  create the conventional labels (+ link/create a Project board)
#   new "<title>" [--label feat] [--body "..."]
#                                  open an issue (+ add to board), print its URL
#   start <issue#> [--type feat]   cut `type/<issue#>-<slug>` off the base branch and push it
#   pr [--draft]                   open a PR for the current branch that Closes its issue
#
# Conventions (match the repo's commit history): types = feat fix chore refactor docs test
#
set -euo pipefail

CONF=".ticket.conf"                       # repo-root config; currently just: project=<number>
LABEL_TYPES="feat fix chore refactor docs test"

die()  { printf 'ticket: %s\n' "$*" >&2; exit 1; }
note() { printf '  • %s\n' "$*" >&2; }

# owner/repo from origin. Handles git@host:owner/repo.git, ssh://git@host/owner/repo,
# and https://host/owner/repo.git — including the github-work SSH host alias.
origin_slug() {
  local url
  url=$(git remote get-url origin 2>/dev/null) || die "no 'origin' remote in $(pwd)"
  url=${url%.git}
  url=${url#git@*:}
  url=${url#ssh://git@*/}
  url=${url#https://*/}
  printf '%s' "$url"
}

base_branch() {
  # Tolerant: returns the default branch name if origin/HEAD is set, else empty.
  # Callers default to 'main' when empty. The `|| true` is required because
  # `set -e + pipefail` would otherwise kill the script when origin/HEAD is
  # not configured (a common state on repos cloned without --branch).
  git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null \
    | sed 's@^origin/@@' || true
}

active_login() { gh api user --jq '.login' 2>/dev/null; }

conf_get() { [ -f "$CONF" ] && sed -n "s/^$1=//p" "$CONF" | head -1; }

# --- Project v2 field helpers ----------------------------------------------
# All of these are silent no-ops when no project is linked (.ticket.conf missing
# or empty), so the rest of the script keeps working without a board.

_project_node_id() {  # echoes PVT_... node id, or nothing
  local num owner
  num=$(conf_get project); [ -n "$num" ] || return 0
  owner=$(origin_slug); owner=${owner%%/*}
  gh project view "$num" --owner "$owner" --format json --jq '.id' 2>/dev/null || true
}

_field_id() {  # field-name -> field id (PVTF_... / PVTSSF_...)
  local fname="$1" num owner
  num=$(conf_get project); [ -n "$num" ] || return 0
  owner=$(origin_slug); owner=${owner%%/*}
  gh project field-list "$num" --owner "$owner" --format json \
    --jq ".fields[] | select(.name==\"$fname\") | .id" 2>/dev/null || true
}

_option_id() {  # field-name option-name -> single-select option id
  local fname="$1" oname="$2" num owner
  num=$(conf_get project); [ -n "$num" ] || return 0
  owner=$(origin_slug); owner=${owner%%/*}
  gh project field-list "$num" --owner "$owner" --format json \
    --jq ".fields[] | select(.name==\"$fname\") | .options[]? | select(.name==\"$oname\") | .id" \
    2>/dev/null || true
}

_item_id_for_issue() {  # issue# -> project item id for that issue, or nothing
  local num owner
  num=$(conf_get project); [ -n "$num" ] || return 0
  owner=$(origin_slug); owner=${owner%%/*}
  gh project item-list "$num" --owner "$owner" --format json \
    --jq ".items[] | select(.content.number==$1) | .id" 2>/dev/null || true
}

_set_singleselect() {  # item-id field-name option-name
  local item_id="$1" fname="$2" oname="$3" pid fid oid
  [ -n "$item_id" ] || return 0
  pid=$(_project_node_id); [ -n "$pid" ] || return 0
  fid=$(_field_id "$fname"); [ -n "$fid" ] || { note "field '$fname' not on board — skipped"; return 0; }
  oid=$(_option_id "$fname" "$oname"); [ -n "$oid" ] || { note "option '$oname' not on '$fname' — skipped"; return 0; }
  if gh project item-edit --project-id "$pid" --id "$item_id" --field-id "$fid" \
       --single-select-option-id "$oid" >/dev/null 2>&1; then
    note "$fname = $oname"
  else
    note "could not set $fname=$oname"
  fi
}

_set_number() {  # item-id field-name number
  local item_id="$1" fname="$2" val="$3" pid fid
  [ -n "$item_id" ] && [ -n "$val" ] || return 0
  pid=$(_project_node_id); [ -n "$pid" ] || return 0
  fid=$(_field_id "$fname"); [ -n "$fid" ] || { note "field '$fname' not on board — skipped"; return 0; }
  gh project item-edit --project-id "$pid" --id "$item_id" --field-id "$fid" --number "$val" \
    >/dev/null 2>&1 && note "$fname = $val" || note "could not set $fname=$val"
}

_set_date() {  # item-id field-name YYYY-MM-DD
  local item_id="$1" fname="$2" val="$3" pid fid
  [ -n "$item_id" ] && [ -n "$val" ] || return 0
  pid=$(_project_node_id); [ -n "$pid" ] || return 0
  fid=$(_field_id "$fname"); [ -n "$fid" ] || { note "field '$fname' not on board — skipped"; return 0; }
  gh project item-edit --project-id "$pid" --id "$item_id" --field-id "$fid" --date "$val" \
    >/dev/null 2>&1 && note "$fname = $val" || note "could not set $fname=$val"
}

# The wrong-account guard: the surest test is "can the active token actually see
# this repo?", which also catches private repos the wrong account can't resolve.
guard() {
  local slug who
  slug=$(origin_slug)
  who=$(active_login) || die "gh is not authenticated. Run: gh auth login"
  if ! gh repo view "$slug" --json name >/dev/null 2>&1; then
    die "active gh account '$who' cannot access '$slug' — wrong account for this repo.
      Fix one of:
        - cd out of and back into this folder so direnv reloads .envrc, or
        - gh auth switch --user <the account that owns $slug>"
  fi
}

ensure_label() {  # name desc color
  if gh label create "$1" --description "$2" --color "$3" --force >/dev/null 2>&1; then
    note "label $1"
  fi
}

cmd_whoami() {
  printf 'active gh login : %s\n' "$(active_login || echo '— not authenticated —')"
  printf 'origin repo     : %s\n' "$(origin_slug)"
  printf 'base branch     : %s\n' "$(base_branch || echo main)"
  printf 'project (conf)  : %s\n' "$(conf_get project || echo '— not linked —')"
}

cmd_init() {
  guard
  local slug owner project="" create=0
  slug=$(origin_slug); owner=${slug%%/*}
  while [ $# -gt 0 ]; do
    case "$1" in
      --project) project="${2:-}"; shift 2;;
      --create)  create=1; shift;;
      *) die "init: unknown arg '$1'";;
    esac
  done

  note "ensuring conventional labels on $slug"
  ensure_label feat     "New feature"           1f883d
  ensure_label fix      "Bug fix"               d1242f
  ensure_label chore    "Tooling / maintenance" 6e7781
  ensure_label refactor "Code restructure"      8250df
  ensure_label docs     "Documentation"         0969da
  ensure_label test     "Tests"                 bf8700

  if [ -n "$project" ]; then
    printf 'project=%s\n' "$project" > "$CONF"
    note "linked Project #$project (wrote $CONF)"
  elif [ "$create" = 1 ]; then
    local num
    num=$(gh project create --owner "$owner" --title "Matchday" --format json 2>/dev/null \
          | tr ',' '\n' | sed -n 's/.*"number":[[:space:]]*\([0-9]*\).*/\1/p' | head -1)
    [ -n "$num" ] || die "could not create a Project — token likely lacks the 'project' scope.
      Run: gh auth refresh -s project --user $owner --hostname github.com"
    printf 'project=%s\n' "$num" > "$CONF"
    note "created Project #$num (wrote $CONF)"
  else
    note "labels done. To wire a board, re-run with --project <number> or --create."
    note "existing boards for $owner:"
    gh project list --owner "$owner" >&2 2>/dev/null || note "(need 'project' scope to list boards)"
  fi
}

cmd_new() {
  guard
  local slug owner title="${1:-}" label="feat" body=""
  local assignee="@me" priority="P2" size="M" estimate="" start="" target="" milestone=""
  slug=$(origin_slug); owner=${slug%%/*}
  [ -n "$title" ] || die "new: missing title.  Usage: ticket.sh new \"<title>\" [--label feat] [--body \"...\"] [--priority P0|P1|P2] [--size XS|S|M|L|XL] [--estimate N] [--start YYYY-MM-DD] [--target YYYY-MM-DD] [--milestone NAME] [--assignee USER]"
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --label)     label="${2:-feat}";     shift 2;;
      --body)      body="${2:-}";          shift 2;;
      --priority)  priority="${2:-}";      shift 2;;
      --size)      size="${2:-}";          shift 2;;
      --estimate)  estimate="${2:-}";      shift 2;;
      --start)     start="${2:-}";         shift 2;;
      --target)    target="${2:-}";        shift 2;;
      --milestone) milestone="${2:-}";     shift 2;;
      --assignee)  assignee="${2:-@me}";   shift 2;;
      *) die "new: unknown arg '$1'";;
    esac
  done

  case "$priority" in P0|P1|P2|"") ;; *) die "--priority must be P0|P1|P2 (got '$priority')";; esac
  case "$size"     in XS|S|M|L|XL|"") ;; *) die "--size must be XS|S|M|L|XL (got '$size')";; esac
  for d in "$start" "$target"; do
    [ -z "$d" ] || printf '%s' "$d" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' \
      || die "--start / --target must be YYYY-MM-DD (got '$d')"
  done

  local -a ca
  ca=(--repo "$slug" --title "$title" --label "$label" --body "${body:-_Opened via /ticket._}")
  [ -n "$assignee" ]  && ca+=(--assignee "$assignee")
  [ -n "$milestone" ] && ca+=(--milestone "$milestone")

  local url
  url=$(gh issue create "${ca[@]}") || die "gh issue create failed"
  note "created $url"

  local pnum item_id=""
  pnum=$(conf_get project)
  if [ -n "$pnum" ]; then
    item_id=$(gh project item-add "$pnum" --owner "$owner" --url "$url" --format json --jq '.id' 2>/dev/null || true)
    if [ -n "$item_id" ]; then
      note "added to Project #$pnum"
      [ -n "$priority" ] && _set_singleselect "$item_id" "Priority"    "$priority"
      [ -n "$size" ]     && _set_singleselect "$item_id" "Size"        "$size"
      [ -n "$estimate" ] && _set_number       "$item_id" "Estimate"    "$estimate"
      [ -n "$start" ]    && _set_date         "$item_id" "Start date"  "$start"
      [ -n "$target" ]   && _set_date         "$item_id" "Target date" "$target"
    else
      note "could not add to Project #$pnum (scope/board?) — issue still created"
    fi
  fi
  printf '%s\n' "$url"
}

cmd_start() {
  guard
  local slug issue="${1:-}" type=""
  slug=$(origin_slug)
  [ -n "$issue" ] || die "start: missing issue number.  Usage: ticket.sh start <issue#> [--type feat]"
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --type) type="${2:-}"; shift 2;;
      *) die "start: unknown arg '$1'";;
    esac
  done

  local title labels base slug_title branch
  title=$(gh issue view "$issue" --repo "$slug" --json title --jq '.title' 2>/dev/null) \
    || die "issue #$issue not found in $slug"

  if [ -z "$type" ]; then
    labels=$(gh issue view "$issue" --repo "$slug" --json labels --jq '.labels[].name' 2>/dev/null || true)
    for t in $LABEL_TYPES; do
      if printf '%s\n' "$labels" | grep -qx "$t"; then type="$t"; break; fi
    done
    type=${type:-feat}
  fi

  slug_title=$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' \
      | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-40 | sed -E 's/-+$//')
  branch="$type/$issue-$slug_title"
  base=$(base_branch); base=${base:-main}

  git fetch origin "$base" >/dev/null 2>&1 || git fetch origin >/dev/null 2>&1 || true
  git switch -c "$branch" "origin/$base" 2>/dev/null || git switch -c "$branch" "$base" \
    || die "could not create branch '$branch' (does it already exist?)"
  if git push -u origin "$branch" >/dev/null 2>&1; then
    note "pushed $branch (tracking origin/$branch)"
  else
    note "branch '$branch' created locally; push it when ready"
  fi

  local issue_item
  issue_item=$(_item_id_for_issue "$issue" || true)
  [ -n "$issue_item" ] && _set_singleselect "$issue_item" "Status" "In progress"

  printf '%s\n' "$branch"
}

cmd_pr() {
  guard
  local slug branch issue base draft="" title body
  slug=$(origin_slug)
  while [ $# -gt 0 ]; do
    case "$1" in --draft) draft="--draft"; shift;; *) die "pr: unknown arg '$1'";; esac
  done
  branch=$(git symbolic-ref --quiet --short HEAD) || die "detached HEAD — checkout a branch first"
  case "$branch" in main|master) die "pr: you're on '$branch' — switch to a feature branch first";; esac

  base=$(base_branch); base=${base:-main}
  issue=$(printf '%s' "$branch" | sed -nE 's@^[a-z]+/([0-9]+)-.*@\1@p')
  git push -u origin "$branch" >/dev/null 2>&1 || true

  if [ -n "$issue" ]; then
    title=$(gh issue view "$issue" --repo "$slug" --json title --jq '.title' 2>/dev/null || echo "$branch")
    body="Closes #$issue"
  else
    title="$branch"
    body="_No linked issue parsed from the branch name._"
  fi
  gh pr create --repo "$slug" --base "$base" --head "$branch" \
    --title "$title" --body "$body" $draft

  if [ -n "$issue" ]; then
    local issue_item
    issue_item=$(_item_id_for_issue "$issue" || true)
    [ -n "$issue_item" ] && _set_singleselect "$issue_item" "Status" "In review"
  fi
}

sub=${1:-}; [ $# -gt 0 ] && shift || true
case "$sub" in
  guard)  guard; printf 'ok: %s can access %s\n' "$(active_login)" "$(origin_slug)";;
  whoami) cmd_whoami;;
  init)   cmd_init  "$@";;
  new)    cmd_new   "$@";;
  start)  cmd_start "$@";;
  pr)     cmd_pr    "$@";;
  *) die "usage: ticket.sh {guard|whoami|init|new|start|pr} ...";;
esac
