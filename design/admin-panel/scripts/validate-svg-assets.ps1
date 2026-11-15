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
  @{ File = '09-settings-desktop.svg'; Width = 1440; Height = 1024; Required = @('Configura', 'Coordenadores', 'Convidar coordenador', 'Administrador da institui', 'Inativo', 'Ativar', 'Desativar') },
  @{ File = '10-dashboard-mobile.svg'; Width = 390; Height = 844; Required = @('Turmas', 'Chamadas', 'Mais') },
  @{ File = '11-classes-mobile.svg'; Width = 390; Height = 844; Required = @('Turmas', 'Chamadas', 'Mais') },
  @{ File = '12-attendance-mobile.svg'; Width = 390; Height = 844; Required = @('Turmas', 'Chamadas', 'Mais') },
  @{ File = '13-reports-mobile.svg'; Width = 390; Height = 844; Required = @('Turmas', 'Chamadas', 'Mais') },
  @{ File = '14-more-mobile.svg'; Width = 390; Height = 844; Required = @('Turmas', 'Chamadas', 'Mais') },
  @{ File = '15-notifications-mobile.svg'; Width = 390; Height = 844; Required = @('Notifica') },
  @{ File = '16-system-admin-login-desktop.svg'; Width = 1440; Height = 1024; Required = @('Administrador do Sistema', 'Acessar plataforma') },
  @{ File = '17-system-dashboard-desktop.svg'; Width = 1440; Height = 1024; Required = @('Vis', 'Atividade recente', 'Status dos servi') },
  @{ File = '18-institutions-desktop.svg'; Width = 1440; Height = 1024; Required = @('Nova institui', 'ADMINISTRADOR', 'USU') },
  @{ File = '19-create-institution-desktop.svg'; Width = 1440; Height = 1024; Required = @('Cadastrar institui', 'Primeiro administrador', 'Nome do administrador', 'E-mail do administrador', 'Telefone do administrador', 'Enviar convite') },
  @{ File = '20-institution-detail-desktop.svg'; Width = 1440; Height = 1024; Required = @('Detalhes da institui', 'Coordenadores', 'Somente leitura', 'Atividade institucional', 'Inativo', 'Pendente', 'Configura') },
  @{ File = '21-institution-admins-desktop.svg'; Width = 1440; Height = 1024; Required = @('Administradores institucionais', 'LTIMO ACESSO', 'Atividade', 'Configura') },
  @{ File = '22-platform-activity-desktop.svg'; Width = 1440; Height = 1024; Required = @('Atividade da plataforma', 'Auditoria', 'Todos os usu', 'Configura') },
  @{ File = '23-platform-settings-desktop.svg'; Width = 1440; Height = 1024; Required = @('Pol', 'Status dos servi', 'Notifica', 'Resumo semanal') },
  @{ File = '24-institution-created-desktop.svg'; Width = 1440; Height = 1024; Required = @('Institui', 'convite', 'Ver institui') },
  @{ File = '25-coordinators-mobile.svg'; Width = 390; Height = 844; Required = @('Coordenadores', 'Convidar coordenador', 'Administrador da institui', 'Inativo', 'Ativar', 'Desativar') }
)

$failures = [System.Collections.Generic.List[string]]::new()
$expectedFiles = @($assets | ForEach-Object { $_.File } | Sort-Object)
$actualFiles = @(Get-ChildItem -LiteralPath $Root -Filter '*.svg' -File | ForEach-Object { $_.Name } | Sort-Object)
$inventoryDiff = @(Compare-Object -ReferenceObject $expectedFiles -DifferenceObject $actualFiles)
if ($inventoryDiff.Count -gt 0) {
  $failures.Add('SVG inventory does not match the expected 25 artboards')
}

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
  if ($svg -match '<text\b(?![^>]*font-family="Inter)[^>]*>') {
    $failures.Add("Typography mismatch: $($asset.File) has a text node without Inter")
  }
  if ($svg -match '<image\b|<use\b|<script\b|<foreignObject\b|(?:href|xlink:href)\s*=|url\s*\(') {
    $failures.Add("External or reusable dependency found: $($asset.File)")
  }
  foreach ($copy in $asset.Required) {
    if ($svg -notmatch [regex]::Escape($copy)) {
      $failures.Add("Required copy missing from $($asset.File): $copy")
    }
  }
}

$coordinatorAssets = @('01-dashboard-desktop.svg', '02-classes-desktop.svg', '03-class-detail-desktop.svg', '04-students-desktop.svg', '05-teachers-desktop.svg', '06-attendance-center-desktop.svg', '07-attendance-review-desktop.svg', '08-reports-desktop.svg', '10-dashboard-mobile.svg', '11-classes-mobile.svg', '12-attendance-mobile.svg', '13-reports-mobile.svg', '14-more-mobile.svg', '15-notifications-mobile.svg')
foreach ($file in $coordinatorAssets) {
  $svg = Get-Content -LiteralPath (Join-Path $Root $file) -Raw -Encoding UTF8
  if ($svg -match 'Marina(?: Costa)?|Coordenadora|Configurações') {
    $failures.Add("Role boundary violated in $file")
  }
}

$globalAssets = @($assets | Where-Object { $_.File -match '^(1[6-9]|2[0-4])-' })
foreach ($asset in $globalAssets) {
  $svg = Get-Content -LiteralPath (Join-Path $Root $asset.File) -Raw -Encoding UTF8
  if ($svg -match 'Turmas|Alunos|Chamadas|Presença|Relatórios acadêmicos') {
    $failures.Add("Academic data leaked into global screen: $($asset.File)")
  }
}

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Host "FAIL: $_" }
  exit 1
}

Write-Host "PASS: validated $($assets.Count) editable standalone SVG artboards."
