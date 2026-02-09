$ErrorActionPreference = "SilentlyContinue"
$OfficeUrl = "https://github.com/GabrielGit25/caixa-ferramentas/raw/refs/heads/main/OfficeSetup.exe"
$tempExe = "$env:TEMP\OfficeSetup-TESTE.exe"

Write-Host "🔍 Testando URL: $OfficeUrl" -ForegroundColor Cyan

try {
    Write-Host "📥 Baixando..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $OfficeUrl -OutFile $tempExe -UseBasicParsing
    $sizeMB = [math]::Round((Get-Item $tempExe).Length/1MB,1)
    Write-Host "✅ ✅ DOWNLOAD OK! $sizeMB MB → $tempExe" -ForegroundColor Green
    Write-Host "▶️  Executando OfficeSetup.exe..." -ForegroundColor Magenta
    Start-Process -FilePath $tempExe -Wait
    Write-Host "✅ EXECUTADO COM SUCESSO!" -ForegroundColor Green
} catch {
    Write-Host "❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔍 Possível: URL errada ou arquivo não .exe" -ForegroundColor Yellow
}
Remove-Item $tempExe -Force -ErrorAction SilentlyContinue
