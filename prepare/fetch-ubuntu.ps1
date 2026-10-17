# ビルド用 Ubuntu のイメージ（.wsl）を _bundle/source/ へ取得する
# 取得元と SHA-256 は、wsl --list --online と同じ Microsoft の配布元一覧から読む（計画: p261017-01）
# _bundle/source/ は prepare 側だけで使う材料。配布物の zip には入れない
param([string]$DistroName = 'Ubuntu-24.04')
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$projectRoot = Split-Path -Parent $PSScriptRoot
$bundleDir = Join-Path $projectRoot '_bundle'
$sourceDir = Join-Path $bundleDir 'source'
$manifestPath = Join-Path $bundleDir 'manifest.json'
$distributionInfoUrl = 'https://raw.githubusercontent.com/microsoft/WSL/master/distributions/DistributionInfo.json'

function Get-JstNow {
	$jst = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::UtcNow, 'Tokyo Standard Time')
	return $jst.ToString('yyyy/MM/dd HH:mm:ss.fff')
}

function Get-RelativePath([string]$fullPath) {
	return $fullPath.Substring($projectRoot.Length + 1).Replace('\', '/')
}

Write-Host "$DistroName の配布元を問い合わせています..."
$distributionInfo = Invoke-RestMethod -Uri $distributionInfoUrl
$entry = @($distributionInfo.ModernDistributions.PSObject.Properties | ForEach-Object { $_.Value } | Where-Object { $_.Name -eq $DistroName })
if ($entry.Count -ne 1) {
	throw "配布元一覧に $DistroName が 1 つに決まりません（$($entry.Count) 件）"
}
$url = $entry[0].Amd64Url.Url
$expectedHash = $entry[0].Amd64Url.Sha256.ToUpperInvariant()

New-Item -ItemType Directory -Force $sourceDir | Out-Null
$fileName = [IO.Path]::GetFileName(([Uri]$url).AbsolutePath)
$filePath = Join-Path $sourceDir $fileName

if ((Test-Path -LiteralPath $filePath) -and (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash -eq $expectedHash) {
	Write-Host "取得済みのため、ダウンロードを省きます: $(Get-RelativePath $filePath)"
} else {
	Write-Host "ダウンロードしています: $url"
	$partPath = "$filePath.part"
	Invoke-WebRequest -Uri $url -OutFile $partPath -UseBasicParsing
	Move-Item -LiteralPath $partPath -Destination $filePath -Force
}

$hash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash
if ($hash -ne $expectedHash) {
	throw "SHA-256 が配布元一覧の値と一致しません: $(Get-RelativePath $filePath)"
}

# 古い版のイメージは使わないので消す
Get-ChildItem -LiteralPath $sourceDir -Filter '*.wsl' | Where-Object { $_.Name -ne $fileName } | ForEach-Object {
	Write-Host "古い版を消します: $(Get-RelativePath $_.FullName)"
	Remove-Item -LiteralPath $_.FullName
}

$manifest = [ordered]@{}
if (Test-Path -LiteralPath $manifestPath) {
	$loaded = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
	foreach ($property in $loaded.PSObject.Properties) { $manifest[$property.Name] = $property.Value }
}
$manifest['ubuntu_source'] = [ordered]@{
	name       = $DistroName
	file       = Get-RelativePath $filePath
	url        = $url
	sha256     = $hash
	fetched_at = Get-JstNow
}
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding $false))

Write-Host "完了: $DistroName のイメージを $(Get-RelativePath $filePath) に用意しました"
