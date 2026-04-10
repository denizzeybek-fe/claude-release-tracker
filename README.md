# Claude Code Release Tracker

GitHub Actions + Telegram bot ile [anthropics/claude-code](https://github.com/anthropics/claude-code) repo'sundaki yeni release'leri otomatik takip eder.

- Her gun 09:00 UTC'de yeni release kontrol edilir
- Son 24 saatte yeni release varsa Telegram'a bildirim gonderilir
- Yoksa bir sey yapmaz — tamamen sessiz

**Tamamen ucretsiz** — sadece GitHub API + Telegram Bot API. Claude API kullanmaz.

```
+-----------------+       +----------------+       +------------------+
| GitHub Actions  | ----> | GitHub API     | ----> | Telegram Bot API |
| (cron: 09:00)   |       | (latest release)|      | (send message)   |
+-----------------+       +----------------+       +------------------+
```

---

## Setup

### 1. Telegram Bot Olustur

1. Telegram'da [@BotFather](https://t.me/BotFather)'a git
2. `/newbot` yaz
3. Bot icin bir isim ver (ornegin `Claude Release Tracker`)
4. Bot icin bir username ver (ornegin `claude_release_tracker_bot`)
5. BotFather sana bir **token** verecek — kaydet

```
Use this token to access the HTTP API:
7123456789:AAHxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 2. Chat ID Al

1. Olusturdugu bot'a Telegram'dan herhangi bir mesaj at (ornegin "test")
2. Tarayicida su URL'yi ac (token'i kendi token'inle degistir):

```
https://api.telegram.org/bot<TOKEN>/getUpdates
```

3. JSON response'ta `chat.id` degerini bul:

```json
{
  "result": [{
    "message": {
      "chat": {
        "id": 123456789
      }
    }
  }]
}
```

> **Grup icin kullanmak istiyorsan:** Bot'u gruba ekle, grupta bir mesaj yaz, ayni `/getUpdates` URL'sini ac. Grup chat ID'si negatif bir sayi olacak (ornegin `-1001234567890`).

### 3. GitHub Repo'yu Fork/Clone Et

```bash
# Fork et (GitHub'da Fork butonuna bas) veya direkt clone:
git clone https://github.com/<YOUR_USERNAME>/claude-release-tracker.git
```

### 4. GitHub Secrets Ekle

Repo'nun **Settings > Secrets and variables > Actions** sayfasina git ve su iki secret'i ekle:

| Secret Name          | Deger                              |
|---------------------|------------------------------------|
| `TELEGRAM_BOT_TOKEN` | BotFather'dan aldigin token        |
| `TELEGRAM_CHAT_ID`   | getUpdates'ten aldigin chat ID     |

### 5. Test Et

```bash
# GitHub Actions'ta manuel tetikle:
# Repo > Actions > "Claude Code Release Checker" > Run workflow
```

Ya da CLI ile:

```bash
gh workflow run release-check.yml
```

---

## Usage Example

### Workflow Nasil Calisir?

```
1. Her gun 09:00 UTC'de GitHub Actions tetiklenir
2. scripts/check-release.sh calisir
3. GitHub API'den anthropics/claude-code'un son release'i cekilir
4. published_at tarihi kontrol edilir:
   - Son 24 saat icinde mi? → Telegram bildirimi gonder
   - 24 saatten eski mi?   → Hicbir sey yapma
```

### Manuel Test

```bash
# 1. Workflow'u tetikle
gh workflow run release-check.yml

# 2. Calisma durumunu kontrol et
gh run list --workflow=release-check.yml --limit=1

# 3. Loglarini gor
gh run view --log
```

### Lokal Test (opsiyonel)

```bash
# Environment variable'lari set et
export TELEGRAM_BOT_TOKEN="7123456789:AAHxxxxxxxxxx"
export TELEGRAM_CHAT_ID="123456789"

# Script'i calistir
bash scripts/check-release.sh
```

---

## Implementation Example

### Telegram Mesaj Ornegi

Bot su formatta mesaj gonderir:

```
+------------------------------------------+
| New Claude Code Release!                  |
|                                          |
| Version: Claude Code v1.0.20 (v1.0.20)  |
| Published: 2026-04-09T15:30:00Z          |
|                                          |
| Changelog Preview:                       |
| - Fixed bug in auto-completion           |
| - Added support for new MCP tools        |
| - Performance improvements               |
|                                          |
| [View Full Release Notes]                |
+------------------------------------------+
```

Gercek Telegram gorunumu (HTML formatted):

> **New Claude Code Release!**
>
> **Version:** Claude Code v1.0.20 (v1.0.20)
> **Published:** 2026-04-09T15:30:00Z
>
> **Changelog Preview:**
> ```
> - Fixed bug in auto-completion
> - Added support for new MCP tools
> ```
>
> [View Full Release Notes](https://github.com/anthropics/claude-code/releases/tag/v1.0.20)

### Workflow Output Ornegi

```
Run bash scripts/check-release.sh
Checking latest release for anthropics/claude-code...
New release detected: v1.0.20 (published 2026-04-09T15:30:00Z)
Telegram notification sent successfully!
```

Release yoksa:

```
Run bash scripts/check-release.sh
Checking latest release for anthropics/claude-code...
Latest release 'v1.0.19' is older than 24 hours. No notification needed.
```

---

## Proje Yapisi

```
claude-release-tracker/
├── .github/
│   └── workflows/
│       └── release-check.yml    # Cron job (09:00 UTC daily)
├── scripts/
│   └── check-release.sh         # Release kontrol + Telegram bildirim
├── README.md
└── .gitignore
```

## Nasil Calisir (Teknik)

1. **GitHub Actions** her gun 09:00 UTC'de `release-check.yml` workflow'unu tetikler
2. Workflow `scripts/check-release.sh` script'ini calistirir
3. Script, GitHub REST API ile `anthropics/claude-code` repo'sunun son release'ini ceker:
   ```
   GET https://api.github.com/repos/anthropics/claude-code/releases/latest
   ```
4. `published_at` alanini kontrol eder — son 24 saat icinde mi?
5. Eger yeni release varsa, Telegram Bot API ile mesaj gonderir:
   ```
   POST https://api.telegram.org/bot<TOKEN>/sendMessage
   ```

---

## License

MIT
