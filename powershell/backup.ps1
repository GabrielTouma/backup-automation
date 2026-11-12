# backup.ps1 - tar backup enligt config.json från Terraform och verifierar
param([string]$DataDir = "$PSScriptRoot/../data")   # var data-mappen finns

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
    param([string]$Source, [string]$Target)           # källa och mål
    New-Item -ItemType Directory $Target | Out-Null   # skapa backupmappen
    $files = Get-ChildItem $Source -File              # array med alla filer
    foreach ($file in $files) {                       # loopa igenom filerna
        Copy-Item $file.FullName $Target              # kopiera filen
        Write-Log "Kopierade $($file.Name)"           # logga att filen kopierats
    }
}

# Funktion 3: kontrollerar att varje fil finns i backupen, returnerar antal fel
function Test-Backup {
    param([string]$Source, [string]$Target)
    $errors = 0                                                                    # räknare för fel
    foreach ($file in Get-ChildItem $Source -File) {                               # loopa igenom filerna
        if (Test-Path "$Target/$($file.Name)") { Write-Log "OK: $($file.Name)" }   # kopian finns
        else { Write-Log "SAKNAS: $($file.Name)"; $errors++ }                      # kopian saknas
    }
    return $errors                                                                 # 0 = allt OK
}

# Huvudprogram - allt i try/catch så fel loggas istället för att krascha
try {
    $config = Get-Content "$DataDir/config.json" -Raw | ConvertFrom-Json                      # läs config från Terraform
    $target = "$DataDir/backup/$($config.backup_name)-$(Get-Date -Format 'yyyyMMdd-HHmmss')"  # namn + tid
    Write-Log "Startar backup: $($config.backup_name)"                                        # logga start
    New-Backup -Source "$DataDir/source" -Target $target                                      # ta backup
    $errors = Test-Backup -Source "$DataDir/source" -Target $target                           # hälsokontroll
    if ($errors -eq 0) { Write-Log "Hälsokontroll klar: backupen är korrekt" }
    else { Write-Log "Hälsokontroll misslyckades: $errors filer saknas" }
}
catch {
    Write-Log "FEL: $($_.Exception.Message)"   # logga vad som gick fel
    exit 1                                     # avsluta med felkod 1
}

# pwsh ./backup.ps1 -DataDir /fel i powershell directory