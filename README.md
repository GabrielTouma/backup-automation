# Backup-automation med Terraform och PowerShell

**GitHub:** https://github.com/GabrielTouma/backup-automation

## Mål
Målet är att automatisera en enkel backuprutin. Terraform skapar mappstruktur,
testfiler och en konfigurationsfil. Ett PowerShell-skript läser konfigurationen,
tar backup av filerna och verifierar att backupen är korrekt.

## Metod
Projektet körs i WSL2 (Ubuntu) med Terraform och PowerShell 7.

**Kedja:** Terraform → PowerShell (backup) → PowerShell (verifiering)

1. **Terraform** (`terraform/`) använder `local`-providern och skapar:
   - testfiler i `data/source/`
   - backupmappen `data/backup/`
   - `data/config.json` med inställningar för backupjobbet
2. **PowerShell** (`powershell/backup.ps1`) läser `config.json` och:
   - kopierar filerna till en ny tidsstämplad mapp
   - verifierar att varje fil finns och har rätt storlek
   - tar bort de äldsta backuperna så att max antal sparas
   - loggar allt med tidsstämpel till `data/backup.log`

**Så kör du projektet:**
```bash
cd terraform
terraform init
terraform apply
cd ../powershell
pwsh ./backup.ps1
```

## Resultat
Terraform skapar 5 resurser. Backupskriptet kopierar och verifierar filerna:

```
2026-11-03 11:01:05 [INFO] Startar backupjobb: dagligbackup
2026-11-03 11:01:05 [INFO] Kopierade rapport.txt
2026-11-03 11:01:05 [OK] Verifierad: rapport.txt
2026-11-03 11:01:05 [OK] Hälsokontroll klar: backupen är korrekt
2026-11-03 11:01:05 [OK] Backupjobbet är klart
```

Om konfigurationsfilen saknas fångas felet av try/catch och loggas med `[FEL]`.

Exempel med en sökväg som inte finns:

```
pwsh ./backup.ps1 -ConfigPath /fel/sokvag.json
2026-11-03 11:04:12 [FEL] Backupen misslyckades: Hittar inte konfigurationsfilen: /fel/sokvag.json. Har du kört terraform apply?
```

## Reflektion
Det svåraste i projektet var inte koden utan miljön runt den. När jag skulle
installera PowerShell i WSL fungerade inte Microsofts vanliga installationsmetod,
eftersom min Ubuntu-version (26.04) var för ny för deras paketkälla. Jag fick
istället ladda ner installationsfilen direkt från PowerShells GitHub-sida.

Jag stötte också på flera små problem som tog tid att förstå. VS Code sa att Git
inte fanns, fast det var installerat, eftersom VS Code körde på Windows-sidan och
inte i WSL. Jag döpte mappen till "Terraform" med stort T, vilket inte fungerade
med "cd terraform" eftersom Linux skiljer på stora och små bokstäver. Jag lärde
mig också att inte lägga projekt i System32, där WSL hamnar som standard när
PowerShell körs som administratör.

Jag lärde mig att Terraform inte bara används för molnet utan också kan skapa
lokala filer och mappar, och att config.json fungerar bra som länk mellan
Terraform och PowerShell. Jag förstod också värdet av att verifiera resultatet
istället för att bara anta att kopieringen fungerade.
