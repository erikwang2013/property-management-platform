# Documentação da API (API Reference)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Visão geral

- A API do painel de administração roda em `http://localhost:8787`
- A API do portal de proprietários roda em `http://localhost:8788`
- Formato de resposta unificado: `{"code": 0, "message": "success", "data": {...}}`
- Todos os campos de ID usam codificação hashids na transmissão
- A versão da API é controlada pelo cabeçalho `API-Version` (padrão `v1`)
- O idioma é controlado pelo cabeçalho `Accept-Language` (`zh-CN` / `en-US`, padrão `zh-CN`)

### Documentação online da API

Após iniciar o serviço, acesse a documentação interativa gerada automaticamente pelo `hg/apidoc`:

| Endpoint | Endereço | Número de grupos |
|----|------|--------|
| Painel de administração | `http://localhost:8787/apidoc` | 10 grupos (common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload) |
| Portal de proprietários | `http://localhost:8788/apidoc` | 9 grupos (API pública/início/cobranças/reparos/feedback/estacionamento/atividades/pessoal/extensões) |

---

## API do painel de administração (admin :8787)

### Endpoints públicos — sem autenticação

#### POST /api/captcha/generate
Obtém o código de verificação por clique.

Parâmetros da requisição: nenhum

Resposta:
```json
{
  "code": 0,
  "data": {
    "key": "captcha_key_string",
    "image": "base64_encoded_png",
    "extra": { "targets": ["树", "鸟", "花"] }
  }
}
```

#### POST /api/captcha/verify
Valida o código de verificação por clique.

Parâmetros da requisição:
| Parâmetro | Tipo | Descrição |
|------|------|------|
| key | string | Key do código de verificação, retornada pelo generate |
| clicks | array | Coordenadas dos cliques [{x, y}, ...] |

Resposta:
```json
{
  "code": 0,
  "data": { "valid": true }
}
```

Em caso de falha na validação, `code` é 422 e `data.valid` é `false`.

#### POST /api/auth/login
Login do administrador.

Parâmetros da requisição:
| Parâmetro | Tipo | Descrição |
|------|------|------|
| username | string | Nome de usuário |
| password | string | Senha |
| captcha_key | string | Key do código de verificação |
| clicks | array | Coordenadas dos cliques [{x, y}, ...] |

Resposta:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "user": { "id": "aB3xK9mW...", "username": "admin", "real_name": "管理员" }
  }
}
```

#### POST /api/auth/refresh
Atualiza o Token.

Parâmetros da requisição:
| Parâmetro | Tipo | Descrição |
|------|------|------|
| refresh_token | string | Token de atualização |

Resposta:
```json
{
  "code": 0,
  "data": { "access_token": "eyJ..." }
}
```

#### GET /health
Verificação de saúde.

#### GET /metrics
Métricas de monitoramento Prometheus.

#### GET /api/docs
Documentação OpenAPI.

---

### Endpoints do painel de administração — com autenticação (Bearer Token)

Todos os endpoints têm o prefixo `/admin` e exigem o cabeçalho `Authorization: Bearer {access_token}`.

#### Painel de controle

**GET /admin/dashboard**
Obtém os dados estatísticos do painel de controle.

#### Gestão de usuários administradores

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/user | Lista de usuários (?keyword=&status=&page=&page_size=) |
| POST | /admin/user | Criar usuário |
| GET | /admin/user/{hashid} | Detalhes do usuário |
| PUT | /admin/user/{hashid} | Atualizar usuário |
| DELETE | /admin/user/{hashid} | Excluir usuário (exige confirmação de senha) |
| POST | /admin/user/batch/destroy | Exclusão em lote |
| POST | /admin/user/batch/status | Ativar/desativar em lote |
| POST | /admin/import/users | Importar usuários via Excel |

#### Gestão de papéis e permissões

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/role | Lista de papéis |
| POST | /admin/role | Criar papel |
| GET | /admin/role/{hashid} | Detalhes do papel |
| PUT | /admin/role/{hashid} | Atualizar papel |
| DELETE | /admin/role/{hashid} | Excluir papel |
| GET | /admin/permission | Lista de permissões (em árvore) |
| POST | /admin/permission | Criar permissão |
| PUT | /admin/permission/{hashid} | Atualizar permissão |
| DELETE | /admin/permission/{hashid} | Excluir permissão |

#### Configuração do sistema

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/config | Lista de configurações (?group=) |
| POST | /admin/config | Criar configuração |
| PUT | /admin/config/{hashid} | Atualizar configuração |
| DELETE | /admin/config/{hashid} | Excluir configuração |

#### Logs de operações

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/log | Lista de logs (?user_id=&action=&method=&source=&start_date=&end_date=) |

#### Central pessoal

| Método | Caminho | Descrição |
|------|------|------|
| PUT | /admin/profile | Alterar dados pessoais |
| PUT | /admin/profile/password | Alterar senha |
| POST | /admin/profile/logout | Sair |

#### Exportação

| Método | Caminho | Descrição |
|------|------|------|
| POST | /admin/export/excel | Exportar Excel ({ table, columns, conditions, title }) |
| POST | /admin/export/pdf | Exportar PDF ({ type, title, data }) |

---

### Gestão de propriedades — endpoints do painel de administração

#### Gestão de condomínios

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/community | Lista (?keyword=&status=) |
| POST | /admin/community | Criar |
| GET | /admin/community/{hashid} | Detalhes |
| PUT | /admin/community/{hashid} | Atualizar |
| DELETE | /admin/community/{hashid} | Excluir (exige senha) |

#### Gestão de edifícios

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/building | Lista (?community_id=&keyword=) |
| POST | /admin/building | Criar |
| GET | /admin/building/{hashid} | Detalhes |
| PUT | /admin/building/{hashid} | Atualizar |
| DELETE | /admin/building/{hashid} | Excluir |

#### Gestão de unidades

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/unit | Lista (?building_id=) |
| POST | /admin/unit | Criar |
| GET | /admin/unit/{hashid} | Detalhes |
| PUT | /admin/unit/{hashid} | Atualizar |
| DELETE | /admin/unit/{hashid} | Excluir |

#### Gestão de layouts

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/room-type | Lista |
| POST | /admin/room-type | Criar |
| GET | /admin/room-type/{hashid} | Detalhes |
| PUT | /admin/room-type/{hashid} | Atualizar |
| DELETE | /admin/room-type/{hashid} | Excluir |

#### Gestão de propriedades

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/room | Lista (?community_id=&building_id=&unit_id=&status=) |
| POST | /admin/room | Criar |
| GET | /admin/room/{hashid} | Detalhes |
| PUT | /admin/room/{hashid} | Atualizar |
| DELETE | /admin/room/{hashid} | Excluir |
| GET | /admin/room/tree | Árvore de imóveis (condomínio→edifício→unidade→imóvel) |

#### Gestão de proprietários

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/owner | Lista (?keyword=&status=) |
| POST | /admin/owner | Criar |
| GET | /admin/owner/{hashid} | Detalhes (inclui propriedades vinculadas) |
| PUT | /admin/owner/{hashid} | Atualizar |
| DELETE | /admin/owner/{hashid} | Excluir (exige senha) |
| POST | /admin/owner/batch/import | Importação em lote via Excel |
| POST | /admin/owner/batch/destroy | Exclusão em lote |

#### Gestão de inquilinos

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/tenant | Lista (?room_id=&status=) |
| POST | /admin/tenant | Criar |
| GET | /admin/tenant/{hashid} | Detalhes |
| PUT | /admin/tenant/{hashid} | Atualizar |
| DELETE | /admin/tenant/{hashid} | Excluir |

#### Tipos de cobrança

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/fee-type | Lista |
| POST | /admin/fee-type | Criar |
| GET | /admin/fee-type/{hashid} | Detalhes |
| PUT | /admin/fee-type/{hashid} | Atualizar |
| DELETE | /admin/fee-type/{hashid} | Excluir |

#### Gestão de faturas

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/fee-bill | Lista (?community_id=&status=&due_date_start=&due_date_end=) |
| POST | /admin/fee-bill | Criar fatura |
| GET | /admin/fee-bill/{hashid} | Detalhes |
| PUT | /admin/fee-bill/{hashid} | Atualizar |
| DELETE | /admin/fee-bill/{hashid} | Excluir |
| POST | /admin/fee-bill/batch/generate | Gerar faturas em lote |

#### Registros de pagamento

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/fee-payment | Lista (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | Registro de cobrança offline |

#### Gestão de reparos

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/repair | Lista (?status=&category=) |
| POST | /admin/repair | Criar |
| GET | /admin/repair/{hashid} | Detalhes (inclui registros de andamento) |
| PUT | /admin/repair/{hashid} | Atualizar |
| DELETE | /admin/repair/{hashid} | Excluir |
| PUT | /admin/repair/{id}/assign | Despachar ({ staff_id }) |
| POST | /admin/repair/{id}/progress | Atualizar andamento ({ status_to, remark }) |

#### Gestão de anúncios

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/announcement | Lista (?community_id=&category=&is_published=) |
| POST | /admin/announcement | Criar |
| GET | /admin/announcement/{hashid} | Detalhes |
| PUT | /admin/announcement/{hashid} | Atualizar |
| DELETE | /admin/announcement/{hashid} | Excluir |

#### Gestão de estacionamento

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/parking-space | Lista (?community_id=) |
| POST | /admin/parking-space | Criar vaga |
| PUT | /admin/parking-space/{hashid} | Atualizar |
| DELETE | /admin/parking-space/{hashid} | Excluir |
| GET | /admin/parking-vehicle | Lista (?owner_id=&space_id=) |
| POST | /admin/parking-vehicle | Criar veículo |
| PUT | /admin/parking-vehicle/{hashid} | Atualizar |
| DELETE | /admin/parking-vehicle/{hashid} | Excluir |
| GET | /admin/parking-record | Registros de estacionamento (?vehicle_id=&date_start=&date_end=) |

#### Gestão de equipamentos

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/equipment | Lista (?community_id=&category=&status=) |
| POST | /admin/equipment | Criar |
| PUT | /admin/equipment/{hashid} | Atualizar |
| DELETE | /admin/equipment/{hashid} | Excluir |
| GET | /admin/equipment-maintenance | Registros de manutenção (?equipment_id=) |
| POST | /admin/equipment-maintenance | Criar manutenção |

#### Tratamento de reclamações

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/complaint | Lista (?type=&status=) |
| GET | /admin/complaint/{hashid} | Detalhes |
| PUT | /admin/complaint/{id}/handle | Tratar ({ handler_remark }) |
| POST | /admin/complaint/{id}/visit | Retorno ({ visitor_remark }) |

#### Aprovação de visitantes

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/visitor | Lista (?status=) |
| PUT | /admin/visitor/{id}/approve | Aprovar |

#### Gestão de contratos

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/contract | Lista (?contract_type=&status=) |
| POST | /admin/contract | Criar |
| PUT | /admin/contract/{hashid} | Atualizar |
| DELETE | /admin/contract/{hashid} | Excluir |

#### Gestão financeira

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/finance-income | Lista de receitas (?income_type=&date_start=&date_end=) |
| POST | /admin/finance-income | Registrar receita |
| GET | /admin/finance-expense | Lista de despesas |
| POST | /admin/finance-expense | Registrar despesa |
| GET | /admin/finance/statistics | Estatísticas mensais de receitas/despesas (?year=) |

#### Painel de propriedades

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/dashboard/property | Estatísticas da propriedade (a receber/taxa de ocupação/reparos/reclamações/tendência de receitas-despesas) |
| POST | /admin/export/property-excel | Exportação Excel dos dados da propriedade ({ type: owners|bills }) |

#### Patrulha de segurança

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/security-patrol | Lista (?community_id=) |
| POST | /admin/security-patrol | Criar rota |
| GET | /admin/patrol-record | Registros (?patrol_id=&staff_id=) |
| POST | /admin/patrol-record | Criar registro |

#### Gestão de limpeza

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/cleaning-area | Lista de áreas |
| POST | /admin/cleaning-area | Criar área |
| GET | /admin/cleaning-record | Registros (?area_id=) |
| POST | /admin/cleaning-record | Criar registro |

#### Gestão de paisagismo

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/green-area | Lista de áreas |
| POST | /admin/green-area | Criar área |
| GET | /admin/green-maintenance | Registros de manutenção (?area_id=) |
| POST | /admin/green-maintenance | Criar registro |

#### Atividades comunitárias

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/activity | Lista (?status=) |
| POST | /admin/activity | Criar atividade |
| PUT | /admin/activity/{hashid} | Atualizar |
| DELETE | /admin/activity/{hashid} | Excluir |
| GET | /admin/activity-signup | Lista de inscrições (?activity_id=) |
| PUT | /admin/activity-signup/{id}/checkin | Check-in |

#### Gestão de consumo de energia

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/energy-meter | Lista de medidores (?room_id=&meter_type=) |
| POST | /admin/energy-meter | Criar medidor |
| GET | /admin/energy-record | Registros de leitura (?meter_id=&date_start=&date_end=) |
| POST | /admin/energy-record | Criar registro |

#### Gestão de funcionários

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/staff | Lista (?community_id=&status=) |
| POST | /admin/staff | Criar |
| PUT | /admin/staff/{hashid} | Atualizar |
| DELETE | /admin/staff/{hashid} | Excluir |
| POST | /admin/staff/batch/status | Ativar/desativar em lote |

#### Notificações

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/notification-template | Lista de templates |
| POST | /admin/notification-template | Criar template |
| PUT | /admin/notification-template/{hashid} | Atualizar template |
| DELETE | /admin/notification-template/{hashid} | Excluir template |
| GET | /admin/notification | Lista de mensagens (?type=&is_read=) |
| POST | /admin/notification/send | Enviar notificação manual |

#### Fluxo de aprovação

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/approval-type | Lista de tipos de aprovação |
| POST | /admin/approval-type | Criar tipo de aprovação |
| GET | /admin/approval | Lista de aprovações (?status=) |
| GET | /admin/approval/{hashid} | Detalhes da aprovação |
| POST | /admin/approval | Enviar aprovação |
| PUT | /admin/approval/{hashid}/approve | Aprovar (aprovar/rejeitar) |

#### Gestão de pagamentos

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/payment-order | Lista de pedidos |
| GET | /admin/payment-order/{hashid} | Detalhes do pedido |
| POST | /admin/payment-order/{hashid}/refund | Reembolsar |
| GET | /admin/payment/statistics | Estatísticas de pagamento |

#### Votação de proprietários

| Método | Caminho | Descrição |
|------|------|------|
| GET | /admin/vote | Lista de votações (?status=) |
| POST | /admin/vote | Criar votação |
| GET | /admin/vote/{hashid}/statistics | Estatísticas de apuração |
| PUT | /admin/vote/{hashid}/publish | Publicar votação |
| PUT | /admin/vote/{hashid}/end | Encerrar votação |

#### Gestão de SLA · Cobrança inteligente · Inspeção · Loja · Reconhecimento facial · Grupo · Base de conhecimento

(Endpoints completos no arquivo `docs/API.md`)

---

## API do portal de proprietários (service :8788)

### Endpoints públicos — sem autenticação

#### POST /api/captcha/generate
Obtém o código de verificação por clique. (Idêntico ao do painel de administração)

#### POST /api/captcha/verify
Valida o código de verificação por clique. (Requisição/resposta idênticas às do painel de administração)

#### POST /api/auth/login
Login do proprietário.

Parâmetros da requisição:
| Parâmetro | Tipo | Descrição |
|------|------|------|
| phone | string | Telefone |
| password | string | Senha |
| captcha_key | string | Key do código de verificação |
| clicks | array | Coordenadas dos cliques |

Resposta:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "owner": { "id": "xB9k...", "name": "张三", "phone": "138****1234" }
  }
}
```

#### POST /api/auth/register
Registro do proprietário.

Parâmetros da requisição:
| Parâmetro | Tipo | Descrição |
|------|------|------|
| phone | string | Telefone |
| password | string | Senha (mínimo 6 caracteres) |
| name | string | Nome |
| captcha_key | string | Key do código de verificação |
| clicks | array | Coordenadas dos cliques |
| room_id | string | (opcional) hashid do imóvel a vincular |
| id_card_last4 | string | (opcional) últimos 4 dígitos do documento |

#### POST /api/auth/refresh
Atualiza o Token.

---

### Endpoints do portal de proprietários — com autenticação (Bearer Token)

Todos os endpoints têm o prefixo `/service` e exigem o cabeçalho `Authorization: Bearer {access_token}`.

#### Início

**GET /service/home**

Resposta:
```json
{
  "code": 0,
  "data": {
    "room_count": 2,
    "pending_amount": "1250.00",
    "pending_bill_count": 3,
    "repairing_count": 1,
    "announcements": [{ "id": "xB9k...", "title": "停水通知", "published_at": "2026-05-20 09:00" }]
  }
}
```

#### Minhas propriedades

| Método | Caminho | Descrição |
|------|------|------|
| GET | /service/rooms | Minha lista de propriedades |
| GET | /service/room/{hashid} | Detalhes da propriedade (inclui área, orientação, titularidade, informações do condomínio) |

#### Gestão de cobranças

| Método | Caminho | Descrição |
|------|------|------|
| GET | /service/fees/bills | Lista de faturas (?status=0 não pago/1 parcialmente pago/2 pago/3 em atraso) |
| GET | /service/fees/bill/{hashid} | Detalhes da fatura (inclui tipo de cobrança, registros de pagamento) |
| GET | /service/fees/payments | Histórico de pagamentos |
| POST | /service/fees/pay | Pagamento online ({ bill_id, payment_method, password }) |
| GET | /service/fees/statistics | Estatísticas de cobranças (?year=2026) |

#### Reparos

| Método | Caminho | Descrição |
|------|------|------|
| GET | /service/repairs | Lista de reparos (?status=) |
| GET | /service/repair/{hashid} | Detalhes do reparo (inclui linha do tempo do andamento) |
| POST | /service/repair | Enviar solicitação de reparo ({ room_id, category, urgency, description, images[], scheduled_at }) |
| DELETE | /service/repair/{hashid} | Cancelar (exige senha, { password }) |
| POST | /service/repair/{hashid}/rate | Avaliar ({ rating: 1-5, feedback }) |

#### Reclamações e sugestões

| Método | Caminho | Descrição |
|------|------|------|
| GET | /service/complaints | Lista de reclamações |
| GET | /service/complaint/{hashid} | Detalhes da reclamação (inclui andamento do tratamento) |
| POST | /service/complaint | Enviar reclamação ({ type, category, title, content, is_anonymous, images[] }) |
| POST | /service/complaint/{hashid}/satisfaction | Avaliação de satisfação ({ satisfaction: 1-5 }) |

#### Anúncios

| Método | Caminho | Descrição |
|------|------|------|
| GET | /service/announcements | Lista de anúncios (?category=) |
| GET | /service/announcement/{hashid} | Detalhes do anúncio |

#### Estacionamento

| Método | Caminho | Descrição |
|------|------|------|
| GET | /service/parking/vehicles | Meus veículos |
| GET | /service/parking/spaces | Minhas vagas |
| GET | /service/parking/records | Registros de estacionamento |

#### Visitantes

| Método | Caminho | Descrição |
|------|------|------|
| GET | /service/visitors | Meus agendamentos de visitante |
| POST | /service/visitor | Criar agendamento (gera código de acesso) |
| PUT | /service/visitor/{hashid} | Alterar agendamento |
| DELETE | /service/visitor/{hashid} | Cancelar agendamento |

#### Atividades comunitárias

| Método | Caminho | Descrição |
|------|------|------|
| GET | /service/activities | Lista de atividades (?status=) |
| GET | /service/activity/{hashid} | Detalhes da atividade |
| POST | /service/activity/{hashid}/signup | Inscrever-se |
| POST | /service/activity/{hashid}/cancel | Cancelar inscrição |

#### Dados pessoais

| Método | Caminho | Descrição |
|------|------|------|
| GET | /service/profile | Dados pessoais |
| PUT | /service/profile | Alterar ({ name, email, gender, birthday }) |
| PUT | /service/profile/password | Alterar senha ({ old_password, new_password }) |
| POST | /service/profile/logout | Sair |

---

## API aberta — autenticação por API Key

Interfaces de leitura voltadas para entrada externa, destinadas a sistemas de terceiros (integração com plataformas imobiliárias, painéis de dados etc.). Prefixo `/open`, todas somente leitura.

### Método de autenticação

Cada requisição deve incluir o cabeçalho `X-API-Key`, cujo valor é uma Key gerada por `scripts/gen_api_key.php` (64 dígitos hex, apenas o resumo SHA-256 é armazenado no banco):

```bash
curl -H "X-API-Key: <suaKey>" http://localhost:8788/open/announcements
```

- Key ausente ou incorreta retorna `401` (`{"code":401,"message":"无效的API Key","data":[]}`)
- Gerenciamento da Key: gere com `php scripts/gen_api_key.php [--name=finalidade]`; para desativar/excluir, altere diretamente a tabela `management_api_key` (`status=0` desativa e a Key perde a validade imediatamente)

### Endpoints

#### GET /open/announcements — lista de anúncios

Parâmetros: `page` (padrão 1), `category` (opcional). A estrutura da resposta é idêntica à de `/service/announcements`.

```bash
curl -H "X-API-Key: <suaKey>" "http://localhost:8788/open/announcements?page=1"
```

#### GET /open/bills — consulta de faturas

Parâmetros: `bill_number` (obrigatório, número da fatura). Retorna os detalhes de uma fatura (incluindo tipo de cobrança, número do imóvel, valor em débito). Retorna 404 se não existir.

```bash
curl -H "X-API-Key: <suaKey>" "http://localhost:8788/open/bills?bill_number=B202608160001"
```

#### GET /open/repairs — consulta de status de reparos

Parâmetros: `order_number` (obrigatório, número da ordem de reparo). Retorna o status atual e a linha do tempo de andamento (array `progress`). Retorna 404 se não existir.

```bash
curl -H "X-API-Key: <suaKey>" "http://localhost:8788/open/repairs?order_number=R202608160001"
```

---

## Códigos de erro

| code | Significado | Descrição |
|------|------|------|
| 0 | Sucesso | Resposta normal |
| 400 | Erro de requisição | Formato de parâmetro incorreto |
| 401 | Não autenticado | Token ausente/expirado/inválido/na blacklist |
| 403 | Sem permissão | O papel do usuário não contém a permissão necessária / conta desativada |
| 404 | Não encontrado | Recurso não encontrado |
| 405 | Método não permitido | Método HTTP diferente de GET/POST/PUT/DELETE/OPTIONS |
| 413 | Corpo da requisição grande demais | Excede 10MB |
| 415 | Tipo de mídia não suportado | Content-Type não é JSON nem form-urlencoded |
| 422 | Falha na validação | Parâmetros do formulário fora das regras / falha na confirmação de senha / código de verificação incorreto |
| 429 | Requisições em excesso | Limite de taxa acionado / conta bloqueada |
| 500 | Erro do servidor | Exceção inesperada |

## Cabeçalhos de limite de taxa

Ao acionar o limite de taxa, retorna 429 e os cabeçalhos de resposta incluem:

| Cabeçalho | Descrição |
|--------|------|
| X-RateLimit-Limit | Número máximo de requisições |
| X-RateLimit-Remaining | Número restante |
| X-RateLimit-Reset | Hora de reinício (timestamp Unix) |
| Retry-After | Segundos sugeridos de espera antes de tentar novamente |
