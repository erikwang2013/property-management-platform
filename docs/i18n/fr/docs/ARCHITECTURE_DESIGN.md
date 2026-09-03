# Document de conception d'architecture (Architecture Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. Vue d'ensemble de l'architecture système

Le système de gestion immobilière adopte une architecture en couches « double backend + multi-frontend ». Le panneau d'administration (admin) et le portail des propriétaires (service) sont deux projets webman v2 indépendants, qui coopèrent via une base de données MySQL partagée. Le front-end couvre Flutter Web (style panneau d'administration PC) et le client mobile HarmonyOS.

### Objectifs de conception

- **Déploiement indépendant** : admin et service se démarrent/s'arrêtent, se dimensionnent et gèrent leurs clés indépendamment
- **Données partagées** : même base de données MySQL commune, évitant les problèmes de synchronisation des données
- **Normes unifiées** : les deux projets suivent les mêmes normes de code, le même style de configuration et les mêmes politiques de sécurité
- **Web PC-first** : Flutter Web conçu selon le style des panneaux d'administration desktop (barre latérale + barre supérieure + zone de contenu)

## 2. Architecture en couches

```
┌─────────────────────────────────────────────────────────────┐
│                        路由层 (Route Layer)                   │
│   config/route.php — URL → Controller 映射 + 中间件绑定       │
├─────────────────────────────────────────────────────────────┤
│                       中间件层 (Middleware Layer)              │
│   SecurityFilter → RateLimit → Auth → Permission               │
├─────────────────────────────────────────────────────────────┤
│                      控制器层 (Controller Layer)               │
│   BaseController → 请求验证 → ID编解码 → 业务逻辑 → 响应格式化  │
├─────────────────────────────────────────────────────────────┤
│                        服务层 (Service Layer)                  │
│   HashidsService | SnowflakeService | EncryptionService       │
├─────────────────────────────────────────────────────────────┤
│                        模型层 (Model Layer)                    │
│   Eloquent ORM + encryptable 自动加解密 + scout ES 同步        │
├─────────────────────────────────────────────────────────────┤
│                        驱动层 (Driver Layer)                   │
│   MySQL PDO | Elasticsearch HTTP | Redis                      │
└─────────────────────────────────────────────────────────────┘
```

## 3. Chaîne d'exécution des middlewares

### Panneau d'administration (admin)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流) 
  → AdminAuth(JWT验证) → AdminPermission(RBAC鉴权)
    → OperationLog(操作记录) → Controller
```

### Portail des propriétaires (service)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流)
  → Controller（URL 版本路由）           # /api/v1/* 公开接口
  → ServiceAuth(JWT业主认证) → Controller       # /service/v1/* 认证接口
```

### Description des middlewares globaux

| Middleware | Position | Rôle |
|--------|------|------|
| Cors | Premier global | Traitement des en-têtes de partage des ressources跨域 |
| SecurityFilter | Global | Liste blanche des méthodes HTTP, interception XSS/injection SQL/parcours de chemins/injection de commandes/CSRF, liste noire IP |
| RateLimit | Global | Limitation de débit à fenêtre glissante Redis (Lua atomique), 60 fois/minute par défaut |
| AdminAuth | routes /admin | Vérification du Token JWT, injection de adminId |
| AdminPermission | routes /admin | Validation des permissions RBAC method.path (cache Redis 60 s) |
| OperationLog | routes /admin | Enregistrement automatique des opérations POST/PUT/DELETE (avec détection de la source) |
| ServiceAuth | routes /service | Vérification du Token JWT, injection de ownerId |

## 4. Cycle de vie complet des ID

```
生成: SnowflakeService::generate()
      datacenter_id(5bit) + worker_id(5bit) + timestamp(41bit) + sequence(12bit)
      → BIGINT(18) 例: 1750123456789

存储: MySQL management_* 表
      id BIGINT UNSIGNED NOT NULL（非自增）
      敏感字段 encryptable cast → AES-256-CBC 加密存储

传输: HashidsService::encode(bigint) → hashid 字符串 例: aB3xK9mW2pQ7rT5v
      API 请求/响应中的所有 ID 字段统一使用 hashid

解码: HashidsService::decode(hashid) → BIGINT
      无效 hashid 抛出 InvalidArgumentException
```

## 5. Couches de chiffrement des données

### Couche de transmission (encryption)
- Chiffrement AES-256-CBC
- Le client chiffre les données sensibles avant envoi, le serveur déchiffre à réception
- Clé indépendante `ENCRYPTION_KEY`

### Couche de stockage (encryptable)
- Chiffrement/déchiffrement automatique via le mécanisme `$casts` du Model
- Champs sensibles : phone, email, id_card, emergency_contact, emergency_phone
- Clé indépendante `ENCRYPTABLE_KEY`
- Écriture chiffrée automatiquement en texte chiffré, lecture déchiffrée automatiquement en texte clair

### Couche d'affichage (masquage)
- Numéro de mobile : `138****1234`
- E-mail : `a***@example.com`
- Carte d'identité : `********`
- Masquage automatique à l'export Excel/PDF

## 6. Authentification et permissions

### Authentification JWT
- Algorithme : HS256
- access_token : validité 2 heures
- refresh_token : validité 14 jours
- Limite de concurrence : 3 Tokens valides maximum par utilisateur, le plus ancien est mis en liste noire au-delà
- Verrouillage du compte : 5 échecs de connexion consécutifs → verrouillage 15 minutes

### Modèle de permissions RBAC
- Utilisateur → Rôle → Permission (plusieurs-à-plusieurs)
- Types de permission : type=1 (menu) / type=2 (bouton) / type=3 (API)
- Format de l'identifiant de permission : `{method}.{path}` ex. : `get.admin/user`
- Identifiant super administrateur : `*` (ignore toutes les vérifications de permission)
- Arbre de permissions : parent_id auto-référencé, profondeur illimitée

## 7. Défense en profondeur (18 couches)

```
第1层  点击验证码      → 登录/注册强制人机验证
第2层  密码二次确认    → 敏感操作（删除/缴费/合同终止）必须输入密码
第3层  poster随机验证  → 高频敏感操作随机弹出验证码
第4层  security-php    → 请求周期内自动安全扫描
第5层  SecurityFilter  → XSS/SQL注入/路径遍历/命令注入/CSRF 攻击拦截
第6层  传输安全        → HTTPS + AES-256-CBC
第7层  JWT 认证        → HS256，2h过期 + refresh token
第8层  并发控制        → 同一用户最多3个Token，超出黑名单
第9层  账号锁定        → 连续5次失败锁定15分钟
第10层 RBAC 鉴权       → method.path 粒度权限控制
第11层 限流保护        → Redis 滑动窗口 Lua原子化
第12层 熔断保护        → Redis 熔断器（支付/回调快速失败+半开探测）
第13层 ID 保护         → Hashids 编码，不可逆推真实ID
第14层 请求体加密      → AES-256-CBC 敏感字段
第15层 存储加密        → encryptable DB字段加密
第16层 展示脱敏        → 手机号/邮箱/身份证脱敏
第17层 审计追溯        → OperationLog 全量记录（含来源端 source 自动检测）
第18层 HTTP 头防护     → CSP + X-Permitted-Cross-Domain-Policies
第19层 出口保护        → PDF 版权水印（不可移除）+ Excel 敏感数据脱敏
```

## 8. Stratégie de limitation de débit

Basée sur l'algorithme de fenêtre glissante Redis Sorted Set, exécutée de façon atomique en script Lua :

| Interface | Limite |
|------|------|
| Défaut | 60 fois/minute/IP/route |
| POST /api/v1/auth/login | 10 fois/minute |
| POST /api/v1/auth/register | 5 fois/minute |

Au dépassement, renvoie 429 + en-têtes de réponse `X-RateLimit-Limit/Remaining/Reset/Retry-After`.

## 9. Stratégie de versionnement API

- La version est portée par le chemin de l'API lui-même (ex. `/api/v1/*`, `/service/v1/*`), pas par un en-tête de requête
- Les chemins de version inexistants renvoient 404 directement depuis le routeur (sans middleware)
- Les contrôleurs sont organisés par version : `app/api/{version}/controller/`
- Ajouter une version = enregistrer un nouveau groupe de routes `/{namespace}/v{version}` (contrôleurs sous `app/api/v1/controller/`) ; les chemins de version inconnus renvoient 404 via FastRoute

## 10. Architecture de déploiement

```
┌─────────────────────────────────────┐
│            CloudFlare DNS + CDN      │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│          Nginx (:443)                │
│   反向代理 + Gzip + SSL 终结         │
│   静态文件: Flutter Web build/       │
└──────┬──────────────────┬───────────┘
       │                  │
┌──────▼──────┐    ┌──────▼──────┐
│ admin webman│    │service webman│
│ :8787       │    │ :8788       │
│ 管理后台API │    │ 业主端API    │
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

### Services Docker Compose

| Service | Image | Description |
|------|------|------|
| nginx | nginx:alpine | Reverse proxy + fichiers statiques |
| admin | construction Dockerfile | PHP 8.3 + OPcache |
| service | construction Dockerfile | PHP 8.3 + OPcache |
| mysql | mysql:8.0 | Persistance par volume de données |
| redis | redis:7-alpine | Cache/limitation de débit/Session |
| elasticsearch | elasticsearch:8.x | Recherche plein texte |

## 11. Conception d'internationalisation (i18n)

### Structure des fichiers de langue

Le système prend en charge le chinois simplifié (zh_CN) et l'anglais (en), chinois par défaut.

**Backend PHP :**
```
resource/translations/
├── zh_CN/
│   └── messages.php    # 中文语言包（42+翻译键）
└── en/
    └── messages.php    # 英文语言包
```

Pilote symfony/translation, configuration dans `config/translation.php` :
- `locale`: `zh_CN`
- `fallback_locale`: `['zh_CN', 'en']`
- `path`: `resource/translations`

Dans les contrôleurs, on obtient la traduction via `$this->__('key')` :
```php
return $this->success([], $this->__('create_success'));
return $this->fail($this->__('community.name_required'), 422);
```

La méthode `__()` appelle en interne la fonction globale `trans()` de webman ; si la traduction n'existe pas, elle retombe sur la clé elle-même.

**Flutter Web :**
```
apps/flutter/lib/i18n/
└── messages.dart       # AppTranslations extends GetX Translations
```

Utilise GetX `Translations`, 101 clés de traduction. Utilisé via l'extension `.tr` :
```dart
Text('login_btn'.tr)   // 中文: "登 录", 英文: "Login"
Text('phone_hint'.tr)  // "请输入手机号" / "Enter phone number"
```

Changement de langue :
```dart
Get.updateLocale(Locale('zh', 'CN'));  // 切换中文
Get.updateLocale(Locale('en', 'US'));  // 切换英文
```

### Classification des clés de traduction

| Catégorie | Exemples de clés PHP | Exemples de clés Flutter |
|------|-----------|---------------|
| Général | `success`, `fail`, `not_found` | `confirm`, `cancel`, `save` |
| Authentification | `auth.login_success`, `auth.*` | `login_btn`, `phone_hint` |
| Résidence | `community.name_required` | - |
| Frais | `fee.bill_not_found`, `fee.*` | `fee_management`, `bill_status` |
| Réparation | `repair.not_found`, `repair.*` | `repair_submit`, `urgency_normal` |
| Réclamation | `complaint.submit_success` | `complaint_type`, `type_complaint` |
| Personnel | - | `profile`, `change_password` |

**HarmonyOS :** utilise les qualificateurs de ressources `resources/base/element/string.json` + `resources/en_US/element/string.json` (implémenté en même temps que la création du projet HarmonyOS).

## 12. Stratégie de test

### Processus de test TDD

Le projet suit le processus TDD (développement piloté par les tests) : rouge → vert → refactorisation.

```
RED: 先写测试，观察失败
  ↓
GREEN: 写最小代码使测试通过
  ↓
REFACTOR: 清理代码，保持测试绿
```

### Couverture des tests

| Couche | Framework de test | Contenu des tests |
|----|---------|---------|
| Services de base | PHPUnit | Génération d'ID Snowflake, encodage/décodage Hashids, format de réponse |
| Base de données | PHPUnit + PDO | Validation de la structure des tables (clé primaire BIGINT, non auto-incrémentée, préfixe management_) |
| Internationalisation | PHPUnit | Existence des fichiers de traduction, cohérence des clés chinois/anglais |
| Points de terminaison API | PHPUnit | Contrôle de santé, format de réponse |
| Middlewares | Tests d'intégration | Authentification JWT, limitation de débit, permissions |

### Exécution des tests

```bash
cd admin && php vendor/bin/phpunit    # 管理端: 60 tests, 164 assertions
cd service && php vendor/bin/phpunit  # 业务端: 18 tests, 45 assertions, 100% pass
```

## 13. Architecture front-end

### Flutter Web (style desktop PC)

```
apps/flutter/lib/
├── main.dart                    # 入口，初始化 ApiService + AuthService
├── app.dart                     # GetMaterialApp，路由表 + 主题 + i18n
├── config/
│   ├── api_config.dart          # API 端点常量（指向 service :8788）
│   └── theme.dart               # Material 3 主题（Ant Design 色系）
├── services/
│   ├── api_service.dart         # Dio 单例 + JWT 拦截器 + 401 自动刷新
│   ├── auth_service.dart        # 登录/登出/Token 持久化
│   └── storage_service.dart     # shared_preferences 封装
├── i18n/
│   └── messages.dart            # GetX Translations（101键，zh_CN/en）
├── pages/
│   ├── login/                   # PC 风格登录页（居中 Card + 表单验证）
│   ├── home/                    # 仪表盘（4个 StatCard + 公告列表）
│   ├── fee/                     # 账单列表 / 详情 / 缴费弹窗
│   ├── repair/                  # 报修列表 / 提交 / 详情 + 评价
│   └── profile/                 # 个人信息 / 修改密码 / 退出
└── widgets/
    └── stat_card.dart           # 统计卡片组件（图标 + 标题 + 数值）
```

### Client mobile HarmonyOS

```
apps/harmonyos/entry/src/main/ets/
├── services/
│   ├── ApiService.ets           # @ohos.net.http 封装，Bearer Token
│   └── AuthService.ets          # 登录/登出（Preference 持久化）
├── model/
│   └── Models.ets               # TypeScript 接口定义
├── pages/
│   ├── LoginPage.ets            # 手机号 + 密码登录
│   └── HomePage.ets             # 仪表盘（统计卡片 + 公告列表）
└── resources/
    ├── base/element/string.json # 中文资源
    └── en_US/element/string.json# 英文资源
```

### Choix techniques

| Couche | Flutter Web | HarmonyOS |
|----|------------|-----------|
| Gestion d'état | GetX | @State + @Prop |
| HTTP | Dio + intercepteur JWT | @ohos.net.http |
| Persistance | shared_preferences | @ohos.data.preferences |
| Graphiques | fl_chart | Composant Web + ECharts |
| Internationalisation | GetX Translations | qualificateurs de ressources |
| Routage | Routes nommées GetX | router.pushUrl/replaceUrl |

## 14. Architecture des fonctions étendues

### Centre de notifications
Modèle de message → génération de notification → envoi multicanal (in-app/SMS/e-mail/push)

### Workflow d'approbation
Configuration du type d'approbation → soumission d'instance → progression des étapes (approbation/rejet) → notification de l'approbateur suivant

### Processus de paiement
Création de la commande de paiement → paiement tiers → callback asynchrone → mise à jour du statut de la facture → journalisation du paiement

### Vote des propriétaires
Publication du vote → vote des propriétaires (pondéré par surface) → dépouillement en temps réel → statistiques des résultats

### Escalade automatique SLA
Correspondance des règles SLA → vérification périodique des dépassements → escalade automatique → enregistrement des pénalités

### Relance intelligente
Correspondance de la stratégie de relance → détection des retards → génération automatique des tâches de relance → exécution des actions de relance

### Gestion des inspections
Dispatch des tâches → pointage GPS mobile → téléversement de photos → marquage des anomalies → statistiques d'achèvement

### Gestion de groupe
Groupe → association de résidences → agrégation des données inter-résidences (biens/propriétaires/facturation/réparations)

## 15. Documentation API

Utilise `hg/apidoc` pour générer automatiquement la documentation des interfaces à partir des annotations des contrôleurs, groupée par fonction.

**Panneau d'administration** (`http://localhost:8787/apidoc`) : 10 groupes — annotations injectées dans 57 contrôleurs (Base/Docs/Install non groupés)

| Groupe | Nombre | Contrôleurs |
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

**Portail des propriétaires** (`http://localhost:8788/apidoc`) : 9 groupes — annotations injectées dans 17 contrôleurs

| Groupe | Nombre | Contrôleurs |
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

### Normes d'annotation

```php
/**
 * 小区列表
 * @Apidoc\Method("GET")
 * @Apidoc\Url("/admin/community")
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(1)
 * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词")
 * @Apidoc\Param(ref="pagination")
 * @Apidoc\Returned("id", type="string", desc="hashid")
 */
```

### Blocs de définition communs

| Nom du bloc | Contenu |
|------|------|
| `pagination` | Paramètres de pagination page/page_size |
| `searchParams` | Filtres de recherche keyword/status |
| `dateRange` | Plage de dates start_date/end_date |
| `passwordConfirm` | Confirmation du mot de passe password |

## 16. Format de réponse unifié

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| code | Signification |
|------|------|
| 0 | Succès |
| 400 | Erreur de paramètres |
| 401 | Non authentifié |
| 403 | Sans permission |
| 404 | Introuvable |
| 422 | Échec de validation |
| 429 | Requêtes trop fréquentes |
| 500 | Erreur serveur |
