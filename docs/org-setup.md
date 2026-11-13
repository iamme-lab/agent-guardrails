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

아래 항목은 GitHub API가 없어서 웹 화면에서만 할 수 있습니다.

### 1. 세분화 토큰 정책 확인

iamme-lab → Settings → Third-party Access → Personal access tokens → Settings

- 세분화 토큰(fine-grained) 접근이 **허용**되어 있는지 확인합니다.
- 관리자 승인이 필요하도록 되어 있으면, 토큰을 발급한 뒤 Personal access tokens → Pending requests에서 승인합니다. 승인 전에는 토큰이 org 저장소에 접근하지 못합니다.
- (권장) classic 토큰 접근은 **제한**합니다. classic 토큰은 저장소별로 범위를 좁힐 수 없어서, 실수로 만든 넓은 토큰이 org 저장소에 닿지 않게 하려는 것입니다.

### 2. 세분화 토큰 발급

본인 계정 → Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token

| 항목 | 값 |
| --- | --- |
| Token name | 예: `agent-lab-20261113` |
| Resource owner | **iamme-lab** (본인 계정이 아님) |
| Expiration | 7~30일 (Custom) |
| Repository access | Only select repositories → **agent-sandbox** 하나 |
| Repository permissions | **Contents: Read and write**, **Pull requests: Read and write**. Metadata: Read-only는 자동으로 붙습니다 |
| 나머지 저장소 권한 | 전부 No access. 특히 **Workflows**와 **Administration**은 주지 않습니다 |
| Organization permissions | 전부 No access |

토큰 값은 발급 화면에서 한 번만 보입니다. 복사해서 바로 컨테이너의 `lab-setup`에 붙여넣고, 다른 곳(메모, 채팅, 호스트의 파일)에는 남기지 않습니다. 이후 절차는 [runbook.md](runbook.md)를 따릅니다.

## 하지 않은 것 (선택적 강화)

| 항목 | 하지 않은 이유 |
| --- | --- |
| 허용 액션을 GitHub 소유 액션으로 제한, 액션 SHA 고정 강제 | 이번 실험 범위 밖입니다. agent-sandbox CI는 이미 SHA로 고정했습니다 |
| 에이전트 전용 계정과 승인 1명 룰셋 | 자기 PR 머지 구멍([THREAT_MODEL.md](../THREAT_MODEL.md)의 T6)을 막는 방법입니다. 계정을 하나 더 만들어야 해서 보류했습니다 |
| 기본 저장소 권한을 none으로 | 멤버가 늘면 고려합니다 |
