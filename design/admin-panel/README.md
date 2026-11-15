# Painel administrativo ClassVision

Este diretório contém 25 pranchetas SVG independentes para a operação acadêmica, a administração institucional e a administração global do ClassVision.

## Importação no Figma

1. Arraste os arquivos SVG individualmente para uma página do Figma.
2. Cada arquivo se torna uma prancheta completa: desktop em `1440 × 1024` e mobile em `390 × 844`.
3. Mantenha a fonte **Inter** instalada ou permita o fallback do Figma antes de editar tipografia.
4. O texto permanece em nós SVG `<text>`, portanto rótulos, métricas, nomes e tabelas podem ser editados após a importação.

## Convenções visuais

- Primária: `#2563EB`; fundo: `#F5F7FA`; superfície: `#FFFFFF`.
- Texto principal: `#1A1A2E`; texto secundário: `#6B7280`; bordas: `#E5E7EB`.
- Sucesso: `#22C55E`; atenção: `#F59E0B`; erro: `#C72933`.
- Desktop usa barra lateral; mobile usa a navegação inferior com Início, Turmas, Chamadas, Relatórios e Mais.

## Verificação

Execute abaixo antes de importar o pacote:

```powershell
powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1
```

O comando confirma o inventário, as dimensões, os textos editáveis e a ausência de imagens ou URLs externas.

## Papéis representados

- **Administrador do Sistema:** arquivos 16–24, com acesso administrativo global e sem dados acadêmicos.
- **Administrador da Instituição:** configurações, integrações e gestão de Coordenadores nos arquivos 09 e 25.
- **Coordenador:** operação acadêmica nas telas institucionais compartilhadas.
