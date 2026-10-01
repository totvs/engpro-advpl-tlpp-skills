# [LEGADO] FWMsExcelEx — Referência de API

> **LEGADO — não use por padrão.** A `FWMsExcelEx` é a classe antiga (gera
> XML Spreadsheet 2003, `.xml`). A recomendação atual da TOTVS é a
> [`FwMsExcelXlsx`](https://tdn.totvs.com/display/public/framework/FWMsExcelXlsx),
> documentada em [fwmsexcelxlsx-api-reference.md](fwmsexcelxlsx-api-reference.md). Use este arquivo
> **somente** quando o usuário pedir explicitamente a `FWMsExcelEx` (ou a versão
> antiga), ou quando o ambiente comprovadamente não atender aos requisitos da
> `FwMsExcelXlsx` e o usuário aceitar a classe legada.

Referência dos métodos da classe `FWMsExcelEx` usados pela skill. A coluna
**Fonte** indica onde a assinatura foi confirmada:

- **TDN-Ex** — página oficial [FWMsExcelEx](https://tdn.totvs.com/display/framework/FWMsExcelEx)
- **DT** — documento técnico de correção da classe no TDN
- **Padrão** — uso real em fontes do produto (ex.: `FINDTEXCELREPORT`, `TECA997`, `RmiMonitor`, `TMSAE73`)
- **Família** — assinatura documentada nas classes irmãs `FWMsExcel`/`FwMsExcelXlsx`, com mesma API

Antes de usar um método marcado só como **Família**, confirme no ambiente.
Não invente métodos fora desta lista.

## Sumário

- [Ciclo de vida](#ciclo-de-vida)
- [Estrutura: abas, tabelas, colunas e linhas](#estrutura-abas-tabelas-colunas-e-linhas)
- [Estilo do título da tabela](#estilo-do-título-da-tabela)
- [Estilo do cabeçalho](#estilo-do-cabeçalho)
- [Estilo das linhas (zebrado)](#estilo-das-linhas-zebrado)
- [Estilo de célula](#estilo-de-célula)
- [Alinhamento, altura e encoding](#alinhamento-altura-e-encoding)
- [Comparativo entre classes](#comparativo-entre-classes)
- [Correções conhecidas (DTs)](#correções-conhecidas-dts)

## Ciclo de vida

| Método | Retorno | Descrição | Fonte |
| --- | --- | --- | --- |
| `FWMsExcelEx():New()` | objeto | Construtor | TDN-Ex, Padrão |
| `:Activate()` | lógico | Finaliza a montagem e habilita a geração. Chamar **depois** de todas as linhas | Padrão |
| `:GetXMLFile(cFile)` | lógico | Grava o arquivo. `cFile` pode ser caminho do servidor (relativo ao RootPath) ou da estação (SmartClient desktop) | Padrão, DT |
| `:DeActivate()` | lógico | Desabilita e limpa o objeto. Seguir com `FreeObj(oExcel)` | Família, Padrão |

## Estrutura: abas, tabelas, colunas e linhas

### AddWorkSheet

`:AddWorkSheet(cWorkSheet)` — adiciona uma aba. Fonte: TDN-Ex, Padrão.

- Excel limita o nome da aba a 31 caracteres e não aceita `: \ / ? * [ ]`.
  Sanitize nomes dinâmicos.

### IsWorkSheet

`:IsWorkSheet(cWorkSheet) → lRet` — indica se o nome de aba já foi usado. Fonte: Família.

### AddTable

`:AddTable(cWorkSheet, cTable [, lPrintHead])` — adiciona a tabela na aba (uma
tabela por aba). `cTable` é o título exibido acima do cabeçalho. Fonte:
TDN-Ex, Padrão (`FINDTEXCELREPORT` usa o 3º parâmetro `.F.`).

| Parâmetro | Tipo | Obrig. | Descrição |
| --- | --- | :-: | --- |
| `cWorkSheet` | C | X | Nome da aba |
| `cTable` | C | X | Título da tabela |
| `lPrintHead` | L | | Imprime o cabeçalho/título |

### AddColumn

`:AddColumn(cWorkSheet, cTable, cColumn [, nAlign] [, nFormat] [, lTotal] [, cPicture])`
Fonte: TDN-Ex, Padrão.

| Parâmetro | Tipo | Default | Descrição |
| --- | --- | --- | --- |
| `cWorkSheet` | C | — | Nome da aba |
| `cTable` | C | — | Nome da tabela |
| `cColumn` | C | — | Título da coluna |
| `nAlign` | N | 1 | 1 = Esquerda, 2 = Centro, 3 = Direita |
| `nFormat` | N | 1 | 1 = Geral, 2 = Número, 3 = Monetário, 4 = Data/Hora |
| `lTotal` | L | `.F.` | Totaliza a coluna (apenas numéricas) |
| `cPicture` | C | `""` | Máscara para numéricos (inclusive 3+ casas decimais — DFRM1-26097) |

### AddRow

`:AddRow(cWorkSheet, cTable, aRow [, aCelStyle])` — Fonte: Padrão (`RmiMonitor`), TDN-Ex.

| Parâmetro | Tipo | Descrição |
| --- | --- | --- |
| `aRow` | A | Valores da linha, na mesma ordem e quantidade das colunas |
| `aCelStyle` | A | Posições (1..N) das colunas que recebem o estilo definido por `SetCel*`. Omitido ou `{}` = sem destaque |

## Estilo do título da tabela

Fonte: DT 236598837 (FWMsExcelEx) e Padrão (`TECA997`).

| Método | Parâmetro |
| --- | --- |
| `:SetTitleFont(cFont)` | Nome da fonte |
| `:SetTitleSizeFont(nSize)` | Tamanho |
| `:SetTitleBold(lBold)` | Negrito |
| `:SetTitleFrColor(cColor)` | Cor da fonte, `"#RRGGBB"` |
| `:SetTitleBgColor(cColor)` | Cor de fundo, `"#RRGGBB"` |

## Estilo do cabeçalho

Fonte: DT 236598837 (FWMsExcelEx) e Padrão (`TECA997`). Note a ordem
diferente das palavras nos setters de cor.

| Método | Parâmetro |
| --- | --- |
| `:SetHeaderFont(cFont)` | Nome da fonte |
| `:SetHeaderSizeFont(nSize)` | Tamanho |
| `:SetHeaderBold(lBold)` | Negrito |
| `:SetFrColorHeader(cColor)` | Cor da fonte |
| `:SetBgColorHeader(cColor)` | Cor de fundo |

## Estilo das linhas (zebrado)

As linhas ímpares usam o estilo `Line`, as pares o estilo `2Line`. Fonte:
Padrão (`TECA997`) / Família.

| Método | Parâmetro |
| --- | --- |
| `:SetLineFrColor(cColor)` | Cor da fonte — linhas ímpares |
| `:SetLineBgColor(cColor)` | Cor de fundo — linhas ímpares |
| `:Set2LineFrColor(cColor)` | Cor da fonte — linhas pares |
| `:Set2LineBgColor(cColor)` | Cor de fundo — linhas pares |

Para planilha sem zebrado, use a mesma cor nos dois estilos.

## Estilo de célula

Aplicado às posições informadas em `aCelStyle` no `AddRow`. Fonte: TDN-Ex.

| Método | Parâmetro |
| --- | --- |
| `:SetCelFont(cFont)` | Nome da fonte |
| `:SetCelSizeFont(nFontSize)` | Tamanho |
| `:SetCelItalic(lItalic)` | Itálico |
| `:SetCelBold(lBold)` | Negrito |
| `:SetCelUnderLine(lUnderline)` | Sublinhado |
| `:SetCelFrColor(cColor)` | Cor da **fonte** (o TDN descreve trocado; siga o padrão `Fr`/`Bg` do framework) |
| `:SetCelBgColor(cColor)` | Cor de **fundo** |

## Alinhamento, altura e encoding

Fonte: TDN-Ex.

| Método | Parâmetro | Default |
| --- | --- | --- |
| `:SetTitleHAlign(nAlign)` | 1 = Esquerda, 2 = Centro, 3 = Direita | 2 |
| `:SetHeaderHAlign(nAlign)` | 1 = Esquerda, 2 = Centro, 3 = Direita | 2 |
| `:SetTitleVAlign(nAlign)` | 1 = Topo, 2 = Centro, 3 = Base | 3 |
| `:SetHeaderVAlign(nAlign)` | 1 = Topo, 2 = Centro, 3 = Base | 3 |
| `:SetLineVAlign(nAlign)` | 1 = Topo, 2 = Centro, 3 = Base | 3 |
| `:SetTitleHeight(nHeight)` | Altura da linha de título | — |
| `:SetHeadHeight(nHeight)` | Altura da linha de cabeçalho | — |
| `:SetLineHeight(nHeight)` | Altura das linhas do corpo | — |
| `:SetUTF8Encode(lUtf8)` | `.T.` converte o conteúdo para UTF-8 (padrão) | `.T.` |

## Comparativo entre classes

| Aspecto | `FWMsExcel` | `FWMsExcelEx` | `FwMsExcelXlsx` |
| --- | --- | --- | --- |
| Formato | XML 2003 (`.xml`) | XML 2003 (`.xml`) | `.xlsx` nativo |
| Montagem | Memória | Grava em arquivo, sequencial | Memória; `SetWriteinFile(.T.)` grava direto |
| Estilo de célula (`aCelStyle`) | Não | Sim | Não |
| Requisitos | — | — | Binário 17.3.0.0+, `printer.exe` ≥ 2.1.0 |
| Troca de classe | Mesma API básica (`AddWorkSheet`, `AddTable`, `AddColumn`, `AddRow`, `Activate`, `GetXMLFile`) | | Mudar a extensão para `.xlsx` |

## Correções conhecidas (DTs)

| DT | Sintoma | Mitigação no código |
| --- | --- | --- |
| DFRM1-38370 | Erro no `Activate()` quando não há linhas | Testar `Eof()`/contador antes de gerar |
| DFRM1-33124 | `GetXMLFile()` retornava `.T.` com o arquivo aberto no Excel | Nome de arquivo único por execução |
| DFRM1-26097 | Sem estilo para números com 3+ casas decimais | Usar `cPicture` com a máscara desejada |
