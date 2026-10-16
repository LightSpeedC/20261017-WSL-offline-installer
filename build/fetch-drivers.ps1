# NVIDIA と Intel の Windows 用 GPU ドライバを bundle/drivers/ へ取得する
# 版数・取得元・SHA-256 を bundle/manifest.json の drivers に書く（計画: p261017-01）
# NVIDIA: ドライバ検索ページが使う API で最新版を探す（公開仕様ではない）
# Intel: サイトがブラウザ以外を 403 で拒むため、URL は build/intel-driver-url.txt に置く。
#        ダウンロード元（downloadmirror.intel.com）は直接取得できる
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$projectRoot = Split-Path -Parent $PSScriptRoot
$bundleDir = Join-Path $projectRoot 'bundle'
$driversDir = Join-Path $bundleDir 'drivers'
$manifestPath = Join-Path $bundleDir 'manifest.json'
$intelUrlPath = Join-Path $PSScriptRoot 'intel-driver-url.txt'

# GeForce RTX 30 Series (Notebooks) / GeForce RTX 3050 Ti Laptop GPU / Windows 11 / 英語 / DCH
$nvidiaLookupUrl = 'https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=123&pfid=962&osID=135&languageCode=1033&dch=1&upCRD=0&qnf=0&sort1=0&numberOfResults=1'

function Get-JstNow {
	$jst = [TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::UtcNow, 'Tokyo Standard Time')
	return $jst.ToString('yyyy/MM/dd HH:mm:ss.fff')
}

function Get-RelativePath([string]$fullPath) {
	return $fullPath.Substring($projectRoot.Length + 1).Replace('\', '/')
}

# 取得済みなら省き、署名者を確かめて、manifest に書く値を返す
function Save-Driver([string]$vendor, [string]$url, [string]$version, [string]$signerPattern) {
	$vendorDir = Join-Path $driversDir $vendor
	New-Item -ItemType Directory -Force $vendorDir | Out-Null
	$fileName = [IO.Path]::GetFileName(([Uri]$url).AbsolutePath)
	$filePath = Join-Path $vendorDir $fileName

	if (Test-Path -LiteralPath $filePath) {
		Write-Host "取得済みのため、ダウンロードを省きます: $(Get-RelativePath $filePath)"
	} else {
		Write-Host "ダウンロードしています: $url"
		$partPath = "$filePath.part"
		Invoke-WebRequest -Uri $url -OutFile $partPath -UseBasicParsing -UserAgent 'Mozilla/5.0'
		Move-Item -LiteralPath $partPath -Destination $filePath -Force
	}

	$signature = Get-AuthenticodeSignature -LiteralPath $filePath
	if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch $signerPattern) {
		throw "署名が有効でないか、署名者が違います: $(Get-RelativePath $filePath)（$($signature.Status)）"
	}

	# 古い版は配布物に入れないので消す
	Get-ChildItem -LiteralPath $vendorDir -File | Where-Object { $_.Name -ne $fileName } | ForEach-Object {
		Write-Host "古い版を消します: $(Get-RelativePath $_.FullName)"
		Remove-Item -LiteralPath $_.FullName
	}

	return [ordered]@{
		version    = $version
		file       = Get-RelativePath $filePath
		url        = $url
		sha256     = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash
		fetched_at = Get-JstNow
	}
}

Write-Host 'NVIDIA の最新ドライバを問い合わせています...'
$lookup = Invoke-RestMethod -Uri $nvidiaLookupUrl
$nvidiaInfo = $lookup.IDS[0].downloadInfo
if ($nvidiaInfo.IsWHQL -ne '1' -or $nvidiaInfo.IsBeta -ne '0') {
	throw "NVIDIA の最新版が WHQL 版ではありません: $($nvidiaInfo.Version)"
}
Write-Host "NVIDIA の最新版: $($nvidiaInfo.Version)（$($nvidiaInfo.ReleaseDateTime)）"
$nvidia = Save-Driver 'nvidia' $nvidiaInfo.DownloadURL $nvidiaInfo.Version 'O=NVIDIA Corporation'

$intelUrl = ([IO.File]::ReadAllText($intelUrlPath)).Trim()
if ($intelUrl -notmatch '^https://downloadmirror\.intel\.com/\d+/gfx_win_(101\.\d+)\.exe$') {
	throw "intel-driver-url.txt の URL が想定の形ではありません: $intelUrl"
}
$intelVersion = "32.0.$($Matches[1])"
Write-Host "Intel の版: $intelVersion"
$intel = Save-Driver 'intel' $intelUrl $intelVersion 'O=Intel Corporation'

$manifest = [ordered]@{}
if (Test-Path -LiteralPath $manifestPath) {
	$loaded = [IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
	foreach ($property in $loaded.PSObject.Properties) { $manifest[$property.Name] = $property.Value }
}
$manifest['drivers'] = [ordered]@{ nvidia = $nvidia; intel = $intel }
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding $false))

Write-Host "完了: NVIDIA $($nvidia.version) と Intel $($intel.version) を bundle/drivers/ に用意しました"
