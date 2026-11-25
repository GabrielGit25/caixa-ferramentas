# caixa.ps1 v3.2 - SHazam 🔥 + Reparo Sistema + Recuperação Pendrive
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
if (-not (Select-String -LiteralPath $PROFILE -Pattern 'caixa-ferramentas/main/caixa.ps1' -SimpleMatch -Quiet)) {
    ac $PROFILE $aliasCode -Encoding UTF8
    . $PROFILE
    Write-Host "`n✅ cf instalado! Use sempre!" -F Green
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

:menu while ($true) {
    cls
    Write-Host "🔥 CAIXA-FERRAMENTAS v3.2 - TI PRO" -F Magenta
    Write-Host "═" * 55 -F Gray
    Write-Host "  [1] 🔐 Ativação Office (MAS)" -F Green
    Write-Host "  [2] 🌐 Correção de Rede (net-ultra)" -F Green
    Write-Host "  [3] 🪟 Instalar Aplicativos do Pacote Office" -F Green
    Write-Host "  [4] 🛠️ Reparar Corrupção do Sistema (DISM+SFC)" -F Green      # ← NOVA!
    Write-Host "  [5] 🪟 Pular Login Microsoft (Conta Local - OOBE)" -F Green    # ← NOVA!
    Write-Host "  [6] 💾 Recuperar Arquivos de Pendrive" -F Green
    Write-Host "  [0] ❌ Sair" -F Red
    Write-Host "═" * 55 -F Gray
    
    $choice = Read-Host "`n👉 Digite 1, 2, 3, 4, 5, 6 ou 0"
    
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
            Write-Host "🚀 INSTALAR APLICATIVOS OFFICE..." -F Yellow
            irm "$RepoUrl/OfficeSetup.ps1" | iex
        }
        4 {                                    # ← NOVA!
            cls
            Write-Host "🚀 REPARAR CORRUPÇÃO SISTEMA..." -F Yellow
            Write-Host "⚠️  Execute COMO ADMIN!" -F Red
            irm "$RepoUrl/sfc-dism.ps1" | iex
        }
        5 {                                    # ← NOVA!
            cls
            Write-Host "🚀 PULAR LOGIN MICROSOFT (CONTA LOCAL)..." -F Yellow
            irm "$RepoUrl/pular-login.ps1" | iex
        }
        6 {
            cls
            Write-Host "🚀 RECUPERANDO ARQUIVOS DO PENDRIVE..." -F Yellow
            Write-Host "⚠️  Se pedir elevação, execute como ADMIN!" -F DarkYellow
            $txt = irm "$RepoUrl/recuperar-pendrive.ps1"
            $txt.TrimStart([char]0xFEFF) | iex
        }
        0 {
            Write-Host "`n👋 Até logo! cf = sempre aqui!" -F Cyan
            break menu
        }
        default {
            Write-Host "`n❌ APENAS 1, 2, 3, 4, 5, 6 ou 0!" -F Red
            Start-Sleep 2
            continue menu
        }
    }
    
    Write-Host "`n✅ ENTER para voltar..." -F Green
    Read-Host | Out-Null
}
