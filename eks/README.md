# ☸️ Terraform EKS Module

AWS EKS 클러스터를 안정적으로 구성/운영하기 위한 Terraform 모듈입니다. 이 모듈은 지정한 서브넷에 EKS Managed Node Group을 배치하고, 실무에 필요한 기본 보안 규칙과 태그를 자동으로 구성합니다. 또한 선택적으로 ALB Controller, Karpenter, External Secrets Operator(ESO)를 위한 IAM/IRSA 리소스 생성을 지원합니다.

---

## ✅ 주요 기능

- AWS 관리형 EKS 클러스터 생성 (terraform-aws-modules/eks v20 기반)
- EKS Managed Node Group 구성 (서브넷 타입은 호출 측에서 선택)
- Node 보안 그룹 기본 규칙 + 사용자 정의 규칙 병합 지원
- 클러스터 Endpoint 공개 여부 제어(public/private)
- 선택 기능
  - ALB Controller용 IAM 정책 생성
  - Karpenter용 IAM 정책 및 Subnet Tag 자동화
  - External Secrets Operator용 IRSA(Role/Policy) 생성

---

## 🧱 디렉토리 구조

```
modules/
├── eks/            # ← 이 README가 해당하는 모듈
└── network/        # VPC 및 서브넷 구성 모듈 (선택)
```

---

## 🛠️ 사용 예시

아래 예시는 이 모듈만으로 EKS를 생성하고, 선택적으로 ALB/Karpenter/ESO를 위한 IAM을 함께 생성하는 구성입니다.

```hcl
module "eks_cluster" {
  source = "./modules/eks"

  cluster_name    = "brian-eks-cluster-dev"
  cluster_version = "1.33"

  # 필수: 계정/리전 정보 (일부 IAM Policy 생성에 필요)
  account_id = "123456789012"
  region     = "ap-northeast-2"

  # 네트워크 연결
  vpc_id           = module.network.vpc_id
  subnet_ids       = module.network.private_subnet_ids
  ipv4_cidr_blocks = module.network.vpc_ipv4_cidr_block

  # 노드 그룹 샘플
  eks_managed_node_groups = {
    default_node_group = {
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      instance_types = ["t3.medium"]
    }
  }

  # 클러스터 API 엔드포인트 공개 여부
  cluster_public_access = true

  # 선택: 부가 IAM/IRSA 생성
  generate_alb_controller_iam_policy = true
  generate_karpenter_iam_policy      = true
  generate_eso_iam_policy            = true

  # ESO(IRSA) 권한 범위: 필요한 secret ARN만 지정 권장
  secrets_manager_arns = [
    "arn:aws:secretsmanager:ap-northeast-2:123456789012:secret:myapp/*"
  ]

  # 공통 태그
  tags = {
    Environment = "dev"
    Owner       = "platform"
  }

  # (선택) 사용자 정의 Node SG 규칙 추가
  additional_node_sg_rules = {
    allow_http_from_vpc = {
      description = "Allow HTTP from VPC"
      protocol    = "TCP"
      from_port   = 80
      to_port     = 80
      type        = "ingress"
      cidr_blocks = [module.network.ipv4_cidr_block]
    }
  }
}
```

참고: ESO(IRSA)를 사용할 때는 secrets_manager_arns 입력 변수로 필요한 Secrets Manager ARN 목록을 모듈 호출 측에서 지정하세요(최소권한 권장). 예: ["arn:aws:secretsmanager:ap-northeast-2:123456789012:secret:myapp/*"].

---

## 📥 입력 변수

| 변수명 | 타입 | 기본값 | 설명 |
|---|---|---|---|
| `cluster_name` | string | - | 생성할 EKS 클러스터 이름 |
| `cluster_version` | string | - | EKS 버전 (예: `1.33`) |
| `vpc_id` | string | - | 연결할 VPC ID |
| `subnet_ids` | list(string) | - | 클러스터/노드가 사용할 서브넷 목록 |
| `ipv4_cidr_blocks` | string | - | VPC CIDR 등 인바운드 허용 CIDR 블록 |
| `tags` | map(string) | - | 공통 태그 |
| `additional_node_sg_rules` | map(any) | `{}` | 사용자 정의 Node SG 추가 규칙 (기본 규칙과 병합) |
| `cluster_public_access` | bool | `false` | EKS Public API Endpoint 활성화 여부 (`true`면 0.0.0.0/0 허용) |
| `access_entries` | any | `{}` | EKS Access Entries 맵 (terraform-aws-modules/eks 방식) |
| `generate_alb_controller_iam_policy` | bool | `false` | ALB Controller용 IAM 정책 생성 여부 |
| `generate_karpenter_iam_policy` | bool | `false` | Karpenter용 IAM 정책 및 Subnet 태그 생성 여부 |
| `generate_eso_iam_policy` | bool | `false` | External Secrets Operator용 IRSA(Role/Policy) 생성 여부 |
| `secrets_manager_arns` | list(string) | `["*"]` | ESO(IRSA)가 조회할 수 있는 Secrets Manager ARN 목록 (최소 권한 권장) |
| `partition` | string | `"aws"` | AWS 파티션 (`aws`, `aws-cn`, `aws-us-gov` 등) |
| `account_id` | string | - | AWS 계정 ID (Karpenter/정책 생성 시 필요) |
| `region` | string | - | 리전 (Karpenter/정책 생성 시 필요) |
| `eks_managed_node_groups` | map(any) | 예시 기본값 포함 | Managed Node Group 설정. 키는 노드 그룹 이름, 값은 크기/인스턴스 타입 등 |

예시 기본값(요약):
- default_node_group: desired=1, min=1, max=1, instance_types=["t3.medium"]

---

## 📤 출력값

| 출력명 | 설명 |
|---|---|
| `cluster_id` | 생성된 EKS 클러스터 ID |
| `cluster_name` | 생성된 EKS 클러스터 이름 |
| `node_security_group_id` | 노드 SG ID |
| `alb_controller_policy_arn` | ALB Controller Policy ARN (생성 옵션 활성화 시) |
| `alb_controller_policy_id` | ALB Controller Policy ID (생성 옵션 활성화 시) |
| `oidc_provider_arn` | 클러스터 OIDC Provider ARN |
| `oidc_issuer_url` | 클러스터 OIDC Issuer URL |

---

## 🔐 기본 보안 그룹 규칙 요약

| 이름 | 포트 범위 | 방향 | 설명 |
|---|---|---|---|
| Node to Node All | all | Ingress | 노드 간 전체 트래픽 허용(필수) |
| ALB Controller Webhook | TCP 9443 | Ingress | Control Plane → ALB Controller Webhook 허용 |
| Kubelet API | TCP 10250 | Ingress | VPC CIDR에서 접근 허용 |
| NodePort Services | TCP 30000–32767 | Ingress | NodePort 범위 허용 |
| DNS | TCP/UDP 53 | Ingress | DNS 통신 허용 |
| Control Plane 통신 | all | Egress | Control Plane SG로의 아웃바운드 허용 |

기본 Egress(인터넷 접근)는 사용 환경(NAT GW/VPC Endpoint 등)에 따라 네트워크 경유로 허용됩니다.

---

## 📎 참고 사항

- `modules/network`와 함께 사용하면 VPC/서브넷을 일관되게 구성할 수 있습니다.
- ALB/LoadBalancer 서비스가 필요한 경우, 추가 포트를 `additional_node_sg_rules`로 확장하세요.
- `terraform apply` 후 `aws eks update-kubeconfig --name <cluster_name> --region <region>`으로 kubeconfig를 구성할 수 있습니다.
- Karpenter 사용 시, 이 모듈은 서브넷에 `karpenter.sh/discovery = <cluster_name>` 태그를 자동으로 부여합니다(옵션 활성화 시).

---

세부 구현은 `main.tf`, `variables.tf`, `outputs.tf`를 참고하세요.

