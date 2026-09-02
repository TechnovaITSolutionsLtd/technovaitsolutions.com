# Local marketing review

The modern corporate homepage, Mind the Cards product page and updated Narrow the Number page are intentionally local-only until the operator explicitly authorises publication.

## Start all sites

```powershell
pwsh -File scripts/Start-LocalMarketingPreview.ps1
```

- Corporate website: `http://127.0.0.1:8766/`
- Mind the Cards: `http://127.0.0.1:8765/`
- Narrow the Number: `http://127.0.0.1:8767/`

When the corporate page is running on loopback, its Mind the Cards and Narrow the Number links are rewritten to ports 8765 and 8767. Away from loopback, the same links point to their intended production subdomains.

## Verify

```powershell
pwsh -File scripts/Test-CorporateWebsite.ps1 -Live
```

## Publication gate

Do not deploy, add DNS, remove the `noindex` markers or push this work until the operator explicitly approves the websites for publication.
