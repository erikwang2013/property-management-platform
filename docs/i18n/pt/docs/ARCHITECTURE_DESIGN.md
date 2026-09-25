# Documento de Design de Arquitetura (Architecture Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

<img src="../../../images/pet_xiaozhu.svg" alt="小筑 · project mascot" width="110" align="right">

<img src="../../../images/design_structure.svg" alt="Estrutura do projeto" width="1000">

> English edition: `../../../images/design_structure_en.svg`

<img src="../../../images/design_architecture.svg" alt="Arquitetura geral do sistema" width="1000">

> English edition: `../../../images/design_architecture_en.svg`


## 1. Visão geral da arquitetura do sistema

O Sistema de Gestão de Propriedades adota uma arquitetura em camadas de "dois back-ends + múltiplos front-ends". O painel de administração (admin) e o portal de proprietários (service) são dois projetos webman v2 independentes que trabalham em conjunto compartilhando o banco de dados MySQL. O front-end cobre Flutter Web (estilo de painel de administração para PC) e o app móvel HarmonyOS.

### Objetivos de design

- **Implantação independente**: admin e service iniciam/param, escalam e gerenciam chaves de forma independente
- **Dados compartilhados**: usam o mesmo banco MySQL, evitando problemas de sincronização de dados
- **Padrões unificados**: os dois projetos seguem os mesmos padrões de código, estilo de configuração e políticas de segurança
- **Web com foco em PC**: o Flutter Web é projetado com estilo de painel de administração desktop (barra lateral + barra superior + área de conteúdo)

## 2. Arquitetura em camadas

```
┌─────────────────────────────────────────────────────────────┐
│                    Camada de rotas (Route Layer)             │
│   config/route.php — mapeamento URL → Controller + middlewares│
├─────────────────────────────────────────────────────────────┤
│                  Camada de middlewares (Middleware Layer)     │
│   SecurityFilter → RateLimit → Auth → Permission               │
├─────────────────────────────────────────────────────────────┤
│                Camada de controladores (Controller Layer)     │
│   BaseController → validação da requisição → codificação de ID│
│   → lógica de negócio → formatação da resposta                │
├─────────────────────────────────────────────────────────────┤
│                    Camada de serviços (Service Layer)         │
│   HashidsService | SnowflakeService | EncryptionService       │
├─────────────────────────────────────────────────────────────┤
│                    Camada de modelos (Model Layer)            │
│   Eloquent ORM + encryptable (criptografia automática) +      │
│   scout ES (sincronização)                                    │
├─────────────────────────────────────────────────────────────┤
│                    Camada de drivers (Driver Layer)           │
│   MySQL PDO | Elasticsearch HTTP | Redis                      │
└─────────────────────────────────────────────────────────────┘
```

## 3. Cadeia de execução de middlewares

### Painel de administração (admin)
```
Cors → SecurityFilter(verificação de método→405) → RateLimit(limite de taxa)
  → AdminAuth(validação JWT) → AdminPermission(autorização RBAC)
    → OperationLog(registro de operações) → Controller
```

### Portal de proprietários (service)
```
Cors → SecurityFilter(verificação de método→405) → RateLimit(limite de taxa)
  → Controller (versão no URL)                     # APIs públicas /api/v1/*
  → ServiceAuth(auth JWT do proprietário) → Controller # APIs autenticadas /service/v1/*
```

### Descrição dos middlewares globais

| Middleware | Posição | Responsabilidade |
|--------|------|------|
| Cors | Primeiro global | Tratamento de cabeçalhos CORS |
| SecurityFilter | Global | Whitelist de métodos HTTP, bloqueio de XSS/injeção de SQL/path traversal/injeção de comandos/CSRF, blacklist de IPs |
| RateLimit | Global | Limite de taxa por janela deslizante no Redis (Lua atômico), padrão 60 vezes/minuto |
| AdminAuth | Rotas /admin | Validação do Token JWT, injeção do adminId |
| AdminPermission | Rotas /admin | Verificação de permissões RBAC method.path (cache Redis 60s) |
| OperationLog | Rotas /admin | Registro automático de operações POST/PUT/DELETE (com detecção de plataforma de origem) |
| ServiceAuth | Rotas /service | Validação do Token JWT, injeção do ownerId |

## 4. Ciclo de vida completo do ID

```
Geração: SnowflakeService::generate()
      datacenter_id(5bit) + worker_id(5bit) + timestamp(41bit) + sequence(12bit)
      → BIGINT(18) ex.: 1750123456789

Armazenamento: tabelas MySQL management_*
      id BIGINT UNSIGNED NOT NULL (sem autoincremento)
      campos sensíveis com cast encryptable → armazenamento criptografado AES-256-CBC

Transmissão: HashidsService::encode(bigint) → string hashid ex.: aB3xK9mW2pQ7rT5v
      todos os campos de ID em requisições/respostas da API usam hashid

Decodificação: HashidsService::decode(hashid) → BIGINT
      hashid inválido lança InvalidArgumentException
```

## 5. Camadas de criptografia de dados

### Camada de transmissão (encryption)
- Criptografia AES-256-CBC
- O cliente criptografa os dados sensíveis antes de enviar; o servidor descriptografa ao receber
- Chave independente `ENCRYPTION_KEY`

### Camada de armazenamento (encryptable)
- Mecanismo de `$casts` do Model com criptografia/descriptografia automática
- Campos sensíveis: phone, email, id_card, emergency_contact, emergency_phone
- Chave independente `ENCRYPTABLE_KEY`
- Gravação criptografa automaticamente para texto cifrado; leitura descriptografa automaticamente para texto claro

### Camada de exibição (mascaramento)
- Telefone: `138****1234`
- E-mail: `a***@example.com`
- CPF/ID: `********`
- Exportação em Excel/PDF com mascaramento automático

## 6. Autenticação e permissões

### Autenticação JWT
- Algoritmo: HS256
- access_token: validade de 2 horas
- refresh_token: validade de 14 dias
- Limite de concorrência: no máximo 3 Tokens válidos por usuário; o Token mais antigo entra na blacklist quando o limite é excedido
- Bloqueio de conta: 5 falhas consecutivas de login bloqueiam por 15 minutos

### Modelo de permissões RBAC
- Usuário → papel → permissão (muitos para muitos)
- Tipos de permissão: type=1 (menu) / type=2 (botão) / type=3 (API)
- Formato do identificador de permissão: `{method}.{path}` ex.: `get.admin/user`
- Identificador de superadministrador: `*` (ignora todas as verificações de permissão)
- Árvore de permissões: parent_id autorreferenciado, suporta profundidade ilimitada

## 7. Defesa em profundidade de segurança (18 camadas)

```
Camada 1   Código de verificação por clique → verificação humano-máquina obrigatória no login/registro
Camada 2   Confirmação dupla de senha → operações sensíveis (exclusão/pagamento/término de contrato) exigem senha
Camada 3   Verificação aleatória poster → código de verificação aleatório em operações sensíveis de alta frequência
Camada 4   security-php → varredura automática de segurança no ciclo da requisição
Camada 5   SecurityFilter → bloqueio de XSS/injeção de SQL/path traversal/injeção de comandos/CSRF
Camada 6   Segurança de transmissão → HTTPS + AES-256-CBC
Camada 7   Autenticação JWT → HS256, expiração em 2h + refresh token
Camada 8   Controle de concorrência → máx. 3 Tokens por usuário; excedeu vai para a blacklist
Camada 9   Bloqueio de conta → 5 falhas consecutivas bloqueiam por 15 minutos
Camada 10  Autorização RBAC → controle de permissões com granularidade method.path
Camada 11  Proteção por limite de taxa → janela deslizante Redis, Lua atômico
Camada 12  Proteção de ID → codificação Hashids, impossível reverter para o ID real
Camada 13  Criptografia do corpo da requisição → AES-256-CBC em campos sensíveis
Camada 14  Criptografia de armazenamento → campos do banco criptografados com encryptable
Camada 15  Mascaramento na exibição → mascaramento de telefone/e-mail/CPF
Camada 16  Rastreabilidade de auditoria → registro completo via OperationLog (com detecção automática da origem)
Camada 17  Proteção de cabeçalhos HTTP → CSP + X-Permitted-Cross-Domain-Policies
Camada 18  Proteção de saída → marca d'água de direitos autorais em PDF (não removível) + mascaramento de dados sensíveis no Excel
```

## 8. Política de limite de taxa

Baseada no algoritmo de janela deslizante com Redis Sorted Set, executada atomicamente via script Lua:

| Interface | Limite |
|------|------|
| Padrão | 60 vezes/minuto/IP/rota |
| POST /api/v1/auth/login | 10 vezes/minuto |
| POST /api/v1/auth/register | 5 vezes/minuto |

Ao exceder o limite, retorna 429 + cabeçalhos `X-RateLimit-Limit/Remaining/Reset/Retry-After`.

## 9. Política de versão da API

- A versão vai no próprio caminho da API (ex.: `/api/v1/*`, `/service/v1/*`), não em um cabeçalho
- Caminhos de versão inexistentes retornam 404 diretamente do roteador (sem middleware)
- Controladores organizados por versão: `app/api/{version}/controller/`
- Adicionar versão = registrar um novo grupo de rotas `/{namespace}/v{version}` (controladores em `app/api/v1/controller/`); caminhos de versão inexistentes retornam 404 via FastRoute

## 10. Arquitetura de implantação

```
┌─────────────────────────────────────┐
│            CloudFlare DNS + CDN      │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│          Nginx (:443)                │
│   proxy reverso + Gzip + término SSL │
│   arquivos estáticos: Flutter Web build/│
└──────┬──────────────────┬───────────┘
       │                  │
┌──────▼──────┐    ┌──────▼──────┐
│ admin webman│    │service webman│
│ :8787       │    │ :8788       │
│ API do painel│    │ API do portal│
└──────┬──────┘    └──────┬──────┘
       │                  │
       └────────┬─────────┘
                │
┌───────────────┼───────────────────┐
│               │                   │
┌▼──────┐  ┌────▼───┐  ┌──────────▼┐
│MySQL  │  │ Redis  │  │Elasticsearch│
│:3306  │  │ :6379  │  │ :9200      │
└───────┘  └────────┘  └────────────┘
```

### Serviços Docker Compose

| Serviço | Imagem | Descrição |
|------|------|------|
| nginx | nginx:alpine | Proxy reverso + arquivos estáticos |
| admin | build Dockerfile | PHP 8.3 + OPcache |
| service | build Dockerfile | PHP 8.3 + OPcache |
| mysql | mysql:8.0 | Persistência com volume de dados |
| redis | redis:7-alpine | Cache/limite de taxa/sessões |
| elasticsearch | elasticsearch:8.x | Busca em texto completo |

## 11. Design de internacionalização (i18n)

### Estrutura dos arquivos de idioma

O sistema suporta chinês simplificado (zh_CN) e inglês (en), com chinês como padrão.

**Back-end PHP:**
```
resource/translations/
├── zh_CN/
│   └── messages.php    # pacote de idioma chinês (42+ chaves de tradução)
└── en/
    └── messages.php    # pacote de idioma inglês
```

Impulsionado por symfony/translation, configurado em `config/translation.php`:
- `locale`: `zh_CN`
- `fallback_locale`: `['zh_CN', 'en']`
- `path`: `resource/translations`

Nos controladores, as traduções são obtidas com `$this->__('key')`:
```php
return $this->success([], $this->__('create_success'));
return $this->fail($this->__('community.name_required'), 422);
```

Internamente, o método `__()` chama a função global `trans()` do webman; se a tradução não existir, retorna a própria chave.

**Flutter Web:**
```
apps/flutter/lib/i18n/
└── messages.dart       # AppTranslations extends GetX Translations
```

Usa as `Translations` do GetX, com 101 chaves de tradução, por meio da extensão `.tr`:
```dart
Text('login_btn'.tr)   // chinês: "登 录", inglês: "Login"
Text('phone_hint'.tr)  // "请输入手机号" / "Enter phone number"
```

Alternância de idioma:
```dart
Get.updateLocale(Locale('zh', 'CN'));  // alternar para chinês
Get.updateLocale(Locale('en', 'US'));  // alternar para inglês
```

### Classificação das chaves de tradução

| Categoria | Exemplo de chave PHP | Exemplo de chave Flutter |
|------|-----------|---------------|
| Geral | `success`, `fail`, `not_found` | `confirm`, `cancel`, `save` |
| Autenticação | `auth.login_success`, `auth.*` | `login_btn`, `phone_hint` |
| Condomínio | `community.name_required` | - |
| Cobranças | `fee.bill_not_found`, `fee.*` | `fee_management`, `bill_status` |
| Reparos | `repair.not_found`, `repair.*` | `repair_submit`, `urgency_normal` |
| Reclamações | `complaint.submit_success` | `complaint_type`, `type_complaint` |
| Pessoal | - | `profile`, `change_password` |

**HarmonyOS:** usa qualificadores de recursos `resources/base/element/string.json` + `resources/en_US/element/string.json` (implementados junto com a criação do projeto HarmonyOS).

## 12. Estratégia de testes

### Fluxo de testes TDD

O projeto segue o fluxo TDD (desenvolvimento orientado a testes): vermelho → verde → refatoração.

```
RED: escrever o teste primeiro, observar a falha
  ↓
GREEN: escrever o código mínimo para passar no teste
  ↓
REFACTOR: limpar o código, mantendo os testes verdes
```

### Cobertura de testes

| Camada | Framework | Conteúdo |
|----|---------|---------|
| Serviços base | PHPUnit | Geração de ID Snowflake, codificação/decodificação Hashids, formato de resposta |
| Banco de dados | PHPUnit + PDO | Validação da estrutura das tabelas (chave primária BIGINT, sem autoincremento, prefixo management_) |
| Internacionalização | PHPUnit | Existência dos arquivos de tradução, consistência das chaves zh/en |
| Endpoints de API | PHPUnit | Verificação de saúde, formato de resposta |
| Middlewares | Testes de integração | Autenticação JWT, limite de taxa, permissões |

### Executar os testes

```bash
cd admin && php vendor/bin/phpunit    # Painel: 60 testes, 164 asserções
cd service && php vendor/bin/phpunit  # Portal: 18 testes, 45 asserções, 100% de aprovação
```

## 13. Arquitetura do front-end

### Flutter Web (estilo desktop PC)

```
apps/flutter/lib/
├── main.dart                    # Entrada, inicializa ApiService + AuthService
├── app.dart                     # GetMaterialApp, tabela de rotas + tema + i18n
├── config/
│   ├── api_config.dart          # Constantes dos endpoints da API (aponta para service :8788)
│   └── theme.dart               # Tema Material 3 (paleta Ant Design)
├── services/
│   ├── api_service.dart         # Singleton Dio + interceptador JWT + refresh automático em 401
│   ├── auth_service.dart        # Login/logout/persistência do Token
│   └── storage_service.dart     # Encapsulamento de shared_preferences
├── i18n/
│   └── messages.dart            # Traduções GetX (101 chaves, zh_CN/en)
├── pages/
│   ├── login/                   # Página de login estilo PC (Card centralizado + validação de formulário)
│   ├── home/                    # Painel de controle (4 StatCards + lista de anúncios)
│   ├── fee/                     # Lista de faturas / detalhes / modal de pagamento
│   ├── repair/                  # Lista de reparos / envio / detalhes + avaliação
│   └── profile/                 # Dados pessoais / alterar senha / sair
└── widgets/
    └── stat_card.dart           # Componente de cartão de estatística (ícone + título + valor)
```

### App móvel HarmonyOS

```
apps/harmonyos/entry/src/main/ets/
├── services/
│   ├── ApiService.ets           # Encapsulamento de @ohos.net.http, Bearer Token
│   └── AuthService.ets          # Login/logout (persistência com Preference)
├── model/
│   └── Models.ets               # Definições de interfaces TypeScript
├── pages/
│   ├── LoginPage.ets            # Login com telefone + senha
│   └── HomePage.ets             # Painel de controle (cartões de estatística + lista de anúncios)
└── resources/
    ├── base/element/string.json # recursos em chinês
    └── en_US/element/string.json# recursos em inglês
```

### Seleção de tecnologias

| Camada | Flutter Web | HarmonyOS |
|----|------------|-----------|
| Gerenciamento de estado | GetX | @State + @Prop |
| HTTP | Dio + interceptador JWT | @ohos.net.http |
| Persistência | shared_preferences | @ohos.data.preferences |
| Gráficos | fl_chart | Componente Web + ECharts |
| Internacionalização | Traduções GetX | qualificadores de recursos |
| Rotas | rotas nomeadas GetX | router.pushUrl/replaceUrl |

## 14. Arquitetura das funcionalidades estendidas

### Central de notificações
Template de mensagem → geração da notificação → envio multicanal (no app/SMS/e-mail/push)

### Fluxo de aprovação
Configuração do tipo de aprovação → envio da instância → fluxo de etapas (aprovar/rejeitar) → notificar o próximo aprovador

### Fluxo de pagamento
Criação do pedido de pagamento → pagamento por terceiro → callback assíncrono → atualização do status da fatura → registro do log de pagamento

### Votação de proprietários
Publicação da votação → voto do proprietário (ponderado por área) → apuração em tempo real → estatísticas do resultado

### Escalonamento automático de SLA
Correspondência das regras de SLA → verificação agendada de timeout → escalonamento automático → registro de multa

### Cobrança de inadimplência inteligente
Correspondência da estratégia → detecção de atraso → geração automática da tarefa de cobrança → execução da ação de cobrança

### Gestão de inspeções
Distribuição de tarefas → check-in por GPS no app → upload de fotos → marcação de anomalias → estatísticas de conclusão

### Gestão de grupo
Grupo → vínculo de condomínios → consolidação de dados entre condomínios (propriedades/proprietários/cobranças/reparos)

## 15. Documentação da API

A documentação da API é gerada automaticamente a partir das anotações dos controladores com `hg/apidoc`, agrupada por funcionalidade.

**Painel de administração** (`http://localhost:8787/apidoc`): 10 grupos — 57 controladores com anotações injetadas (Base/Docs/Install não agrupados)

| Grupo | Quantidade | Controladores |
|------|------|--------|
| `common` | 2 | Auth, Captcha |
| `dashboard` | 3 | Dashboard, Metrics, Health |
| `export` | 1 | Export |
| `import` | 1 | Import |
| `upload` | 1 | Upload |
| `system` | 6 | User, Role, Permission, Config, Log, Profile |
| `property-core` | 12 | Community, Building, Unit, RoomType, Room, Owner, Tenant, FeeType, FeeBill, FeePayment, Repair, Announcement |
| `property-aux` | 9 | Parking(3), Equipment(2), Complaint, Visitor, Contract, Finance |
| `property-adv` | 11 | Activity(2), Patrol(2), Cleaning(2), Green(2), Energy(2), Staff |
| `extensions` | 11 | Notification, Approval, Payment, Vote, Sla, Collection, Inspection, Mall, Face, Group, Knowledge |

**Portal de proprietários** (`http://localhost:8788/apidoc`): 9 grupos — 17 controladores com anotações injetadas

| Grupo | Quantidade | Controladores |
|------|------|--------|
| `public` | 2 | Auth, Captcha |
| `home` | 2 | Home, Room |
| `fee` | 1 | Fee |
| `repair` | 1 | Repair |
| `feedback` | 2 | Complaint, Announcement |
| `parking` | 2 | Parking, Visitor |
| `activity` | 1 | Activity |
| `profile` | 1 | Profile |
| `extensions` | 5 | Notification, Vote, Mall, Knowledge, Face |

### Padrão de anotações

```php
/**
 * Lista de condomínios
 * @Apidoc\Method("GET")
 * @Apidoc\Url("/admin/community")
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(1)
 * @Apidoc\Param("keyword", type="string", require=false, desc="Palavra-chave de busca")
 * @Apidoc\Param(ref="pagination")
 * @Apidoc\Returned("id", type="string", desc="hashid")
 */
```

### Blocos de definições comuns

| Nome do bloco | Conteúdo |
|------|------|
| `pagination` | Parâmetros de paginação page/page_size |
| `searchParams` | Filtros de busca keyword/status |
| `dateRange` | Intervalo de datas start_date/end_date |
| `passwordConfirm` | Confirmação de senha password |

## 16. Formato de resposta unificado

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| code | Significado |
|------|------|
| 0 | Sucesso |
| 400 | Erro de parâmetros |
| 401 | Não autenticado |
| 403 | Sem permissão |
| 404 | Não encontrado |
| 422 | Falha na validação |
| 429 | Requisições em excesso |
| 500 | Erro do servidor |
