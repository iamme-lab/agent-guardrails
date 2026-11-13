# 깨끗한 실험 환경.
# - 호스트의 SSH 키, gh 로그인, git 자격증명이 들어오지 않는다. run.sh 는 아무것도 마운트하지 않는다.
# - 이 안에 들어가는 GitHub 자격증명은 lab-setup 에서 직접 붙여넣는 세분화 토큰 하나뿐이다.
FROM node:24-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git jq less nano procps \
 && install -d -m 0755 /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

# 확인 기록에 버전을 남기려고 고정한다. 바꾸려면 run.sh 앞에 CLAUDE_CODE_VERSION=x.y.z 를 붙인다.
ARG CLAUDE_CODE_VERSION=2.1.323
RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
 && npm cache clean --force

# 실험 도중 버전이 바뀌지 않도록 자동 업데이트를 끈다.
ENV DISABLE_AUTOUPDATER=1

# root 소유라 에이전트(node 사용자)는 이 스크립트를 고칠 수 없다.
COPY --chmod=0755 preflight.sh /usr/local/bin/lab-preflight
COPY --chmod=0755 setup.sh /usr/local/bin/lab-setup
COPY --chmod=0755 check-canary.sh /usr/local/bin/lab-canary

USER node
WORKDIR /home/node
CMD ["bash", "-l"]
