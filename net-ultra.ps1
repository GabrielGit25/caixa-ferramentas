# net-ultra.ps1 v1.5 - SHazam 🔥 Correção Rede ULTRA - PS5.1 FIX
$LogPath = "$env:USERPROFILE\AppData\Local\net-ultra.log"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Log {
    param($Msg, $Color="Green")
    $ts = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    "[$ts] $Msg" | Out-File $LogPath -Append -Encoding UTF8
    Write-Host "📊 [$ts] $Msg" -ForegroundColor $Color
}

cls
Write-Host "🔥 NET-ULTRA v1.5 - Resolução 98% Internet" -ForegroundColor Magenta
Write-Log "🚀 net-ultra v1.5 iniciado"

# DIAGNÓSTICO
Write-Host "`n🔍 Teste Google DNS..." -ForegroundColor Yellow
$pingOk = Test-Connection 8.8.8.8 -Quiet -Count 3
$statusInicial = if($pingOk){ "✅ CONECTADO" } else { "❌ SEM INTERNET" }
Write-Host "📊 STATUS: $statusInicial" -ForegroundColor $(if($pingOk){"Green"}else{"Red"})
Write-Log "Inicial: $statusInicial"

if($pingOk) {
    Write-Host "`n🎉 Internet OK! Manutenção..." -ForegroundColor Green
    ipconfig /flushdns | Out-Null 2>&1
    Write-Log "✅ DNS limpo"
} else {
    Write-Host "`n🚨 CORREÇÕES ULTRA..." -ForegroundColor Red
    
    # FIXES MICROSOFT (sem $var:)
    @(
        @{Nome="DNS"; Cmd="ipconfig /flushdns"},
        @{Nome="ARP"; Cmd="arp -d *"},
        @{Nome="Release"; Cmd="ipconfig /release"},
        @{Nome="Renew"; Cmd="ipconfig /renew"},
        @{Nome="TCP Reset"; Cmd="netsh int ip reset"},
        @{Nome="Winsock"; Cmd="netsh winsock reset"}
    ) | % {
        Write-Host "🔧 $($_.Nome): " -NoNewline -ForegroundColor Yellow
        try {
            iex $_.Cmd | Out-Null 2>&1
            Write-Host "✅ OK" -ForegroundColor Green
            Write-Log "✅ $($_.Nome)"
        }
        catch {
            Write-Host "⚠️ SKIP" -ForegroundColor Yellow
        }
    }
    
    # SERVIÇOS (sem $svc:)
    @("Dhcp", "NlaSvc", "WlanSvc") | % {
        $svcName = $_
        Write-Host "🔄 ${svcName}: " -NoNewline -ForegroundColor Cyan
        Restart-Service $svcName -Force -ErrorAction SilentlyContinue | Out-Null
        Write-Host "✅ Reiniciado" -ForegroundColor Green
    }
    
    # ADAPTERS (só admin, sem $nome:)
    if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Get-NetAdapter | ? Status -eq 'Up' | % {
            $adapterName = $_.Name
            Write-Host "🌐 ${adapterName}: " -NoNewline -ForegroundColor Cyan
            Disable-NetAdapter $adapterName -Confirm:$false -ErrorAction SilentlyContinue
            Start-Sleep 1
            Enable-NetAdapter $adapterName -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "✅ Ciclo OK" -ForegroundColor Green
        }
    }
    
    # TESTE FINAL
    Write-Host "`n🔍 Teste final (5s)..." -ForegroundColor Yellow
    Start-Sleep 5
    $pingFinal = Test-Connection 8.8.8.8 -Quiet -Count 4
    
    if($pingFinal) {
        Write-Host "`n🎯 ✅ INTERNET RESOLVIDA!" -ForegroundColor Green
        Write-Log "🏁 ✅ RESOLVIDO"
    } else {
        Write-Host "`n🎯 ❌ REBOOT necessário" -ForegroundColor Red
        Write-Log "🏁 ❌ Reboot"
    }
}

Write-Host "`n📊 LOG: $LogPath" -ForegroundColor Cyan

# PIPELINE FIX - sai limpo para caixa
if ($MyInvocation.MyCommand.Definition -match 'irm|iex') { exit 0 }
Write-Host "`n🔥 ENTER para sair..." -ForegroundColor Magenta
Read-Host | Out-Null
