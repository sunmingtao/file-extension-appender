param(
  [Parameter(Mandatory=$true)]
  [string]$Folder
)

if (-not (Test-Path -LiteralPath $Folder)) {
  Write-Error "Folder not found: $Folder"
  exit 1
}

$log = Join-Path $Folder "append-png.log"

Get-ChildItem -LiteralPath $Folder -File -Force |
  Where-Object { $_.Extension -eq "" } |
  ForEach-Object {
    $src = $_.FullName
    $target = Join-Path $Folder ($_.Name + ".png")
    $counter = 1
    while (Test-Path -LiteralPath $target) {
      $target = Join-Path $Folder ("{0} ({1}).png" -f $_.Name, $counter++)
    }
    try {
      Rename-Item -LiteralPath $src -NewName (Split-Path -Leaf $target) -ErrorAction Stop
      Add-Content $log "$(Get-Date -Format o) RENAMED `"$($_.Name)`" -> `"$([IO.Path]::GetFileName($target))`""
    } catch {
      Add-Content $log "$(Get-Date -Format o) FAILED `"$($_.Name)`": $($_.Exception.Message)"
    }
  }
