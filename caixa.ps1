# caixa.ps1 v2.4 - SHazam 🔥 100% INDEPENDENTE
$LogPath = "$env:USERPROFILE\AppData\Local\caixa.log"

# AUTO-INSTALAÇÃO (só 1x)
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
    Write-Host "✅ INSTALADO! Digite 'cf' sempre!" -ForegroundColor Green
    Start-Sleep 2
}

# 🔥 PAINEL COMPLETO HARD-CODED (nunca quebra)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$RepoUrl = "https://raw.githubusercontent.com/GabrielGit25/caixa-ferramentas/main"

Clear-Host
Write-Host "🔥 CAIXA-FERRAMENTAS v2.4 - SHazam" -ForegroundColor Magenta
Write-Host "Sempre pronta • cf = Caixa!" -ForegroundColor Cyan

:menuLoop do {
    Clear-Host
    Write-Host "🛠️  CAIXA DE FERRAMENTAS TI v2.4" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
    Write-Host "  [1] 🔐 Ativação Office (MAS)" -ForegroundColor Green
    Write-Host "  [2] 🌐 Correção Rede (net-fix)" -ForegroundColor Green
    Write-Host "  [0] ❌ Sair" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
    
    $choice = Read-Host "`n👉 Digite [1,2,0]"
    
    switch -Regex ($choice) {
        "^1$" {
            Clear-Host
            Write-Host "🚀 [1] ATIVAÇÃO OFFICE (MAS)..." -ForegroundColor Yellow
            try {
                irm "$RepoUrl/ativa-office.ps1" | iex
            }
            catch {
                Write-Host "🔗 Fallback direto MAS..." -ForegroundColor Cyan
                irm https://get.activated.win | iex
            }
        }
        "^2$" {
            Clear-Host
            Write-Host "🚀 [2] CORREÇÃO REDE (net-fix)..." -ForegroundColor Yellow
            try {
                irm "$RepoUrl/net-fix.ps1" | iex
            }
            catch {
                Write-Host "❌ net-fix.ps1 não encontrado no repo!" -ForegroundColor Red
                Write-Host "Crie o arquivo no GitHub primeiro." -ForegroundColor Yellow
            }
        }
        "^0$" {
            Write-Host "`n👋 Até logo! cf = sempre aqui!" -ForegroundColor Red
            break menuLoop
        }
        default {
            Write-Host "`n❌ Digite apenas: 1, 2 ou 0" -ForegroundColor Red
            Start-Sleep 1
            continue menuLoop
        }
    }
    
    if ($choice -match "^[12]$") {
        Write-Host "`n✅ Concluído! ENTER para MENU..." -ForegroundColor Green
        Read-Host | Out-Null
    }
}

Write-Host "`n💡 Dica: 'cf' abre caixa em qualquer lugar!" -ForegroundColor Cyan
