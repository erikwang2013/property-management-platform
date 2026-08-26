# Lista de Lacunas do App Móvel

> Data de geração: 2026-08-16 · Fonte: ci-agent da pmp-team (P3-③ inventário da situação atual, somente leitura)
> Roteiro correspondente: docs/PROJECT_PLAN.md P3 — "expandir as 7 páginas do HarmonyOS para os caminhos principais (pagamento/reparos/anúncios/visitantes/estacionamento), adaptação mobile do Flutter do proprietário"

## 1. Situação atual do portal de proprietários HarmonyOS (apps/harmonyos, 7 páginas)

| Página | Rota (main_pages.json registrado) | API chamada |
|------|------------------------------|---------|
| LoginPage | pages/LoginPage | Login (AuthService) |
| HomePage | pages/HomePage | GET /service/home (painel: a pagar/ordens/nº de propriedades + lista de anúncios) |
| FeeBillsPage | pages/FeeBillsPage | GET /service/fees/bills?page=1&per_page=50 |
| RepairListPage | pages/RepairListPage | GET /service/repairs |
| RepairSubmitPage | pages/RepairSubmitPage | POST /service/repair |
| AnnouncementPage | pages/AnnouncementPage | GET /service/announcements?page=1&per_page=50 |
| ProfilePage | pages/ProfilePage | GET /service/profile、POST /service/profile/logout |

**Navegação atual** (apenas 4 transições em todo o app): Login→Home, Home→Login (sair), Profile→Login, RepairList→RepairSubmit. A HomePage tem apenas cartões de estatística + lista de anúncios, sem grade de entradas de funcionalidades; as páginas FeeBills/Announcement/Profile existem mas **sem entrada, inacessíveis**.

## 2. Comparação dos caminhos principais do HarmonyOS

| Caminho principal | Situação atual | Tipo de lacuna |
|---------|------|---------|
| Pagamento | página existe, API funciona | Só front-end: Home sem entrada (inacessível) |
| Reparos | páginas de lista+envio existem, API funciona | Só front-end: Home sem entrada (inacessível) |
| Anúncios | página existe, API funciona | Só front-end: Home sem entrada (inacessível) |
| Visitantes | página ausente | Precisa de nova página (API já existe: GET/POST/PUT/DELETE /visitor*) |
| Estacionamento | página ausente | Precisa de nova página (API já existe: /parking/vehicles, /parking/spaces, /parking/records) |

Sem lacunas no back-end: as APIs do service para os 5 caminhos principais estão todas prontas (fees/repairs/announcements como rotas permanentes; parking/visitors dentro do portão da edição standard). ApiService.ets já tem get/post/put/delete genéricos; novas páginas podem reutilizar diretamente.

## 3. Situação atual do portal de proprietários Flutter (apps/flutter, 13 módulos)

**Lista de páginas**: login, home, fee, repair, parking×3, visitor×2, activity, notification, vote, mall×3, chat, face, profile — todas com rota registrada (getPages do app.dart), os 5 caminhos principais já implementados.

**Problemas de adaptação mobile**: apenas home_page / login_page usam breakpoints responsivos LayoutBuilder/MediaQuery; **10 páginas com largura de desktop codificada**, com estouro RenderFlex garantido em largura de celular (<400px):

| Página | Codificação |
|------|--------|
| chat_page | SizedBox(width: 600) |
| mall_products_page | width: 800 |
| mall_product_detail / mall_orders | SizedBox(width: 600) |
| notification_list | width: 480 + SizedBox(width: 600) |
| vote_list / vote_detail | SizedBox(width: 600) |
| activity_detail, parking_records/vehicles, visitor_list, face_register | sem tratamento de breakpoints (problema semelhante esperado, não verificado linha a linha) |

Além disso: sem barra de navegação inferior (BottomNavigationBar), entradas via AppBar + grade; padding de 24 nas páginas com estilo mais desktop. O i18n bilíngue já está pronto.

## 4. Lista de lacunas (classificada + esforço)

### Depende do back-end (nenhuma)

### Só front-end

| # | Item | Esforço |
|---|----|--------|
| 1 | Adicionar grade de entradas de funcionalidades na HomePage do HarmonyOS (comparada às 12 entradas da versão Flutter), conectando pagamento/reparos/anúncios/visitantes/estacionamento/central pessoal | M |
| 2 | Nova VisitorPage no HarmonyOS (lista + novo, reutilizando VisitorController) | M |
| 3 | Nova ParkingPage no HarmonyOS (veículos/vagas/registros, reutilizando ParkingController) | M |
| 4 | Eliminar larguras codificadas no Flutter do proprietário (600/800/480 → restringir a maxWidth ou usar ConstrainedBox) | S |
| 5 | Adicionar barra de navegação inferior + padding compacto no Flutter do proprietário (se o celular for meta de aceitação) | M |

### Precisa de integração

| # | Item | Esforço |
|---|----|--------|
| 6 | Validar em dispositivo real/emulador HarmonyOS o fluxo completo de pagamento→pagamento, envio de reparo e registro de visitante | S (limitado pelo dispositivo de teste; risco já listado no PROJECT_PLAN) |

## 5. Ordem de implementação sugerida

1. Lacuna 1 (melhor custo-benefício: reutiliza as 3 páginas existentes, zero páginas novas)
2. Lacuna 4 (estouro no Flutter é falha grave, celular certamente quebra)
3. Lacunas 2, 3 (páginas novas)
4. Lacuna 5 (otimização de experiência)
5. Lacuna 6 (requer dispositivo, executar separadamente)
