# Comparação de Edições (Editions Comparison)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

O Sistema de Gestão de Propriedades é dividido em três edições: Básica (Lite), Padrão (Standard) e Completa (Full), com progressão cumulativa entre elas.

---

## Visão geral

| Métrica | Básica (Lite) | Padrão (Standard) | Completa (Full) |
|------|:-----------:|:---------------:|:-----------:|
| Tabelas do banco | **21** | **31** | **65** |
| Modelos Eloquent | 19 | 30 | 58 |
| Controladores do painel | 17 | 28 | 47 |
| Controladores do portal de proprietários | 9 | 12 | 17 |
| Rotas de API | 35 | 70 | 178 |
| Módulos de negócio | 10 | 18 | 34 |
| Camadas de segurança | 18 | 18 | 18 |

---

## Comparação dos módulos funcionais

### Básica (Lite)

Gestão de propriedades principal, incluindo o sistema geral do painel de administração + 10 módulos de negócio principal.

**Painel de administração**: painel de controle, CRUD de usuários/papéis/permissões/configurações/logs, CRUD de condomínio/edifício/unidade/layout/propriedade/proprietário/inquilino/cobranças/reparos/anúncios

**Portal de proprietários**: registro/login, início, minhas propriedades, pagamento de faturas, envio/avaliação de reparos, visualização de anúncios, dados pessoais

---

### Padrão (Standard)

Além da edição básica, adiciona 6 módulos de negócios auxiliares + visualização em painel + exportação de dados.

**Novidades no painel de administração**: CRUD de vagas/veículos, cadastro de equipamentos + manutenção, tratamento de reclamações + retorno, aprovação de visitantes, gestão de contratos, gestão de receitas/despesas + estatísticas

**Novidades no portal de proprietários**: meus veículos/vagas, registros de estacionamento, agendamento de visitante/código de acesso

---

### Completa (Full)

Além da edição padrão, adiciona módulos avançados + 12 funcionalidades estendidas.

**Novidades no painel de administração**: rotas de patrulha + registros, áreas de limpeza + registros, áreas verdes + manutenção, gestão de atividades comunitárias, medidores de energia + leituras, gestão de funcionários, templates de notificação + envio, mecanismo de aprovação, pedidos de pagamento + reembolsos, gestão de votações + regras de SLA + estratégias de cobrança + tarefas de inspeção + gestão da loja + revisão facial + gestão de grupo + base de conhecimento

**Novidades no portal de proprietários**: inscrição em atividades comunitárias, agendamento de estacionamento/visitantes, notificações, votação + apuração, navegação de produtos + pedidos, P&R inteligente, registro facial

---

## Comparação de métricas técnicas

| Métrica | Básica | Padrão | Completa |
|------|:------:|:------:|:------:|
| Tabelas do banco | 21 | 31 | 65 |
| Arquivos de modelo | 19 | 30 | 58 |
| Controladores admin | 17 | 28 | 47 |
| Controladores service | 9 | 12 | 17 |
| Rotas admin | 45 | 80 | 123 |
| Rotas service | 20 | 35 | 55 |
| Páginas Flutter Admin | 4 | 7 | 57 |
| Páginas HarmonyOS | 2 | 3 | 7 |
| Middlewares | 7 | 8 | 9 |
| Testes PHP | 18 | 18 | 133 |

---

## Sistema de segurança (comum às três edições)

Defesa em profundidade com 18 camadas: código de verificação → confirmação de senha → verificação aleatória → varredura de segurança → bloqueio de ataques → HTTPS + AES-256-CBC → JWT → controle de sessões → bloqueio de conta → RBAC → limite de taxa → proteção de ID → criptografia de requisição → criptografia de armazenamento → mascaramento na exibição → auditoria → CSP → marca d'água de direitos autorais

---

## Caminho de migração

```
Básica (Lite)
  │
  │  + 6 módulos auxiliares + painel + exportação
  ▼
Padrão (Standard)
  │
  │  + 6 módulos avançados + 12 funcionalidades estendidas
  ▼
Completa (Full)
```

A atualização requer apenas executar os arquivos de migração SQL da fase correspondente, sem migração de dados ou alterações destrutivas.

---

## Fluxo de demonstração

**Preparação**: executar `docs/install.sql` (estrutura completa das tabelas, incluindo as tabelas de todas as edições); `admin/.env` com conexão de banco configurada. As diferenças entre edições estão no registro de rotas e na visibilidade das funcionalidades; a estrutura das tabelas é unificada e completa.

### Básica (Lite)

1. Executar os dados de demonstração: `cd admin && php ../scripts/demo_data.php` (idempotente, pode ser executado várias vezes)
2. Escopo dos dados de demonstração: condomínio/edifício/unidade/layout/propriedade/proprietário/inquilino/cobranças/faturas/anúncios + contas de demonstração, cobrindo os módulos principais do Lite
3. O que ver: painel de controle + usuários/papéis/permissões/configurações/logs + CRUD de propriedades/proprietários/inquilinos/cobranças/reparos/anúncios; no portal de proprietários: registro/login, início, minhas propriedades, pagamento de faturas, reparos, anúncios
4. Diferença de rotas: apenas os grupos Lite são registrados; blocos envolvidos por `edition_supports('standard'/'full')` não são registrados (`admin/config/route.php`)

### Padrão (Standard)

1. Executar os dados de demonstração: `cd admin && php ../scripts/demo_data.php` (idempotente; execuções repetidas apenas preenchem o que falta, sem duplicar)
2. Os módulos auxiliares têm poucos dados; estacionamento/equipamentos/reclamações/visitantes/contratos/receitas-despesas podem ser inseridos manualmente em pequena quantidade na demonstração
3. O que ver: no painel, novos itens de vagas/veículos, cadastro de equipamentos + manutenção, tratamento de reclamações + retorno, aprovação de visitantes, gestão de contratos, gestão de receitas/despesas + estatísticas; no portal, meus veículos/vagas, registros de estacionamento, agendamento de visitante/código de acesso
4. Diferença de rotas: adiciona os grupos `edition_supports('standard')`, mantendo os grupos Lite

### Completa (Full)

1. Executar os dados de demonstração: `cd admin && php ../scripts/demo_data.php` (idempotente)
2. Os dados de demonstração dos módulos avançados (pagamento/aprovação/votação/loja/inspeção/facial/grupo/base de conhecimento) são inseridos conforme necessário ou criados diretamente com as contas de demonstração
3. O que ver: além do Standard, novos itens de patrulha/limpeza/paisagismo/energia/funcionários/templates de notificação/mecanismo de aprovação/pedidos de pagamento/votação/SLA/cobrança/inspeção/loja/facial/grupo/base de conhecimento; no portal, inscrição em atividades, notificações, votação, pedidos na loja, P&R inteligente, registro facial
4. Diferença de rotas: registro completo, grupos `edition_supports('full')` ativos (`admin/config/route.php`)

### Alternar de edição

```bash
# Defina a edição alvo no admin/.env (progressão cumulativa; full inclui tudo)
EDITIONS=lite|standard|full

# Reinicie o webman para aplicar (implantação em contêiner: docker compose restart app; bare metal: php start.php restart)
```

- Configuração fail-fast: valor inválido de `EDITIONS` gera erro imediatamente (`admin/config/edition.php`), sem fallback silencioso para uma edição errada.
- O script de dados de demonstração é idempotente; não é necessário limpar o banco ao alternar entre edições; os módulos Standard/Full têm poucos dados e podem ser preenchidos pelo uso real.
