---
name: fwmsexcelxlsx-generator
description: >-
  Gera customizações AdvPL/TLPP (sempre User Function) que exportam dados do
  Protheus para planilha Excel .xlsx usando a classe de framework
  FwMsExcelXlsx, padrão recomendado pela TOTVS — abas, tabelas, colunas com
  alinhamento, formato, máscara e totalizador, fonte da planilha, gravação
  direta em arquivo ou no banco para grandes volumes, verificação da
  printer.exe e entrega do arquivo em SmartClient, WebApp ou job. A classe
  legada FWMsExcelEx (XML 2003) só é usada quando o usuário pedir
  explicitamente. Use quando o usuário pedir "exportar para Excel", "gerar
  planilha", "gerar xlsx", "integração com Excel", "relatório em Excel",
  "exportar consulta para planilha", "planilha com várias abas",
  "FwMsExcelXlsx", "FWMsExcel", "FWMsExcelEx" ou "export to Excel AdvPL" —
  mesmo que não cite nenhuma classe.
license: MIT
metadata:
  domain: Protheus
  maintainer: Customizações ADVPL/TLPP
  author: Renato Cunha
  version: '1.0.0'
  category: Code Generation
---

# FwMsExcelXlsx Generator

## Visão geral

`FwMsExcelXlsx` é a classe de framework recomendada para gerar planilhas
Excel **`.xlsx` nativas** no Protheus. Tem a mesma API básica da família
`FWMsExcel` (`AddWorkSheet`, `AddTable`, `AddColumn`, `AddRow`, `Activate`,
`GetXMLFile`), mas o arquivo é montado pela `printer.exe` do AppServer, o que
elimina o aviso de "formato e extensão não correspondem" do Excel.

Este repositório é de **customização**: todo código gerado é `User Function`
(pública) com `Static Function` para os auxiliares. `Function` é proibido.

## Qual classe usar — regra de decisão

| Situação | Classe |
| --- | --- |
| **Qualquer pedido de planilha / exportação / integração com Excel** | **`FwMsExcelXlsx`** (padrão desta skill) |
| Controle célula a célula: cores, bordas, mesclagem, fórmulas, imagens | `FwPrinterXlsx` (fora do escopo desta skill — avise o usuário) |
| Usuário pede **explicitamente** `FWMsExcelEx` ou "a versão antiga" | `FWMsExcelEx` — **legada**, ver [seção legada](#classe-legada-fwmsexcelex) |

`FWMsExcelEx` e `FWMsExcel` são **legadas** (geram XML Spreadsheet 2003,
`.xml`). Não as use por iniciativa própria. Se o pedido citar `FWMsExcelEx`
(ou grafias como `FWMsExcelExv`) sem dizer que quer a versão antiga, **avise
que a classe é legada, proponha `FwMsExcelXlsx`** e só siga com a legada se o
usuário confirmar.

Não use esta skill para relatórios impressos (TReport/Smart View) nem para
importar planilhas.

## Pré-requisitos do ambiente

| Requisito | Versão mínima | Consequência se faltar |
| --- | --- | --- |
| Binário (AppServer) | 17.3.0.0 | Classe indisponível |
| `printer.exe` (AppServer; e SmartClient quando usado) | 2.1.0 | **Exceção** em tempo de execução: "Versão da printer.exe não suporta a geração de arquivos .xlsx" |
| `SetWriteinDB` | DBAccess 22.1.1.0 | Retorna `.F.` e continua em memória |

Todo fonte gerado deve **verificar a `printer.exe`** com
`PrinterVersion():fromServer()` antes de montar a planilha e, se não atender,
informar o requisito ao usuário em vez de deixar a exceção estourar.

## Ciclo de vida

```
New()
 └─ [SetWriteinFile(.T.) | SetWriteinDB(.T.)]   // opcional, grandes volumes, ANTES de qualquer AddRow
 └─ [SetFont / SetFontSize / SetBold ...]        // opcional, vale para a planilha inteira
 └─ para cada aba (uma de cada vez):
      AddWorkSheet(cAba)
      AddTable(cAba, cTabela)
      AddColumn(cAba, cTabela, cTitulo, nAlign, nFormat, lTotal, cPicture)   // N vezes
      AddRow(cAba, cTabela, aLinha)                                           // N vezes
Activate()
GetXMLFile(cArquivo.xlsx)      // grava no servidor
DeActivate()  +  FreeObj(oExcel)
```

| Parâmetro de `AddColumn` | Valores |
| --- | --- |
| `nAlign` | 1 = Esquerda, 2 = Centro, 3 = Direita |
| `nFormat` | 1 = Geral, 2 = Número, 3 = Monetário, 4 = Data/Hora |
| `lTotal` | `.T.` totaliza a coluna (somente numéricas) |
| `cPicture` | Máscara para numéricos no padrão dos exemplos do TDN (ex.: `"999.99"`); opcional — `nFormat` já formata número/moeda |

Assinaturas completas: [references/fwmsexcelxlsx-api-reference.md](references/fwmsexcelxlsx-api-reference.md).

## Workflow de geração

1. **Levante o requisito**: tabela(s), filtros, colunas, totais, número de
   abas, volume esperado e onde a rotina roda (menu SmartClient, WebApp ou
   job/schedule). Se o usuário pedir cores ou destaque por célula, explique
   que a `FwMsExcelXlsx` só tem fonte global e ofereça uma coluna de
   "situação" (ver exemplo 2) ou a `FwPrinterXlsx`.
2. **Valide o dicionário**: confirme que cada campo existe na tabela de
   origem (SX3) antes de usá-lo; títulos via `FWX3Titulo()`, tipo/tamanho via
   `TamSX3()`. Nunca digite títulos de coluna à mão quando o campo é do SX3.
3. **Monte a consulta** com `FWExecStatement` e parâmetros `?` (valores via
   `SetString`/`SetDate`/`SetNumeric`, na ordem dos `?`): `RetSqlName()` para
   o nome físico, filtro de filial com `xFilial()`, `D_E_L_E_T_ = ' '` em
   **todas** as tabelas do `FROM`/`JOIN`, `ChangeQuery()` e `TCSetField()`
   para datas e numéricos. Feche o alias e chame `oExec:Destroy()` ao final.
4. **Verifique a `printer.exe`** antes de criar o objeto.
5. **Descreva as colunas uma única vez** (`aCols`) e use o mesmo array para
   `AddColumn` e para montar cada `aLinha`.
6. **Escolha o modo de gravação**: memória (padrão) para volumes pequenos e
   médios; `SetWriteinFile(.T.)` para grandes volumes; `SetWriteinDB(.T.)`
   como alternativa quando o
   DBAccess for ≥ 22.1.1.0. Não combine os dois.
7. **Gere** seguindo o ciclo de vida, uma aba completa por vez.
8. **Grave no servidor e entregue**: `GetXMLFile()` em pasta do servidor
   (`MV_XDIRXLS`, padrão `\spool\`); depois `CpyS2T()` + `ShellExecute()` no
   SmartClient, `CpyS2TW()` no WebApp (`GetRemoteType() == 5`) ou apenas
   `FWLogMsg()` em job (`IsBlind()`).
9. **Libere recursos**: `DeActivate()`, `FreeObj(oExcel)`,
   `(cAlias)->(DbCloseArea())`, `oExec:Destroy()`.
10. **Salve o fonte em Windows-1252 (CP1252)** e compile. O compilador do
    Protheus não aceita UTF-8: acentos em strings e comentários ficam
    corrompidos. Em Linux/macOS, converta com
    `iconv -f UTF-8 -t WINDOWS-1252 origem.prw > destino.prw`; no VS Code, use
    "Save with Encoding → Western (Windows 1252)".

Template base reutilizável e 4 exemplos completos:
[references/fwmsexcelxlsx-examples.md](references/fwmsexcelxlsx-examples.md).
Leia esse arquivo **sempre** antes de gerar código.

## Boas práticas obrigatórias nos fontes gerados

- `User Function` para a rotina e `Static Function` para auxiliares. Em
  `.prw`, nome da `User Function` com **no máximo 8 caracteres** (o `U_`
  ocupa 2 dos 10 significativos); em `.tlpp` nomes longos são permitidos.
- Includes em minúsculas: `#include "totvs.ch"`; em TLPP,
  `#include "tlpp-core.th"` primeiro.
- Bloco `/*/{Protheus.doc}` em cada função; notação húngara; todos os
  `Local` no topo.
- Sem `IIf()` (use `If/Else/EndIf`), sem `ConOut()` (use `FWLogMsg`), sem
  concatenar entrada do usuário em SQL (use `FWExecStatement` com `?`), sem
  `SuperGetMV()` dentro de laço (leia antes), sem UI quando `IsBlind()`.
- `#define` para alinhamento, formato e posições de array.
- Pasta do servidor vinda de parâmetro (`SuperGetMV("MV_XDIRXLS", .F.,
  "\spool\")`) e nome de arquivo único (prefixo + data + hora + thread).

## Gotchas

- **`printer.exe` desatualizada gera exceção**, não retorno `.F.`. Verifique
  a versão antes; compare por segmento numérico (`"10.0.0"` é menor que
  `"2.1.0"` em comparação de string).
- **Grave sempre no servidor**: quem monta o `.xlsx` é a `printer.exe` do
  AppServer. Gere em pasta do servidor e copie para a estação depois
  (`CpyS2T` no SmartClient desktop, `CpyS2TW` no WebApp sem Web-Agent).
- **Sem estilo por célula**: `AddRow` tem só 3 parâmetros — não existe
  `aCelStyle` nem setters de cor de título/cabeçalho/linha nesta classe.
  `SetFont`, `SetFontSize`, `SetBold`, `SetItalic` e `SetUnderLine` valem para
  **todos os estilos da planilha**. Chame-os logo após `New()`.
- **Nome de aba**: limitado a 30 caracteres; nomes maiores são truncados — dois
  nomes longos podem colidir. Use `IsWorkSheet()` quando o nome for dinâmico.
- **`SetWriteinFile(.T.)` torna a escrita procedural**: cada `AddRow` vai para
  a **última tabela criada**; não é possível voltar a uma aba anterior. Monte
  uma aba inteira por vez — faça isso sempre, mesmo em memória, para o código
  continuar válido se o modo de gravação mudar.
- **`SetWriteinDB`** precisa ser chamado antes de qualquer `AddRow`, exige
  ambiente preparado e é mais lento; se retornar `.F.`, a geração segue em
  memória (registre um aviso).
- **Tipos importam**: número como numérico (não `Transform()`), data como `D`
  (`TCSetField`), código com zeros à esquerda como caractere, `Nil` → `""`,
  caracteres com `AllTrim()`. `aLinha` deve ter o mesmo número de posições
  que as colunas.
- **Sem linhas**: não gere arquivo vazio. Teste `Eof()` antes de criar o objeto
  e avise o usuário.
- **Extensão `.xlsx`**: `GetXMLFile` manteve o nome por compatibilidade, mas
  grava `.xlsx`.

## Checklist de validação

- [ ] Classe `FwMsExcelXlsx` (a legada só com pedido explícito do usuário)
- [ ] Somente `User Function`/`Static Function`; nome `.prw` ≤ 8 caracteres
- [ ] ProtheusDOC; `Local` no topo; notação húngara; sem `IIf`/`ConOut`
- [ ] Verificação de `PrinterVersion():fromServer()` ≥ 2.1.0 antes de gerar
- [ ] Query com `FWExecStatement` + `?`, `xFilial()`, `D_E_L_E_T_`, `ChangeQuery()`
- [ ] Datas/numéricos com `TCSetField`; títulos via `FWX3Titulo()`
- [ ] `aCols` único dirigindo `AddColumn` e as linhas; uma aba por vez
- [ ] Modo de gravação adequado ao volume (retorno de `SetWriteinDB` tratado)
- [ ] Tratamento de "sem dados" antes de criar o objeto
- [ ] `Activate()` → `GetXMLFile()` → `DeActivate()` → `FreeObj()`; alias fechado e `oExec:Destroy()`
- [ ] Arquivo gravado no servidor e entregue conforme contexto
- [ ] Fonte convertido para CP1252

## Classe legada (FWMsExcelEx)

Mantida apenas para quem pedir explicitamente. Ao usá-la, diga ao usuário que
é legada e que a recomendação é `FwMsExcelXlsx`. Diferenças principais: gera
`.xml` (Excel 2003), grava sequencialmente em arquivo, tem cores de
título/cabeçalho/linhas zebradas e estilo de célula (`SetCel*` + 4º parâmetro
`aCelStyle` do `AddRow`).

| Arquivo | Conteúdo |
| --- | --- |
| [references/legacy-fwmsexcelex-api-reference.md](references/legacy-fwmsexcelex-api-reference.md) | Métodos da `FWMsExcelEx`, gotchas e DTs |
| [references/legacy-fwmsexcelex-examples.md](references/legacy-fwmsexcelex-examples.md) | Template base e 4 exemplos em `User Function` com a classe legada |

## Referências

| Arquivo | Quando ler | Conteúdo |
| --- | --- | --- |
| [references/fwmsexcelxlsx-examples.md](references/fwmsexcelxlsx-examples.md) | Sempre, antes de gerar código | Template base com auxiliares reutilizáveis e 4 exemplos completos em `User Function` (cadastro simples, totais com coluna de situação, várias abas, TLPP para job com grande volume) |
| [references/fwmsexcelxlsx-api-reference.md](references/fwmsexcelxlsx-api-reference.md) | Assinatura exata, requisitos por versão, modos de gravação | Métodos da `FwMsExcelXlsx`, `PrinterVersion`, `SetWriteinFile`, `SetWriteinDB`, comparativo com as classes legadas e DTs |

Documentação oficial: [FWMsExcelXlsx](https://tdn.totvs.com/display/public/framework/FWMsExcelXlsx),
[SetWriteinDB](https://tdn.totvs.com/display/framework/SetWriteinDB),
[PrinterVersion](https://tdn.totvs.com/display/framework/PrinterVersion),
[Geração de planilhas](https://tdn.totvs.com/pages/viewpage.action?pageId=560647734).
