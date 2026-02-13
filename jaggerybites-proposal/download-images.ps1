# Downloads images from jaggerybites.in homepage into ./assets
# Run in PowerShell (Windows):
#   .\download-images.ps1

$site = 'https://jaggerybites.in/'
$assets = Join-Path -Path $PSScriptRoot -ChildPath 'assets'
if (-not (Test-Path $assets)) { New-Item -ItemType Directory -Path $assets | Out-Null }

Write-Host "Fetching homepage: $site" -ForegroundColor Cyan
try {
    $res = Invoke-WebRequest -Uri $site -UseBasicParsing -ErrorAction Stop
    $html = $res.Content
} catch {
    Write-Error "Failed to fetch $site : $_"
    exit 1
}

# Extract image URLs using parsed Images collection (avoids fragile regex)
$imgs = @()
if ($res.Images) {
    foreach ($img in $res.Images) {
        if ($img.src) { $imgs += $img.src }
    }
}

# Normalize and make absolute
$uniq = @()
foreach ($u in ($imgs | Where-Object { $_ -and ($_ -notlike 'data:*') } | Select-Object -Unique)) {
    $url = $u
    if ($url -like '///*') { $url = 'https:' + $url }
    elseif ($url.StartsWith('//')) { $url = 'https:' + $url }
    elseif ($url.StartsWith('/')) { $url = (New-Object System.Uri($site, $url)).AbsoluteUri }
    elseif ($url -notmatch '^https?:') { $url = (New-Object System.Uri($site, $url)).AbsoluteUri }
    if ($uniq -notcontains $url) { $uniq += $url }
}

if ($uniq.Count -eq 0) {
    Write-Host "Parsed Images empty — falling back to regex scan of HTML" -ForegroundColor Yellow
    $pattern = '(?:https?:\/\/|\/\/|\/)[^\s<>]+\.(?:jpg|jpeg|png|webp|svg|gif|mp4)(\?[^\s<>]*)?'

    $regexMatches = [regex]::Matches($html, $pattern, 'IgnoreCase') | ForEach-Object { $_.Value } | Select-Object -Unique
    foreach ($m in $regexMatches) {
        $u = $m
        if ($u -like '///*') { $u = 'https:' + $u }
        elseif ($u.StartsWith('//')) { $u = 'https:' + $u }
        elseif ($u.StartsWith('/')) { $u = (New-Object System.Uri($site, $u)).AbsoluteUri }
        if ($uniq -notcontains $u) { $uniq += $u }
    }
}

if ($uniq.Count -eq 0) { Write-Host "No images found on the homepage."; exit 0 }

# We'll save first image as hero.jpg and next three as product1/2/3.jpg, and download others into assets/originals
$i=0
foreach ($u in $uniq) {
    $i++
    try {
        if ($i -eq 1) { $fname = 'hero' + [System.IO.Path]::GetExtension($u) -replace '\?.*$','' }
        elseif ($i -le 4) { $fname = 'product' + ($i-1) + [System.IO.Path]::GetExtension($u) -replace '\?.*$','' }
        else { $fname = 'original-' + ($i-4) + [System.IO.Path]::GetFileName($u.Split('?')[0]) }
        $out = Join-Path $assets $fname
        Write-Host "Downloading $u -> $out"
        Invoke-WebRequest -Uri $u -OutFile $out -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Warning "Failed to download $u : $_"
    }
}

Write-Host "Finished. Images in: $assets" -ForegroundColor Green
Write-Host "Rename or update index.html to point to specific image files if needed." -ForegroundColor Yellow
