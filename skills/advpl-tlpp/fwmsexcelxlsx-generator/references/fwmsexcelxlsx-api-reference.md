# FwMsExcelXlsx — Referência de API

Referência dos métodos da classe `FwMsExcelXlsx` (padrão da skill). A coluna
**Fonte** indica onde a assinatura foi confirmada:

- **TDN** — página oficial [FWMsExcelXlsx](https://tdn.totvs.com/display/public/framework/FWMsExcelXlsx)
- **TDN-DB** — página [SetWriteinDB](https://tdn.totvs.com/display/framework/SetWriteinDB)
- **DT** — documento técnico de melhoria/correção da classe
- **Padrão** — uso real em fontes do produto (`RmiMonitor`, `FISA843`, `LIBBOL`, `JURA112B`)

Não use métodos fora desta lista. Em especial, **não existem** nesta classe
`aCelStyle`, `SetCel*`, `SetTitle*`, `SetHeader*`, `SetLine*`/`Set2Line*` —
esses são da classe legada `FWMsExcelEx`.

## Sumário

- [Requisitos](#requisitos)
- [Ciclo de vida](#ciclo-de-vida)
- [Estrutura: abas, tabelas, colunas e linhas](#estrutura-abas-tabelas-colunas-e-linhas)
- [Fonte da planilha](#fonte-da-planilha)
- [Modos de gravação para grandes volumes](#modos-de-gravação-para-grandes-volumes)
- [Funções de apoio](#funções-de-apoio)
- [Comparativo com as classes legadas](#comparativo-com-as-classes-legadas)
- [DTs relevantes](#dts-relevantes)

## Requisitos

| Item | Mínimo | Observação |
| --- | --- | --- |
| Binário AppServer | 17.3.0.0 | — |
| `printer.exe` | 2.1.0 | Versão anterior **lança exceção** na geração. Manter atualizada no servidor e no SmartClient |

Mensagem da exceção quando a `printer.exe` não atende:
`Versão da printer.exe não suporta a geração de arquivos .xlsx`.

## Ciclo de vida

| Método | Retorno | Descrição | Fonte |
| --- | --- | --- | --- |
| `FwMsExcelXlsx():New()` | objeto | Construtor | TDN |
| `:ClassName()` | caractere | Nome da classe | TDN |
| `:Activate()` | lógico | Habilita a geração. Chamar depois de todas as linhas | TDN, Padrão |
| `:GetXMLFile(cFile)` | lógico | Grava o arquivo `.xlsx` (nome mantido por compatibilidade). Use caminho do servidor | TDN, Padrão |
| `:DeActivate()` | lógico | Desabilita e limpa o objeto. Seguir com `FreeObj(oExcel)` | TDN, Padrão |

## Estrutura: abas, tabelas, colunas e linhas

### AddWorkSheet

`:AddWorkSheet(cWorkSheet) → lRet` — Fonte: TDN.

Nome com até **30 caracteres**; strings maiores são truncadas.

### IsWorkSheet

`:IsWorkSheet(cWorkSheet) → lRet` — indica se o nome de aba já foi usado. Fonte: TDN.

### AddTable

`:AddTable(cWorkSheet, cTable [, lPrintHead])` — Fonte: TDN.

| Parâmetro | Tipo | Default | Descrição |
| --- | --- | --- | --- |
| `cWorkSheet` | C | — | Nome da aba |
| `cTable` | C | — | Título da tabela |
| `lPrintHead` | L | `.T.` | Imprime o cabeçalho na primeira linha da tabela |

Uma aba comporta apenas uma tabela.

### AddColumn

`:AddColumn(cWorkSheet, cTable, cColumn [, nAlign] [, nFormat] [, lTotal] [, cPicture]) → lRet`
— Fonte: TDN, Padrão.

| Parâmetro | Tipo | Default | Descrição |
| --- | --- | --- | --- |
| `cColumn` | C | — | Título da coluna |
| `nAlign` | N | 1 | 1 = Esquerda, 2 = Centro, 3 = Direita |
| `nFormat` | N | 1 | 1 = Geral, 2 = Número, 3 = Monetário, 4 = Data/Hora |
| `lTotal` | L | `.F.` | Totaliza a coluna |
| `cPicture` | C | `""` | Máscara, somente numéricos (exemplos do TDN: `"999.99"`, `"999.9999"`) |

### AddRow

`:AddRow(cWorkSheet, cTable, aRow) → lRet` — Fonte: TDN.

`aRow` com os valores na mesma ordem e quantidade das colunas. **Não há 4º
parâmetro de estilo.**

## Fonte da planilha

Todos aplicam-se a **todos os estilos da planilha** (título, cabeçalho e
linhas). Fonte: TDN, Padrão (`FISA843`).

| Método | Parâmetro | Observação |
| --- | --- | --- |
| `:SetFont(cFont)` | Nome da fonte | Fonte inexistente → Calibri |
| `:SetFontSize(nFontSize)` | Tamanho | — |
| `:SetBold(lBold)` | Negrito | — |
| `:SetItalic(lItalic)` | Itálico | — |
| `:SetUnderLine(lUnderline)` | Sublinhado | — |

Chame logo após `New()`, antes da primeira aba — obrigatório quando
`SetWriteinFile(.T.)` estiver ativo, porque as linhas são gravadas no momento
do `AddRow`.

## Modos de gravação para grandes volumes

Por padrão a classe monta a planilha em memória do AppServer.

### SetWriteinFile

`:SetWriteinFile(lWriteinFile)` — Fonte: TDN, DT (DFRM1-29800).

- Grava direto em arquivo: cada `AddRow` faz o flush e a memória do servidor
  não cresce com o volume.
- A geração fica **procedural**: `AddRow` sempre grava na **última tabela
  adicionada**; não é possível adicionar linhas em uma tabela criada antes.

### SetWriteinDB

`:SetWriteinDB(lWriteinDb [, nLimit]) → lHabilitou` — Fonte: TDN-DB.

| Parâmetro | Tipo | Default | Descrição |
| --- | --- | --- | --- |
| `lWriteinDb` | L | — | `.T.` grava os dados auxiliares no banco em vez da memória |
| `nLimit` | N | 200000 | Quantidade de registros (células) por Bulk Insert |

- Chamar **antes de qualquer `AddRow`**.
- Exige DBAccess ≥ 22.1.1.0 e ambiente preparado; caso contrário retorna `.F.`
  e a geração segue em memória.
- Mais lento que memória; em SQLite a inserção é registro a registro.
- Não há documentação sobre combinar com `SetWriteinFile` — use um ou outro.

## Funções de apoio

| Função | Uso na skill | Fonte |
| --- | --- | --- |
| `PrinterVersion():fromServer() → cVersao` | Versão da `printer.exe` do AppServer | TDN, Padrão (`RmiMonitor`) |
| `PrinterVersion():fromClient() → cVersao` | Versão da `printer.exe` do SmartClient | TDN |
| `CpyS2T(cFile, cFolder [, lCompress])` | Copia do servidor para a estação (SmartClient desktop) | TDN |
| `CpyS2TW(cFile [, lOpen])` | Copia do servidor para o navegador (WebApp sem Web-Agent) | TDN, Padrão |
| `GetRemoteType()` | `5` = SmartClient HTML (WebApp) | Padrão |

## Comparativo com as classes legadas

| Aspecto | `FwMsExcelXlsx` (padrão) | `FWMsExcelEx` (legada) | `FWMsExcel` (legada) |
| --- | --- | --- | --- |
| Formato | `.xlsx` nativo | XML 2003 (`.xml`) | XML 2003 (`.xml`) |
| Gerado por | `printer.exe` | AdvPL | AdvPL |
| Montagem | Memória; `SetWriteinFile` / `SetWriteinDB` | Sequencial em arquivo | Memória |
| Cores de título/cabeçalho/zebrado | Não | Sim | Sim |
| Estilo de célula (`aCelStyle`) | Não | Sim | Não |
| Fonte global (`SetFont`...) | Sim | — | — |
| Requisitos | Binário 17.3.0.0, `printer.exe` 2.1.0 | — | — |

Migrar de legada para `FwMsExcelXlsx`: trocar o construtor, mudar a extensão
para `.xlsx`, remover `SetCel*`/`SetTitle*`/`SetHeader*`/`SetLine*` e o 4º
parâmetro do `AddRow`, gravar no servidor e adicionar a verificação da
`printer.exe`.

## DTs relevantes

| DT | Assunto |
| --- | --- |
| DFRM1-25248 | Alto consumo de memória — fontes e formatações passaram a usar cache |
| DFRM1-29800 | Criação do `SetWriteinFile` |
| DFRM1-32067 | Planilha `.xlsx` exportada em branco — corrigido na classe |
| DFRM1-23910 | Geração de `.xlsx` pelo TReport depende dos mesmos requisitos de binário |
