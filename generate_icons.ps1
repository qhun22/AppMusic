Add-Type -AssemblyName System.Drawing
$srcPath = "var.jpg"
$src = [System.Drawing.Image]::FromFile((Resolve-Path $srcPath))
$outDir = "app\ios\Runner\Assets.xcassets\AppIcon.appiconset"

$sizes = @(
    @{ name = "Icon-App-20x20@2x.png"; w = 40; h = 40 },
    @{ name = "Icon-App-20x20@3x.png"; w = 60; h = 60 },
    @{ name = "Icon-App-29x29@1x.png"; w = 29; h = 29 },
    @{ name = "Icon-App-29x29@2x.png"; w = 58; h = 58 },
    @{ name = "Icon-App-29x29@3x.png"; w = 87; h = 87 },
    @{ name = "Icon-App-40x40@1x.png"; w = 40; h = 40 },
    @{ name = "Icon-App-40x40@2x.png"; w = 80; h = 80 },
    @{ name = "Icon-App-40x40@3x.png"; w = 120; h = 120 },
    @{ name = "Icon-App-60x60@2x.png"; w = 120; h = 120 },
    @{ name = "Icon-App-60x60@3x.png"; w = 180; h = 180 },
    @{ name = "Icon-App-76x76@1x.png"; w = 76; h = 76 },
    @{ name = "Icon-App-76x76@2x.png"; w = 152; h = 152 },
    @{ name = "Icon-App-83.5x83.5@2x.png"; w = 167; h = 167 },
    @{ name = "Icon-App-1024x1024@1x.png"; w = 1024; h = 1024 }
)

foreach ($item in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap $item.w, $item.h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($src, 0, 0, $item.w, $item.h)
    $destFile = Join-Path $outDir $item.name
    $bmp.Save($destFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}
$src.Dispose()
Write-Host "Generated all icons successfully!"
