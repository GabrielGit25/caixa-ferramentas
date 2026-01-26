# caixa.ps1 v2.8.1 - SHazam 🔥 PS5.1 + JSON
$RepoUrl = "https://raw.githubusercontent.com/GabrielGit25/caixa-ferramentas/main"

# AUTO-INSTALAÇÃO
if (!(Test-Path $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force | Out-Null }
$aliasCode = @"
function caixa { irm "$RepoUrl/caixa.ps1" | iex }
Set-Alias cf caixa
"@
if (!(Select-String -Path $PROFILE -Pattern "caixa-ferramentas/main/caixa.ps1")) {
    Add-Content -Path $PROFILE -Value $aliasCode -Encoding UTF8; . $PROFILE
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

while ($true) {
    Clear-Host
    Write-Host "🔥 CAIXA-FERRAMENTAS v2.8.1 - Lê menu.json" -ForegroundColor Magenta
    
    # LÊ menu.json (com fallback PS5.1)
    try {
        $json = irm "$RepoUrl/menu.json"
        $menu = $json | ConvertFrom-Json
    }
    catch {
        Write-Host "⚠️ menu.json indisponível - menu fixo" -ForegroundColor Yellow
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
    
    # PS5.1 COMPATÍVEL - sem 'join'
    $opcoes = ($menu.menu | ? {$_.Id -ne 0} | % {$_.Id}) -join ','
    $choice = Read-Host "`n👉 [$opcoes]"
    
    $selected = $menu.menu | ? Id -eq [int]$choice
    if ($selected -and $selected.Id -ne 0) {
        Clear-Host
        Write-Host "🚀 $($selected.Name)..." -ForegroundColor Yellow
        try {
            if ($selected.Script -match '^http') { irm $selected.Script | iex }
            else { irm "$RepoUrl/$($selected.Script)" | iex }
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
        Write-Host "❌ Opção inválida!" -ForegroundColor Red
        Start-Sleep 1 
    }
    
    Write-Host "`n✅ ENTER para menu..." -ForegroundColor Green
    Read-Host | Out-Null
}

Write-Host "💡 cf funciona sempre!" -ForegroundColor Cyan
