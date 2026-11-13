# 위협 모델

## 범위

AI 코딩 에이전트(Claude Code)가 실수하거나 프롬프트 인젝션(저장소 파일, 이슈, 웹 페이지에 숨은 지시)에 넘어가 의도하지 않은 일을 할 때, 피해를 어디까지로 묶을 수 있는지 본다.

에이전트는 토큰 주인(사람)의 신분으로 움직인다고 가정한다. 토큰 주인이 할 수 있는 일은 에이전트도 할 수 있다. 룰셋 우회 목록을 비워 둔 이유도 같다. 세분화 토큰이 주인의 우회 권한을 물려받는지는 GitHub 문서에 나와 있지 않으므로, 물려받는다고 가정한다. 룰셋은 브랜치 보호 규칙과 달리 org 소유자나 저장소 관리자도 기본으로는 예외가 아니고, 우회 목록에 넣은 행위자만 예외다.
출처: <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets>

## 지킬 것

| ID | 자산 | 왜 중요한가 |
| --- | --- | --- |
| A1 | org의 다른 저장소 (agent-guardrails 등) | 에이전트 작업 범위 밖이라 바뀌면 안 됨 |
| A2 | agent-sandbox의 `main` | 사람이 확인한 코드만 들어가야 함 |
| A3 | 로컬 비밀값 (`.env`) | 대화에 들어가면 기록에 남고 밖으로 샐 수 있음 |
| A4 | CI 워크플로 (`.github/workflows/`) | 바꿀 수 있으면 CI의 권한과 비밀값을 손에 넣을 수 있음 |
| A5 | 토큰과 자격증명 자체 | 새면 에이전트 밖에서도 쓸 수 있음 |

## 위협과 통제

| ID | 위협 | 통제 | 검증 |
| --- | --- | --- | --- |
| T1 | 범위 밖 저장소에 쓰기 | 토큰: 저장소 1개만 선택 | 테스트 1 |
| T2 | `main` 직접 변경, 강제 push, 삭제 | 룰셋 (우회 목록 없음) | 테스트 2 |
| T3 | `.env` 읽기 | Claude Code deny 규칙 | 테스트 3, canary 검사 |
| T4 | 워크플로 변조 | 토큰: Workflows 권한 없음 | 테스트 4 |
| T5 | 호스트 자격증명 사용 (SSH 키, gh 로그인) | 마운트 없는 컨테이너 | `lab-preflight` |
| T6 | 리뷰 없이 `main`에 반영 (자기 PR 머지) | **없음**. 아래 "알려진 한계" 참고 | 선택 테스트 5 |
| T7 | 권한 규칙 변조 (`.claude/settings.json` 수정) | Claude Code가 `.claude/` 쓰기를 항상 묻고, 저장소 반영은 PR을 거침 | 이번 범위 밖 |
| T8 | 토큰 노출 | 저장소 1개, 권한 2개, 짧은 만료, `~/.config/gh` 읽기 거부 규칙 | 이번 범위 밖 |

## 가정

- GitHub과 Claude Code가 공식 문서대로 동작한다. 실제가 문서와 다르면 그 자체가 기록할 결과다.
- 컨테이너 탈출은 없다.
- 사람은 Claude Code의 승인 요청을 읽고 판단한다. 권한 모드는 기본(default)이고 `--dangerously-skip-permissions`는 쓰지 않는다. 프로젝트 설정의 `disableBypassPermissionsMode`로도 막아 두었다.

## 알려진 한계

**Claude Code 규칙은 보안 경계가 아니다.** 공식 문서에 따르면 `Read(.env)` 같은 deny 규칙은 Claude의 파일 도구와, Bash의 `cat`·`head`·`tail`·`sed`·`tee`, 리다이렉션까지는 막는다. 하지만 파일 이름을 적지 않는 명령(`grep -r 패턴 .`)이나 스스로 파일을 여는 스크립트(`node -e ...`, `python ...`)는 막지 않는다. 모든 프로세스를 막으려면 OS 수준 sandbox를 켜라고 안내하는데, 이 실험 컨테이너에서는 켜지 않았다. 그래서 남는 방어선은 Bash 명령마다 뜨는 사람의 승인이다. 선택 테스트 3-b가 이 구멍을 확인한다.
출처: <https://code.claude.com/docs/en/permissions.md#read-and-edit>

**Bash 인자를 제한하는 규칙은 쉽게 비켜 간다.** 문서에 따르면 `Bash(git push *)` 규칙은 `git -C . push`를 잡지 못하고, 이런 규칙은 그 프로그램을 둘러싼 보안 경계가 아니다. 그래서 강제 push 금지는 Claude Code 규칙이 아니라 룰셋(서버)에 맡겼다.
출처: <https://code.claude.com/docs/en/permissions.md#what-a-bash-rule-doesnt-match>

**권한 규칙은 실행 중에 바뀔 수 있다.** Claude Code는 설정 파일을 감시하다가 바뀌면 실행 중인 세션에 바로 반영한다. 사람이 `.claude/settings.json` 수정 요청을 승인하면 그 순간부터 규칙이 달라진다. `.claude/`는 보호 경로라 기본 모드에서는 쓰기 전에 항상 묻는다.
출처: <https://code.claude.com/docs/en/settings.md#when-edits-take-effect>, <https://code.claude.com/docs/en/permission-modes.md#protected-paths>

**자기 PR 머지 (T6).** "PR 필수, 승인 0명" 규칙은 PR이 열리기만 하면 머지를 허용하고, PR 머지 API에 필요한 권한은 Contents 쓰기다. 둘 다 이 토큰에 있다. 그래서 에이전트는 PR을 만들고 바로 머지해서 리뷰 없이 `main`을 바꿀 수 있다. 승인을 1명 이상 요구하면 이번에는 사람도 막힌다. 작성자는 자기 PR을 승인할 수 없고, 에이전트가 만든 PR의 작성자가 곧 토큰 주인이기 때문이다. 해결책 후보는 에이전트 전용 계정을 만들어 그 계정의 토큰을 쓰고, 사람이 승인 1명으로 리뷰하는 것이다. 이번 실험에서는 선택 테스트 5로 실제 동작을 확인하고 구멍으로 기록한다.
출처: <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets> ("The pull request doesn't necessarily have to be approved, but it must be opened."), <https://docs.github.com/en/rest/pulls/pulls#merge-a-pull-request> (Contents 쓰기)

**공개 저장소는 읽기를 막을 수 없다.** 문서에 따르면 토큰은 항상 GitHub의 모든 공개 저장소를 읽을 수 있다. 그래서 테스트 1의 기준은 "쓰기 거절"이다.
출처: <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens>

**네트워크로 새는 것.** 컨테이너는 인터넷에 연결되어 있다. 에이전트가 읽은 값을 밖으로 보내는 일(curl 등)은 이번 범위 밖이고, Bash 승인 요청이 유일한 방어선이다.

**대화 기록에 남는 값.** Claude Code는 도구 결과를 `~/.claude/projects/` 아래에 평문으로 저장한다. `.env`가 한 번이라도 읽히면 그 값이 기록에 남는다. 이 성질을 거꾸로 이용해서, `.env`에 넣은 무작위 canary가 기록에 나타나는지로 테스트 3을 판정한다.
출처: <https://code.claude.com/docs/en/claude-directory.md>

**Anthropic 자격증명.** 컨테이너 안 Claude Code 로그인 정보(`~/.claude/.credentials.json`)는 에이전트와 같은 사용자 권한으로 읽을 수 있다. 읽기 거부 규칙을 넣었지만 위와 같은 한계가 있다.

## 범위 밖

컨테이너 탈출, GitHub 계정 탈취, Anthropic 쪽 보안, npm 패키지 공급망 공격.
