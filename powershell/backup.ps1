# backup.ps1 - tar backup enligt config.json från Terraform och verifierar
param(
    [string]$DataDir = "$PSScriptRoot/../data"
)

$ErrorActionPreference = "Stop"
$LogFile = "$DataDir/backup.log"

# Funktion 1: skriver tidsstämplad rad till skärm och loggfil
function Write-Log {
    param([string]$Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

# Funktion 2: kopierar alla filer från källa till mål
function New-Backup {
    param([string]$Source, [string]$Target)
    New-Item -ItemType Directory -Path $Target | Out-Null
    $files = Get-ChildItem -Path $Source -File
    foreach ($file in $files) {
        Copy-Item -Path $file.FullName -Destination $Target
        Write-Log "Kopierade $($file.Name)"
    }
}

# Funktion 3: kontrollerar att varje fil finns i backupen
function Test-Backup {
    param([string]$Source, [string]$Target)
    $errors = 0
    foreach ($file in Get-ChildItem -Path $Source -File) {
        if (Test-Path "$Target/$($file.Name)") {
            Write-Log "OK: $($file.Name)"
        }
        else {
            Write-Log "SAKNAS: $($file.Name)"
            $errors++
        }
    }
    return $errors
}

# Huvudprogram
try {
    $config = Get-Content "$DataDir/config.json" -Raw | ConvertFrom-Json
    $target = "$DataDir/backup/$($config.backup_name)-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

    Write-Log "Startar backup: $($config.backup_name)"
    New-Backup -Source "$DataDir/source" -Target $target

    $errors = Test-Backup -Source "$DataDir/source" -Target $target
    if ($errors -eq 0) {
        Write-Log "Hälsokontroll klar: backupen är korrekt"
    }
    else {
        Write-Log "Hälsokontroll misslyckades: $errors filer saknas"
    }
}
catch {
    Write-Log "FEL: $($_.Exception.Message)"
    exit 1
}