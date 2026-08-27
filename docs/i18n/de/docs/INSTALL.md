# Installationsanleitung

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

Dieses Dokument führt Sie von Grund auf durch die Bereitstellung des Immobilienverwaltungssystems.

---

## Inhaltsverzeichnis

1. [Web-Installationsassistent (empfohlen)](#web-安装向导推荐)
2. [Manuelle Installation](#手动安装)
3. [Docker-Bereitstellung](#docker-部署)
4. [Standardkonten](#默认账户)
5. [Installation verifizieren](#验证安装)
6. [Häufige Fragen](#常见问题)

---

## Web-Installationsassistent (empfohlen)

Das Projekt enthält einen integrierten Web-Installationsassistenten: Nach dem Start des Admin-Panels kann die gesamte Konfiguration über den Browser abgeschlossen werden.

### Schritte

```bash
# 1. In das Admin-Verzeichnis wechseln
cd admin

# 2. Umgebungsvariablendatei erstellen (aus der Vorlage kopieren)
cp .env.example .env

# 3. Abhängigkeiten installieren
composer install --no-dev --optimize-autoloader

# 4. Dienst starten
php start.php start -d
```

### 5. Installationsassistenten öffnen

Im Browser **`http://localhost:8787/install`** aufrufen und die dreistufige Konfiguration wie angezeigt abschließen:

| Schritt | Inhalt | Beschreibung |
|------|------|------|
| Schritt 1 | Datenbankkonfiguration | Host, Port, Datenbankname, Benutzername, Passwort eintragen |
| Schritt 2 | Administratorkonto | Benutzername und Passwort für das Backend festlegen (mindestens 6 Zeichen) |
| Schritt 3 | Installation bestätigen | Konfiguration prüfen, nach Bestätigung wird die Installation automatisch ausgeführt |

Der Installationsprozess erledigt automatisch:
1. Datenbankverbindung testen
2. `.env`-Konfigurationsdatei schreiben
3. Alle 65 Datentabellen + Berechtigungs-Seeds importieren
4. Administratorkonto erstellen und Rolle „Superadministrator" vergeben
5. Sperrdatei `public/.installed` erstellen

### Nach der Installation

- Admin-Backend-Adresse: `http://localhost:8787/admin`
- Der Installationsassistent zeigt Anmeldeadresse und Kontoinformationen an
- Es wird empfohlen, den Dienst neu zu starten, damit die Konfiguration wirksam wird: `php start.php restart -d`
- Für eine Neuinstallation genügt es, die Datei `public/.installed` zu löschen

---

## Manuelle Installation

### Umgebungsanforderungen

| Komponente | Versionsanforderung | Beschreibung |
|------|---------|------|
| PHP | 8.1+ (empfohlen 8.3) | Erweiterungen pcntl, pdo_mysql, redis, gd, mbstring erforderlich |
| MySQL | 8.0+ | utf8mb4-Zeichensatz |
| Redis | 6.0+ | Cache, Ratenbegrenzung, Session |
| Composer | 2.x | PHP-Abhängigkeitsverwaltung |
| Elasticsearch | 8.x | Volltextsuche (optional; deaktiviert wird über Datenbankabfragen gesucht) |
| Flutter SDK | 3.x | Nur für die Frontend-Entwicklung erforderlich |

### PHP-Erweiterungsprüfung

```bash
php -m | grep -E "pcntl|pdo_mysql|redis|gd|mbstring|curl|json|xml|dom"
```

---

## Datenbankinitialisierung

### 1. Datenbank erstellen

```bash
mysql -u root -p <<SQL
CREATE DATABASE IF NOT EXISTS management
  DEFAULT CHARSET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL
```

### 2. Zusammengeführtes Installationsskript importieren

```bash
mysql -u root -p management < docs/install.sql
```

`docs/install.sql` enthält alle 65 Tabellen + RBAC-Berechtigungs-Seed-Daten und verwendet `CREATE TABLE IF NOT EXISTS`, um die erneute Ausführbarkeit sicherzustellen.

Nach der Ausführung verifizieren:

```bash
mysql -u root -p management -e "SHOW TABLES;" | wc -l
# Sollte ausgeben: 66 (65 Tabellen + 1 Kopfzeile)
```

---

## Bereitstellung des Admin-Panels

Das Admin-Panel läuft unter `http://localhost:8787` und stellt die Admin-Backend-API bereit.

```bash
cd admin

# 1. Umgebungsvariablen konfigurieren
cp .env.example .env
# .env bearbeiten: Datenbankpasswort, JWT-Schlüssel usw. ändern

# 2. Abhängigkeiten installieren
composer install --no-dev --optimize-autoloader

# 3. Dienst starten
php start.php start -d
# -d bedeutet Hintergrundbetrieb; ohne -d läuft es im Vordergrund und zeigt Protokolle

# 4. Verifizieren
curl http://localhost:8787/health
```

### Wichtige Konfigurationseinträge (admin/.env)

| Konfigurationseintrag | Beschreibung | Anforderung für Produktion |
|--------|------|-------------|
| `JWT_SECRET_KEY` | JWT-Signaturschlüssel | Zufällige Zeichenfolge mit 64+ Zeichen |
| `HASHIDS_SALT` | Salt für die ID-Verschlüsselung | Zufällige Zeichenfolge, identisch mit service |
| `SNOWFLAKE_DATACENTER_ID` | Rechenzentrums-ID (0-31) | Bei Multi-Datacenter-Bereitstellung unterscheiden |
| `SNOWFLAKE_WORKER_ID` | Arbeitsknoten-ID (0-31) | Im selben Rechenzentrum je Maschine unterschiedlich |
| `ENCRYPTION_KEY` | Schlüssel für die API-Übertragungsverschlüsselung | Zufällige Zeichenfolge mit 32 Bytes |
| `ENCRYPTABLE_KEY` | Schlüssel für die Datenbankfeldverschlüsselung | Zufällige Zeichenfolge mit 32 Bytes |
| `DB_PASSWORD` | Datenbankpasswort | Starkes Passwort |

---

## Bereitstellung des Service-Endes

Das Service-Ende läuft unter `http://localhost:8788` und stellt die Eigentümer-API bereit.

```bash
cd service

# 1. Umgebungsvariablen konfigurieren
cp .env.example .env
# .env bearbeiten: Datenbankpasswort, JWT-Schlüssel usw. ändern

# 2. Abhängigkeiten installieren
composer install --no-dev --optimize-autoloader

# 3. Dienst starten
php start.php start -d

# 4. Verifizieren
curl http://localhost:8788/health
```

> **Hinweis:** admin und service teilen sich dieselbe Datenbank. `HASHIDS_SALT` muss mit admin übereinstimmen, sonst können die von admin erzeugten verschlüsselten IDs auf der service-Seite nicht entschlüsselt werden.

---

## Docker-Bereitstellung

### Admin-Panel

```bash
cd admin
cp .env.docker .env
# .env bearbeiten: Produktionsschlüssel ändern

docker compose up -d
# Enthält: Nginx + PHP + MySQL + Redis + Elasticsearch
```

### Service-Ende

```bash
cd service
cp .env.docker .env
# .env bearbeiten: Produktionsschlüssel ändern

docker compose up -d
```

### Portplanung der Dienste

| Dienst | admin | service | Beschreibung |
|------|-------|---------|------|
| Anwendung | 8787 | 8788 | webman HTTP |
| MySQL | 3306 | 3307 | Container-Portzuordnung |
| Redis | 6379 | 6380 | Container-Portzuordnung |
| Elasticsearch | 9200 | 9201 | Container-Portzuordnung |
| Nginx | 80/443 | 80/443 | Versetzt bereitstellen |

> Bei Bereitstellung beider docker-compose auf demselben Host sind die Ports des Service-Endes voreingestellt versetzt, um Konflikte zu vermeiden.

---

## Standardkonten

| Benutzername | Passwort | Rolle | Beschreibung |
|--------|------|------|------|
| admin | admin123 | Superadministrator | Besitzt alle Berechtigungen |

> **Bitte das Standardpasswort in der Produktion umgehend ändern.**

---

## Installation verifizieren

### 1. Health-Check

```bash
# Admin-Panel
curl http://localhost:8787/health

# Service-Ende
curl http://localhost:8788/health
```

### 2. API-Dokumentation

Alle API-Endpunkte und Parameterbeschreibungen finden Sie im separaten Dokument [API.md](API.md). Nach dem Start des Dienstes ist außerdem die automatisch erzeugte interaktive Schnittstellendokumentation erreichbar:

| Ende | Adresse |
|----|------|
| Admin-Panel | http://localhost:8787/apidoc |
| Service-Ende | http://localhost:8788/apidoc |

### 3. Anmeldetest

```bash
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 4. Tests ausführen

```bash
# Admin-Panel
cd admin && php vendor/bin/phpunit

# Service-Ende
cd service && php vendor/bin/phpunit
```

---

## Häufige Fragen

### F: Beim Start erscheint `Call to undefined function pcntl_fork()`

Der PHP-Erweiterung pcntl fehlt.

```bash
# Ubuntu/Debian
apt install php-pcntl

# Docker
docker-php-ext-install pcntl
```

### F: Nach der Anmeldung wird „Token ungültig" angezeigt

Prüfen, ob die folgenden Einstellungen in den `.env`-Dateien von admin und service übereinstimmen:
- `JWT_SECRET_KEY`
- `JWT_ALGORITHM`

### F: Verschlüsselte IDs sind an beiden Enden unterschiedlich

Sicherstellen, dass `HASHIDS_SALT` in admin und service exakt identisch ist.

### F: Netzwerk zwischen Docker-Containern funktioniert nicht

Zur Verbindung Containernamen statt IPs verwenden (z. B. `DB_HOST=mysql`).

### F: Wie setze ich die Datenbank zurück?

```bash
mysql -u root -p -e "DROP DATABASE IF EXISTS management;"
mysql -u root -p -e "CREATE DATABASE management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p management < docs/install.sql
```

### F: Wie konfiguriere ich HTTPS?

In der Produktion wird empfohlen, TLS über einen Nginx-Reverse-Proxy zu terminieren. Referenzkonfiguration siehe `admin/docs/nginx-security.conf`.

---

## Nächste Schritte

- [Architekturdesign-Dokument](ARCHITECTURE_DESIGN.md) — System-Schichtenarchitektur und Middleware-Ausführungskette
- [API-Dokument](API.md) — Vollständige Schnittstellenreferenz
- [Funktionsdesign-Dokument](FEATURE_DESIGN.md) — Funktionsspezifikationen der 34 Module
- [Versionsvergleich](EDITIONS.md) — Unterschiede zwischen Lite / Standard / Full
