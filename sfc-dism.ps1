# sfc-dism.ps1 v1.1 - SHazam 🔥 Reparo Sistema Windows (Versão Refatorada)
# MODIFICADO: Adicionada verificação de administrador no início.

# Verifica se o script está sendo executado como Administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ Este script precisa ser executado como Administrador." -ForegroundColor Red
    Write-Host "   Clique com o botão direito no script e selecione 'Executar como Administrador'." -ForegroundColor Yellow
    # Pausa para o usuário ler a mensagem antes de fechar
    Read-Host "Pressione ENTER para sair"
    exit
}

 $LogPath = "$env:USERPROFILE\AppData\Local\sfc-dism.log"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Log {
    param($Msg, $Color="Green")
    $ts = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    "[$ts] $Msg" | Out-File $LogPath -Append -Encoding UTF8
    Write-Host "📊 [$ts] $Msg" -ForegroundColor $Color
}

Clear-Host
Write-Host "🔥 SFC-DISM v1.1 - Reparo Corrupção Sistema" -ForegroundColor Magenta
Write-Log "🚀 sfc-dism v1.1 iniciado"

# 1. DISM /Online /Cleanup-Image /RestoreHealth (10-30min)
Write-Host "`n🔧 PASSO 1/2: DISM RestoreHealth (10-30min)..." -ForegroundColor Cyan
Write-Log "Executando: DISM /Online /Cleanup-Image /RestoreHealth"
Write-Host "⏳ Aguarde conclusão (pode demorar)..." -ForegroundColor Yellow

 $dismResult = DISM /Online /Cleanup-Image /RestoreHealth 2>&1
 $dismExit = $LASTEXITCODE

# ADICIONADO: Log da saída completa do comando DISM
Write-Log "--- SAÍDA DO COMANDO DISM ---"
Write-Log $dismResult
Write-Log "-----------------------------"

Write-Host "`n📊 DISM concluído (Código: $dismExit)" -ForegroundColor $(if($dismExit -eq 0){'Green'}else{'Yellow'})
Write-Log "DISM concluído (Exit: $dismExit)"

# 2. sfc /scannow (5-15min)
Write-Host "`n🔧 PASSO 2/2: SFC /scannow (5-15min)..." -ForegroundColor Cyan
Write-Log "Executando: sfc /scannow"
Write-Host "⏳ Escaneando arquivos sistema..." -ForegroundColor Yellow

 $sfcResult = sfc /scannow 2>&1
 $sfcExit = $LASTEXITCODE

# ADICIONADO: Log da saída completa do comando SFC
Write-Log "--- SAÍDA DO COMANDO SFC ---"
Write-Log $sfcResult
Write-Log "----------------------------"

Write-Host "`n📊 SFC concluído (Código: $sfcExit)" -ForegroundColor $(if($sfcExit -in 0,1){'Green'}else{'Yellow'})
Write-Log "SFC concluído (Exit: $sfcExit)"

# RESULTADO
# MODIFICADO: Lógica de verificação de sucesso aprimorada para o SFC (códigos 0 e 1 são sucesso).
if ($dismExit -eq 0 -and $sfcExit -in 0, 1) {
    $sfcStatus = switch ($sfcExit) {
        0 { "Nenhuma corrupção encontrada." }
        1 { "Corrupções encontradas e reparadas com sucesso." }
    }
    Write-Host "`n🎯 ✅ REPARO CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
    Write-Host "   Status SFC: $sfcStatus" -ForegroundColor Cyan
    Write-Host "   Reinicie o PC para garantir a aplicação de todas as mudanças." -ForegroundColor Yellow
    Write-Log "🏁 ✅ Reparo 100% OK (DISM:$dismExit, SFC:$sfcExit)"
} else {
    Write-Host "`n🎯 ⚠️  ERROS ENCONTRADOS DURANTE O REPARO." -ForegroundColor Red
    Write-Host "   Verifique o log para detalhes: $LogPath" -ForegroundColor Yellow
    Write-Host "   Tente executar o script novamente após reiniciar o computador." -ForegroundColor Yellow
    Write-Log "🏁 ❌ Erros encontrados (DISM:$dismExit, SFC:$sfcExit)"
}

Write-Host "`n📋 LOG completo salvo em: $LogPath" -ForegroundColor Cyan
Write-Log "🏁 sfc-dism v1.1 concluído"

# PIPELINE SAFE
if ($MyInvocation.InvocationName -eq 'irm' -or $MyInvocation.Line -match 'iex') { exit 0 }
Write-Host "`n🔥 ENTER para sair..." -ForegroundColor Magenta
Read-Host | Out-Null
