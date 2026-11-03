<#
  backup.ps1
  Läser config.json (skapad av Terraform), tar backup av källmappen
  och verifierar att backupen är korrekt.
#>
param(
    [string]$ConfigPath = "$PSScriptRoot/../data/config.json"
)

$ErrorActionPreference = "Stop"
$script:LogFile = $null

# Funktion 1: skriver tidsstämplad rad till skärm och loggfil
function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO", "OK", "FEL")][string]$Level = "INFO"
    )
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $line
    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $line
    }
}

# Funktion 2: läser in config.json
function Get-BackupConfig {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Hittar inte konfigurationsfilen: $Path. Har du kört terraform apply?"
    }
    return Get-Content -Path $Path -Raw | ConvertFrom-Json
}

# Funktion 3: kopierar alla filer till en ny tidsstämplad mapp
function New-Backup {
    param(
        [Parameter(Mandatory)][string]$SourceDir,
        [Parameter(Mandatory)][string]$BackupDir,
        [Parameter(Mandatory)][string]$BackupName
    )
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $target = Join-Path $BackupDir "$BackupName-$timestamp"
    New-Item -ItemType Directory -Path $target | Out-Null
    Write-Log "Skapade backupmapp: $target"

    $files = Get-ChildItem -Path $SourceDir -File
    foreach ($file in $files) {
        Copy-Item -Path $file.FullName -Destination $target
        Write-Log "Kopierade $($file.Name)"
    }
    return $target
}

# Funktion 4: verifierar att varje fil finns och har rätt storlek
function Test-Backup {
    param(
        [Parameter(Mandatory)][string]$SourceDir,
        [Parameter(Mandatory)][string]$BackupFolder
    )
    $errors = 0
    foreach ($file in Get-ChildItem -Path $SourceDir -File) {
        $copy = Join-Path $BackupFolder $file.Name

        if (-not (Test-Path $copy)) {
            Write-Log "Saknas i backup: $($file.Name)" -Level FEL
            $errors++
        }
        elseif ((Get-Item $copy).Length -ne $file.Length) {
            Write-Log "Fel storlek: $($file.Name)" -Level FEL
            $errors++
        }
        else {
            Write-Log "Verifierad: $($file.Name)" -Level OK
        }
    }
    return ($errors -eq 0)
}

# Funktion 5: tar bort äldsta backuperna om det finns fler än MaxBackups
function Remove-OldBackups {
    param(
        [Parameter(Mandatory)][string]$BackupDir,
        [Parameter(Mandatory)][int]$MaxBackups
    )
    $backups = @(Get-ChildItem -Path $BackupDir -Directory | Sort-Object Name)
    $i = 0
    while (($backups.Count - $i) -gt $MaxBackups) {
        Remove-Item -Path $backups[$i].FullName -Recurse
        Write-Log "Tog bort gammal backup: $($backups[$i].Name)"
        $i++
    }
}

# Huvudprogram
try {
    $config = Get-BackupConfig -Path $ConfigPath
    $script:LogFile = $config.log_file
    Write-Log "Startar backupjobb: $($config.backup_name)"

    if (-not (Test-Path $config.source_dir)) {
        throw "Källmappen finns inte: $($config.source_dir)"
    }

    $backupFolder = New-Backup -SourceDir $config.source_dir -BackupDir $config.backup_dir -BackupName $config.backup_name

    if (Test-Backup -SourceDir $config.source_dir -BackupFolder $backupFolder) {
        Write-Log "Hälsokontroll klar: backupen är korrekt" -Level OK
    }
    else {
        throw "Hälsokontrollen misslyckades, se loggen"
    }

    Remove-OldBackups -BackupDir $config.backup_dir -MaxBackups $config.max_backups
    Write-Log "Backupjobbet är klart" -Level OK
}
catch {
    Write-Log "Backupen misslyckades: $($_.Exception.Message)" -Level FEL
    exit 1
}