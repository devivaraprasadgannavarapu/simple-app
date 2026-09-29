$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$key = Join-Path $root 'sample-app-kubeadm.pem'
$config = Join-Path $root 'kubeconfig-sample-app.yaml'
$defaultDirectory = Join-Path $HOME '.kube'
$defaultConfig = Join-Path $defaultDirectory 'config'
$controlPlane = '100.56.251.56'

if (-not (Test-Path $key)) {
  throw "SSH key not found: $key"
}
if (-not (Test-Path $config)) {
  throw "Kubeconfig not found: $config"
}

New-Item -ItemType Directory -Path $defaultDirectory -Force | Out-Null
if ((Test-Path $defaultConfig) -and ((Get-FileHash $defaultConfig).Hash -ne (Get-FileHash $config).Hash)) {
  $backup = "$defaultConfig.eks-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  Copy-Item $defaultConfig $backup
  Write-Host "Previous kubeconfig backed up to $backup"
}
Copy-Item $config $defaultConfig -Force

$existing = Get-NetTCPConnection -LocalPort 6443 -State Listen -ErrorAction SilentlyContinue
if (-not $existing) {
  Start-Process -FilePath 'ssh.exe' -WindowStyle Hidden -ArgumentList @(
    '-i', $key,
    '-o', 'StrictHostKeyChecking=no',
    '-o', 'ExitOnForwardFailure=yes',
    '-N',
    '-L', '6443:10.0.101.241:6443',
    "ubuntu@$controlPlane"
  ) | Out-Null
  Start-Sleep -Seconds 2
}

$env:KUBECONFIG = $config
kubectl get nodes
Write-Host "KUBECONFIG=$config"
Write-Host 'Default kubectl config now points to this cluster.'
Write-Host 'The SSH tunnel is active on 127.0.0.1:6443.'
