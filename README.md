# Browser‑Extension Metadata Scraper  
*A simple PowerShell tool for quickly retrieving details about Chrome & Edge add‑ons*

---

## ✨ Features

| Capability | Details |
|------------|---------|
| **Single‑lookup** | Enter one extension ID and immediately get its name, version, description and a direct link. |
| **Batch mode** | Paste multiple IDs and save all metadata to a TSV file. |
| **Multi‑source scraping** | • Attempts the Chrome Web Store first<br>• Falls back to the official Edge Add‑ons JSON API<br>• Finally scrapes the Edge Add‑ons HTML page if needed. |
| **Reference link generation** | Adds a `Link` column that points to the correct store listing. |
| **Clean output** | Results are shown in a formatted table and can be exported as tab‑separated values for spreadsheets. |

---

## 🔧 Requirements

* **Windows PowerShell 5.1** (or newer / PowerShell Core)
* Internet connectivity (the script queries live store endpoints)
* TLS 1.2 support (enabled automatically at start‑up via `ServicePointManager`)

---

## 📦 Installation

1. Clone or download this repository.
2. Save the script as `Get-ExtensionInfo.ps1` (or any name you prefer).
3. Unblock the file if needed (`Unblock‑File .\Get-ExtensionInfo.ps1`).
4. Run PowerShell and navigate to the script folder.

```powershell
powershell -ExecutionPolicy Bypass -File .\new5.ps1
```

---

## 🚀 Usage

When the script starts youʼll see the **Extension Info Menu**:

```
==== Extension Info Menu ====
1) Lookup one extension ID
2) Lookup multiple IDs (save to TSV)
3) Exit
4) Help/About
```

### 1  Lookup one extension ID

*Press `1` and enter a 16‑ to 32‑character ID.*

```
Enter extension ID: hdokiejnpimakedhajhdlcegeplioahd
```

Output:

```
ID                                 Name                Version Description                           Source Link
--                                 ----                ------- -----------                           ------ ----
hdokiejnpimakedhajhdlcegeplioahd   Grammarly for Chrome 15.32.2 Write clearly across the web…       Chrome https://chrome.google.com/webstore/detail/hdokiejnpimakedhajhdlcegeplioahd
```

### 2  Lookup multiple IDs (batch / TSV export)

*Press `2` and enter each ID on its own line. Type **`done`** when finished.*

```
ID: hdokiejnpimakedhajhdlcegeplioahd
ID: gighmmpiobklfepjocnamgkkbiglidom
ID: done
```

You will be prompted for an output file name. The default is **`compile1.tsv`**.

The script prints the same table and writes the selected columns (`ID Name Version Description Source Link`) to the TSV file, ready for Excel / Google Sheets.

---

## 🗂️ Output file format

```
ID [tab] Name [tab] Version [tab] Description [tab] Source [tab] Link
```

Example row:

```
hdokiejnpimakedhajhdlcegeplioahd   Grammarly for Chrome   15.32.2   Write clearly across the web…   Chrome   https://chrome.google.com/webstore/detail/hdokiejnpimakedhajhdlcegeplioahd
```

---

## 🛡️ How it works

1. **Chrome scrape** – Tries to fetch the extensionʼs public HTML page and regex‑extracts `<title>`, description meta tag and version.
2. **Edge JSON API** – If Chrome fails, calls Microsoftʼs undocumented JSON endpoint which returns clean fields.
3. **Edge HTML scrape** – Final fallback: scrapes the Edge listing page.
4. **Reference link** – Adds the correct store URL based on where data was discovered.

---

## ⚠️ Limitations & Notes

* Only public listings are supported (private / unlisted add‑ons will fail).
* Descriptions longer than ~250 chars are truncated by the stores themselves.
* Rate‑limits: very large batch jobs may trigger temporary store throttling.
* The script performs minimal HTML parsing via regex – layout changes could break scraping.

---

## 🤝 Contributing

Pull requests are welcome! Feel free to open issues or suggest improvements.

---

## 📄 License

MIT © 2025 [Zzulfaqar](https://github.com/Zzulfaqar)

---

## 🙌 Acknowledgements

* Chrome Web Store & Microsoft Edge Add‑ons teams for public endpoints.
* Inspired by numerous Stack Overflow snippets and the PowerShell community.

