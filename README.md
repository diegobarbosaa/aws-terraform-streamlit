# Terraform AWS

Projeto de Infraestrutura como Código (IaC) usando Terraform para provisionar recursos na AWS.

## 📁 Estrutura do Projeto

```
terraform-aws/
├── app/                          # Aplicação Streamlit (código local)
│   ├── main.py                   # Código do app
│   ├── requirements.txt          # Dependências Python
│   └── Dockerfile                # Imagem Docker do app
├── terraform/                    # Configuração Terraform
│   ├── main.tf                   # Chamada dos módulos + URL do Git
│   ├── providers.tf              # Configuração do provedor
│   ├── versions.tf               # Versões + Backend S3
│   ├── outputs.tf                # Saídas (outputs) raiz
│   ├── variables.tf              # Variáveis globais
│   └── modules/                  # Módulos reutilizáveis
│       ├── ec2/                  # EC2 + Security Group + SSM + Git
│       │   ├── main.tf           # EC2 + IAM Role SSM + user_data
│       │   ├── variables.tf      # Variáveis do módulo EC2
│       │   └── outputs.tf        # Saídas do módulo EC2
│       └── s3/                   # S3 Bucket
│           ├── main.tf           # Configuração do bucket S3
│           ├── variables.tf      # Variáveis do módulo S3
│           └── outputs.tf        # Saídas do módulo S3
└── keys/                         # Chaves SSH (não usado com SSM)
```

## 🚀 Recursos Provisionados

| Recurso | Descrição | Free Tier |
|---------|-----------|-----------|
| **Instância EC2** | Ubuntu 22.04 LTS, t2.micro | ✅ 750h/mês (12 meses) |
| **Security Group** | Portas 80, 443, 8501 (SEM SSH) | ✅ Ilimitado |
| **Volume EBS** | 8 GB gp2 (root) | ✅ Incluído nos 30 GB |
| **Bucket S3** | Bucket privado com versionamento | ⚠️ 5 GB grátis (12 meses) |
| **Streamlit App** | Docker com app Python (Git ou inline) | ✅ Incluído na EC2 |
| **IAM Role SSM** | Session Manager (acesso sem SSH) | ✅ Ilimitado |

> ⚠️ **Atenção:** O Free Tier é válido por 12 meses a partir da criação da conta AWS.

## 🛠️ Pré-requisitos

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado
- [AWS Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) (para acesso via SSM)

## 📋 Uso

### Inicializar o Terraform

```bash
cd terraform
terraform init
```

> **Nota:** Na primeira execução, o backend S3 será criado automaticamente.

### Visualizar Mudanças

```bash
terraform plan
```

### Aplicar Infraestrutura

```bash
terraform apply
```

### Destruir Infraestrutura

```bash
terraform destroy
```

## 🔄 Deploy com Git Clone

Este projeto suporta **duas formas de deploy**:

### Opção 1: Git Clone (Recomendado)

Edite `terraform/main.tf` e configure seu repositório:

```hcl
module "ec2" {
  source             = "./modules/ec2"
  git_repository_url = "https://github.com/SEU-USUARIO/SEU-REPO.git"
  git_branch         = "main"
  # ...
}
```

**Requisitos do repositório:**
- Deve conter `Dockerfile` na raiz
- Deve conter `requirements.txt` na raiz
- Deve conter `main.py` (app Streamlit) na raiz

**Vantagens:**
| ✅ | Explicação |
|---|------------|
| Versionamento | Código no Git |
| Atualização fácil | `git pull` na EC2 |
| Histórico | Quem mudou o quê |
| CI/CD | Webhook no push |

### Opção 2: Scripts Inline (Padrão)

Deixe `git_repository_url` vazio (ou remova a linha):

```hcl
module "ec2" {
  source             = "./modules/ec2"
  git_repository_url = ""  # ← Vazio usa scripts inline
  # ...
}
```

O código Streamlit será embutido no `user_data` da EC2.

**Vantagens:**
| ✅ | Explicação |
|---|------------|
| Sem Git | Tudo no Terraform |
| Rápido | Só `terraform apply` |
| Simples | Sem repositório externo |

## 🔐 Acesso à EC2 via Session Manager (SEM SSH)

Este projeto usa **AWS Systems Manager Session Manager** para acesso seguro à instância, sem necessidade de:
- ❌ Porta SSH aberta
- ❌ Chaves SSH
- ❌ IP público exposto para SSH

### Pré-requisitos

1. **AWS CLI configurado:**
   ```bash
   aws configure
   ```

2. **Session Manager Plugin instalado:**
   - [Windows (Chocolatey)](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html): `choco install session-manager-plugin`
   - [macOS (Homebrew)](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html): `brew install session-manager-plugin`
   - [Linux](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html): Seguir instruções da AWS

### Conectar à Instância

```bash
# Obter o ID da instância
INSTANCE_ID=$(terraform output -raw ec2_instance_id)

# Conectar via Session Manager
aws ssm start-session --target $INSTANCE_ID
```

### Comandos Úteis do SSM

```bash
# Listar sessões ativas
aws ssm describe-sessions --filters "Key=TargetId,Values=$INSTANCE_ID"

# Encerrar sessão
exit

# Acessar e executar comando direto
aws ssm start-session --target $INSTANCE_ID --document-name AWS-StartInteractiveCommand \
  --parameters "command= docker ps"
```

## 🌐 Acessar o Streamlit

Após aplicar o Terraform, a EC2 será configurada automaticamente com Docker e o app Streamlit.

1. Aguarde 2-3 minutos após `terraform apply` para a EC2 inicializar
2. Acesse no navegador: `http://<ec2_public_ip>:8501`

### Verificar status do container (via SSM)

```bash
# Conecte-se via SSM
aws ssm start-session --target $(terraform output -raw ec2_instance_id)

# Verificar container rodando
docker ps

# Ver logs do Streamlit
docker logs streamlit-app

# Reiniciar o container
docker restart streamlit-app
```

## 📦 Deploy de Atualizações

Para atualizar o app Streamlit após mudanças no código:

### Opção 1: Via SSM (recomendado para desenvolvimento)

```bash
# 1. Conecte-se via SSM
aws ssm start-session --target $(terraform output -raw ec2_instance_id)

# 2. Navegue até o diretório do app
cd /app/streamlit

# 3. Atualize os arquivos (ex: editar main.py diretamente)
nano main.py

# 4. Rebuild e restart
docker stop streamlit-app
docker rm streamlit-app
docker build -t streamlit-app .
docker run -d --restart=always -p 8501:8501 --name streamlit-app streamlit-app
```

### Opção 2: Copiar arquivos via SCP (requer SSH alternativo)

Se precisar usar SCP, habilite temporariamente o SSH no security group.

### Opção 3: Usando Git (produção)

Configure um webhook ou CI/CD para fazer pull automático na EC2 e rebuild do container.

## 📊 Backend Remoto (S3 + DynamoDB)

O estado do Terraform é armazenado remotamente no S3 com locking via DynamoDB:

| Recurso | Finalidade |
|---------|-----------|
| **S3 Bucket** | Armazena o `terraform.tfstate` com versionamento |
| **DynamoDB** | Previne que 2 pessoas apliquem ao mesmo tempo |
| **Encryption** | Estado criptografado em repouso |

### Criar Backend (primeira execução)

O backend é criado automaticamente no `terraform init`. Se quiser criar manualmente:

```bash
# Criar bucket S3
aws s3 mb s3://terraform-state-black-gustavo

# Habilitar versionamento
aws s3api put-bucket-versioning --bucket terraform-state-black-gustavo \
  --versioning-configuration Status=Enabled

# Criar tabela DynamoDB para locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## 📝 Outputs

Após aplicar, você receberá:

```bash
ec2_instance_id          = i-xxxxxxxxxxxxxxxxx
ec2_public_ip            = xx.xxx.xxx.xxx
ec2_private_ip           = xx.xxx.xxx.xxx
ssm_iam_role_arn         = arn:aws:iam::...
ssm_iam_instance_profile = arn:aws:iam::...
s3_bucket_name           = meu-bucket-aws-terraform
s3_bucket_arn            = arn:aws:s3:::meu-bucket-aws-terraform
```

## 📚 Boas Práticas Adotadas

- ✅ **Módulos reutilizáveis** - Separação por responsabilidades (EC2, S3)
- ✅ **Versionamento** - S3 com versionamento habilitado
- ✅ **Segurança** - Bucket S3 bloqueia acesso público
- ✅ **Session Manager** - Acesso sem SSH, sem porta 22 aberta
- ✅ **Tags** - Todos os recursos taggeados para organização
- ✅ **Criptografia** - Volume root da EC2 criptografado
- ✅ **Backend remoto** - Estado no S3 com locking no DynamoDB
- ✅ **Comentários** - Código documentado em PT-BR
- ✅ **Free Tier** - Recursos configurados dentro do limite grátis

## 💰 AWS Free Tier

Este projeto está configurado para usar apenas recursos elegíveis ao **AWS Free Tier**:

| Recurso | Limite Free Tier | Configurado |
|---------|-----------------|-------------|
| EC2 t2.micro | 750 horas/mês | ✅ t2.micro |
| EBS | 30 GB/mês | ✅ 8 GB |
| S3 Standard | 5 GB | ⚠️ Monitorar uso |
| Security Groups | Ilimitado | ✅ 1 SG |
| Data Transfer | 100 GB/mês | ✅ Incluído |
| IAM | Ilimitado | ✅ 1 Role + Policies |
| Systems Manager | Ilimitado | ✅ Session Manager |

> **Dica:** Monitore seu uso no [AWS Cost Explorer](https://console.aws.amazon.com/billing/home?#/costexplorer)

## 🌍 Região AWS

Este projeto usa `us-east-1` (N. Virginia) como padrão. Para alterar:

```bash
# Via variável
terraform apply -var="aws_region=eu-west-1"

# Ou via variável de ambiente
AWS_DEFAULT_REGION=eu-west-1 terraform apply

# Ou edite terraform/variables.tf
```

## 🔒 Por Que Session Manager é Melhor Que SSH?

| Aspecto | SSH Tradicional | Session Manager |
|---------|-----------------|-----------------|
| Porta aberta | ✅ Porta 22 exposta | ❌ Nenhuma porta aberta |
| Chave SSH | ✅ Necessária | ❌ Não necessária |
| Autenticação | ✅ Chave/senha | ✅ IAM (usuário AWS) |
| Auditoria | ❌ Logs limitados | ✅ CloudTrail completo |
| Acesso | ✅ IP fixo necessário | ✅ De qualquer lugar |
| Custo | ✅ Grátis | ✅ Grátis |
