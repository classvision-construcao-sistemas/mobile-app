[CmdletBinding()]
param(
  [string]$Root
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Root)) {
  $Root = Split-Path -Parent $PSScriptRoot
}

$assets = @(
  @{ File = '01-dashboard-desktop.svg'; Width = 1440; Height = 1024; Required = @('Visão geral') },
  @{ File = '02-classes-desktop.svg'; Width = 1440; Height = 1024; Required = @('Turmas') },
  @{ File = '03-class-detail-desktop.svg'; Width = 1440; Height = 1024; Required = @('Detalhes da turma') },
  @{ File = '04-students-desktop.svg'; Width = 1440; Height = 1024; Required = @('Alunos') },
  @{ File = '05-teachers-desktop.svg'; Width = 1440; Height = 1024; Required = @('Professores') },
  @{ File = '06-attendance-center-desktop.svg'; Width = 1440; Height = 1024; Required = @('Chamadas') },
  @{ File = '07-attendance-review-desktop.svg'; Width = 1440; Height = 1024; Required = @('Revisar chamada', 'Confirmar chamada', 'Editar presença') },
  @{ File = '08-reports-desktop.svg'; Width = 1440; Height = 1024; Required = @('Relatórios', 'Exportar relatório') },
  @{ File = '09-settings-desktop.svg'; Width = 1440; Height = 1024; Required = @('Configurações', 'Regras de presença', 'Integração de IA') },
  @{ File = '10-dashboard-mobile.svg'; Width = 390; Height = 844; Required = @('Início', 'Turmas', 'Chamadas', 'Relatórios', 'Mais') },
  @{ File = '11-classes-mobile.svg'; Width = 390; Height = 844; Required = @('Início', 'Turmas', 'Chamadas', 'Relatórios', 'Mais') },
  @{ File = '12-attendance-mobile.svg'; Width = 390; Height = 844; Required = @('Início', 'Turmas', 'Chamadas', 'Relatórios', 'Mais') },
  @{ File = '13-reports-mobile.svg'; Width = 390; Height = 844; Required = @('Início', 'Turmas', 'Chamadas', 'Relatórios', 'Mais') },
  @{ File = '14-more-mobile.svg'; Width = 390; Height = 844; Required = @('Início', 'Turmas', 'Chamadas', 'Relatórios', 'Mais') },
  @{ File = '15-notifications-mobile.svg'; Width = 390; Height = 844; Required = @('Notificações') }
)

$failures = [System.Collections.Generic.List[string]]::new()

foreach ($asset in $assets) {
  $path = Join-Path $Root $asset.File
  if (-not (Test-Path -LiteralPath $path)) {
    $failures.Add("Missing asset: $($asset.File)")
    continue
  }

  $svg = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  $rootPattern = '<svg\b[^>]*\bwidth="' + $asset.Width + '"[^>]*\bheight="' + $asset.Height + '"[^>]*\bviewBox="0 0 ' + $asset.Width + ' ' + $asset.Height + '"'
  if ($svg -notmatch $rootPattern) {
    $failures.Add("Invalid artboard: $($asset.File) must use $($asset.Width)x$($asset.Height) and matching viewBox")
  }
  if ($svg -notmatch '<text\b') {
    $failures.Add("Text is not editable: $($asset.File) has no <text> nodes")
  }
  if ($svg -match '<image\b|https?://|<use\b') {
    $failures.Add("External or reusable dependency found: $($asset.File)")
  }
  foreach ($copy in $asset.Required) {
    if ($svg -notmatch [regex]::Escape($copy)) {
      $failures.Add("Required copy missing from $($asset.File): $copy")
    }
  }
}

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Host "FAIL: $_" }
  exit 1
}

Write-Host "PASS: validated $($assets.Count) editable standalone SVG artboards."
