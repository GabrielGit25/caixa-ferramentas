# caixa.ps1 v2.1 - SHazam 🔥 COMANDO 5 CARACTERES: "cf"
$LogPath = "$env:USERPROFILE\AppData\Local\caixa.log"

# 🔥 AUTO-INSTALAÇÃO ALIAS (1ª execução)
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
    Write-Host "✅ INSTALADO! Use: 'cf'" -ForegroundColor Green
    Read-Host "ENTER para abrir caixa..."
}

# 🔧 PAINEL PRINCIPAL (executa após instalação)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$RepoUrl = "https://raw.githubusercontent.com/GabrielGit25/caixa-ferramentas/main"

Clear-Host
Write-Host "🔥 CAIXA-FERRAMENTAS v2.1 - SHazam" -ForegroundColor Magenta
Write-Host "Repo: GabrielGit25/caixa-ferramentas" -ForegroundColor Cyan

do {
    Clear-Host
    Write-Host "🛠️  CAIXA DE FERRAMENTAS TI" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
    
    # Menu dinâmico GitHub
    $menu = irm "$RepoUrl/menu.json" | ConvertFrom-Json
    
    foreach ($item in $menu.menu) {
        $cor = if ($item.Id -eq 0) { "Red" } else { "Green" }
        Write-Host "  [$($item.Id)] $($item.Name)" -ForegroundColor $cor
    }
    
    $choice = Read-Host "`n👉 Escolha [1-$(($menu.menu | ? Id -ne 0 | Select -Last 1).Id),0=Sair]"
    $selected = $menu.menu | ? Id -eq [int]$choice
    
    if ($selected -and $selected.Id -ne 0) {
        Write-Host "`n🚀 $($selected.Name)..." -ForegroundColor Yellow
        irm "$RepoUrl/$($selected.Script)" | iex
        Write-Host "`n✅ Concluído! ENTER..." -ForegroundColor Green
        Read-Host | Out-Null
    } elseif ($choice -eq "0") { 
        Write-Host "👋 Até logo!" -ForegroundColor Red
        break 
    } else { 
        Write-Host "❌ Opção inválida!" -ForegroundColor Red
        Start-Sleep 1 
    }
} while ($true)
