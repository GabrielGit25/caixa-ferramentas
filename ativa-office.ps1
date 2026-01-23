# ativa-office.ps1 - Integração MAS
if (!(Test-Path $PROFILE)) { 
    New-Item -Path $PROFILE -ItemType File -Force | Out-Null 
}
$aliasCode = @"
function ativa-office { irm https://get.activated.win | iex }
Set-Alias ao ativa-office
"@
Add-Content -Path $PROFILE -Value $aliasCode -Encoding UTF8
. $PROFILE
Write-Host "✅ 'instalado!' e 'ativa-office' instalados!" -F Green
Read-Host "ENTER"
