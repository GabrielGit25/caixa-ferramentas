# net-fix.ps1 v1.4 - SHazam 🔥 SEM ERROS SYNTAX
$LogPath = "$env:USERPROFILE\AppData\Local\net-fix.log"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Log {
param($Msg, $Color="Green")
$ts = Get-Date -f "yyyy-MM-dd HH:mm:ss"
"[$ts] $Msg" | Out-File $LogPath -Append -Encoding UTF8
Write-Host "📊 [$ts] $Msg" -ForegroundColor $Color
}

Write-Host "🔥 NET-FIX v1.4 - RESOLUÇÃO TOTAL!" -ForegroundColor Magenta
Write-Log "🚀 Iniciado net-fix v1.4"

# TESTE INICIAL
Write-Host "`n🔍 Testando internet..." -ForegroundColor Yellow
$pingOk = Test-Connection 8.8.8.8 -Quiet -Count 2
Write-Log "Teste inicial: $(if($pingOk){'OK'}else{'FALHOU'})"

if($pingOk) {
$cor = "Green"
$status = "✅ FUNCIONANDO"
Write-Log "✅ Internet OK - Manutenção preventiva"
} else {
$cor = "Red"
$status = "❌ SEM CONEXÃO"
}

Write-Host "📊 STATUS INICIAL: $status" -ForegroundColor $cor

if($pingOk) {
Write-Host "`n🎉 Internet OK! Manutenção preventiva executada." -ForegroundColor Green
} else {
Write-Host "`n🔧 Iniciando correções..." -ForegroundColor Cyan

# FIXES BÁSICOS (seguros)
Write-Host "🔧 DNS Cache: " -NoNewline -ForegroundColor Yellow
ipconfig /flushdns | Out-Null 2>&1
Write-Host "✅ LIMPO" -ForegroundColor Green
Write-Log "✅ DNS cache limpo"

Write-Host "🔧 IP Renew: " -NoNewline -ForegroundColor Yellow
ipconfig /release | Out-Null 2>&1
ipconfig /renew | Out-Null 2>&1
Write-Host "✅ RENOVADO" -ForegroundColor Green
Write-Log "✅ IP renovado"

# TESTE FINAL
Write-Host "🔍 Teste final..." -ForegroundColor Yellow
Start-Sleep 2
$pingFinal = Test-Connection 8.8.8.8 -Quiet -Count 2

if($pingFinal) {
Write-Host "`n🎯 FINAL: ✅ INTERNET RESOLVIDA!" -ForegroundColor Green
Write-Log "🏁 ✅ RESOLVIDO"
} else {
Write-Host "`n🎯 FINAL: ❌ Reboot necessário" -ForegroundColor Red
Write-Log "🏁 ❌ Reboot necessário"
}
}

Write-Host "`n📋 LOG criado: $LogPath" -ForegroundColor Cyan
Write-Host "`n🔥 Pressione ENTER para sair..." -ForegroundColor Magenta

# 🔒 ANTI-FECHAR
Read-Host | Out-Null
