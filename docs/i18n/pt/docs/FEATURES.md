# Documento de Funcionalidades (Features)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Lista de funcionalidades

| Nº | Módulo | Fase | Painel de administração | Portal de proprietários | Tabelas |
|------|------|---------|---------|--------|--------|
| 1 | Gestão de condomínios | 1ª fase | CRUD + busca com paginação | Visualizar condomínio vinculado | erik_community |
| 2 | Gestão de edifícios | 1ª fase | CRUD + filtro por condomínio | - | erik_building |
| 3 | Gestão de unidades | 1ª fase | CRUD + filtro por edifício | - | erik_unit |
| 4 | Gestão de layouts | 1ª fase | CRUD | - | erik_room_type |
| 5 | Gestão de propriedades | 1ª fase | CRUD + árvore de imóveis + vínculo em lote com proprietários | Minha lista/detalhes de propriedades | erik_room |
| 6 | Gestão de proprietários | 1ª fase | CRUD + importação em lote/ativar-desativar/excluir | Registro/login/dados pessoais | erik_owner, erik_room_owner |
| 7 | Gestão de inquilinos | 1ª fase | CRUD + filtro por propriedade | - | erik_tenant |
| 8 | Gestão de cobranças | 1ª fase | CRUD de tipos de cobrança + gestão de faturas + geração em lote + cobrança offline | Consulta de faturas + pagamento online + estatísticas de cobranças | erik_fee_type, erik_fee_bill, erik_fee_payment |
| 9 | Gestão de reparos | 1ª fase | Lista de reparos + despacho + atualização de andamento | Enviar solicitação de reparo + acompanhar andamento + avaliar | erik_repair_order, erik_repair_progress |
| 10 | Anúncios e notificações | 1ª fase | CRUD + publicação/fixação | Lista/detalhes de anúncios | erik_announcement |
| 11 | Gestão de estacionamento | 2ª fase | Gestão de vagas/veículos + registros | Minhas vagas/veículos + registros | erik_parking_space, erik_parking_vehicle, erik_parking_record |
| 12 | Gestão de equipamentos | 2ª fase | Cadastro de equipamentos + registros de manutenção | - | erik_equipment, erik_equipment_maintenance |
| 13 | Reclamações e sugestões | 2ª fase | Lista de reclamações + tratamento + retorno | Enviar reclamação + acompanhar andamento + avaliar | erik_complaint |
| 14 | Gestão de visitantes | 2ª fase | Aprovação de visitantes + consulta de registros | Agendamento de visitante + código de acesso | erik_visitor |
| 15 | Gestão de contratos | 2ª fase | CRUD + gestão de status | - | erik_contract |
| 16 | Gestão financeira | 2ª fase | Gestão de receitas/despesas + relatórios estatísticos | - | erik_finance_income, erik_finance_expense |
| 17 | Patrulha de segurança | 3ª fase | Rotas de patrulha + registros de patrulha | - | erik_security_patrol, erik_patrol_record |
| 18 | Gestão de limpeza | 3ª fase | Áreas de limpeza + registros de limpeza | - | erik_cleaning_area, erik_cleaning_record |
| 19 | Gestão de paisagismo | 3ª fase | Áreas verdes + registros de manutenção | - | erik_green_area, erik_green_maintenance |
| 20 | Atividades comunitárias | 3ª fase | Gestão de atividades + consulta de inscrições | Lista de atividades + inscrição | erik_community_activity, erik_activity_signup |
| 21 | Gestão de consumo de energia | 3ª fase | Gestão de medidores + registros de leitura | - | erik_energy_meter, erik_energy_record |
| 22 | Gestão de funcionários | 3ª fase | CRUD + gestão de status | - | erik_staff |

## Funcionalidades estendidas (4ª fase — 12 módulos)

| Nº | Módulo | Painel de administração | Portal de proprietários | Tabelas |
|------|------|---------|--------|--------|
| 23 | Notificações | CRUD de templates + envio manual + lista | Minhas mensagens + marcar como lida | erik_notification_template, erik_notification |
| 24 | Fluxo de aprovação | Tipos de aprovação + instâncias + fluxo de etapas | - | erik_approval_type, erik_approval, erik_approval_record |
| 25 | Integração de pagamento | Gestão de pedidos + reembolsos + callbacks WeChat/Alipay | - | erik_payment_order |
| 26 | Votação de proprietários | CRUD de votações + opções + estatísticas ponderadas por área | Lista de votações + votar + ponderação por área | erik_vote, erik_vote_option, erik_vote_record |
| 27 | Escalonamento automático de SLA | Configuração de regras + verificação de timeout + multas | - | erik_sla_rule, erik_sla_record |
| 28 | Cobrança de inadimplência inteligente | Configuração de estratégias + correspondência de atrasos + multas | - | erik_collection_strategy, erik_collection_record |
| 29 | App móvel de inspeção | Distribuição de tarefas + check-in por GPS + fotos | - | erik_inspection_task, erik_inspection_checkpoint |
| 30 | Loja comunitária | Gestão de categorias/produtos/pedidos/envios | Navegar produtos + fazer pedidos + meus pedidos | erik_mall_category, erik_mall_product, erik_mall_order |
| 31 | Reconhecimento facial | Gestão de revisão | Registrar rosto + status de autenticação | erik_face_info |
| 32 | Gestão de grupo | CRUD de grupos + vínculo de condomínios + consolidação entre áreas | - | erik_group, erik_group_community |
| 33 | P&R inteligente | Base de conhecimento + histórico de conversas + estatísticas | Perguntar + correspondência por palavras-chave | erik_knowledge_base, erik_chat_record |
| - | Painel de dados | Visualização em tela cheia de dados imobiliários em tempo real | - | (reutiliza APIs existentes) |

## Módulos do painel de administração (já existentes no admin)

| Módulo | Funcionalidade |
|------|------|
| Painel de controle | Estatísticas em tempo real/tendências/distribuição/logs (cache Redis 5m) |
| Gestão de usuários | CRUD de usuários administradores + exclusão em lote/ativar-desativar + importação Excel |
| Papéis e permissões | CRUD + árvore de permissões + autorização RBAC method.path |
| Configuração do sistema | CRUD de pares chave-valor |
| Auditoria de operações | Consulta de logs + detecção automática de 8 plataformas de origem |
| Gestão de arquivos | Upload + exportação Excel/PDF (mascaramento de dados sensíveis) |
| Gestão de segurança | Defesa em profundidade com 18 camadas + security.txt |
| Monitoramento de operações | Verificação de saúde + métricas Prometheus + documentação da API |
| Internacionalização | Bilíngue chinês/inglês, PHP symfony/translation + Flutter GetX Translations + qualificadores de recursos HarmonyOS |
| Documentação da API | Geração automática com `hg/apidoc`, admin com 10 grupos + service com 9 grupos, organizados por módulo funcional |

## Funcionalidades transversais

### Transmissão criptografada de IDs
Os campos de ID em todas as requisições e respostas da API usam codificação/decodificação `erikwang2013/hashids`. O cliente recebe strings hashid (ex.: `aB3xK9mW2pQ7rT5v`) e o back-end decodifica para BIGINT para operar.

### Proteção de dados sensíveis
- Camada de transmissão da API: `erikwang2013/encryption` — AES-256-CBC
- Camada de armazenamento no banco: `erikwang2013/encryptable` — casts dos modelos Eloquent com criptografia automática
- Camada de exibição no front-end: telefone 138****1234, e-mail a***@e.com

### Auditoria de operações
Todas as operações POST/PUT/DELETE do painel de administração são registradas automaticamente, incluindo usuário da operação, IP, caminho, parâmetros (mascarados), hora da operação e plataforma de origem (web/ios/android/harmonyos/windows/macos/linux/ipados).

### Controle de permissões
- Painel de administração: autorização RBAC com granularidade method.path; superadministrador ignora com `*`
- Portal de proprietários: autenticação JWT Bearer Token; proprietários só operam seus próprios dados

### Proteção de segurança
Defesa em profundidade com 18 camadas: código de verificação → confirmação de senha → verificação aleatória → varredura de segurança → bloqueio de ataques → criptografia em trânsito → JWT → controle de sessões → bloqueio de conta → RBAC → limite de taxa → proteção de ID → criptografia de requisição → criptografia de armazenamento → mascaramento na exibição → auditoria → CSP → marca d'água de direitos autorais

### Exportação
- Excel: PhpSpreadsheet, cabeçalho azul com texto branco + primeira linha congelada + filtro automático + mascaramento de dados sensíveis
- PDF: Dompdf A4 paisagem, direitos autorais no cabeçalho + marca d'água de direitos autorais não removível no rodapé
- Exportação em PDF dos dados do painel de visualização

### Mecanismo de busca
- `erikwang2013/webman-scout` aciona o Elasticsearch
- Sincronização automática de índices (envio automático em criações/alterações/exclusões)
- Prefixo de índice `erik_`, consistente com o prefixo das tabelas

### Internacionalização (i18n)
- **Back-end PHP**: symfony/translation — `resource/translations/{zh_CN,en}/messages.php`, 42 chaves de tradução, controladores obtêm traduções pelo método `__()`
- **Flutter Web**: `Translations` do GetX — `lib/i18n/messages.dart`, 101 chaves de tradução, páginas usam a extensão `.tr`
- **HarmonyOS**: qualificadores de recursos `resources/{base,en_US}/element/string.json`
- **Idioma padrão**: chinês simplificado (zh_CN), idioma de fallback inglês (en)
- **Cabeçalho de requisição**: suporte a `Accept-Language` para controlar o idioma da resposta

### Cobertura de testes
- **Framework de testes**: PHPUnit 12.x
- **Fluxo TDD**: vermelho → verde → refatoração, testes antes do código
- **Painel de administração**: 60 testes, 164 asserções, cobrindo serviços base, configuração de ambiente, validação de segurança
- **Portal de proprietários**: 18 testes, 45 asserções, 100% de aprovação
- **Total**: 78 testes, 209 asserções
- **Escopo**: unicidade da geração de ID Snowflake, ida e volta de codificação/decodificação Hashids, formato de resposta unificado, validação do schema das 64 tabelas, consistência das chaves de tradução chinês/inglês
- **Flutter**: flutter analyze sem problemas
- **Documentação da API**: geração automática com `hg/apidoc`, admin (10 grupos) + service (9 grupos), documentação organizada por módulo funcional
