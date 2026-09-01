# Local marketing review

The modern corporate homepage and Mind the Cards product page are intentionally local-only until the app is approved and the operator explicitly authorises publication.

## Start both sites

```powershell
pwsh -File scripts/Start-LocalMarketingPreview.ps1
```

- Corporate website: `http://127.0.0.1:8766/`
- Mind the Cards: `http://127.0.0.1:8765/`

When the corporate page is running on loopback, its Mind the Cards link is rewritten locally to port 8765. Away from loopback, the same link points to the intended production subdomain.

## Verify

```powershell
pwsh -File scripts/Test-CorporateWebsite.ps1 -Live
```

## Publication gate

Do not deploy, add DNS, remove the `noindex` marker or push this work until the operator explicitly approves both websites for publication.
