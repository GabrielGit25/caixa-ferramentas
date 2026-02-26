# sfc-dism.ps1 v1.0 - SHazam 🔥 Reparo Sistema Windows
$LogPath = "$env:USERPROFILE\AppData\Local\sfc-dism.log"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Log {
    param($Msg, $Color="Green")
    $ts = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    "[$ts] $Msg" | Out-File $LogPath -Append -Encoding UTF8
    Write-Host "📊 [$ts] $Msg" -ForegroundColor $Color
}

Clear-Host
Write-Host "🔥 SFC-DISM v1.0 - Reparo Corrupção Sistema" -ForegroundColor Magenta
Write-Log "🚀 sfc-dism v1.0 iniciado"

Write-Host "`n⚠️  Execute COMO ADMIN para reparo completo!" -ForegroundColor Yellow

# 1. DISM /Online /Cleanup-Image /RestoreHealth (10-30min)
Write-Host "`n🔧 PASSO 1/2: DISM RestoreHealth (10-30min)..." -ForegroundColor Cyan
Write-Log "Executando: DISM /Online /Cleanup-Image /RestoreHealth"
Write-Host "⏳ Aguarde conclusão (pode demorar)..." -ForegroundColor Yellow

$dismResult = DISM /Online /Cleanup-Image /RestoreHealth 2>&1
$dismExit = $LASTEXITCODE

Write-Host "`n📊 DISM concluído (Código: $dismExit)" -ForegroundColor Green
Write-Log "DISM concluído (Exit: $dismExit)"

# 2. sfc /scannow (5-15min)
Write-Host "`n🔧 PASSO 2/2: SFC /scannow (5-15min)..." -ForegroundColor Cyan
Write-Log "Executando: sfc /scannow"
Write-Host "⏳ Escaneando arquivos sistema..." -ForegroundColor Yellow

$sfcResult = sfc /scannow 2>&1
$sfcExit = $LASTEXITCODE

Write-Host "`n📊 SFC concluído (Código: $sfcExit)" -ForegroundColor Green
Write-Log "SFC concluído (Exit: $sfcExit)"

# RESULTADO
if ($dismExit -eq 0 -and $sfcExit -eq 0) {
    Write-Host "`n🎯 ✅ REPARO CONCLUÍDO!" -ForegroundColor Green
    Write-Host "   Reinicie o PC para aplicar mudanças" -ForegroundColor Yellow
    Write-Log "🏁 ✅ Reparo 100% OK"
} else {
    Write-Host "`n🎯 ⚠️  Alguns erros encontrados" -ForegroundColor Yellow
    Write-Host "   Reinicie e teste novamente" -ForegroundColor Yellow
    Write-Log "🏁 ⚠️ Erros encontrados (DISM:$dismExit, SFC:$sfcExit)"
}

Write-Host "`n📋 LOG: $LogPath" -ForegroundColor Cyan
Write-Log "🏁 sfc-dism v1.0 concluído"

# PIPELINE SAFE
if ($MyInvocation.InvocationName -eq 'irm' -or $MyInvocation.Line -match 'iex') { exit 0 }
Write-Host "`n🔥 ENTER para sair..." -ForegroundColor Magenta
Read-Host | Out-Null
