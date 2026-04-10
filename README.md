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

### Workflow Akisi

```
┌─────────────────────────────────────────────────────────┐
│  09:00 UTC — GitHub Actions cron tetiklenir             │
│                                                         │
│  1. scripts/check-release.sh calisir                    │
│  2. GitHub API'den son release cekilir:                 │
│     GET /repos/anthropics/claude-code/releases/latest   │
│  3. published_at kontrol edilir:                        │
│     ├─ < 24 saat → Telegram bildirimi gonder ✅         │
│     └─ > 24 saat → Sessizce cik, bildirim yok 🔇       │
└─────────────────────────────────────────────────────────┘
```

### Manuel Test (CLI)

```bash
# Workflow'u tetikle
gh workflow run release-check.yml

# Durumunu takip et (canli)
gh run watch

# Veya son calismayi gor
gh run list --workflow=release-check.yml --limit=1
# STATUS  TITLE                        BRANCH  EVENT              ID            ELAPSED
# ✓       Claude Code Release Checker  main    workflow_dispatch  24246092237   9s

# Loglarini gor
gh run view 24246092237 --log
```

### Lokal Test

```bash
# Secret'lari set et
export TELEGRAM_BOT_TOKEN="your-token-here"
export TELEGRAM_CHAT_ID="your-chat-id"

# Calistir
bash scripts/check-release.sh
# Checking latest release for anthropics/claude-code...
# New release detected: v2.1.100 (published 2026-04-10T05:16:35Z)
# Telegram notification sent successfully!
```

---

## Implementation Example

### Gercek Telegram Bildirimi

Asagidaki bildirim `v2.1.100` release'i icin gercek workflow ciktisidir (10 Nisan 2026):

```
┌──────────────────────────────────────────┐
│  🆕 New Claude Code Release!             │
│                                          │
│  Version: v2.1.100 (v2.1.100)           │
│  Published: 2026-04-10T05:16:35Z        │
│                                          │
│  Changelog Preview:                      │
│  (release notes icerigi buraya gelir)    │
│                                          │
│  📎 View Full Release Notes              │
└──────────────────────────────────────────┘
```

Bot mesaji HTML formatinda gonderir. Telegram'da soyle gorunur:

> **New Claude Code Release!**
>
> **Version:** v2.1.100 (v2.1.100)
> **Published:** 2026-04-10T05:16:35Z
>
> **Changelog Preview:**
> `(ilk 300 karakter gosterilir)`
>
> [View Full Release Notes](https://github.com/anthropics/claude-code/releases/tag/v2.1.100)

### Gercek Workflow Log Ciktisi

Yeni release varsa:

```
Run bash scripts/check-release.sh
Checking latest release for anthropics/claude-code...
New release detected: v2.1.100 (published 2026-04-10T05:16:35Z)
Telegram notification sent successfully!
```

Yeni release yoksa:

```
Run bash scripts/check-release.sh
Checking latest release for anthropics/claude-code...
Latest release 'v2.1.100' is older than 24 hours. No notification needed.
```

### Script Nasil Calisiyor? (Adim Adim)

```bash
# 1. GitHub API'den son release'i cek
curl -s "https://api.github.com/repos/anthropics/claude-code/releases/latest"
# → { "tag_name": "v2.1.100", "published_at": "2026-04-10T05:16:35Z", ... }

# 2. published_at'i unix timestamp'e cevir
date -d "2026-04-10T05:16:35Z" +%s  # → 1744258595

# 3. Simdiki zaman ile karsilastir (fark < 86400 saniye = 24 saat mi?)
now=$(date +%s)  # → 1744310804
diff=$((now - 1744258595))  # → 52209 (< 86400 ✅)

# 4. Fark 24 saatten kucukse Telegram'a gonder
curl -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d chat_id="<CHAT_ID>" \
  -d parse_mode="HTML" \
  --data-urlencode "text=<b>New Claude Code Release!</b>..."
# → { "ok": true, "result": { "message_id": 42, ... } }
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
