# caixa.ps1 v2.2 - SHazam 🔥 JSON FIX + FALLBACK
$LogPath = "$env:USERPROFILE\AppData\Local\caixa.log"

# AUTO-INSTALAÇÃO ALIAS
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
}

# PAINEL PRINCIPAL
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$RepoUrl = "https://raw.githubusercontent.com/GabrielGit25/caixa-ferramentas/main"

function Get-Menu {
    try {
        $response = irm "$RepoUrl/menu.json" -ErrorAction Stop
        if ($response -match '^{.*}$') {
            return $response | ConvertFrom-Json
        } else {
            throw "JSON inválido"
        }
    }
    catch {
        Write-Host "⚠️ menu.json indisponível. Usando menu local..." -ForegroundColor Yellow
        return @{
            menu = @(
                @{Id=1; Name="🔐 Ativação Office"; Script="ativa-office.ps1"},
                @{Id=2; Name="🌐 Correção Rede"; Script="net-fix.ps1"},
                @{Id=0; Name="❌ Sair"}
            )
        }
    }
}

Clear-Host
Write-Host "🔥 CAIXA-FERRAMENTAS v2.2 - JSON FIX" -ForegroundColor Magenta

do {
    Clear-Host
    Write-Host "🛠️  CAIXA DE FERRAMENTAS TI" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
    
    $menu = Get-Menu
    
    foreach ($item in $menu.menu) {
        $cor = if ($item.Id -eq 0) { "Red" } else { "Green" }
        Write-Host "  [$($item.Id)] $($item.Name)" -ForegroundColor $cor
    }
    
    $choice = Read-Host "`n👉 Escolha [1-2,0=Sair]"
    $selected = $menu.menu | ? Id -eq [int]$choice
    
    if ($selected -and $selected.Id -ne 0) {
        Write-Host "`n🚀 $($selected.Name)..." -ForegroundColor Yellow
        try {
            irm "$RepoUrl/$($selected.Script)" | iex
        }
        catch {
            Write-Host "❌ Erro: $($selected.Script) não encontrado!" -ForegroundColor Red
        }
        Write-Host "`n✅ ENTER para menu..." -ForegroundColor Green
        Read-Host | Out-Null
    } elseif ($choice -eq "0") { 
        Write-Host "👋 Até logo!" -ForegroundColor Red
        break 
    } else { 
        Write-Host "❌ Opção inválida!" -ForegroundColor Red
        Start-Sleep 1 
    }
} while ($true)
