# recuperar-pendrive.ps1 v1.0 - SHazam 🔥 Recuperação de arquivos corrompidos de pendrive
param(
    [string]$DriveLetter,
    [string]$OutputPath = (Join-Path (Get-Location) 'recuperados'),
    [int]$MaxMB = 320,
    [double]$StartGB = 0,
    [double]$EndGB = 0,
    [int]$Alignment = 4096,
    [switch]$DryRun,
    [switch]$SkipOrphanRebuild
)

$LogPath = "$env:USERPROFILE\AppData\Local\recuperar-pendrive.log"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Write-Log {
    param($Msg, $Color = 'Green')
    $ts = Get-Date -f 'yyyy-MM-dd HH:mm:ss'
    "[$ts] $Msg" | Out-File $LogPath -Append -Encoding UTF8
    Write-Host "📊 [$ts] $Msg" -ForegroundColor $Color
}

function Find-All {
    param([string]$Text, [string]$Pattern)
    $res = New-Object System.Collections.ArrayList
    $i = $Text.IndexOf($Pattern, 0, [System.StringComparison]::Ordinal)
    while ($i -ge 0) {
        [void]$res.Add([long]$i)
        $i = $Text.IndexOf($Pattern, $i + 1, [System.StringComparison]::Ordinal)
    }
    return ,$res
}

function Get-CleanPart {
    param([string]$Value, [int]$MaxLen)
    if (-not $Value) { return '' }
    $v = $Value -replace '[\\/:*?"<>|]', '_' -replace '\s+', ' '
    $v = $v.Trim()
    if ($v.Length -gt $MaxLen) { $v = $v.Substring(0, $MaxLen) }
    return $v
}

function Get-OfficeMeta {
    param([string]$Path)
    $meta = @{ Creator = ''; Title = ''; Created = '' }
    try {
        $za = [System.IO.Compression.ZipFile]::OpenRead($Path)
        $core = $za.GetEntry('docProps/core.xml')
        if ($core) {
            $sr = New-Object System.IO.StreamReader($core.Open())
            $xml = $sr.ReadToEnd()
            $sr.Close()
            $meta.Creator = [regex]::Match($xml, '<dc:creator>(.*?)</dc:creator>').Groups[1].Value
            $meta.Created = [regex]::Match($xml, '<dcterms:created[^>]*>(.*?)</dcterms:created>').Groups[1].Value
            $meta.Title = [regex]::Match($xml, '<dc:title>(.*?)</dc:title>').Groups[1].Value
        }
        $za.Dispose()
    } catch {}
    return $meta
}

function New-OutputName {
    param([string]$Ext, [long]$Offset, [int]$Seq, [hashtable]$Meta)
    $who = Get-CleanPart $Meta.Creator 45
    if (-not $who) { $who = 'sem_autor' }
    $ttl = Get-CleanPart $Meta.Title 40
    $when = if ($Meta.Created -match '^(\d{4}-\d{2}-\d{2})') { $Matches[1] } else { 'sem_data' }
    $base = if ($ttl) { "$who - $ttl" } else { $who }
    return ('{0:D4}_{1}_{2}_{3}.{4}' -f $Seq, $Offset, $base, $when, $Ext)
}

function Select-RemovableDrive {
    param([string]$Letter)
    $disks = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=2' | Sort-Object DeviceID)
    $target = $null
    if ($Letter) {
        $wanted = $Letter.TrimEnd(':') + ':'
        $target = $disks | Where-Object { $_.DeviceID -eq $wanted } | Select-Object -First 1
        if (-not $target -and (Test-Path -LiteralPath "$wanted\")) {
            $target = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $wanted } | Select-Object -First 1
        }
        if (-not $target) {
            Write-Log "Unidade $wanted não encontrada." 'Red'
            return $null
        }
    } else {
        if ($disks.Count -eq 0) {
            Write-Log 'Nenhum pendrive removível detectado. Use -DriveLetter se necessário.' 'Yellow'
            return $null
        }
        Write-Host "`n💾 PENDRIVES DETECTADOS:" -ForegroundColor Cyan
        $n = 0
        foreach ($d in $disks) {
            $n++
            $label = if ($d.VolumeName) { $d.VolumeName } else { 'sem rótulo' }
            $size = [math]::Round($d.Size / 1GB, 2)
            $free = [math]::Round($d.FreeSpace / 1GB, 2)
            Write-Host ("  [{0}] {1} ({2}) - {3} GB total, {4} GB livre" -f $n, $d.DeviceID, $label, $size, $free) -ForegroundColor Green
        }
        $answer = Read-Host "`n👉 Digite o número ou a letra da unidade"
        if ($answer -match '^\d+$') {
            $ix = [int]$answer - 1
            if ($ix -ge 0 -and $ix -lt $disks.Count) { $target = $disks[$ix] }
        } else {
            $wanted = $answer.TrimEnd(':') + ':'
            $target = $disks | Where-Object { $_.DeviceID -eq $wanted } | Select-Object -First 1
        }
        if (-not $target) {
            Write-Log 'Seleção inválida.' 'Red'
            return $null
        }
    }
    $label = if ($target.VolumeName) { $target.VolumeName } else { 'sem rótulo' }
    Write-Host "`n🎯 ALVO: $($target.DeviceID) ($label)" -ForegroundColor Yellow
    $confirm = Read-Host 'Confirma a leitura dessa unidade? (S/N)'
    if ($confirm -notmatch '^[Ss]') {
        Write-Log 'Operação cancelada pelo usuário.' 'Yellow'
        return $null
    }
    return $target.DeviceID.TrimEnd(':')
}

function Open-RawDevice {
    param([string]$Letter)
    $path = '\\.\' + $Letter + ':'
    try {
        return [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    } catch [System.UnauthorizedAccessException] {
        Write-Log 'Acesso negado ao dispositivo bruto. Execute o PowerShell como Administrador e tente novamente.' 'Red'
        return $null
    } catch {
        Write-Log "Falha ao abrir $path : $($_.Exception.Message)" 'Red'
        return $null
    }
}

function Read-RawWindow {
    param([string]$Letter, [long]$Start, [long]$Length)
    $aligned = [long][math]::Floor($Start / 512) * 512
    $skip = [int]($Start - $aligned)
    $total = [long]$skip + $Length
    if ($total -gt 1GB) {
        Write-Log 'Janela muito grande; limitando a 1 GB por segurança.' 'Yellow'
        $total = [long]1GB
        $Length = $total - $skip
    }
    if ($total -gt [int]::MaxValue) {
        Write-Log 'Janela ainda maior que o limite de memória; abortando.' 'Red'
        return $null
    }
    $fs = Open-RawDevice $Letter
    if (-not $fs) { return $null }
    $buf = New-Object byte[] ([int]$total)
    [void]$fs.Seek($aligned, [System.IO.SeekOrigin]::Begin)
    $got = 0
    try {
        while ($got -lt $total) {
            $n = $fs.Read($buf, $got, [int]($total - $got))
            if ($n -le 0) { break }
            $got += $n
        }
    } finally { $fs.Close() }
    if ($got -le $skip) {
        Write-Log 'Nenhum dado lido na janela solicitada.' 'Red'
        return $null
    }
    return @{ Buffer = $buf; Skip = $skip; Base = $Start; Length = ([long]$got - $skip) }
}

$crcMask = [int64]4294967295
$crcTable = New-Object int64[] 256
for ($t = 0; $t -lt 256; $t++) {
    $c = [int64]$t
    for ($j = 0; $j -lt 8; $j++) {
        if (($c -band 1) -ne 0) { $c = ([int64]3988292384 -bxor ($c -shr 1)) -band $crcMask } else { $c = $c -shr 1 }
    }
    $crcTable[$t] = $c
}

function Get-Crc32 {
    param([byte[]]$Data)
    $c = $crcMask
    foreach ($b in $Data) {
        $ix = [int](($c -bxor [int64]$b) -band 0xFF)
        $c = ($crcTable[$ix] -bxor ($c -shr 8)) -band $crcMask
    }
    return ($c -bxor $crcMask) -band $crcMask
}

$ranges = New-Object System.Collections.ArrayList
$index = New-Object System.Collections.ArrayList
$unrecovered = New-Object System.Collections.ArrayList

function Test-InRange {
    param([long]$Position)
    foreach ($r in $ranges) {
        if ($Position -ge $r.Start -and $Position -lt $r.End) { return $true }
    }
    return $false
}

function Add-Result {
    param([string]$Sub, [string]$Name, [long]$Offset, [string]$Ext, [string]$Method, [long]$Size, [hashtable]$Meta)
    [void]$index.Add([pscustomobject]@{
        Arquivo  = "$Sub\$Name"
        OffsetHex = ('0x{0:X}' -f $Offset)
        Autor    = $Meta.Creator
        Titulo   = $Meta.Title
        Criado   = $Meta.Created
        Tipo     = $Ext
        Tamanho  = $Size
        Metodo   = $Method
        Valido   = 'SIM'
    })
    [void]$ranges.Add([pscustomobject]@{ Start = $Offset; End = ($Offset + $Size) })
}

function Save-Bytes {
    param([string]$Sub, [string]$Name, [byte[]]$Data)
    if ($DryRun) { return "$Sub\$Name (simulação)" }
    $dir = Join-Path $OutputPath $Sub
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $path = Join-Path $dir $Name
    [System.IO.File]::WriteAllBytes($path, $Data)
    return "$Sub\$Name"
}

Clear-Host
Write-Host '🔥 RECUPERAR PENDRIVE v1.0 - SHazam 💾' -ForegroundColor Magenta
Write-Log '🚀 recuperar-pendrive v1.0 iniciado'

$letter = Select-RemovableDrive $DriveLetter
if (-not $letter) { return }

$fullOut = [System.IO.Path]::GetFullPath($OutputPath)
$outRoot = [System.IO.Path]::GetPathRoot($fullOut).TrimEnd('\')
if ($outRoot -ieq ($letter + ':')) {
    Write-Log 'A pasta de saída não pode estar no próprio pendrive.' 'Red'
    return
}

$startByte = [long]($StartGB * 1GB)
$lengthByte = if ($EndGB -gt $StartGB) { [long](($EndGB - $StartGB) * 1GB) } else { [long]($MaxMB * 1MB) }
if ($lengthByte -le 0) { $lengthByte = [long]($MaxMB * 1MB) }

Write-Log ("Lendo {0}: de 0x{1:X}, {2:N0} bytes" -f $letter, $startByte, $lengthByte) -Color Cyan
$window = Read-RawWindow $letter $startByte $lengthByte
if (-not $window) { return }

$buf = $window.Buffer
$skip = [int]$window.Skip
$winBase = [long]$window.Base
$windowLength = [long]$window.Length
$enc = [System.Text.Encoding]::GetEncoding(28591)
$text = $enc.GetString($buf, $skip, [int]$windowLength)

function Get-StrAt {
    param([long]$Rel, [int]$Len)
    if ($Rel -lt 0 -or $Rel + $Len -gt $windowLength) { return '' }
    return $enc.GetString($buf, [int]($skip + $Rel), $Len)
}

$sigLocal = 'PK' + [char]3 + [char]4
$sigCdh = 'PK' + [char]1 + [char]2
$sigEocd = 'PK' + [char]5 + [char]6
$eocds = Find-All $text $sigEocd
$seq = 0

Write-Log "EOCD encontrados: $($eocds.Count)" -Color Cyan

foreach ($e in $eocds) {
    if ($e + 22 -gt $windowLength) { continue }
    $rel = [long]$e
    $abs = $winBase + $rel
    if (Test-InRange $abs) { continue }

    $cdSize = [BitConverter]::ToUInt32($buf, [int]($skip + $rel + 12))
    $cdOff = [BitConverter]::ToUInt32($buf, [int]($skip + $rel + 16))
    $clen = [BitConverter]::ToUInt16($buf, [int]($skip + $rel + 20))
    $total = [BitConverter]::ToUInt16($buf, [int]($skip + $rel + 10))
    if ($cdSize -le 0 -or $cdSize -gt 100MB -or $total -lt 1 -or $total -gt 100000 -or $clen -gt 65535) { continue }

    $cdRel = $rel - [long]$cdSize
    $startRel = $cdRel - [long]$cdOff
    if ($cdRel -lt 0 -or $startRel -lt 0 -or $startRel -ge $windowLength -or $cdRel -ge $windowLength) { continue }

    $startAbs = $winBase + $startRel
    if (Test-InRange $startAbs) { continue }
    $startSig = Get-StrAt $startRel 4
    $cdSig = Get-StrAt $cdRel 4
    if (-not ($startSig -eq $sigLocal -or $startSig -eq $sigCdh) -or $cdSig -ne $sigCdh) { continue }

    $endRel = $rel + 22 + [long]$clen
    if ($endRel -le $startRel -or $endRel -gt $windowLength) { continue }
    $size = $endRel - $startRel
    if ($size -gt 200MB) { continue }

    $slice = New-Object byte[] ([int]$size)
    [Array]::Copy($buf, [int]($skip + $startRel), $slice, 0, [int]$size)

    $tmp = Join-Path $env:TEMP ('cf_rec_' + [guid]::NewGuid().ToString('N') + '.zip')
    $meta = @{ Creator = ''; Title = ''; Created = '' }
    $valid = $false
    $ext = 'zip'
    $ec = 0
    try {
        if (-not $DryRun) { [System.IO.File]::WriteAllBytes($tmp, $slice) }
        $firstLen = [BitConverter]::ToUInt16($buf, [int]($skip + $cdRel + 28))
        $firstName = if ($firstLen -gt 0 -and $firstLen -lt 500) { Get-StrAt ($cdRel + 46) ([int]$firstLen) } else { '' }
        if ($firstName -match '^xl/') { $ext = 'xlsx' }
        elseif ($firstName -match '^word/') { $ext = 'docx' }
        elseif ($firstName -match '^ppt/') { $ext = 'pptx' }
        if (-not $DryRun) {
            $meta = Get-OfficeMeta $tmp
            $za = [System.IO.Compression.ZipFile]::OpenRead($tmp)
            $ec = $za.Entries.Count
            $za.Dispose()
        }
        $valid = ($ec -gt 0) -or $DryRun
    } catch { $valid = $false }
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }

    if (-not $valid) { [void]$unrecovered.Add("EOCD inválido em 0x{0:X}" -f $abs); continue }

    $seq++
    $name = New-OutputName $ext $startAbs $seq $meta
    $saved = Save-Bytes $ext $name $slice
    Add-Result $ext $name $startAbs $ext 'EOCD' $size $meta
    Write-Log ("OK ZIP {0} 0x{1:X} {2} ({3} entradas) -> {4}" -f $seq, $startAbs, $ext, $ec, $saved) -Color Green
}

$candidates = New-Object System.Collections.ArrayList
$sigs = [ordered]@{
    pdf = '%PDF-'
    mp4 = [char]0 + [char]0 + [char]0 + [char]24 + 'ftyp'
    png = [char]0x89 + 'PNG' + [char]13 + [char]10 + [char]26 + [char]10
    jpg = [char]255 + [char]216 + [char]255
}
foreach ($kind in $sigs.Keys) {
    foreach ($i in (Find-All $text $sigs[$kind])) {
        $abs = $winBase + [long]$i
        if (($abs % $Alignment) -ne 0) { continue }
        if (Test-InRange $abs) { continue }
        [void]$candidates.Add([pscustomobject]@{ Rel = [long]$i; Abs = $abs; Kind = $kind })
    }
}
$candidates = @($candidates | Sort-Object Abs)
$starts = @($candidates | ForEach-Object { $_.Abs }) + @($ranges | ForEach-Object { $_.Start })
$starts = @($starts | Sort-Object -Unique)

foreach ($cand in $candidates) {
    $relStart = $cand.Rel
    $abs = $cand.Abs
    $kind = $cand.Kind
    $relLimit = $windowLength
    foreach ($s0 in $starts) {
        if ($s0 -gt $abs -and $s0 -lt ($winBase + $relLimit)) { $relLimit = $s0 - $winBase }
    }
    if ($relLimit -le $relStart + 16) {
        [void]$unrecovered.Add(("Arquivo {0} em 0x{1:X} sem limite válido" -f $kind, $abs))
        continue
    }

    $size = 0
    $valid = $false
    if ($kind -eq 'pdf') {
        $searchStart = [int]($relLimit - 1)
        $searchCount = [int]($relLimit - $relStart)
        $endMark = if ($searchCount -ge 5) { $text.LastIndexOf('%%EOF', $searchStart, $searchCount, [System.StringComparison]::Ordinal) } else { -1 }
        if ($endMark -gt $relStart) {
            $e = $endMark + 5
            while ($e -lt $relLimit -and ($buf[$skip + $e] -eq 13 -or $buf[$skip + $e] -eq 10)) { $e++ }
            $size = $e - $relStart
            $valid = $size -gt 100
        }
        if (-not $valid) { [void]$unrecovered.Add("PDF truncado em 0x{0:X}" -f $abs) }
    } elseif ($kind -eq 'mp4') {
        $pos = $relStart
        $boxes = 0
        while ($pos + 8 -le $relLimit -and $boxes -lt 1000) {
            $sz = ([long]$buf[$skip + $pos] -shl 24) -bor ([long]$buf[$skip + $pos + 1] -shl 16) -bor ([long]$buf[$skip + $pos + 2] -shl 8) -bor [long]$buf[$skip + $pos + 3]
            if ($sz -eq 1) {
                if ($pos + 16 -gt $relLimit) { break }
                $sz = 0
                for ($q = 0; $q -lt 8; $q++) { $sz = ($sz -shl 8) -bor [long]$buf[$skip + $pos + 8 + $q] }
            } elseif ($sz -eq 0) { $sz = $relLimit - $pos }
            if ($sz -lt 8 -or $pos + $sz -gt $relLimit) { break }
            $boxes++
            $pos += $sz
        }
        if ($boxes -ge 2 -and $pos -gt $relStart + 100) { $size = $pos - $relStart; $valid = $true }
        if (-not $valid) { [void]$unrecovered.Add("MP4 incompleto em 0x{0:X}" -f $abs) }
    } elseif ($kind -eq 'png') {
        $pos = $relStart + 8
        $chunks = 0
        while ($pos + 12 -le $relLimit -and $chunks -lt 100000) {
            $len = ([long]$buf[$skip + $pos] -shl 24) -bor ([long]$buf[$skip + $pos + 1] -shl 16) -bor ([long]$buf[$skip + $pos + 2] -shl 8) -bor [long]$buf[$skip + $pos + 3]
            $ty = Get-StrAt ($pos + 4) 4
            if ($len -lt 0 -or $pos + 12 + $len -gt $relLimit) { break }
            $pos += 12 + $len
            $chunks++
            if ($ty -eq 'IEND') { $valid = $true; break }
        }
        if ($valid) { $size = $pos - $relStart }
        if (-not $valid) { [void]$unrecovered.Add("PNG sem IEND em 0x{0:X}" -f $abs) }
    } elseif ($kind -eq 'jpg') {
        $count = [int]($relLimit - $relStart - 2)
        if ($count -gt 0) {
            $eoi = [System.Array]::IndexOf($buf, [byte]0xD9, [int]($skip + $relStart + 2), $count)
            while ($eoi -gt $skip + $relStart + 2 -and $buf[$eoi - 1] -ne 0xFF) {
                $nextCount = [int]($skip + $windowLength - $eoi - 1)
                if ($nextCount -le 0) { $eoi = -1; break }
                $eoi = [System.Array]::IndexOf($buf, [byte]0xD9, [int]($eoi + 1), $nextCount)
            }
            if ($eoi -gt $skip + $relStart + 100) { $size = $eoi + 1 - ($skip + $relStart); $valid = $true }
        }
        if (-not $valid) { [void]$unrecovered.Add("JPEG sem FFD9 em 0x{0:X}" -f $abs) }
    }

    if ($valid -and $size -gt 0 -and $size -lt 200MB) {
        $slice = New-Object byte[] ([int]$size)
        [Array]::Copy($buf, [int]($skip + $relStart), $slice, 0, [int]$size)
        $seq++
        $ext = if ($kind -eq 'jpg') { 'jpg' } else { $kind }
        $name = ('{0:D4}_{1:X}.{2}' -f $seq, $abs, $ext)
        $saved = Save-Bytes $ext $name $slice
        Add-Result $ext $name $abs $ext 'CARVE' $size @{ Creator = ''; Title = ''; Created = '' }
        Write-Log "OK $($ext.ToUpper()) $seq 0x{0:X} -> $saved" -Color Green
    }
}

$rebuilt = 0
if (-not $SkipOrphanRebuild) {
    $lfh = @{}
    foreach ($i in (Find-All $text $sigLocal)) {
        if ($i + 30 -gt $windowLength) { continue }
        $nl = [BitConverter]::ToUInt16($buf, [int]($skip + $i + 26))
        $xl = [BitConverter]::ToUInt16($buf, [int]($skip + $i + 28))
        if ($nl -le 0 -or $nl -ge 300 -or $i + 30 + $nl + $xl -gt $windowLength) { continue }
        $nm = $enc.GetString($buf, [int]($skip + $i + 30), [int]$nl)
        if (-not $lfh.ContainsKey($nm)) { $lfh[$nm] = New-Object System.Collections.ArrayList }
        [void]$lfh[$nm].Add([pscustomobject]@{ Offset = $winBase + [long]$i; Nlen = $nl; Xlen = $xl })
    }

    function Inflate-Entry {
        param([long]$DataAbs, [int]$Csize, [int]$Method, [long]$Expected, [int64]$ExpectedCrc)
        $dataRel = $DataAbs - $winBase
        if ($Csize -le 0 -or $dataRel -lt 0 -or $dataRel + $Csize -gt $windowLength) { return $null }
        try {
            $ms = New-Object System.IO.MemoryStream($buf, [int]($skip + $dataRel), $Csize, $false)
            if ($Method -eq 8) { $ds = New-Object System.IO.Compression.DeflateStream($ms, [System.IO.Compression.CompressionMode]::Decompress) } else { $ds = $ms }
            $out = New-Object System.IO.MemoryStream
            $chunk = New-Object byte[] 65536
            while (($k = $ds.Read($chunk, 0, $chunk.Length)) -gt 0) { $out.Write($chunk, 0, $k) }
            if ($ds -ne $ms) { $ds.Dispose() }
            $ms.Dispose()
            if ($out.Length -ne $Expected) { $out.Dispose(); return $null }
            $bytes = $out.ToArray()
            $out.Dispose()
            if ((Get-Crc32 $bytes) -ne $ExpectedCrc) { return $null }
            return ,$bytes
        } catch { return $null }
    }

    foreach ($e in $eocds) {
        $rel = [long]$e
        $abs = $winBase + $rel
        if (Test-InRange $abs) { continue }
        $cdSize = [BitConverter]::ToUInt32($buf, [int]($skip + $rel + 12))
        $cdOff = [BitConverter]::ToUInt32($buf, [int]($skip + $rel + 16))
        $total = [BitConverter]::ToUInt16($buf, [int]($skip + $rel + 10))
        $cdRel = $rel - [long]$cdSize
        if ($cdSize -le 0 -or $cdSize -gt 100MB -or $total -lt 1 -or $total -gt 2000 -or $cdRel -lt 0 -or $cdRel -ge $windowLength) { continue }
        if ((Get-StrAt $cdRel 4) -ne $sigCdh) { continue }

        $entries = New-Object System.Collections.ArrayList
        $pos = $cdRel
        $ok = $true
        $missing = ''
        for ($k = 0; $k -lt $total; $k++) {
            if ($pos + 46 -gt $windowLength -or (Get-StrAt $pos 4) -ne $sigCdh) { $ok = $false; $missing = "CDH inválido $k"; break }
            $nl = [BitConverter]::ToUInt16($buf, [int]($skip + $pos + 28))
            $xl = [BitConverter]::ToUInt16($buf, [int]($skip + $pos + 30))
            $cl = [BitConverter]::ToUInt16($buf, [int]($skip + $pos + 32))
            $method = [BitConverter]::ToUInt16($buf, [int]($skip + $pos + 10))
            $crc = [BitConverter]::ToUInt32($buf, [int]($skip + $pos + 16))
            $cs = [BitConverter]::ToUInt32($buf, [int]($skip + $pos + 20))
            $us = [BitConverter]::ToUInt32($buf, [int]($skip + $pos + 24))
            if ($pos + 46 + $nl + $xl + $cl -gt $windowLength) { $ok = $false; $missing = "entrada $k fora da janela"; break }
            $nm = $enc.GetString($buf, [int]($skip + $pos + 46), [int]$nl)
            $data = $null
            if ($lfh.ContainsKey($nm)) {
                foreach ($cand in $lfh[$nm]) {
                    $data = Inflate-Entry ($cand.Offset + 30 + $cand.Nlen + $cand.Xlen) ([int]$cs) ([int]$method) ([long]$us) ([int64]$crc)
                    if ($null -ne $data) { break }
                }
            }
            if ($null -eq $data) { $ok = $false; $missing = $nm; break }
            [void]$entries.Add([pscustomobject]@{ Name = $nm; Data = $data })
            $pos += 46 + $nl + $xl + $cl
        }
        if (-not $ok) {
            [void]$unrecovered.Add(("Órfão 0x{0:X} incompleto (faltou: {1})" -f $abs, $missing))
            continue
        }

        $names = @($entries | ForEach-Object { $_.Name })
        $ext = 'zip'
        if ($names -contains 'xl/workbook.xml') { $ext = 'xlsx' }
        elseif ($names -contains 'word/document.xml') { $ext = 'docx' }
        elseif ($names -contains 'ppt/presentation.xml') { $ext = 'pptx' }

        $seq++
        $meta = @{ Creator = ''; Title = ''; Created = '' }
        $tmp = Join-Path $env:TEMP ('cf_rebuild_' + [guid]::NewGuid().ToString('N') + '.' + $ext)
        if (-not $DryRun) {
            $outFs = [System.IO.File]::Open($tmp, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
            $za = New-Object System.IO.Compression.ZipArchive($outFs, [System.IO.Compression.ZipArchiveMode]::Create)
            foreach ($en in $entries) {
                $ze = $za.CreateEntry($en.Name, [System.IO.Compression.CompressionLevel]::Optimal)
                $ws = $ze.Open()
                $ws.Write($en.Data, 0, $en.Data.Length)
                $ws.Close()
            }
            $za.Dispose()
            $outFs.Close()
            $meta = Get-OfficeMeta $tmp
        }
        $bytes = if ($DryRun) { [byte[]]@() } else { [System.IO.File]::ReadAllBytes($tmp) }
        $name = New-OutputName $ext $abs $seq $meta
        $saved = Save-Bytes 'reconstruidos' $name $bytes
        if (-not $DryRun) {
            $startAbs = $abs
            [void]$index.Add([pscustomobject]@{
                Arquivo = "reconstruidos\$name"
                OffsetHex = ('0x{0:X}' -f $startAbs)
                Autor = $meta.Creator
                Titulo = $meta.Title
                Criado = $meta.Created
                Tipo = $ext
                Tamanho = $bytes.Length
                Metodo = 'REBUILD'
                Valido = 'SIM'
            })
        }
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        $rebuilt++
        Write-Log "OK REBUILD $rebuilt 0x{0:X} $ext -> $saved" -Color Green
    }
}

$verified = 0
$badFiles = New-Object System.Collections.ArrayList
if (-not $DryRun) {
    foreach ($row in $index) {
        if ($row.Tipo -notin 'docx','xlsx','pptx','zip') { continue }
        $path = Join-Path $OutputPath $row.Arquivo
        try {
            $za = [System.IO.Compression.ZipFile]::OpenRead($path)
            foreach ($en in $za.Entries) {
                $s = $en.Open()
                $ms = New-Object System.IO.MemoryStream
                $s.CopyTo($ms)
                $s.Dispose()
                $ms.Dispose()
            }
            $za.Dispose()
            $verified++
        } catch {
            [void]$badFiles.Add("$($row.Arquivo): $($_.Exception.Message)")
            $row.Valido = 'NAO'
        }
    }
}

$counts = $index | Group-Object Tipo | ForEach-Object { "$($_.Name)=$($_.Count)" }
$summary = @(
    '=== RELATÓRIO DE RECUPERAÇÃO ==='
    "Data: $(Get-Date -f 'yyyy-MM-dd HH:mm:ss')"
    ('Unidade: ' + $letter + ':')
    ("Janela: 0x{0:X} + {1:N0} bytes" -f $winBase, $windowLength)
    "Saída: $fullOut"
    "Arquivos recuperados: $($index.Count)"
    "Tipos: $(($counts) -join ' ')"
    "ZIPs reconstruídos: $rebuilt"
    "Verificação ZIP: OK=$verified BAD=$($badFiles.Count)"
    'Não recuperados:'
)
$summary += $unrecovered.ToArray()
if ($badFiles.Count -gt 0) { $summary += 'Falhas na verificação:'; $summary += $badFiles.ToArray() }

if (-not $DryRun) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    $index.ToArray() | Export-Csv -LiteralPath (Join-Path $OutputPath 'indice.csv') -NoTypeInformation -Encoding UTF8
    $summary | Out-File -LiteralPath (Join-Path $OutputPath 'relatorio.txt') -Encoding UTF8
}

foreach ($line in $summary) { Write-Host $line -ForegroundColor $(if ($line -like 'BAD=*') { 'Red' } else { 'Gray' }) }
Write-Log "🏁 Concluído: $($index.Count) arquivos, $($badFiles.Count) falhas" -Color Green

if ($MyInvocation.InvocationName -eq 'irm' -or $MyInvocation.Line -match 'iex') { return }
Write-Host "`n🔥 ENTER para sair..." -ForegroundColor Magenta
Read-Host | Out-Null
