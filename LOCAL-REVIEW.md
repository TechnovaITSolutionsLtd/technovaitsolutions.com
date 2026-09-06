# Corporate website workflow

The corporate homepage is published from `master`. Product marketing pages live in the Hodgepodge repository and are linked from the homepage.

## Start all sites

```powershell
pwsh -File scripts/Start-LocalMarketingPreview.ps1
```

- Corporate website: `http://127.0.0.1:8766/`
- Mind the Cards: `http://127.0.0.1:8765/`
- Narrow the Number: `http://127.0.0.1:8767/`
- Ultimate Code Breaker: `http://127.0.0.1:8768/`

The corporate page always links to the production product sites and stores. The local product previews are available for checking changes in their own repositories.

## Verify

```powershell
pwsh -File scripts/Test-CorporateWebsite.ps1 -Live
```

The production homepage must remain indexable and must never identify unreleased web applications before they are ready to be announced.
