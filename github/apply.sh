#!/usr/bin/env bash
# [호스트에서 실행, org 소유자의 gh 로그인 사용]
# iamme-lab 에 공개 저장소 2개를 만들고 첫 내용을 올린 뒤 main 에 룰셋을 건다.
# 여러 번 실행해도 안전하다. 있는 저장소는 건너뛰고, 같은 이름의 룰셋은 갱신한다.
set -euo pipefail

ORG=${ORG:-iamme-lab}
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)   # agent-guardrails 와 agent-sandbox 가 나란히 있는 폴더
RULESET="$HERE/ruleset-main.json"

# 전역 git 설정과 상관없이 gh 로그인 계정으로만 인증한다.
gitgh() { git -c credential.helper= -c 'credential.helper=!gh auth git-credential' "$@"; }

publish() { # <저장소> <설명>
  local repo=$1 desc=$2 dir="$ROOT/$1"
  [ -d "$dir/.git" ] || { echo "로컬 저장소가 없습니다: $dir"; exit 1; }
  if gh repo view "$ORG/$repo" >/dev/null 2>&1; then
    echo "· $ORG/$repo: 이미 있음"
  else
    gh repo create "$ORG/$repo" --public --description "$desc" --disable-wiki >/dev/null
    echo "· $ORG/$repo: 생성 (public)"
  fi
  git -C "$dir" remote get-url origin >/dev/null 2>&1 \
    || git -C "$dir" remote add origin "https://github.com/$ORG/$repo.git"
  # 우회 목록이 비어 있어서 룰셋이 걸린 뒤에는 소유자도 main 에 직접 push 할 수 없다. 그래서 첫 push 는 룰셋보다 먼저 한다.
  if [ -z "$(gitgh -C "$dir" ls-remote --heads origin main)" ]; then
    gitgh -C "$dir" push -u origin main
  else
    echo "· $ORG/$repo: 원격 main 이 이미 있어 push 를 건너뜀 (이후 변경은 PR 로)"
  fi
}

protect() { # <저장소>
  local repo=$1 id
  id=$(gh api "repos/$ORG/$repo/rulesets" --jq '.[] | select(.name == "protect-main") | .id')
  if [ -n "$id" ]; then
    gh api -X PUT "repos/$ORG/$repo/rulesets/$id" --input "$RULESET" >/dev/null
    echo "· $ORG/$repo: 룰셋 protect-main 갱신"
  else
    gh api -X POST "repos/$ORG/$repo/rulesets" --input "$RULESET" >/dev/null
    echo "· $ORG/$repo: 룰셋 protect-main 생성"
  fi
  gh api "repos/$ORG/$repo/rules/branches/main" --jq '"  main 에 걸린 규칙: " + ([.[].type] | join(", "))'
}

publish agent-guardrails "에이전트에게 좁은 토큰을 줬을 때 무엇이 막히는지 확인한 기록: 위협 모델, 실험 절차, 확인 기록"
publish agent-sandbox "agent-guardrails 실험 대상: 작은 Express 앱"
protect agent-guardrails
protect agent-sandbox
