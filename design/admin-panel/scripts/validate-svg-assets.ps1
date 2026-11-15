[CmdletBinding()]
param(
  [string]$Root
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Root)) {
  $Root = Split-Path -Parent $PSScriptRoot
}

$assets = @(
  @{ File = '01-dashboard-desktop.svg'; Width = 1440; Height = 1024; Required = @('Vis') },
  @{ File = '02-classes-desktop.svg'; Width = 1440; Height = 1024; Required = @('Turmas') },
  @{ File = '03-class-detail-desktop.svg'; Width = 1440; Height = 1024; Required = @('Detalhes da turma') },
  @{ File = '04-students-desktop.svg'; Width = 1440; Height = 1024; Required = @('Alunos') },
  @{ File = '05-teachers-desktop.svg'; Width = 1440; Height = 1024; Required = @('Professores') },
  @{ File = '06-attendance-center-desktop.svg'; Width = 1440; Height = 1024; Required = @('Chamadas') },
  @{ File = '07-attendance-review-desktop.svg'; Width = 1440; Height = 1024; Required = @('Revisar chamada', 'Confirmar chamada', 'Editar presen') },
  @{ File = '08-reports-desktop.svg'; Width = 1440; Height = 1024; Required = @('Relat', 'Exportar relat') },
  @{ File = '09-settings-desktop.svg'; Width = 1440; Height = 1024; Required = @('Configura', 'Coordenadores', 'Convidar coordenador', 'Administrador da institui') },
  @{ File = '10-dashboard-mobile.svg'; Width = 390; Height = 844; Required = @('Turmas', 'Chamadas', 'Mais') },
  @{ File = '11-classes-mobile.svg'; Width = 390; Height = 844; Required = @('Turmas', 'Chamadas', 'Mais') },
  @{ File = '12-attendance-mobile.svg'; Width = 390; Height = 844; Required = @('Turmas', 'Chamadas', 'Mais') },
  @{ File = '13-reports-mobile.svg'; Width = 390; Height = 844; Required = @('Turmas', 'Chamadas', 'Mais') },
  @{ File = '14-more-mobile.svg'; Width = 390; Height = 844; Required = @('Turmas', 'Chamadas', 'Mais') },
  @{ File = '15-notifications-mobile.svg'; Width = 390; Height = 844; Required = @('Notifica') },
  @{ File = '16-system-admin-login-desktop.svg'; Width = 1440; Height = 1024; Required = @('Administrador do Sistema', 'Acessar plataforma') },
  @{ File = '17-system-dashboard-desktop.svg'; Width = 1440; Height = 1024; Required = @('Vis', 'Institui', 'Atividade recente') },
  @{ File = '18-institutions-desktop.svg'; Width = 1440; Height = 1024; Required = @('Institui', 'Nova institui') },
  @{ File = '19-create-institution-desktop.svg'; Width = 1440; Height = 1024; Required = @('Cadastrar institui', 'Primeiro administrador', 'Enviar convite') },
  @{ File = '20-institution-detail-desktop.svg'; Width = 1440; Height = 1024; Required = @('Detalhes da institui', 'Coordenadores', 'Somente leitura') },
  @{ File = '21-institution-admins-desktop.svg'; Width = 1440; Height = 1024; Required = @('Administradores institucionais', 'Institui', 'ltimo acesso') },
  @{ File = '22-platform-activity-desktop.svg'; Width = 1440; Height = 1024; Required = @('Atividade da plataforma', 'Auditoria', 'Per') },
  @{ File = '23-platform-settings-desktop.svg'; Width = 1440; Height = 1024; Required = @('Configura', 'Pol', 'Status dos servi') },
  @{ File = '24-institution-created-desktop.svg'; Width = 1440; Height = 1024; Required = @('Institui', 'convite', 'Ver institui') },
  @{ File = '25-coordinators-mobile.svg'; Width = 390; Height = 844; Required = @('Coordenadores', 'Convidar coordenador', 'Administrador da institui') }
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
  if ($svg -match '<image\b|<use\b|(?:href|xlink:href)\s*=\s*["'']https?://') {
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
