param(
  [Parameter(Mandatory=$true)]
  [string]$GitHubToken,
  [string]$FirebaseToken,
  [string]$Repo = 'Diey-Fajri/key-record',
  [string]$ApkPath = 'build/app/outputs/flutter-apk/app-release.apk',
  [string]$Project = 'keyrecordpbscb',
  [string]$ReleaseTag,
  [string]$ReleaseName,
  [string]$ReleaseBody
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
  if (-not (Test-Path $ApkPath)) {
    throw "APK not found: $ApkPath"
  }

  $version = (Get-Content pubspec.yaml | Select-String '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)' | ForEach-Object { $_.Matches[0].Groups[1].Value } | Select-Object -First 1)
  if (-not $version) { $version = '1.0.0' }
  if (-not $ReleaseTag) { $ReleaseTag = "v$version" }
  if (-not $ReleaseName) { $ReleaseName = $ReleaseTag }
  if (-not $ReleaseBody) { $ReleaseBody = "Release $ReleaseTag" }

  $headers = @{ Accept = 'application/vnd.github+json'; Authorization = "Bearer $GitHubToken" }
  $releasePayload = @{ tag_name = $ReleaseTag; name = $ReleaseName; body = $ReleaseBody; draft = $false; prerelease = $false } | ConvertTo-Json -Depth 5

  Write-Host "Creating or updating GitHub release $ReleaseTag for $Repo"
  try {
    $existing = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$Repo/releases/tags/$ReleaseTag" -Headers $headers
    $releaseId = $existing.id
    $releaseResponse = Invoke-RestMethod -Method Patch -Uri "https://api.github.com/repos/$Repo/releases/$releaseId" -Headers $headers -ContentType 'application/json' -Body $releasePayload
  }
  catch {
    if ($_.Exception.Response.StatusCode -ne 404) {
      throw
    }
    $releaseResponse = Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$Repo/releases" -Headers $headers -ContentType 'application/json' -Body $releasePayload
  }

  $releaseId = $releaseResponse.id
  $assetName = 'app-release.apk'

  $existingAssets = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$Repo/releases/$releaseId/assets" -Headers $headers
  foreach ($asset in $existingAssets) {
    if ($asset.name -eq $assetName) {
      try {
        Invoke-RestMethod -Method Delete -Uri $asset.url -Headers $headers
      }
      catch {
        Write-Warning "Failed to delete existing asset: $($_.Exception.Message)"
      }
    }
  }

  $assetUri = "https://uploads.github.com/repos/$Repo/releases/$releaseId/assets?name=$assetName"
  $assetHeaders = @{ Accept = 'application/vnd.github+json'; Authorization = "Bearer $GitHubToken" }
  $assetResponse = Invoke-RestMethod -Method Post -Uri $assetUri -Headers $assetHeaders -ContentType 'application/vnd.android.package-archive' -InFile $ApkPath
  $downloadUrl = $assetResponse.browser_download_url

  if (-not $downloadUrl) {
    throw 'GitHub asset upload did not return a browser download URL.'
  }

  Write-Host "GitHub asset URL: $downloadUrl"

  if ($FirebaseToken) {
    $ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $firestorePayload = @{
      fields = @{
        latestVersion = @{ stringValue = $version }
        releaseNotes = @{ stringValue = $ReleaseBody }
        apkUrl = @{ stringValue = $downloadUrl }
        forceUpdate = @{ booleanValue = $false }
        minimumVersion = @{ stringValue = $version }
        updatedAt = @{ timestampValue = $ts }
      }
    } | ConvertTo-Json -Depth 8

    $firestoreHeaders = @{ Authorization = "Bearer $FirebaseToken" }
    Invoke-RestMethod -Method Patch -Uri "https://firestore.googleapis.com/v1/projects/$Project/databases/(default)/documents/app_updates/current" -Headers $firestoreHeaders -ContentType 'application/json' -Body $firestorePayload | Out-Null
    Write-Host 'Firestore app_updates/current updated successfully.'
  }
  else {
    Write-Host 'Firebase token not provided; skipping Firestore update.'
  }
}
finally {
  Pop-Location
}
