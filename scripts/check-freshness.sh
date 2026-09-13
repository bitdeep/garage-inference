#!/usr/bin/env bash
# Freshness check: does each chapter still reference the published HEAD of its stack?
#
# Drift is a prompt to review, not automatically an error: a docs-only commit
# in a stack does not invalidate its chapter. The living rule (see README,
# "How this book stays alive") requires a chapter update when behavior,
# defaults or numbers change — this script tells you where to look.
#
# Usage: scripts/check-freshness.sh        (exit 1 if any chapter drifted)
set -uo pipefail

chapters=(
  "01-llm-serving vllm-serving-stack"
  "02-speech-to-text whisper-asr-stack"
  "03-voice-cloning chatterbox-ptbr-server"
  "04-gpu-lifecycle gpu-worker-orchestrator"
)

cd "$(dirname "$0")/.."
stale=0
for entry in "${chapters[@]}"; do
  read -r chapter repo <<< "$entry"
  pinned=$(sed -n "s/.*bitdeep\/$repo@\`\([0-9a-f]\{7,\}\)\`.*/\1/p" "$chapter/README.md" | head -1)
  if [ -z "$pinned" ]; then
    echo "MISSING $chapter: no pinned $repo commit in status line"
    stale=1
    continue
  fi
  head=$(git ls-remote "https://github.com/bitdeep/$repo.git" refs/heads/main | cut -c1-7)
  short_pinned=${pinned:0:7}
  if [ "$short_pinned" = "$head" ]; then
    echo "ok       $chapter <- $repo@$head"
  else
    echo "DRIFT    $chapter pins $repo@$short_pinned; published HEAD is $head"
    echo "         -> review the commits in between: behavior/defaults/numbers changed? update the chapter (living rule) or confirm docs-only."
    stale=1
  fi
done
exit $stale
