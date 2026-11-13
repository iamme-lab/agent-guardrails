# iamme-lab에 반영하기

실험 계획을 iamme-lab org에 어떻게 반영했는지, 그리고 웹에서 직접 해야 하는 일을 정리합니다.

## 현재 상태 (2026-11-13, GitHub API로 확인)

| 항목 | 값 | 비고 |
| --- | --- | --- |
| 플랜 | Free | |
| 멤버 2단계 인증 필수 | 켜짐 ✓ | 계획 1단계 완료 |
| 멤버 | 1명 (소유자) | |
| 기본 저장소 권한 | read | 멤버가 1명이라 지금은 영향 없음 |
| org 단위 룰셋 | 쓸 수 없음 | API 응답 `Upgrade to GitHub Team to enable this feature.` 그래서 저장소 단위 룰셋을 씀 |
| Actions `GITHUB_TOKEN` 기본 권한 | read ✓ | Actions가 PR을 승인하는 것도 막혀 있음 ✓ |
| 허용 액션 | 전부 | 액션 SHA 고정 강제는 꺼져 있음 |

## 적용한 것 (API, [github/apply.sh](../github/apply.sh))

| 항목 | 내용 |
| --- | --- |
| 저장소 | `agent-guardrails`(본 저장소), `agent-sandbox`(실험 저장소). 둘 다 public |
| 룰셋 `protect-main` | 두 저장소의 기본 브랜치에 삭제 금지, 강제 push 금지, PR 필수(승인 0명), 우회 목록 없음 |

첫 내용을 push한 다음에 룰셋을 겁니다. 우회 목록이 비어 있어서 룰셋이 걸린 뒤에는 org 소유자도 `main`에 직접 push할 수 없습니다. 의도한 동작입니다. 토큰은 소유자 신분으로 움직이므로, 소유자가 우회할 수 있으면 에이전트도 우회할 수 있다고 가정해야 합니다. 그래서 이 저장소의 변경도 이제 PR로 올립니다.

다시 적용할 때 (여러 번 실행해도 안전합니다):

```bash
./github/apply.sh
```

## 웹에서 해야 하는 일

org 만들기, 2단계 인증 필수 켜기, 세분화 토큰 만들기는 github.com에 API가 없어서 웹 화면에서만 할 수 있습니다. 앞의 두 가지는 이미 끝났습니다.

### 1. 토큰 정책 (권장)

iamme-lab → Settings → 왼쪽 메뉴 **Personal access tokens** → Settings. 화면 위의 **Fine-grained tokens**와 **Tokens (classic)** 탭에서 각각 설정합니다.

| 탭 | 설정 | 권장 | 이유 |
| --- | --- | --- | --- |
| Fine-grained tokens | 승인 정책 | 기본값(관리자 승인 필요) 유지 | org 소유자가 만든 토큰은 승인 없이 바로 쓰입니다. 나중에 멤버가 생기면 그들의 토큰은 승인을 거칩니다 |
| Fine-grained tokens | Set maximum lifetimes for personal access tokens | 30일 | 기본값은 366일입니다. 짧은 만료를 org 차원에서 강제합니다 |
| Tokens (classic) | Restrict personal access tokens (classic) from accessing your organizations | 접근 제한 | classic 토큰은 저장소별로 범위를 좁힐 수 없습니다. 제한해도 공개 자원 읽기는 그대로 됩니다 |

GitHub CLI 로그인 토큰(`gho_`)은 classic 토큰과 다른 종류(OAuth 토큰)라 classic 토큰 제한의 영향을 받지 않을 것으로 보지만, 문서에 명시되어 있지는 않습니다. 제한을 켠 뒤 `gh api orgs/iamme-lab`이 여전히 되는지 확인하세요.

출처: [Setting a personal access token policy for your organization](https://docs.github.com/en/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization)

### 2. 세분화 토큰 발급

아래 링크를 열면 이름, 리소스 주인(iamme-lab), 만료(14일), 권한(Contents와 Pull requests 쓰기)이 미리 채워집니다.

<https://github.com/settings/personal-access-tokens/new?name=agent-lab&description=agent-guardrails+experiment%2C+agent-sandbox+only&target_name=iamme-lab&expires_in=14&contents=write&pull_requests=write>

저장소 선택은 링크로 채울 수 없어서 화면에서 직접 고릅니다. 만들기 전에 화면이 아래 표와 같은지 확인합니다.

| 항목 | 값 |
| --- | --- |
| Resource owner | **iamme-lab** (본인 계정이 아님) |
| Expiration | 14일 (7~30일 안에서) |
| Repository access | Only select repositories → **agent-sandbox** 하나 |
| Repository permissions | **Contents: Read and write**, **Pull requests: Read and write**. Metadata: Read-only는 자동으로 붙습니다 |
| 나머지 저장소 권한 | 전부 No access. 특히 **Workflows**와 **Administration**은 주지 않습니다 |
| Organization permissions | 전부 No access |

토큰 값은 발급 화면에서 한 번만 보입니다. 복사해서 바로 컨테이너의 `lab-setup`에 붙여넣고, 다른 곳(메모, 채팅, 호스트의 파일)에는 남기지 않습니다. 이후 절차는 [runbook.md](runbook.md)를 따릅니다.

출처: [Pre-filling fine-grained personal access token details using URL parameters](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#pre-filling-fine-grained-personal-access-token-details-using-url-parameters)

## 하지 않은 것 (선택적 강화)

| 항목 | 하지 않은 이유 |
| --- | --- |
| 허용 액션을 GitHub 소유 액션으로 제한, 액션 SHA 고정 강제 | 이번 실험 범위 밖입니다. agent-sandbox CI는 이미 SHA로 고정했습니다 |
| 에이전트 전용 계정과 승인 1명 룰셋 | 자기 PR 머지 구멍([THREAT_MODEL.md](../THREAT_MODEL.md)의 T6)을 막는 방법입니다. 계정을 하나 더 만들어야 해서 보류했습니다 |
| 기본 저장소 권한을 none으로 | 멤버가 늘면 고려합니다 |
