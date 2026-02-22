# caixa.ps1 v3.0 - SHazam 🔥 SIMPLES + FUNCIONA SEMPRE
$RepoUrl = "https://raw.githubusercontent.com/GabrielGit25/caixa-ferramentas/main"
Clear-Host

# AUTO-INSTALAÇÃO
if (!(Test-Path $PROFILE)) { 
    ni $PROFILE -ItemType File -Force | Out-Null 
}
$aliasCode = @"
function caixa { irm `"$RepoUrl/caixa.ps1`" | iex }
Set-Alias cf caixa
"@
if (!(sls $PROFILE "caixa-ferramentas/main/caixa.ps1")) {
    ac $PROFILE $aliasCode -Encoding UTF8
    . $PROFILE
    Write-Host "`n✅ cf instalado! Use sempre!" -F Green
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

:menu while ($true) {
    cls
    Write-Host "🔥 CAIXA-FERRAMENTAS v3.0 - TI PRO" -F Magenta
    Write-Host "═" * 50 -F Gray
    Write-Host "  [1] 🔐 Ativação Office (MAS)" -F Green
    Write-Host "  [2] 🌐 Correção de Rede (net-ultra)" -F Green
    Write-Host "  [3] 🪟 Instalar Aplicativos do Pacote Office" -F Green   
    Write-Host "  [0] ❌ Sair" -F Red
    Write-Host "═" * 50 -F Gray
    
    $choice = Read-Host "`n👉 Digite 1, 2, 3, ou 0"
    
    switch ($choice) {
        1 {
            cls
            Write-Host "🚀 ATIVAÇÃO OFFICE..." -F Yellow
            irm https://get.activated.win | iex
        }
        2 {
            cls
            Write-Host "🚀 CORREÇÃO REDE..." -F Yellow
            irm "$RepoUrl/net-ultra.ps1" | iex
        }
        3 {                                  
        cls
        Write-Host "🚀 INSTALAR APLICATIVOS DO PACOTE OFFICE" -F Yellow
        irm "$RepoUrl/OfficeSetup.ps1" | iex
       }
        0 {
            Write-Host "`n👋 Até logo! cf = sempre aqui!" -F Cyan
            break menu
        }
        default {
            Write-Host "`n❌ APENAS 1, 2, 3, ou 0!" -F Red
            Start-Sleep 2
            continue menu
        }
    }
    
    Write-Host "`n✅ ENTER para voltar..." -F Green
    Read-Host | Out-Null
}
