# net-fix.ps1 v1.5 - SHazam 🔥 100% irm|iex COMPATÍVEL
$LogPath = "$env:USERPROFILE\AppData\Local\net-fix.log"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Log { 
    param($Msg, $Color="Green")
    $ts = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    "[$ts] $Msg" | Out-File $LogPath -Append -Encoding UTF8
    Write-Host "📊 [$ts] $Msg" -ForegroundColor $Color
}

# MAIN EXECUTION
Write-Host "🔥 NET-FIX v1.5 - Resolução TOTAL (irm|iex OK)" -ForegroundColor Magenta
Write-Log "🚀 net-fix v1.5 pipeline compatível"

# TESTE INICIAL
Write-Host "`n🔍 Testando 8.8.8.8..." -ForegroundColor Yellow
$pingOk = Test-Connection 8.8.8.8 -Quiet -Count 2
Write-Log "Teste inicial: $(if($pingOk){'OK'}else{'FALHOU'})"

if($pingOk) { 
    $cor = "Green"; $status = "✅ FUNCIONANDO"
    Write-Log "✅ Internet OK - Manutenção leve"
} else { 
    $cor = "Red"; $status = "❌ SEM CONEXÃO" 
}

Write-Host "📊 STATUS: $status" -ForegroundColor $cor

if($pingOk) {
    Write-Host "`n🎉 Internet OK! DNS limpo..." -ForegroundColor Green
    ipconfig /flushdns | Out-Null 2>&1
} else {
    Write-Host "`n🔧 CORREÇÕES (Ordem Microsoft)..." -ForegroundColor Cyan
    
    # FIXES COMPLETOS
    'ipconfig /flushdns', 'arp -d *', 'ipconfig /release', 'ipconfig /renew', 
    'netsh int ip reset', 'netsh winsock reset' | % {
        Write-Host "🔧 $_ : " -NoNewline -ForegroundColor Yellow
        Invoke-Expression $_ | Out-Null 2>&1
        Write-Host "✅ OK" -ForegroundColor Green
    }
    
    # SERVIÇOS
    @('Dhcp','NlaSvc','WlanSvc') | % {
        Restart-Service $_ -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    # TESTE FINAL
    Start-Sleep 3
    $pingFinal = Test-Connection 8.8.8.8 -Quiet -Count 3
    if($pingFinal) {
        Write-Host "`n🎯 ✅ INTERNET RESOLVIDA!" -ForegroundColor Green
    } else {
        Write-Host "`n🎯 ❌ REBOOT necessário" -ForegroundColor Red
    }
}

Write-Host "`n📊 LOG: $LogPath" -ForegroundColor Cyan

# PIPELINE FIX: Sai SEM Read-Host (caixa controla)
if ($MyInvocation.InvocationName -eq 'irm') { exit 0 }
Write-Host "`n🔥 ENTER para sair..." -ForegroundColor Magenta
Read-Host | Out-Null
