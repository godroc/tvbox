# 在仓库根目录执行：powershell -ExecutionPolicy Bypass -File custom/build-config.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$base = Get-Content (Join-Path $root 'jsm.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$own = @(Get-Content (Join-Path $PSScriptRoot 'sites.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
$excluded = @(Get-Content (Join-Path $PSScriptRoot 'exclude-sites.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
$seen = @{}
$sites = @()
foreach ($site in @($base.sites)) {
    if ($excluded -ccontains $site.key) { continue }
    $key = [string]$site.key
    if ($seen.ContainsKey($key)) {
        $n = 2
        while ($seen.ContainsKey("$key-upstream-$n")) { $n++ }
        $site.key = "$key-upstream-$n"
        Write-Warning "上游重复 key：$key -> $($site.key)"
    }
    $seen[[string]$site.key] = $true
    $sites += $site
}
$ownSeen = @{}
foreach ($site in $own) {
    if (-not $site.key -or -not $site.api -or $null -eq $site.type) { throw '自有站点缺少 key/api/type' }
    if ($ownSeen.ContainsKey([string]$site.key)) { throw "自有站点重复 key：$($site.key)" }
    $ownSeen[[string]$site.key] = $true
    $sites = @($sites | Where-Object { $_.key -cne $site.key })
    $sites += $site
}
$base.sites = $sites
$liveFile = Join-Path $PSScriptRoot 'lives.json'
if (Test-Path -LiteralPath $liveFile) {
    $ownLives = @(Get-Content -LiteralPath $liveFile -Raw -Encoding UTF8 | ConvertFrom-Json)
    $liveNames = @{}
    $mergedLives = @($base.lives)
    foreach ($live in $ownLives) {
        if (-not $live.name -or (-not $live.api -and -not $live.url)) { throw '自有直播缺少 name 或 api/url' }
        if ($liveNames.ContainsKey([string]$live.name)) { throw "自有直播重复 name：$($live.name)" }
        $liveNames[[string]$live.name] = $true
        $mergedLives = @($mergedLives | Where-Object { $_.name -cne $live.name })
        $mergedLives += $live
    }
    $base.lives = $mergedLives
}
# 所有 ./ 路径基于根目录 my-tv.json；逐项检查实际文件。
function Check-Paths($value) {
    if ($null -eq $value) { return }
    if ($value -is [string]) {
        if ($value.StartsWith('./')) {
            $relative = ($value -split ';')[0].Substring(2)
            $candidate = [IO.Path]::GetFullPath((Join-Path $root $relative))
            if (-not $candidate.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "路径越界：$value" }
            if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { throw "引用文件不存在：$value" }
        }
    } elseif ($value -is [System.Collections.IDictionary]) {
        foreach ($item in $value.Values) { Check-Paths $item }
    } elseif ($value -is [System.Collections.IEnumerable]) {
        foreach ($item in $value) { Check-Paths $item }
    } else {
        foreach ($property in $value.PSObject.Properties) { Check-Paths $property.Value }
    }
}
Check-Paths $base
$spiderParts = $base.spider -split ';'
if ($spiderParts.Length -eq 3 -and $spiderParts[1] -eq 'md5' -and $spiderParts[0].StartsWith('./')) {
    $actual = (Get-FileHash -LiteralPath (Join-Path $root $spiderParts[0]) -Algorithm MD5).Hash
    if ($actual -ine $spiderParts[2]) { throw 'spider.jar 与配置 MD5 不一致，请先同步完整上游文件' }
}
$json = $base | ConvertTo-Json -Depth 100
[IO.File]::WriteAllText((Join-Path $root 'my-tv.json'), $json + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))
Write-Output "已生成 my-tv.json：$($sites.Count) 个站点；所有相对引用存在。jsm.json 未修改。"

