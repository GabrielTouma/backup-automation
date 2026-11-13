# backup.ps1 - tar backup enligt config.json från Terraform och verifierar
param([string]$DataDir = "$PSScriptRoot/../data")   # var data-mappen finns, $DataDir är basmappen för all data

$ErrorActionPreference = "Stop"    # alla fel fångas av catch
$LogFile = "$DataDir/backup.log"   # loggfil med tidsstämplar

# Funktion 1: skriver tidsstämplad rad till skärm och logg
function Write-Log {
    param([string]$Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"   # tid + meddelande
    Write-Host $line                                               # skriv till skärm
    Add-Content $LogFile $line -ErrorAction SilentlyContinue       # skriv till logg
}

# Funktion 2: kopierar alla filer från källa till mål
function New-Backup {
    param([string]$Source, [string]$Target)           # källa och mål --> (sökväg till backup)
    New-Item -ItemType Directory $Target | Out-Null   # skapa backupmappen
    $files = Get-ChildItem $Source -File              # array med alla filer, listar innehåll
    foreach ($file in $files) {                       # loopa igenom filerna efter att listat
        Copy-Item $file.FullName $Target              # kopiera filen, hamnar i backupmapp som target pekar på
        Write-Log "Kopierade $($file.Name)"           # logga att filen kopierats
    }
}

# Funktion 3: kontrollerar att varje fil finns i backupen, returnerar antal fel, hälsokontroll
function Test-Backup {
    param([string]$Source, [string]$Target)
    $errors = 0
    foreach ($file in Get-ChildItem $Source -File) {                               # loopa igenom filerna i källan, läggs i $file
        if (Test-Path "$Target/$($file.Name)") { Write-Log "OK: $($file.Name)" }   # kollar om kopian finns i backupen
        else { Write-Log "SAKNAS: $($file.Name)"; $errors++ }                      # kopian saknas
    }
    return $errors                                                                 # 0 = allt OK
}

# Funktion 4: kör backup och hälsokontroll, fel loggas istället för att krascha
function Start-Backup {
    try {
        $config = Get-Content "$DataDir/config.json" -Raw | ConvertFrom-Json                 # läs config från Terraform
        $target = "$DataDir/backup/$($config.backup_name)-$(Get-Date -Format 'yyyyMMdd-HHmmss')"  # sökväg: namn + tid
        Write-Log "Startar backup: $($config.backup_name)"                                   # logga start
        New-Backup -Source "$DataDir/source" -Target $target                                 # filer från source kopieras till target
        $errors = Test-Backup -Source "$DataDir/source" -Target $target                      # hälsokontroll
        if ($errors -eq 0) { Write-Log "Hälsokontroll klar: backupen är korrekt" }
        else { Write-Log "Hälsokontroll misslyckades: $errors filer saknas" }
    }
    catch {
        Write-Log "FEL: $($_.Exception.Message)"   # logga vad som gick fel, tillbaka till menyn
    }
}

# Meny - visas tills användaren väljer 0
do {
    Write-Host ""
    Write-Host "===== BACKUP-MENY ====="
    Write-Host "1. Ta backup och verifiera"
    Write-Host "2. Visa befintliga backuper"
    Write-Host "3. Visa loggen"
    Write-Host "0. Avsluta"
    $choice = Read-Host "Välj ett alternativ"     # läs användarens val

    switch ($choice) {                             # kör olika kod beroende på valet
        "1" { Start-Backup }
        "2" { Get-ChildItem "$DataDir/backup" -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name } }
        "3" {
            if (Test-Path $LogFile) { Get-Content $LogFile }
            else { Write-Host "Ingen logg finns än" }
        }
        "0" { Write-Host "Avslutar..." }
        default { Write-Host "Ogiltigt val, försök igen" }
    }
} while ($choice -ne "0")                          # upprepa tills användaren väljer 0

# rm -rf ~/projects/backup-automation/data