# pular-login.ps1 v1.0 - SHazam 🔥 Pular Login Microsoft (Conta Local - OOBE)
# Comando: start ms-cxh:localonly (funciona na configuração inicial do Windows 11)
$LogPath = "$env:USERPROFILE\AppData\Local\pular-login.log"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Log {
    param($Msg, $Color="Green")
    $ts = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    "[$ts] $Msg" | Out-File $LogPath -Append -Encoding UTF8
    Write-Host "📊 [$ts] $Msg" -ForegroundColor $Color
}

Clear-Host
Write-Host "🔥 PULAR LOGIN MICROSOFT v1.0 - Conta Local (OOBE)" -ForegroundColor Magenta
Write-Log "🚀 pular-login v1.0 iniciado"

Write-Host "`nℹ️  Este atalho funciona APENAS na configuração inicial do Windows 11" -ForegroundColor Yellow
Write-Host "   (tela de rede ou login de e-mail durante a instalação)." -ForegroundColor Yellow
Write-Log "Verificando execução do comando ms-cxh:localonly"

# TENTA EXECUTAR O COMANDO AUTOMATICAMENTE
Write-Host "`n🚀 Tentando abrir a criação de conta local offline..." -ForegroundColor Cyan
try {
    Start-Process "ms-cxh:localonly" -ErrorAction Stop
    Write-Host "✅ Janela de criação de conta local aberta!" -ForegroundColor Green
    Write-Host "   Digite um nome de usuário e uma senha opcional." -ForegroundColor Cyan
    Write-Log "✅ Start-Process ms-cxh:localonly executado com sucesso"
} catch {
    Write-Host "⚠️  Não foi possível executar agora (fora da OOBE ou comando bloqueado)." -ForegroundColor Yellow
    Write-Host "   Use o método manual abaixo durante a instalação do Windows." -ForegroundColor Yellow
    Write-Log "⚠️ Falha ao executar ms-cxh:localonly: $_" "Yellow"
}

# INSTRUÇÕES MANUAIS (FALLBACK/REFERÊNCIA)
Write-Host "`n" + ("═" * 55) -ForegroundColor Gray
Write-Host "📋 MÉTODO MANUAL (tela de configuração do Windows 11)" -ForegroundColor Magenta
Write-Host ("═" * 55) -ForegroundColor Gray
Write-Host "1️⃣  Abra o Prompt de Comando:" -ForegroundColor White
Write-Host "     • Na tela que pede e-mail/conexão com internet," -ForegroundColor Gray
Write-Host "       pressione Shift + F10" -ForegroundColor White
Write-Host "     • Em alguns notebooks: Shift + Fn + F10" -ForegroundColor Gray
Write-Host "2️⃣  Execute o comando:" -ForegroundColor White
Write-Host "     start ms-cxh:localonly" -ForegroundColor Green
Write-Host "3️⃣  Crie o usuário local:" -ForegroundColor White
Write-Host "     • Digite apenas o nome de usuário" -ForegroundColor Gray
Write-Host "     • Senha opcional (pode deixar em branco)" -ForegroundColor Gray
Write-Host "     • Conclua sem precisar de e-mail Microsoft" -ForegroundColor Gray
Write-Host ("═" * 55) -ForegroundColor Gray
Write-Host "💡 Esse atalho funciona mesmo nas compilações recentes em" -ForegroundColor Yellow
Write-Host "   que o antigo comando oobe\\bypassnro foi bloqueado." -ForegroundColor Yellow

Write-Host "`n📋 LOG: $LogPath" -ForegroundColor Cyan
Write-Log "🏁 pular-login v1.0 concluído"

# PIPELINE FIX: Sai SEM Read-Host se executado via irm
if ($MyInvocation.InvocationName -eq 'irm' -or $MyInvocation.Line -match 'iex') { exit 0 }
Write-Host "`n🔥 ENTER para sair..." -ForegroundColor Magenta
Read-Host | Out-Null
