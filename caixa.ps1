# caixa.ps1 v2.8.2 - SHazam 🔥 PS5.1 + JSON SEM JOIN
$RepoUrl = "https://raw.githubusercontent.com/GabrielGit25/caixa-ferramentas/main"

# AUTO-INSTALAÇÃO
if (!(Test-Path $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force | Out-Null }
$aliasCode = @"
function caixa { irm "$RepoUrl/caixa.ps1" | iex }
Set-Alias cf caixa
"@
if (!(Select-String -Path $PROFILE -Pattern "caixa-ferramentas/main/caixa.ps1")) {
    Add-Content -Path $PROFILE -Value $aliasCode -Encoding UTF8
    . $PROFILE
    Write-Host "✅ cf instalado!" -ForegroundColor Green
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

while ($true) {
    Clear-Host
    Write-Host "🔥 CAIXA-FERRAMENTAS v2.8.2 - JSON PS5.1" -ForegroundColor Magenta
    
    # LÊ menu.json (fallback PS5.1)
    try {
        $menu = irm "$RepoUrl/menu.json" | ConvertFrom-Json
        Write-Host "✅ menu.json carregado!" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ menu.json indisponível - usando fixo" -ForegroundColor Yellow
        $menu = @{menu = @(
            @{Id=1;Name="🔐 Ativação Office";Script="https://get.activated.win"}
            @{Id=2;Name="🌐 Correção Rede";Script="net-fix.ps1"}
            @{Id=3;Name="🌐 Rede Ultra";Script="net-ultra.ps1"}
            @{Id=0;Name="❌ Sair"}
        )}
    }
    
    Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
    foreach ($item in $menu.menu) {
        $cor = if ($item.Id -eq 0) {"Red"} else {"Green"}
        Write-Host "  [$($item.Id)] $($item.Name)" -ForegroundColor $cor
    }
    Write-Host "═══════════════════════════════════════" -ForegroundColor Gray
    
    # PS5.1 SEM JOIN - fixo simples
    $choice = Read-Host "`n👉 Digite [1,2,3,0]"
    
    $selected = $menu.menu | ? Id -eq [int]$choice
    if ($selected -and $selected.Id -ne 0) {
        Clear-Host
        Write-Host "🚀 $($selected.Name)..." -ForegroundColor Yellow
        try {
            if ($selected.Script -match '^http') { 
                irm $selected.Script | iex 
            }
            else { 
                irm "$RepoUrl/$($selected.Script)" | iex 
            }
        }
        catch { 
            Write-Host "❌ $($selected.Script) falhou!" -ForegroundColor Red 
        }
    }
    elseif ($choice -eq "0") { 
        Write-Host "`n👋 Até logo! (cf)" -ForegroundColor Cyan
        break 
    }
    else { 
        Write-Host "❌ Opção inválida! Use 1,2,3,0" -ForegroundColor Red
        Start-Sleep 1 
    }
    
    Write-Host "`n✅ ENTER para menu..." -ForegroundColor Green
    Read-Host | Out-Null
}

Write-Host "💡 cf = sempre pronto!" -ForegroundColor Cyan
