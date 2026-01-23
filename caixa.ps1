# caixa.ps1 v2.3 - SHazam 🔥 NUNCA QUEBRA
$LogPath = "$env:USERPROFILE\AppData\Local\caixa.log"

# AUTO-INSTALAÇÃO (1ª vez)
if (!(Test-Path $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force | Out-Null }
$aliasCode = @"
function caixa {
    irm https://raw.githubusercontent.com/GabrielGit25/caixa-ferramentas/main/caixa.ps1 | iex
}
Set-Alias cf caixa
"@

if (!(Select-String -Path $PROFILE -Pattern "caixa-ferramentas/main/caixa.ps1")) {
    Add-Content -Path $PROFILE -Value $aliasCode -Encoding UTF8
    . $PROFILE
    Write-Host "✅ INSTALADO! Use: 'cf'" -ForegroundColor Green
    Start-Sleep 2
}

# PAINEL PRINCIPAL
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$RepoUrl = "https://raw.githubusercontent.com/GabrielGit25/caixa-ferramentas/main"

Clear-Host
Write-Host "🔥 CAIXA-FERRAMENTAS v2.3 - SHazam" -ForegroundColor Magenta
Write-Host "Repositório: GabrielGit25/caixa-ferramentas" -ForegroundColor Cyan

# MENU HARD-CODED (NUNCA FALHA)
$menu = @(
    @{Id=1; Name="🔐 Ativação Office (MAS)", Script="ativa-office.ps1"},
    @{Id=2; Name="🌐 Correção Rede (net-fix)", Script="net-fix.ps1"},
    @{Id=0; Name="❌ Sair"}
)

do {
    Clear-Host
    Write-Host "🛠️  CAIXA DE FERRAMENTAS TI" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
    
    foreach ($item in $menu) {
        $cor = if ($item.Id -eq 0) { "Red" } else { "Green" }
        Write-Host "  [$($item.Id)] $($item.Name)" -ForegroundColor $cor
    }
    
    Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
    $choice = Read-Host "👉 Escolha opção [1-2,0=Sair]"
    
    switch ($choice) {
        "1" {
            Write-Host "`n🚀 Ativação Office..." -ForegroundColor Yellow
            try { irm "$RepoUrl/ativa-office.ps1" | iex }
            catch { irm https://get.activated.win | iex }
        }
        "2" {
            Write-Host "`n🚀 Correção Rede..." -ForegroundColor Yellow
            try { irm "$RepoUrl/net-fix.ps1" | iex }
            catch { Write-Host "❌ net-fix.ps1 não encontrado!" -ForegroundColor Red }
        }
        "0" {
            Write-Host "👋 Até logo!" -ForegroundColor Red
            break
        }
        default {
            Write-Host "❌ Opção inválida! [1,2,0]" -ForegroundColor Red
            Start-Sleep 1
        }
    }
    
    if ($choice -in @("1","2")) {
        Write-Host "`n✅ Concluído! ENTER para menu..." -ForegroundColor Green
        Read-Host | Out-Null
    }
} while ($true)

Write-Host "`n🔥 cf = Caixa sempre pronta!" -ForegroundColor Cyan
