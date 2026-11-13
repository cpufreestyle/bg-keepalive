$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$prop = Get-Content (Join-Path $root 'module.prop') -Raw
if ($prop -notmatch 'version=(v[\d.]+)') { throw 'version not found in module.prop' }
$ver = $Matches[1]

$out = Join-Path $root 'out'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$zip = Join-Path $out ("bg_keepalive-{0}.zip" -f $ver)
if (Test-Path $zip) { Remove-Item $zip -Force }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::Open($zip, 'Create')
try {
    foreach ($item in @('module.prop', 'service.sh', 'customize.sh', 'META-INF')) {
        $path = Join-Path $root $item
        if (Test-Path $path -PathType Container) {
            Get-ChildItem $path -Recurse -File | ForEach-Object {
                $rel = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
                [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                    $archive, $_.FullName, $rel,
                    [IO.Compression.CompressionLevel]::Optimal) | Out-Null
            }
        } else {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive, $path, $item,
                [IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    }
}
finally { $archive.Dispose() }

Write-Output ("built: {0} ({1} bytes)" -f $zip, (Get-Item $zip).Length)
