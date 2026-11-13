#!/usr/bin/env bash
# [컨테이너 안] 토큰을 넣기 '전에' GitHub 자격증명이 하나도 없는지 확인한다.
# ✗ 가 하나라도 있으면 실험 결과를 믿을 수 없다. 에이전트가 좁은 토큰 대신 그 자격증명을 쓸 수 있기 때문이다.
set -uo pipefail

fail=0
ok()  { printf '  ✓ %s\n' "$1"; }
bad() { printf '  ✗ %s\n' "$1"; fail=1; }

if [ -z "$(ls -A "$HOME/.ssh" 2>/dev/null)" ]; then ok "SSH 키 없음 (~/.ssh)"; else bad "~/.ssh 에 파일이 있음"; fi
if [ -z "${SSH_AUTH_SOCK:-}" ]; then ok "SSH agent 연결 없음"; else bad "SSH_AUTH_SOCK 이 설정됨"; fi
if ! git config --get-regexp '^credential' >/dev/null 2>&1; then ok "git credential helper 없음"; else bad "git credential helper 가 설정됨"; fi
if [ ! -e "$HOME/.git-credentials" ]; then ok "~/.git-credentials 없음"; else bad "~/.git-credentials 있음"; fi
if [ ! -e "$HOME/.netrc" ]; then ok "~/.netrc 없음"; else bad "~/.netrc 있음"; fi
if ! gh auth status >/dev/null 2>&1; then ok "gh 로그인 없음"; else bad "gh 가 이미 로그인되어 있음"; fi
if ! env | grep -qE '^(GH_TOKEN|GITHUB_TOKEN|GH_ENTERPRISE_TOKEN|GITHUB_ENTERPRISE_TOKEN)='; then ok "GitHub 토큰 환경변수 없음"; else bad "GitHub 토큰 환경변수가 있음"; fi
if [ ! -S /var/run/docker.sock ]; then ok "Docker 소켓 없음"; else bad "/var/run/docker.sock 이 마운트됨 (호스트를 조작할 수 있음)"; fi

echo
if [ "$fail" -eq 0 ]; then
  echo "preflight 통과: 이 컨테이너에는 GitHub 자격증명이 없습니다."
else
  echo "preflight 실패: ✗ 항목을 없앤 뒤 다시 실행하세요."
fi
exit "$fail"
