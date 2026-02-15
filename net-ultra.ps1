# net-fix.ps1 v3.0 - SHazam 🔥 FERRAMENTA UNIFICADA
# Adapta-se automaticamente ao nível de privilégio (Usuário vs. Administrador)
# Compatível com execução local e remota (irm | iex)

# --- CONFIGURAÇÃO INICIAL ---
 $LogPath = "$env:USERPROFILE\AppData\Local\net-fix.log"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- FUNÇÕES ---
function Write-Log { 
    param($Msg, $Color="Green")
    $ts = Get-Date -f "yyyy-MM-dd HH:mm:ss"
    "[$ts] $Msg" | Out-File $LogPath -Append -Encoding UTF8
    Write-Host "📊 [$ts] $Msg" -ForegroundColor $Color
}

function Test-IsAdministrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# --- INÍCIO DO SCRIPT ---
Clear-Host
 $isAdmin = Test-IsAdministrator
 $titulo = if ($isAdmin) { "NET-FIX v3.0 (MODO ADMIN)" } else { "NET-FIX v3.0 (MODO USUÁRIO)" }
Write-Host "🔥 $titulo - Resolução Inteligente" -ForegroundColor Magenta
Write-Log "🚀 net-fix v3.0 iniciado (Modo: $(if($isAdmin){'Admin'}else{'Usuário'}))"

# 1. DIAGNÓSTICO INICIAL
Write-Host "`n🔍 Testando 8.8.8.8..." -ForegroundColor Yellow
 $pingOk = Test-Connection 8.8.8.8 -Quiet -Count 2
 $statusInicial = if($pingOk){ "✅ CONECTADO" } else { "❌ SEM INTERNET" }
 $corInicial = if($pingOk){ "Green" } else { "Red" }

Write-Host "📊 STATUS INICIAL: $statusInicial" -ForegroundColor $corInicial
Write-Log "Inicial: $statusInicial"

if($pingOk) { 
    Write-Host "`n🎉 Internet OK! Manutenção preventiva..." -ForegroundColor Green
    Write-Host "🔧 Limpando DNS cache..." -ForegroundColor Cyan
    ipconfig /flushdns | Out-Null
    Write-Log "✅ Manutenção DNS concluída"
} else {
    Write-Host "`n🚨 PROBLEMA DETECTADO - Iniciando correções..." -ForegroundColor Red
    
    # 2. CORREÇÕES BÁSICAS (Executam sempre)
    $fixesBasicos = @(
        @{Nome="DNS Cache"; Cmd="ipconfig /flushdns"},
        @{Nome="IP Release"; Cmd="ipconfig /release"},
        @{Nome="IP Renew"; Cmd="ipconfig /renew"}
    )
    
    foreach($fix in $fixesBasicos) {
        Write-Host "🔧 $($fix.Nome): " -NoNewline -ForegroundColor Yellow
        try {
            & ([scriptblock]::Create($fix.Cmd)) | Out-Null
            Write-Host "✅ OK" -ForegroundColor Green
            Write-Log "✅ $($fix.Nome)"
        }
        catch {
            Write-Host "❌ FALHA" -ForegroundColor Red
            Write-Log "❌ $($fix.Nome): $_"
        }
    }

    # 3. CORREÇÕES AVANÇADAS (Executam apenas com Admin)
    if ($isAdmin) {
        Write-Host "`n🛠️ Aplicando correções avançadas..." -ForegroundColor Cyan
        $fixesAvancados = @(
            @{Nome="TCP/IP Reset"; Cmd="netsh int ip reset"},
            @{Nome="Winsock Reset"; Cmd="netsh winsock reset"}
        )
        
        foreach($fix in $fixesAvancados) {
            Write-Host "🔧 $($fix.Nome): " -NoNewline -ForegroundColor Yellow
            try {
                & ([scriptblock]::Create($fix.Cmd)) | Out-Null
                Write-Host "✅ OK" -ForegroundColor Green
                Write-Log "✅ $($fix.Nome)"
            }
            catch {
                Write-Host "❌ FALHA" -ForegroundColor Red
                Write-Log "❌ $($fix.Nome): $_"
            }
        }

        # 4. SERVIÇOS CRÍTICOS
        $servicos = @("Dhcp", "NlaSvc", "WlanSvc")
        foreach($svc in $servicos) {
            Write-Host "🔄 Reiniciando serviço $svc`: " -NoNewline -ForegroundColor Cyan
            try {
                Restart-Service $svc -Force -ErrorAction Stop
                Write-Host "✅ OK" -ForegroundColor Green
                Write-Log "✅ Serviço $svc reiniciado"
            }
            catch {
                Write-Host "❌ FALHA" -ForegroundColor Red
                Write-Log "❌ Falha ao reiniciar serviço $svc`: $_"
            }
        }
    } else {
        Write-Host "`n⚠️ Pulando correções avançadas (execute como Admin para mais opções)." -ForegroundColor Yellow
        Write-Log "⚠️ Correções avançadas puladas."
    }
    
    # 5. TESTE FINAL
    Write-Host "`n🔍 Teste final (aguarde 5s)..." -ForegroundColor Yellow
    Start-Sleep 5
    $pingFinal = Test-Connection 8.8.8.8 -Quiet -Count 4
    
    if($pingFinal) { 
        Write-Host "`n🎯 ✅ INTERNET RESOLVIDA!" -ForegroundColor Green
        Write-Log "🏁 ✅ RESOLVIDO"
    } else { 
        $msgFinal = if ($isAdmin) { "🎯 ❌ Reboot necessário (Winsock/TCP resetado)" } else { "🎯 ❌ Problema persistente. Tente executar como Administrador." }
        Write-Host "`n$msgFinal" -ForegroundColor Red
        Write-Host "   Reinicie e teste novamente." -ForegroundColor Yellow
        Write-Log "🏁 $msgFinal"
    }
}

Write-Host "`n📋 LOG: $LogPath" -ForegroundColor Cyan

# PIPELINE FIX: Sai SEM Read-Host se executado via irm
if ($MyInvocation.InvocationName -eq 'irm' -or $MyInvocation.Line -match 'iex') { exit 0 }
Write-Host "`n🔥 Pressione ENTER para sair..." -ForegroundColor Magenta
Read-Host | Out-Null
