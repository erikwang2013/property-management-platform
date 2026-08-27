# Guia de Instalação

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

Este documento orienta a implantação do Sistema de Gestão de Propriedades do zero.

---

## Sumário

1. [Assistente de instalação Web (recomendado)](#assistente-de-instalação-web-recomendado)
2. [Instalação manual](#instalação-manual)
3. [Implantação com Docker](#implantação-com-docker)
4. [Conta padrão](#conta-padrão)
5. [Verificação da instalação](#verificação-da-instalação)
6. [Perguntas frequentes](#perguntas-frequentes)

---

## Assistente de instalação Web (recomendado)

O projeto inclui um assistente de instalação Web: após iniciar o painel de administração, toda a configuração pode ser concluída pelo navegador.

### Passos

```bash
# 1. Entre no diretório do painel de administração
cd admin

# 2. Crie o arquivo de variáveis de ambiente (copiado do template)
cp .env.example .env

# 3. Instale as dependências
composer install --no-dev --optimize-autoloader

# 4. Inicie o serviço
php start.php start -d
```

### 5. Abra o assistente de instalação

Acesse **`http://localhost:8787/install`** no navegador e conclua a configuração em três etapas:

| Etapa | Conteúdo | Descrição |
|------|------|------|
| Etapa 1 | Configuração do banco de dados | Preencha host, porta, nome do banco, usuário e senha |
| Etapa 2 | Conta de administrador | Defina usuário e senha de login do painel (mínimo 6 caracteres) |
| Etapa 3 | Confirmação da instalação | Revise as informações e clique em confirmar para executar a instalação |

O processo de instalação conclui automaticamente:
1. Teste da conexão com o banco de dados
2. Gravação do arquivo de configuração `.env`
3. Importação de todas as 65 tabelas + seed de permissões
4. Criação da conta de administrador com papel de superadministrador
5. Criação do arquivo de bloqueio de instalação `public/.installed`

### Após a instalação

- Endereço do painel de administração: `http://localhost:8787/admin`
- O assistente exibirá o endereço de login e as informações da conta
- Recomenda-se reiniciar o serviço para aplicar a configuração: `php start.php restart -d`
- Para reinstalar, basta excluir o arquivo `public/.installed`

---

## Instalação manual

### Requisitos de ambiente

| Componente | Versão exigida | Descrição |
|------|---------|------|
| PHP | 8.1+ (recomendado 8.3) | Extensões necessárias: pcntl, pdo_mysql, redis, gd, mbstring |
| MySQL | 8.0+ | Charset utf8mb4 |
| Redis | 6.0+ | Cache, limite de taxa, sessões |
| Composer | 2.x | Gerenciamento de dependências PHP |
| Elasticsearch | 8.x | Busca em texto completo (opcional; se desativado, usa consultas ao banco) |
| Flutter SDK | 3.x | Necessário apenas para desenvolvimento de front-end |

### Verificação das extensões PHP

```bash
php -m | grep -E "pcntl|pdo_mysql|redis|gd|mbstring|curl|json|xml|dom"
```

---

## Inicialização do banco de dados

### 1. Criar o banco de dados

```bash
mysql -u root -p <<SQL
CREATE DATABASE IF NOT EXISTS management
  DEFAULT CHARSET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL
```

### 2. Importar o script de instalação consolidado

```bash
mysql -u root -p management < docs/install.sql
```

O `docs/install.sql` contém todas as 65 tabelas + dados de seed de permissões RBAC, usando `CREATE TABLE IF NOT EXISTS` para garantir execução repetível.

Verificação após a execução:

```bash
mysql -u root -p management -e "SHOW TABLES;" | wc -l
# Deve exibir: 66 (65 tabelas + 1 linha de cabeçalho)
```

---

## Implantação do painel de administração

O painel de administração roda em `http://localhost:8787` e fornece as APIs do painel administrativo.

```bash
cd admin

# 1. Configure as variáveis de ambiente
cp .env.example .env
# Edite o .env: senha do banco, chave JWT etc.

# 2. Instale as dependências
composer install --no-dev --optimize-autoloader

# 3. Inicie o serviço
php start.php start -d
# -d indica execução em segundo plano; sem -d, roda em primeiro plano para ver os logs

# 4. Verifique
curl http://localhost:8787/health
```

### Itens de configuração importantes (admin/.env)

| Item de configuração | Descrição | Exigência em produção |
|--------|------|-------------|
| `JWT_SECRET_KEY` | Chave de assinatura JWT | String aleatória com 64+ caracteres |
| `HASHIDS_SALT` | Salt de criptografia de ID | String aleatória, idêntica à do service |
| `SNOWFLAKE_DATACENTER_ID` | ID do datacenter (0-31) | Diferencie em implantações multi-datacenter |
| `SNOWFLAKE_WORKER_ID` | ID do nó de trabalho (0-31) | Diferente em cada máquina do mesmo datacenter |
| `ENCRYPTION_KEY` | Chave de criptografia de transmissão da API | String aleatória de 32 bytes |
| `ENCRYPTABLE_KEY` | Chave de criptografia de campos do banco | String aleatória de 32 bytes |
| `DB_PASSWORD` | Senha do banco de dados | Senha forte |

---

## Implantação do portal de proprietários

O portal de proprietários roda em `http://localhost:8788` e fornece as APIs para proprietários.

```bash
cd service

# 1. Configure as variáveis de ambiente
cp .env.example .env
# Edite o .env: senha do banco, chave JWT etc.

# 2. Instale as dependências
composer install --no-dev --optimize-autoloader

# 3. Inicie o serviço
php start.php start -d

# 4. Verifique
curl http://localhost:8788/health
```

> **Atenção:** admin e service compartilham o mesmo banco de dados. O `HASHIDS_SALT` deve ser idêntico ao do admin; caso contrário, os IDs criptografados gerados pelo admin não poderão ser descriptografados no service.

---

## Implantação com Docker

### Painel de administração

```bash
cd admin
cp .env.docker .env
# Edite o .env para alterar as chaves de produção

docker compose up -d
# Inclui: Nginx + PHP + MySQL + Redis + Elasticsearch
```

### Portal de proprietários

```bash
cd service
cp .env.docker .env
# Edite o .env para alterar as chaves de produção

docker compose up -d
```

### Planejamento de portas dos serviços

| Serviço | admin | service | Descrição |
|------|-------|---------|------|
| Aplicação | 8787 | 8788 | HTTP webman |
| MySQL | 3306 | 3307 | Mapeamento de porta do contêiner |
| Redis | 6379 | 6380 | Mapeamento de porta do contêiner |
| Elasticsearch | 9200 | 9201 | Mapeamento de porta do contêiner |
| Nginx | 80/443 | 80/443 | Requer implantação em portas distintas |

> Ao implantar os dois docker-compose no mesmo host, as portas do service já possuem deslocamento predefinido para evitar conflitos.

---

## Conta padrão

| Usuário | Senha | Papel | Descrição |
|--------|------|------|------|
| admin | admin123 | Superadministrador | Possui todas as permissões |

> **Altere a senha padrão imediatamente em produção.**

---

## Verificação da instalação

### 1. Verificação de saúde

```bash
# Painel de administração
curl http://localhost:8787/health

# Portal de proprietários
curl http://localhost:8788/health
```

### 2. Documentação da API

Todos os endpoints e parâmetros da API estão no documento [API.md](API.md). Após iniciar o serviço, também é possível acessar a documentação interativa gerada automaticamente:

| Endpoint | Endereço |
|----|------|
| Painel de administração | http://localhost:8787/apidoc |
| Portal de proprietários | http://localhost:8788/apidoc |

### 3. Teste de login

```bash
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 4. Executar os testes

```bash
# Painel de administração
cd admin && php vendor/bin/phpunit

# Portal de proprietários
cd service && php vendor/bin/phpunit
```

---

## Perguntas frequentes

### P: Erro ao iniciar `Call to undefined function pcntl_fork()`

Falta a extensão pcntl no PHP.

```bash
# Ubuntu/Debian
apt install php-pcntl

# Docker
docker-php-ext-install pcntl
```

### P: Após o login, mensagem de Token inválido

Verifique se as configurações a seguir são idênticas nos `.env` de admin e service:
- `JWT_SECRET_KEY`
- `JWT_ALGORITHM`

### P: IDs criptografados divergem entre os dois serviços

Garanta que o valor de `HASHIDS_SALT` seja exatamente o mesmo em admin e service.

### P: Sem comunicação de rede entre contêineres Docker

Conecte usando o nome do contêiner em vez do IP (por exemplo, `DB_HOST=mysql`).

### P: Como redefinir o banco de dados

```bash
mysql -u root -p -e "DROP DATABASE IF EXISTS management;"
mysql -u root -p -e "CREATE DATABASE management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p management < docs/install.sql
```

### P: Como configurar HTTPS

Em produção, recomenda-se usar o Nginx como proxy reverso para terminar o TLS. Consulte a configuração de referência em `admin/docs/nginx-security.conf`.

---

## Próximos passos

- [Documento de design de arquitetura](ARCHITECTURE_DESIGN.md) — arquitetura em camadas do sistema e cadeia de execução de middlewares
- [Documentação da API](API.md) — referência completa da API
- [Documento de design de funcionalidades](FEATURE_DESIGN.md) — especificações dos 34 módulos
- [Comparação de edições](EDITIONS.md) — diferenças entre Lite / Standard / Full
