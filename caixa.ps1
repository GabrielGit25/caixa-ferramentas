# caixa.ps1 v2.8 - SHazam 🔥 LÊ menu.json AUTOMATICAMENTE!
$RepoUrl = "https://raw.githubusercontent.com/GabrielGit25/caixa-ferramentas/main"

# AUTO-INSTALAÇÃO (igual)
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
    Write-Host "🔥 CAIXA-FERRAMENTAS v2.8 - JSON" -ForegroundColor Magenta
    
    # LÊ menu.json ou fallback
    try {
        $menu = irm "$RepoUrl/menu.json" | ConvertFrom-Json
    }
    catch {
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
    
    $choice = Read-Host "`n👉 [$($menu.menu | ? Id -ne 0 | % Id | join ',')]"
    
    $selected = $menu.menu | ? Id -eq [int]$choice
    if ($selected -and $selected.Id -ne 0) {
        Clear-Host
        Write-Host "🚀 $($selected.Name)..." -ForegroundColor Yellow
        try {
            if ($selected.Script -match '^http') { irm $selected.Script | iex }
            else { irm "$RepoUrl/$($selected.Script)" | iex }
        }
        catch { Write-Host "❌ $($selected.Script) falhou!" -ForegroundColor Red }
    }
    elseif ($choice -eq "0") { break }
    else { Write-Host "❌ Inválido!" -ForegroundColor Red; Start-Sleep 1 }
    
    Write-Host "`n✅ ENTER para menu..." -ForegroundColor Green
    Read-Host | Out-Null
}

Write-Host "💡 cf = sempre!" -ForegroundColor Cyan
