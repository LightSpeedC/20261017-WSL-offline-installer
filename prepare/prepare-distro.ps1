# ビルド用の Ubuntu 24.04 を入れ、apt・nvm・Node.js・AI エージェントを入れる（計画: p261017-01）
# 初回はユーザ名とパスワードを Ubuntu の入力欄で入れるため、窓から対話で実行する
# -Recreate: ビルド用の Ubuntu を消して作り直す
param([switch]$Recreate)
$ErrorActionPreference = 'Stop'

$distroName = 'wsl-offline-build'
$sourceDistro = 'Ubuntu-24.04'
# wsl.exe の出力を UTF-16 ではなく UTF-8 で受け取る
$env:WSL_UTF8 = '1'

# subst のドライブは WSL から見えないため、実体のパスに直してから /mnt/<ドライブ>/ に変える
function ConvertTo-LinuxPath([string]$windowsPath) {
	$fullPath = [IO.Path]::GetFullPath($windowsPath).Replace('/', '\')
	foreach ($line in @(subst)) {
		if ($line -match '^([A-Z]):\\: => (.+)$' -and $fullPath.StartsWith("$($Matches[1]):\", [StringComparison]::OrdinalIgnoreCase)) {
			$fullPath = $Matches[2].TrimEnd('\') + $fullPath.Substring(2)
			break
		}
	}
	$drive = $fullPath.Substring(0, 1).ToLowerInvariant()
	return "/mnt/$drive" + $fullPath.Substring(2).Replace('\', '/')
}

function Test-DistroExists {
	$names = @(wsl --list --quiet) | ForEach-Object { $_.Trim() }
	return $names -contains $distroName
}

function Invoke-InDistro([string[]]$arguments) {
	& wsl -d $distroName @arguments | Out-Host
	if ($LASTEXITCODE -ne 0) { throw "WSL 内の処理が失敗しました（終了コード $LASTEXITCODE）: $($arguments -join ' ')" }
}

if ($Recreate -and (Test-DistroExists)) {
	Write-Host "ビルド用の $distroName を消して作り直します"
	wsl --unregister $distroName | Out-Host
}

if (-not (Test-DistroExists)) {
	Write-Host "$sourceDistro を $distroName という名前で入れます"
	Write-Host 'Ubuntu が起動したら、ユーザ名とパスワードを入力してください。入力が済んだら exit で抜けてください'
	wsl --install -d $sourceDistro --name $distroName | Out-Host
	if (-not (Test-DistroExists)) { throw "$distroName を入れられませんでした" }
}

$prepareDir = ConvertTo-LinuxPath $PSScriptRoot
Write-Host "WSL から見た prepare/: $prepareDir"

Invoke-InDistro @('-u', 'root', '--', 'bash', "$prepareDir/distro/setup-root.sh", $prepareDir)
# wsl.conf の変更を効かせるため、いったん止める
wsl --terminate $distroName | Out-Host
Invoke-InDistro @('--', 'bash', "$prepareDir/distro/setup-user.sh", $prepareDir)

Write-Host "完了: $distroName の準備ができました"
