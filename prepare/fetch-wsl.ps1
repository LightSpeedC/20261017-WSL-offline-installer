# 最新の WSL（x64 の msi）を GitHub の microsoft/WSL から _bundle/wsl/ へ取得する
# 版数・取得元・SHA-256 を _bundle/manifest.json の wsl に書く（計画: p261017-01）
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$projectRoot = Split-Path -Parent $PSScriptRoot
$bundleDir = Join-Path $projectRoot '_bundle'
$wslDir = Join-Path $bundleDir 'wsl'
$manifestPath = Join-Path $bundleDir 'manifest.json'

function Get-JstNow {
	$jst = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::UtcNow, 'Tokyo Standard Time')
	return $jst.ToString('yyyy/MM/dd HH:mm:ss.fff')
}

function Get-RelativePath([string]$fullPath) {
	return $fullPath.Substring($projectRoot.Length + 1).Replace('\', '/')
}

Write-Host '最新の WSL リリースを問い合わせています...'
$release = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/WSL/releases/latest' -Headers @{ 'User-Agent' = 'wsl-offline-installer' }
$asset = @($release.assets | Where-Object { $_.name -match '\.x64\.msi$' })
if ($asset.Count -ne 1) {
	throw "x64 の msi が 1 つに決まりません（$($asset.Count) 件）: $($release.tag_name)"
}
$asset = $asset[0]
$version = $release.tag_name
Write-Host "最新の版: $version（$($asset.name)）"

New-Item -ItemType Directory -Force $wslDir | Out-Null
$msiPath = Join-Path $wslDir $asset.name

# GitHub が資産の digest（sha256:...）を返すときは、それと突き合わせる
$expectedHash = $null
if ($asset.PSObject.Properties.Name -contains 'digest' -and $asset.digest -match '^sha256:([0-9a-f]{64})$') {
	$expectedHash = $Matches[1].ToUpperInvariant()
}

$needDownload = $true
if (Test-Path -LiteralPath $msiPath) {
	$currentHash = (Get-FileHash -LiteralPath $msiPath -Algorithm SHA256).Hash
	if ($null -eq $expectedHash -or $currentHash -eq $expectedHash) {
		Write-Host "取得済みのため、ダウンロードを省きます: $(Get-RelativePath $msiPath)"
		$needDownload = $false
	}
}
if ($needDownload) {
	Write-Host "ダウンロードしています: $($asset.browser_download_url)"
	$partPath = "$msiPath.part"
	Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $partPath -UseBasicParsing
	Move-Item -LiteralPath $partPath -Destination $msiPath -Force
}

$hash = (Get-FileHash -LiteralPath $msiPath -Algorithm SHA256).Hash
if ($null -ne $expectedHash -and $hash -ne $expectedHash) {
	throw "SHA-256 が GitHub の値と一致しません: $(Get-RelativePath $msiPath)"
}
if ($null -eq $expectedHash) {
	Write-Host '注意: GitHub が digest を返さなかったため、突き合わせは省きました'
}

# 古い版の msi は配布物に入れないので消す（_bundle/ は取得物の置き場）
Get-ChildItem -LiteralPath $wslDir -Filter '*.msi' | Where-Object { $_.Name -ne $asset.name } | ForEach-Object {
	Write-Host "古い版を消します: $(Get-RelativePath $_.FullName)"
	Remove-Item -LiteralPath $_.FullName
}

$manifest = [ordered]@{}
if (Test-Path -LiteralPath $manifestPath) {
	$loaded = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
	foreach ($property in $loaded.PSObject.Properties) { $manifest[$property.Name] = $property.Value }
}
$manifest['wsl'] = [ordered]@{
	version    = $version
	file       = Get-RelativePath $msiPath
	url        = $asset.browser_download_url
	sha256     = $hash
	fetched_at = Get-JstNow
}
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding $false))

Write-Host "完了: WSL $version を $(Get-RelativePath $msiPath) に用意しました"
Write-Host "SHA-256: $hash"
