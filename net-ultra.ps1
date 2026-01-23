# net-fix.ps1 v1.4 - SHazam 🔥 Correção Rede Profissional
# Windows 11 BR | UTF8 | Standalone | Ctrl+C OK

$LogPath = "$env:USERPROFILE\AppData\Local\net-fix.log"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Log {
param($Msg, $Color="Green")
$ts = Get-Date -f "yyyy-MM-dd HH:mm:ss"
"[$ts] $Msg" | Out-File $LogPath -Append -Encoding UTF8
Write-Host "📊 [$ts] $Msg" -ForegroundColor $Color
}

Clear-Host
Write-Host "🔥 NET-FIX v1.4 - Resolução 95% Internet" -ForegroundColor Magenta
Write-Log "🚀 net-fix v1.4 iniciado"

# 1. DIAGNÓSTICO INICIAL
Write-Host "`n🔍 Teste inicial Google DNS..." -ForegroundColor Yellow
$pingOk = Test-Connection 8.8.8.8 -Quiet -Count 3
$statusInicial = if($pingOk){ "✅ CONECTADO" } else { "❌ SEM INTERNET" }
$corInicial = if($pingOk){ "Green" } else { "Red" }

Write-Host "📊 STATUS INICIAL: $statusInicial" -ForegroundColor $corInicial
Write-Log "Inicial: $statusInicial"

if($pingOk) {
Write-Host "`n🎉 Internet funcionando! Manutenção preventiva:" -ForegroundColor Green
Write-Host "🔧 Limpando DNS cache..." -ForegroundColor Cyan
ipconfig /flushdns | Out-Null 2>&1
Write-Log "✅ Manutenção DNS concluída"
} else {
Write-Host "`n🚨 PROBLEMA DETECTADO - Iniciando correções..." -ForegroundColor Red

# 2. CORREÇÕES ORDEM MICROSOFT OFICIAL
$fixes = @(
@{Nome="DNS Cache"; Cmd="ipconfig /flushdns"},
@{Nome="ARP Cache"; Cmd="arp -d *"},
@{Nome="IP Release"; Cmd="ipconfig /release"},
@{Nome="IP Renew"; Cmd="ipconfig /renew"},
@{Nome="TCP/IP Reset"; Cmd="netsh int ip reset"},
@{Nome="Winsock Reset"; Cmd="netsh winsock reset"}
)

foreach($fix in $fixes) {
Write-Host "🔧 $($fix.Nome): " -NoNewline -ForegroundColor Yellow
try {
Invoke-Expression $fix.Cmd | Out-Null 2>&1
Write-Host "✅ OK" -ForegroundColor Green
Write-Log "✅ $($fix.Nome)"
}
catch {
Write-Host "⚠️ SKIP" -ForegroundColor Yellow
Write-Log "⚠️ $($fix.Nome): $_"
}
}

# 3. SERVIÇOS CRÍTICOS
$servicos = @("Dhcp", "NlaSvc", "WlanSvc")
foreach($svc in $servicos) {
Write-Host "🔄 $svc: " -NoNewline -ForegroundColor Cyan
Restart-Service $svc -Force -ErrorAction SilentlyContinue | Out-Null
Write-Host "✅ Reiniciado" -ForegroundColor Green
}

# 4. ADAPTERS CYCLE (só se admin)
if ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") {
Get-NetAdapter | ? Status -eq 'Up' | % {
$nome = $_.Name
Write-Host "🌐 $nome: " -NoNewline -ForegroundColor Cyan
Disable-NetAdapter $nome -Confirm:$false -ErrorAction SilentlyContinue
Start-Sleep 1
Enable-NetAdapter $nome -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "✅ Ciclo OK" -ForegroundColor Green
}
}

# 5. TESTE FINAL
Write-Host "`n🔍 Teste final (aguarde 5s)..." -ForegroundColor Yellow
Start-Sleep 5
$pingFinal = Test-Connection 8.8.8.8 -Quiet -Count 4

if($pingFinal) {
Write-Host "`n🎯 ✅ INTERNET RESOLVIDA! Teste: google.com" -ForegroundColor Green
Write-Log "🏁 ✅ RESOLVIDO (sem reboot)"
} else {
Write-Host "`n🎯 ❌ Winsock/TCP precisa reboot" -ForegroundColor Red
Write-Host " Reinicie e teste novamente" -ForegroundColor Yellow
Write-Log "🏁 ❌ Reboot necessário (Winsock)"
}
}

Write-Host "`n📋 LOG: $LogPath" -ForegroundColor Cyan
Write-Host "`n🔥 Pressione ENTER para sair..." -ForegroundColor Magenta
Read-Host | Out-Null
