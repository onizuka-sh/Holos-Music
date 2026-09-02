param([string]$Source = (Join-Path $PSScriptRoot '..\app\assets\brand\holos_logo_source.png'))

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$appRoot = Join-Path $projectRoot 'app'
$resRoot = Join-Path $appRoot 'android\app\src\main\res'
$brandRoot = Join-Path $appRoot 'assets\brand'
New-Item -ItemType Directory -Force -Path $brandRoot | Out-Null
$sourceImage = [Drawing.Image]::FromFile((Resolve-Path -LiteralPath $Source))

function Write-Icon([string]$Path, [int]$Size, [double]$Scale = 1.0, [bool]$Transparent = $false) {
    New-Item -ItemType Directory -Force -Path (Split-Path $Path) | Out-Null
    $bitmap = [Drawing.Bitmap]::new($Size, $Size, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.Clear($(if ($Transparent) { [Drawing.Color]::Transparent } else { [Drawing.Color]::White }))
        $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $side = [int][Math]::Round($Size * $Scale)
        $offset = [int][Math]::Round(($Size - $side) / 2)
        $graphics.DrawImage($sourceImage, $offset, $offset, $side, $side)
        $bitmap.Save($Path, [Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

try {
    if ($sourceImage.Width -ne $sourceImage.Height) { throw 'Use a square source logo.' }
    $resolvedSource = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Source).Path)
    $masterPath = Join-Path $brandRoot 'holos_logo_source.png'
    if (-not [StringComparer]::OrdinalIgnoreCase.Equals($resolvedSource, $masterPath)) {
        Copy-Item -LiteralPath $resolvedSource -Destination $masterPath -Force
    }
    Write-Icon (Join-Path $brandRoot 'holos_logo.png') 512
    $densities = [ordered]@{ mdpi = 1.0; hdpi = 1.5; xhdpi = 2.0; xxhdpi = 3.0; xxxhdpi = 4.0 }
    foreach ($density in $densities.GetEnumerator()) {
        Write-Icon (Join-Path $resRoot "mipmap-$($density.Key)\ic_launcher.png") ([int](48 * $density.Value))
        # Preserve artwork and keep its visible badge inside adaptive masks.
        Write-Icon (Join-Path $resRoot "mipmap-$($density.Key)\ic_launcher_foreground.png") ([int](108 * $density.Value)) (82.0 / 108.0) $true
        Write-Icon (Join-Path $resRoot "drawable-$($density.Key)\holos_logo.png") ([int](128 * $density.Value))
    }
    Write-Output 'Generated launcher icons, adaptive foregrounds, splash images and Flutter logo asset.'
} finally {
    $sourceImage.Dispose()
}
