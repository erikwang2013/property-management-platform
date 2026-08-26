# Documento de Design de Funcionalidades (Feature Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Visão geral

O Sistema de Gestão de Propriedades é dividido em **painel de administração** (uso interno da administradora de propriedades) e **portal de proprietários** (uso dos proprietários/inquilinos do condomínio), cobrindo 15 módulos de negócio, entregues em 3 fases.

---

## 1ª fase: negócio principal

### 1. Gestão de condomínios/comunidades (Community)

**Painel de administração:**
- Lista de condomínios (busca, paginação, filtro por status)
- Criar/visualizar/editar/excluir condomínio
- Informações do condomínio: nome, endereço (província/cidade/distrito), área construída, número de edifícios, número de unidades habitacionais, incorporadora, administradora de propriedades, telefone de contato
- Exclusão exige confirmação dupla de senha e usa exclusão lógica

**Portal de proprietários:** sem necessidade de permissão administrativa; a página inicial exibe as informações do condomínio vinculado.

### 2. Gestão de edifícios (Building)

**Painel de administração:**
- Lista de edifícios filtrada por condomínio
- Criar/visualizar/editar/excluir edifício
- Informações do edifício: nome, tipo (torre/placa/vila/comercial), número de andares, número de unidades, número de elevadores, ano de construção, tipo de estrutura
- Suporte a ordenação

### 3. Gestão de unidades (Unit)

**Painel de administração:**
- Lista de unidades filtrada por edifício
- Criar/visualizar/editar/excluir unidade
- Informações da unidade: nome, número de unidades por andar

### 4. Gestão de layouts (RoomType)

**Painel de administração:**
- CRUD da lista de layouts
- Informações do layout: nome (três quartos duas salas), quantidade de quartos/salas/banheiros, planta baixa

### 5. Gestão de propriedades (Room)

**Painel de administração:**
- Visualização em árvore de imóveis (condomínio→edifício→unidade→imóvel)
- Criar/visualizar/editar/excluir imóvel
- Informações do imóvel: número, andar, layout, área (privativa/condomínio/total), orientação, acabamento, uso (residencial/comercial/escritório), status (vago/vendido/alugado/ocupado)
- Vínculo/desvínculo em lote com proprietários

**Portal de proprietários:**
- Visualizar minha lista de propriedades vinculadas
- Visualizar detalhes da propriedade (área, orientação, layout, informações de titularidade)

### 6. Gestão de proprietários (Owner)

**Painel de administração:**
- Lista de proprietários (busca, paginação, filtro por status)
- Criar/visualizar/editar/excluir proprietário
- Informações do proprietário: nome, telefone (criptografado), e-mail (criptografado), documento (criptografado), sexo, data de nascimento, contato de emergência, data de mudança
- Importação em lote (Excel), ativar/desativar em lote, exclusão em lote
- Vínculo/desvínculo de propriedades

**Portal de proprietários:**
- Registro (telefone + senha + código de verificação, com possibilidade de validação pelo vínculo de propriedade)
- Login (telefone + senha + código de verificação por clique, com proteção de bloqueio de conta)
- Visualizar/alterar dados pessoais
- Alterar senha, sair

### 7. Gestão de inquilinos (Tenant)

**Painel de administração:**
- Lista de inquilinos filtrada por propriedade/proprietário
- Criar/visualizar/editar/excluir inquilino
- Informações do inquilino: nome, telefone (criptografado), documento (criptografado), início/fim do contrato de locação, aluguel mensal, status

### 8. Gestão de cobranças (Fee)

**Tipos de cobrança (painel de administração):**
- CRUD de tipos de cobrança: taxa de condomínio, água, eletricidade, gás, aquecimento, estacionamento, fundo de manutenção, outros
- Preço unitário, unidade de cobrança (R$/m²/mês, R$/tonelada, R$/kWh etc.), ciclo de cobrança (mensal/trimestral/anual), se é obrigatório

**Gestão de faturas (painel de administração):**
- Consulta de faturas por condomínio/edifício/propriedade
- Criação/edição manual de faturas
- Geração de faturas em lote (selecionar condomínio + tipo de cobrança + ciclo, geração automática para todos os imóveis)
- Informações da fatura: tipo de cobrança, valor, multa por atraso, ciclo de cobrança, data limite
- Status: não pago/parcialmente pago/pago/em atraso/isento
- Notificação de cobrança em lote

**Faturas (portal de proprietários):**
- Minha lista de faturas (filtro por status: não pago/pago/em atraso)
- Detalhes da fatura
- Pagamento online (WeChat/Alipay, exige confirmação dupla de senha)
- Consulta do histórico de pagamentos
- Estatísticas de cobranças (tendência mensal/anual, proporção por categoria de cobrança)

**Registros de pagamento (painel de administração):**
- Consulta de registros de pagamento
- Registro de cobrança offline (dinheiro/cartão/transferência bancária)

### 9. Gestão de reparos (Repair)

**Painel de administração:**
- Lista de reparos (filtro por status/categoria)
- Visualização dos detalhes do reparo
- Despacho (atribuição do técnico de manutenção)
- Atualização do andamento da manutenção

**Portal de proprietários:**
- Minha lista de reparos
- Enviar solicitação de reparo (selecionar propriedade, categoria, urgência, descrição, upload de fotos, horário agendado)
- Visualizar detalhes e andamento do reparo
- Cancelar solicitação (apenas no status "aguardando despacho", exige confirmação de senha)
- Avaliar o reparo (1-5 estrelas + avaliação em texto)

### 10. Anúncios e notificações (Announcement)

**Painel de administração:**
- CRUD da lista de anúncios
- Publicação de anúncios por condomínio
- Categorias: aviso/anúncio/lembrete/atividade
- Fixação, status rascunho/publicado

**Portal de proprietários:**
- Visualizar lista de anúncios publicados (filtro por categoria)
- Detalhes do anúncio

---

## 2ª fase: negócios auxiliares

### 11. Gestão de estacionamento (Parking)

**Painel de administração:**
- Gestão de vagas (número, coberta/descoberta, área, status: livre/vendida/alugada/em manutenção)
- Gestão de veículos (placa criptografada, marca, cor, tipo, vínculo com vaga/proprietário)
- Consulta de registros de estacionamento (horário de entrada/saída, duração, valor)

**Portal de proprietários:**
- Minha lista de veículos
- Minha lista de vagas
- Consulta de registros de estacionamento

### 12. Gestão de equipamentos (Equipment)

**Painel de administração:**
- Cadastro de equipamentos (nome, número, categoria: elevador/incêndio/controle de acesso/CFTV/água e esgoto/energia/ar-condicionado e ventilação)
- Informações do equipamento: marca, modelo, local de instalação, data de instalação, fim da garantia, vida útil projetada
- Registros de manutenção: inspeção diária/manutenção periódica/reparo de falha/revisão geral/substituição
- Responsável pela manutenção, custo, empresa de manutenção, próxima data de manutenção

### 13. Reclamações e sugestões (Complaint)

**Painel de administração:**
- Lista de reclamações (filtro por tipo/status)
- Tratamento da reclamação (atribuição do responsável, preenchimento de observações)
- Registro de retorno (observações do retorno, registro de satisfação)

**Portal de proprietários:**
- Minha lista de reclamações/sugestões
- Enviar reclamação/sugestão (tipo: reclamação/sugestão/elogio; categoria: serviço/ambiente/segurança/instalações/ruído/construção irregular)
- Suporte a envio anônimo e upload de fotos
- Visualizar andamento do tratamento
- Avaliação de satisfação

### 14. Gestão de visitantes (Visitor)

**Painel de administração:**
- Aprovação de agendamentos de visitante
- Consulta de registros de visitantes

**Portal de proprietários:**
- Agendamento de visitante (nome do visitante, telefone, documento, placa do veículo, número de acompanhantes, motivo da visita, horário previsto)
- Geração do código de acesso
- Alterar/cancelar agendamento

### 15. Gestão de contratos (Contract)

**Painel de administração:**
- Lista de contratos (filtro por tipo/status)
- Tipos de contrato: contrato de condomínio/contrato de locação/contrato de manutenção/contrato de serviço/contrato de compra
- Informações do contrato: número, partes envolvidas, valor, datas de início/fim, data de assinatura, anexos
- Status: rascunho/em execução/expirado/encerrado/renovado

### 16. Gestão financeira (Finance)

**Painel de administração:**
- Gestão de receitas (taxa de condomínio/estacionamento/aluguel/publicidade/fundo de manutenção/outros)
- Gestão de despesas (pessoal/compra de equipamentos/manutenção/energia/limpeza e paisagismo/escritório/impostos/outros)
- Relatórios estatísticos de receitas/despesas (mensal/trimestral/anual)

---

## 3ª fase: funcionalidades avançadas

### 17. Patrulha de segurança (Security Patrol)

**Painel de administração:**
- Gestão de rotas de patrulha (coordenadas da rota, pontos de verificação)
- Registros de patrulha (horário de início/fim, duração, observações de anomalias)
- Estatísticas de taxa de conclusão de patrulha

### 18. Gestão de limpeza (Cleaning)

**Painel de administração:**
- Gestão de áreas de limpeza (local, área, frequência: diária/semanal/quinzenal/mensal)
- Registros de limpeza (horário da limpeza, inspetor, observações da inspeção, fotos do local)
- Estatísticas de taxa de conclusão de limpeza

### 19. Gestão de paisagismo (Green)

**Painel de administração:**
- Gestão de áreas verdes (local, área, principais plantas)
- Registros de manutenção (rega/poda/adubação/controle de pragas/replantio, custos)

### 20. Atividades comunitárias (Activity)

**Painel de administração:**
- Gestão de atividades (título, conteúdo, categoria: cultural/esportiva/festiva/beneficente/palestra/familiar)
- Imagem de capa, local, número máximo de participantes, horário, custo
- Status: aceitando inscrições/em andamento/encerrada/cancelada
- Visualização da lista de inscrições

**Portal de proprietários:**
- Lista de atividades (filtro: aceitando inscrições/em andamento)
- Detalhes da atividade
- Inscrever-se/cancelar inscrição

### 21. Gestão de consumo de energia (Energy)

**Painel de administração:**
- Gestão de medidores (eletricidade/água/gás/aquecimento, número)
- Registros de leitura (leitura atual, consumo, preço unitário, valor)
- Geração automática de faturas vinculadas

### 22. Gestão de funcionários (Staff)

**Painel de administração:**
- Informações do funcionário (nome, telefone criptografado, documento criptografado, cargo, departamento, data de admissão)
- Departamentos: administração/atendimento/engenharia/segurança/limpeza/paisagismo/financeiro
- Status: ativo/desligado/de licença

---

## Visualização em painel e exportação

### Painel de controle

**Painel de controle do administrador:**
- Cartões de indicadores principais: total a receber, total recebido, taxa de inadimplência, taxa de ocupação
- Gráfico de linhas da tendência de cobranças (mensal/trimestral)
- Gráfico de pizza por categoria de cobrança
- Estatísticas de reparos (por categoria, por status)
- Estatísticas de reclamações
- Logs de operações recentes

**Início do portal de proprietários:**
- Número de minhas propriedades, valor a pagar, número de reparos em andamento, anúncios mais recentes

### Exportação Excel

- Exportação da lista de proprietários
- Exportação do relatório de faturas
- Exportação do histórico de pagamentos
- Exportação do relatório financeiro
- Mascaramento automático de dados sensíveis na exportação

### Exportação PDF

- Exportação da visualização do painel de controle
- Relatório financeiro em PDF (direitos autorais no cabeçalho + marca d'água de direitos autorais não removível no rodapé)
- Layout A4 paisagem

---

## Funcionalidades transversais

| Funcionalidade | Descrição |
|------|------|
| Proteção de ID | Todos os IDs das interfaces usam codificação hashids na transmissão |
| Criptografia de dados | Campos sensíveis (telefone/e-mail/documento): AES-256-CBC na camada de API, encryptable na camada de banco |
| Auditoria de operações | Todas as operações POST/PUT/DELETE do administrador são registradas automaticamente, com detecção automática da plataforma de origem |
| Controle de permissões | RBAC com granularidade method.path, superadministrador com identificador * |
| Proteção por limite de taxa | Janela deslizante no Redis: login 10 vezes/minuto, registro 5 vezes/minuto |
| Código de verificação | Código de verificação chinês por clique, obrigatório no login/registro |
| Exclusão lógica | Proprietários, condomínios, propriedades e anúncios suportam exclusão lógica |
| Internacionalização | Bilíngue chinês/inglês, PHP symfony/translation + Flutter GetX Translations, chinês padrão com fallback para inglês |
| Documentação da API | Geração automática com `hg/apidoc`, 57 dos 58 controladores anotados em 10 grupos (Base/Docs/Install não agrupados), `/apidoc/config` fornece a API de configuração |
| Testes | Fluxo TDD, 133 testes/465 asserções, service 100% aprovado, flutter analyze sem problemas |
| Flutter Web | 13 páginas (login/início/cobranças/reparos/central pessoal etc.), estilo desktop PC, gerenciamento de estado GetX |
| HarmonyOS | Estrutura completa do projeto, camada de serviços ArkTS + autenticação + login/início, @ohos.net.http |

## Funcionalidades estendidas (4ª fase)

### Central de notificações
- Templates de notificação configuráveis (push no app/SMS/e-mail)
- Lembretes de faturas, andamento de reparos e publicação de anúncios com notificação automática
- Lista de mensagens no portal de proprietários + gestão de leitura

### Mecanismo de fluxo de aprovação
- Tipos e etapas de aprovação configuráveis (supervisor→gerente→diretor)
- Despacho de reparos/aprovação de visitantes/aprovação de contratos seguem fluxo padronizado
- Registros de aprovação rastreáveis

### Integração de pagamento
- Gestão de pedidos de pagamento WeChat/Alipay
- Tratamento de callbacks de pagamento, reembolsos, estatísticas de conciliação
- Atualização automática das faturas vinculadas

### Votação/decisão de proprietários
- Votação comum + decisão em assembleia de proprietários (ponderada por área)
- Gestão de opções, registros de votação, apuração automática
- Estatísticas de participação

### Escalonamento automático de SLA de reparos
- Configuração dos prazos de resposta/resolução por categoria + urgência
- Escalonamento automático para o papel superior em caso de timeout
- Registro automático de multa por timeout

### Cobrança de inadimplência inteligente
- Configuração de estratégias de cobrança em etapas (dias de atraso → ação)
- Correspondência automática de faturas em atraso para execução da cobrança (App/SMS/telefone/visita)
- Cálculo automático da multa por atraso

### App móvel de inspeção
- Distribuição de tarefas de inspeção (rota GPS + pontos de verificação)
- Check-in pelo app (localização + foto + marcação de anomalias)
- Estatísticas de taxa de conclusão de inspeção

### Loja comunitária
- Gestão de categorias de produtos/publicação/retirada de produtos
- Navegação do proprietário + pedidos + rastreamento de pedidos
- Gestão de envios/reembolsos

### Reconhecimento facial
- Registro facial do proprietário (integração com serviço de reconhecimento de terceiros)
- Revisão e certificação no painel de administração
- Vínculo com controle de acesso

### Gestão de grupo multi-condomínio
- Associação muitos para muitos grupo→condomínio
- Consolidação de dados entre condomínios (visão unificada de propriedades/proprietários/cobranças)

### P&R inteligente
- Gestão da base de conhecimento (categorias/artigos/palavras-chave)
- Correspondência automática às perguntas dos proprietários
- Histórico de conversas + estatísticas de taxa de resolução

### Painel de dados
- Visualização em tela cheia de dados imobiliários em tempo real
- Quatro painéis: cobranças/reparos/equipamentos/energia
- Atualização automática em carrossel
