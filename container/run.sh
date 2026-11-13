#!/usr/bin/env bash
# [호스트에서 실행] 실험 이미지를 빌드하고 컨테이너에 들어간다.
# 일부러 아무것도 마운트하지 않고(-v 없음) 호스트 환경변수도 넘기지 않는다(-e 없음).
# 두 번째 터미널이 필요하면: docker exec -it agent-lab bash -l
set -euo pipefail
cd "$(dirname "$0")"

IMAGE=iamme-agent-lab
NAME=${NAME:-agent-lab}
CLAUDE_CODE_VERSION=${CLAUDE_CODE_VERSION:-2.1.323}

if docker container inspect "$NAME" >/dev/null 2>&1; then
  echo "기존 컨테이너 '$NAME' 로 다시 들어갑니다. (처음부터 하려면: docker rm -f $NAME)"
  exec docker start -ai "$NAME"
fi

docker build --build-arg CLAUDE_CODE_VERSION="$CLAUDE_CODE_VERSION" -t "$IMAGE" .
exec docker run -it --name "$NAME" --hostname agent-lab \
  --cap-drop ALL --security-opt no-new-privileges \
  "$IMAGE"
