# caixa.ps1 v2.6 - SHazam 🔥 MAS DIRETO
$LogPath = "$env:USERPROFILE\AppData\Local\caixa.log"

# AUTO-INSTALAÇÃO
if (!(Test-Path $PROFILE)) { 
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null 
}

$aliasCode = @"
function caixa {
    irm https://raw.githubusercontent.com/GabrielGit25/caixa-ferramentas/main/caixa.ps1 | iex
}
Set-Alias cf caixa
"@

if (!(Select-String -Path $PROFILE -Pattern "caixa-ferramentas/main/caixa.ps1")) {
    Add-Content -Path $PROFILE -Value $aliasCode -Encoding UTF8
    . $PROFILE
}

# CONFIG
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$RepoUrl = "https://raw.githubusercontent.com/GabrielGit25/caixa-ferramentas/main"

while ($true) {
    Clear-Host
    Write-Host "🔥 CAIXA DE FERRAMENTAS v2.6" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
    Write-Host "  [1] 🔐 Ativação Office (MAS)" -ForegroundColor Green
    Write-Host "  [2] 🌐 Correção Rede (net-fix)" -ForegroundColor Green
    Write-Host "  [3] 🌐  Correção Rede Ultra: para problemas mais complexos (net-ultra)" -ForegroundColor Green     
    Write-Host "  [0] ❌ Sair" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
    
    $choice = Read-Host "`n👉 [1,2,0]"
    
    if ($choice -eq "1") {
        Clear-Host
        Write-Host "🚀 ATIVAÇÃO OFFICE - Microsoft Activation Scripts" -ForegroundColor Yellow
        irm https://get.activated.win | iex    # ← DIRETO MAS!
    }
    elseif ($choice -eq "2") {
        Clear-Host
        Write-Host "🚀 CORREÇÃO REDE..." -ForegroundColor Yellow
        try {
            irm "$RepoUrl/net-fix.ps1" | iex
        }
        catch {
            Write-Host "❌ net-fix.ps1 não encontrado!" -ForegroundColor Red
        }
    }
   elseif ($choice -eq "3") {
    Clear-Host
    Write-Host "🚀 CORREÇÃO REDE ULTRA..." -ForegroundColor Yellow
    try {
        irm "$RepoUrl/net-ultra.ps1" | iex
    }
    catch {
        Write-Host "❌ net-ultra.ps1 não encontrado!" -ForegroundColor Red
    }
}

    elseif ($choice -eq "0") {
        Write-Host "`n👋 Até logo! (cf)" -ForegroundColor Cyan
        break
    }
    else {
        Write-Host "`n❌ Digite 1, 2 ou 0!" -ForegroundColor Red
        Start-Sleep 1
    }
    
    if ($choice -in "123") {
        Write-Host "`n✅ ENTER para MENU principal..." -ForegroundColor Green
        Read-Host | Out-Null
    }
}

Write-Host "`n💡 'cf' abre caixa sempre!" -ForegroundColor Cyan
