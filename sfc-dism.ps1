# sfc-dism.ps1 v1.2 - SHazam 🔥 Reparo Sistema Windows (Versão Refatorada)
# v1.2: verificação de admin, log completo e códigos de reinício aceitos.

# Verifica se o script está sendo executado como Administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ Este script precisa ser executado como Administrador." -ForegroundColor Red
    Write-Host "   Abra o PowerShell como Administrador e rode novamente: cf -> opção 4." -ForegroundColor Yellow
    Write-Host "   Ou clique com o botão direito no script e selecione 'Executar como Administrador'." -ForegroundColor Gray
    Read-Host "Pressione ENTER para sair"
    return
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
Write-Host "🔥 SFC-DISM v1.2 - Reparo Corrupção Sistema" -ForegroundColor Magenta
Write-Log "🚀 sfc-dism v1.2 iniciado"

# 1. DISM /Online /Cleanup-Image /RestoreHealth (10-30min)
Write-Host "`n🔧 PASSO 1/2: DISM RestoreHealth (10-30min)..." -ForegroundColor Cyan
Write-Log "Executando: DISM /Online /Cleanup-Image /RestoreHealth"
Write-Host "⏳ Aguarde conclusão (pode demorar)..." -ForegroundColor Yellow

 $dismResult = DISM /Online /Cleanup-Image /RestoreHealth 2>&1
 $dismExit = $LASTEXITCODE

Write-Log "--- SAÍDA DO COMANDO DISM ---"
foreach ($line in $dismResult) { Write-Log $line }
Write-Log "-----------------------------"

Write-Host "`n📊 DISM concluído (Código: $dismExit)" -ForegroundColor $(if($dismExit -in 0, 3010){'Green'}else{'Yellow'})
Write-Log "DISM concluído (Exit: $dismExit)"

# 2. sfc /scannow (5-15min)
Write-Host "`n🔧 PASSO 2/2: SFC /scannow (5-15min)..." -ForegroundColor Cyan
Write-Log "Executando: sfc /scannow"
Write-Host "⏳ Escaneando arquivos sistema..." -ForegroundColor Yellow

 $sfcResult = sfc /scannow 2>&1
 $sfcExit = $LASTEXITCODE

Write-Log "--- SAÍDA DO COMANDO SFC ---"
foreach ($line in $sfcResult) { Write-Log $line }
Write-Log "----------------------------"

Write-Host "`n📊 SFC concluído (Código: $sfcExit)" -ForegroundColor $(if($sfcExit -in 0, 1, 2){'Green'}else{'Yellow'})
Write-Log "SFC concluído (Exit: $sfcExit)"

$dismOk = $dismExit -in 0, 3010
$sfcOk = $sfcExit -in 0, 1, 2
if ($dismOk -and $sfcOk) {
    $dismStatus = switch ($dismExit) {
        0 { "Concluído." }
        3010 { "Concluído; reinício necessário." }
    }
    $sfcStatus = switch ($sfcExit) {
        0 { "Nenhuma corrupção encontrada." }
        1 { "Corrupções encontradas e reparadas com sucesso." }
        2 { "Reparo pendente; reinicie o PC para concluir." }
    }
    $reboot = ($dismExit -eq 3010 -or $sfcExit -eq 2)
    Write-Host "`n🎯 ✅ REPARO CONCLUÍDO COM SUCESSO!" -ForegroundColor Green
    Write-Host "   Status DISM: $dismStatus" -ForegroundColor Cyan
    Write-Host "   Status SFC: $sfcStatus" -ForegroundColor Cyan
    if ($reboot) { Write-Host "   Reinicie o PC agora para finalizar os reparos." -ForegroundColor Yellow }
    else { Write-Host "   Reinicie o PC para garantir a aplicação de todas as mudanças." -ForegroundColor Yellow }
    Write-Log "🏁 ✅ Reparo OK (DISM:$dismExit, SFC:$sfcExit)"
} else {
    Write-Host "`n🎯 ⚠️  ERROS ENCONTRADOS DURANTE O REPARO." -ForegroundColor Red
    Write-Host "   Verifique o log para detalhes: $LogPath" -ForegroundColor Yellow
    Write-Host "   Tente executar o script novamente após reiniciar o computador." -ForegroundColor Yellow
    Write-Log "🏁 ❌ Erros encontrados (DISM:$dismExit, SFC:$sfcExit)"
}

Write-Host "`n📋 LOG completo salvo em: $LogPath" -ForegroundColor Cyan
Write-Log "🏁 sfc-dism v1.2 concluído"

# PIPELINE SAFE
if ($MyInvocation.InvocationName -eq 'irm' -or $MyInvocation.Line -match 'iex') { return }
Write-Host "`n🔥 ENTER para sair..." -ForegroundColor Magenta
Read-Host | Out-Null
