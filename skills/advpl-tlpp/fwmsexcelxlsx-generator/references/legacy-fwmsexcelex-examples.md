# [LEGADO] FWMsExcelEx — Template base e exemplos de customização

> **LEGADO — não use por padrão.** A `FWMsExcelEx` é a classe antiga (gera
> XML Spreadsheet 2003, `.xml`). A recomendação atual da TOTVS é a
> [`FwMsExcelXlsx`](https://tdn.totvs.com/display/public/framework/FWMsExcelXlsx),
> documentada em [fwmsexcelxlsx-examples.md](fwmsexcelxlsx-examples.md). Use este arquivo
> **somente** quando o usuário pedir explicitamente a `FWMsExcelEx` (ou a versão
> antiga), ou quando o ambiente comprovadamente não atender aos requisitos da
> `FwMsExcelXlsx` e o usuário aceitar a classe legada.

Todos os exemplos usam `User Function` (rotina pública da customização) e
`Static Function` (auxiliares privados do fonte), seguindo as boas práticas
de programação AdvPL/TLPP descritas no `SKILL.md`.

## Sumário

- [Como usar este arquivo](#como-usar-este-arquivo)
- [Template base (.prw) — auxiliares reutilizáveis](#template-base-prw--auxiliares-reutilizáveis)
- [Exemplo 1 — Cadastro simples: clientes ativos (XEXCSA1)](#exemplo-1--cadastro-simples-clientes-ativos-xexcsa1)
- [Exemplo 2 — Destaque de célula e totais: títulos vencidos (XEXCSE1)](#exemplo-2--destaque-de-célula-e-totais-títulos-vencidos-xexcse1)
- [Exemplo 3 — Várias abas em sequência: pedidos e itens (XEXCMULT)](#exemplo-3--várias-abas-em-sequência-pedidos-e-itens-xexcmult)
- [Exemplo 4 — TLPP tipado, pronto para job (xExcelSaldoEstoque)](#exemplo-4--tlpp-tipado-pronto-para-job-xexcelsaldoestoque)
- [Parâmetros customizados sugeridos (SX6)](#parâmetros-customizados-sugeridos-sx6)

## Como usar este arquivo

- Os exemplos 1, 2 e 3 são fontes `.prw` independentes. `Static Function` só é
  visível dentro do próprio fonte, então **cada `.prw` deve conter o bloco
  "Template base" inteiro** (constantes + auxiliares) além da sua
  `User Function`. Alternativa: mover os auxiliares para um fonte próprio como
  `User Function` (ex.: `U_XLSADDAB`) — só faça isso se o cliente já tiver uma
  biblioteca de utilitários.
- O exemplo 4 (TLPP) é autocontido.
- Ajuste nomes de rotina ao padrão do cliente. Em `.prw`, nome de
  `User Function` com no máximo 8 caracteres.
- Após gerar, salve o fonte em Windows-1252 (CP1252) — o compilador do
  Protheus não aceita UTF-8 (veja o passo 10 do workflow no `SKILL.md`).

## Template base (.prw) — auxiliares reutilizáveis

Cada coluna é descrita uma única vez em `aCols`; o mesmo array dirige
`AddColumn` e a montagem de cada linha, garantindo que `aLinha` tenha sempre o
tamanho correto.

```advpl
#include "totvs.ch"

// Alinhamento (AddColumn - nAlign)
#define XLS_ESQUERDA     1
#define XLS_CENTRO       2
#define XLS_DIREITA      3

// Formato (AddColumn - nFormat)
#define XLS_GERAL        1
#define XLS_NUMERO       2
#define XLS_MOEDA        3
#define XLS_DATA         4

// Estrutura de cada item de aCols
#define COL_CAMPO        1   // Campo do SX3 ou identificador de coluna calculada
#define COL_TITULO       2   // Título da coluna; vazio = FWX3Titulo(campo)
#define COL_ALINHA       3
#define COL_FORMATO      4
#define COL_TOTAL        5
#define COL_BLOCO        6   // {|cAlias| xValor } para coluna calculada; Nil = lê o campo

// GetRemoteType() para SmartClient HTML (WebApp)
#define XLS_REMOTE_HTML  5

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsCol
Monta a definição de uma coluna para o array aCols.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cCampo, character, Campo do SX3 ou identificador da coluna calculada
@param cTitulo, character, Título da coluna (vazio = título do SX3)
@param nAlinha, numeric, Alinhamento (XLS_ESQUERDA, XLS_CENTRO, XLS_DIREITA)
@param nFormato, numeric, Formato (XLS_GERAL, XLS_NUMERO, XLS_MOEDA, XLS_DATA)
@param lTotal, logical, Indica se a coluna é totalizada
@param bValor, codeblock, Bloco que recebe o alias e devolve o valor (opcional)
@return array, Definição da coluna no layout COL_*
/*/
//-------------------------------------------------------------------
Static Function XlsCol(cCampo, cTitulo, nAlinha, nFormato, lTotal, bValor)

    Default cTitulo  := ""
    Default nAlinha  := XLS_ESQUERDA
    Default nFormato := XLS_GERAL
    Default lTotal   := .F.
    Default bValor   := Nil

Return {cCampo, cTitulo, nAlinha, nFormato, lTotal, bValor}

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsEstilo
Aplica o padrão visual de título, cabeçalho e linhas zebradas.
Chamar logo após FWMsExcelEx():New(), antes da primeira aba.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param oExcel, object, Instância de FWMsExcelEx
@return nil
/*/
//-------------------------------------------------------------------
Static Function XlsEstilo(oExcel)

    oExcel:SetTitleBold(.T.)
    oExcel:SetTitleFrColor("#1F4E78")
    oExcel:SetTitleBgColor("#FFFFFF")

    oExcel:SetHeaderBold(.T.)
    oExcel:SetFrColorHeader("#FFFFFF")
    oExcel:SetBgColorHeader("#1F4E78")

    oExcel:SetLineFrColor("#000000")
    oExcel:SetLineBgColor("#FFFFFF")
    oExcel:Set2LineFrColor("#000000")
    oExcel:Set2LineBgColor("#DDEBF7")

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsAddAba
Cria uma aba COMPLETA (aba, tabela, colunas e todas as linhas) a partir
de um alias de query já aberto e posicionado no primeiro registro.
A FWMsExcelEx grava em sequência: termine esta aba antes de criar outra.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param oExcel, object, Instância de FWMsExcelEx
@param cAba, character, Nome da aba (máx. 31 caracteres)
@param cTabela, character, Título da tabela
@param aCols, array, Colunas montadas com XlsCol()
@param cAlias, character, Alias da query de origem
@param bDestaque, codeblock, {|cAlias| aPosicoes } colunas a destacar (opcional)
@return numeric, Quantidade de linhas gravadas
/*/
//-------------------------------------------------------------------
Static Function XlsAddAba(oExcel, cAba, cTabela, aCols, cAlias, bDestaque)

    Local nLinhas := 0
    Local nCol    := 0
    Local cTitulo := ""
    Local aLinha  := {}
    Local aEstilo := {}

    Default bDestaque := Nil

    XlsTipos(cAlias, aCols)

    oExcel:AddWorkSheet(cAba)
    oExcel:AddTable(cAba, cTabela)

    For nCol := 1 To Len(aCols)
        cTitulo := aCols[nCol][COL_TITULO]
        If Empty(cTitulo)
            cTitulo := AllTrim(FWX3Titulo(aCols[nCol][COL_CAMPO]))
        EndIf
        oExcel:AddColumn(cAba, cTabela, cTitulo, aCols[nCol][COL_ALINHA], aCols[nCol][COL_FORMATO], aCols[nCol][COL_TOTAL])
    Next nCol

    While !(cAlias)->(Eof())
        aLinha := Array(Len(aCols))
        For nCol := 1 To Len(aCols)
            aLinha[nCol] := XlsValor(cAlias, aCols[nCol])
        Next nCol

        aEstilo := {}
        If ValType(bDestaque) == "B"
            aEstilo := Eval(bDestaque, cAlias)
        EndIf

        If Empty(aEstilo)
            oExcel:AddRow(cAba, cTabela, aLinha)
        Else
            oExcel:AddRow(cAba, cTabela, aLinha, aEstilo)
        EndIf

        nLinhas++
        (cAlias)->(DbSkip())
    EndDo

Return nLinhas

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsTipos
Converte, no alias da query, os campos data e numéricos do SX3 para o
tipo correto (a query devolve datas como caractere AAAAMMDD).
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cAlias, character, Alias da query
@param aCols, array, Colunas montadas com XlsCol()
@return nil
/*/
//-------------------------------------------------------------------
Static Function XlsTipos(cAlias, aCols)

    Local nCol   := 0
    Local cCampo := ""
    Local aTam   := {}

    For nCol := 1 To Len(aCols)
        cCampo := aCols[nCol][COL_CAMPO]
        If ValType(aCols[nCol][COL_BLOCO]) != "B" .And. (cAlias)->(FieldPos(cCampo)) > 0
            aTam := TamSX3(cCampo)
            If !Empty(aTam) .And. aTam[3] $ "DN"
                TCSetField(cAlias, cCampo, aTam[3], aTam[1], aTam[2])
            EndIf
        EndIf
    Next nCol

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsValor
Obtém e normaliza o valor de uma coluna para a planilha.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cAlias, character, Alias posicionado
@param aCol, array, Definição da coluna (XlsCol)
@return variant, Valor pronto para AddRow
/*/
//-------------------------------------------------------------------
Static Function XlsValor(cAlias, aCol)

    Local xValor := Nil

    If ValType(aCol[COL_BLOCO]) == "B"
        xValor := Eval(aCol[COL_BLOCO], cAlias)
    Else
        xValor := (cAlias)->(FieldGet(FieldPos(aCol[COL_CAMPO])))
    EndIf

    If ValType(xValor) == "C"
        xValor := AllTrim(xValor)
    ElseIf ValType(xValor) == "U"
        xValor := ""
    ElseIf ValType(xValor) == "D" .And. Empty(xValor)
        xValor := ""
    EndIf

Return xValor

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsArquivo
Define o caminho completo e único do arquivo conforme o contexto:
job ou WebApp grava no servidor (MV_XDIRXLS); SmartClient grava na
pasta temporária da estação.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cPrefixo, character, Prefixo do nome do arquivo
@return character, Caminho completo com extensão .xml
/*/
//-------------------------------------------------------------------
Static Function XlsArquivo(cPrefixo)

    Local cDir  := ""
    Local cNome := ""

    If IsBlind() .Or. GetRemoteType() == XLS_REMOTE_HTML
        cDir := AllTrim(SuperGetMV("MV_XDIRXLS", .F., "\spool\"))
        If Right(cDir, 1) != "\"
            cDir += "\"
        EndIf
        If !ExistDir(cDir)
            MakeDir(cDir)
        EndIf
    Else
        cDir := GetTempPath()
    EndIf

    cNome := Lower(cPrefixo) + "_" + DtoS(Date()) + "_" + StrTran(Time(), ":", "")
    cNome += "_" + cValToChar(ThreadId()) + ".xml"

Return cDir + cNome

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsFinaliza
Fecha a montagem, grava o arquivo e libera o objeto.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param oExcel, object, Instância de FWMsExcelEx com ao menos uma linha
@param cArquivo, character, Caminho completo do arquivo
@return logical, .T. quando o arquivo foi gravado
/*/
//-------------------------------------------------------------------
Static Function XlsFinaliza(oExcel, cArquivo)

    Local lOk := .F.

    oExcel:Activate()
    lOk := oExcel:GetXMLFile(cArquivo)
    oExcel:DeActivate()
    FreeObj(oExcel)

Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsEntrega
Entrega a planilha conforme o contexto de execução.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cArquivo, character, Caminho completo do arquivo gerado
@return nil
/*/
//-------------------------------------------------------------------
Static Function XlsEntrega(cArquivo)

    If IsBlind()
        FWLogMsg("INFO", , "XLSEXPORT", FunName(), , "01", "Planilha gerada em " + cArquivo)
    ElseIf GetRemoteType() == XLS_REMOTE_HTML
        CpyS2TW(cArquivo, .T.)
    ElseIf MsgYesNo("Planilha gerada em " + cArquivo + CRLF + "Deseja abrir agora?", "Exportação")
        ShellExecute("open", cArquivo, "", GetTempPath(), 1)
    EndIf

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsAviso
Informa um aviso ou erro sem usar interface quando em job.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cMensagem, character, Texto da mensagem
@param lErro, logical, .T. para erro, .F. para aviso
@return nil
/*/
//-------------------------------------------------------------------
Static Function XlsAviso(cMensagem, lErro)

    Default lErro := .F.

    If IsBlind()
        If lErro
            FWLogMsg("ERROR", , "XLSEXPORT", FunName(), , "02", cMensagem)
        Else
            FWLogMsg("WARN", , "XLSEXPORT", FunName(), , "03", cMensagem)
        EndIf
    ElseIf lErro
        MsgStop(cMensagem, "Exportação")
    Else
        MsgInfo(cMensagem, "Exportação")
    EndIf

Return Nil
```

## Exemplo 1 — Cadastro simples: clientes ativos (XEXCSA1)

Arquivo `XEXCSA1.prw` = **Template base** + o código abaixo. Mostra o fluxo
mínimo: query parametrizada, colunas vindas do dicionário, tratamento de
"sem dados" e entrega por contexto.

```advpl
//-------------------------------------------------------------------
/*/{Protheus.doc} XEXCSA1
Exporta os clientes ativos (não bloqueados) da filial corrente para
planilha Excel usando FWMsExcelEx.
@type User Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@return logical, .T. quando a planilha foi gerada
@example U_XEXCSA1()
/*/
//-------------------------------------------------------------------
User Function XEXCSA1()

    Local cArquivo := ""
    Local cErro    := ""

    If IsBlind()
        cArquivo := GeraSA1(@cErro)
    Else
        FWMsgRun(, {|| cArquivo := GeraSA1(@cErro) }, "Exportação", "Gerando planilha de clientes...")
    EndIf

    If Empty(cArquivo)
        XlsAviso(cErro, .F.)
    Else
        XlsEntrega(cArquivo)
    EndIf

Return !Empty(cArquivo)

//-------------------------------------------------------------------
/*/{Protheus.doc} GeraSA1
Executa a consulta de clientes e grava a planilha.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cErro, character, Mensagem de retorno (por referência)
@return character, Caminho do arquivo gerado ou vazio quando não gerou
/*/
//-------------------------------------------------------------------
Static Function GeraSA1(cErro)

    Local cArquivo := ""
    Local cAlias   := ""
    Local cAba     := "Clientes"
    Local cTabela  := "Clientes ativos - Filial " + AllTrim(cFilAnt)
    Local aCols    := {}
    Local oExec    := Nil
    Local oExcel   := Nil

    oExec := FWExecStatement():New(QrySA1())
    oExec:SetString(1, xFilial("SA1"))
    oExec:SetString(2, "1")          // A1_MSBLQL = 1 -> bloqueado
    oExec:SetString(3, " ")
    cAlias := oExec:OpenAlias()

    If (cAlias)->(Eof())
        cErro := "Nenhum cliente ativo encontrado na filial " + AllTrim(cFilAnt) + "."
    Else
        aAdd(aCols, XlsCol("A1_COD"))
        aAdd(aCols, XlsCol("A1_LOJA", , XLS_CENTRO))
        aAdd(aCols, XlsCol("A1_NOME"))
        aAdd(aCols, XlsCol("A1_CGC"))                       // caractere: preserva zeros à esquerda
        aAdd(aCols, XlsCol("A1_EST", , XLS_CENTRO))
        aAdd(aCols, XlsCol("A1_ULTCOM", , XLS_CENTRO, XLS_DATA))

        oExcel := FWMsExcelEx():New()
        XlsEstilo(oExcel)
        XlsAddAba(oExcel, cAba, cTabela, aCols, cAlias)

        cArquivo := XlsArquivo("clientes")
        If !XlsFinaliza(oExcel, cArquivo)
            cErro    := "Não foi possível gravar o arquivo " + cArquivo + "."
            cArquivo := ""
        EndIf
    EndIf

    (cAlias)->(DbCloseArea())
    oExec:Destroy()

Return cArquivo

//-------------------------------------------------------------------
/*/{Protheus.doc} QrySA1
Monta a query de clientes com parâmetros de bind.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@return character, Query tratada por ChangeQuery
/*/
//-------------------------------------------------------------------
Static Function QrySA1()

    Local cQuery := ""

    cQuery := "SELECT SA1.A1_COD, SA1.A1_LOJA, SA1.A1_NOME, SA1.A1_CGC,"
    cQuery += "       SA1.A1_EST, SA1.A1_ULTCOM"
    cQuery += "  FROM " + RetSqlName("SA1") + " SA1"
    cQuery += " WHERE SA1.A1_FILIAL  = ?"
    cQuery += "   AND SA1.A1_MSBLQL <> ?"
    cQuery += "   AND SA1.D_E_L_E_T_ = ?"
    cQuery += " ORDER BY SA1.A1_COD, SA1.A1_LOJA"

Return ChangeQuery(cQuery)
```

## Exemplo 2 — Destaque de célula e totais: títulos vencidos (XEXCSE1)

Arquivo `XEXCSE1.prw` = **Template base** + o código abaixo. Mostra:
parâmetros via `ParamBox` (somente com interface), coluna calculada, colunas
monetárias totalizadas e destaque de células com `SetCel*` + `aCelStyle`.

```advpl
//-------------------------------------------------------------------
/*/{Protheus.doc} XEXCSE1
Exporta os títulos a receber vencidos e em aberto, destacando o saldo e
os dias de atraso quando o atraso ultrapassa MV_XDIASAT (padrão 30 dias).
@type User Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param dVencDe, date, Vencimento real inicial (job); padrão dDataBase - 365
@param dVencAte, date, Vencimento real final (job); padrão dDataBase - 1
@return logical, .T. quando a planilha foi gerada
@example U_XEXCSE1()
/*/
//-------------------------------------------------------------------
User Function XEXCSE1(dVencDe, dVencAte)

    Local cArquivo := ""
    Local cErro    := ""
    Local lSegue   := .T.
    Local aPergs   := {}
    Local aResp    := {}

    Default dVencDe  := dDataBase - 365
    Default dVencAte := dDataBase - 1

    If !IsBlind()
        aAdd(aPergs, {1, "Vencimento de",  dVencDe,  "", "", "", "", 50, .T.})
        aAdd(aPergs, {1, "Vencimento até", dVencAte, "", "", "", "", 50, .T.})
        lSegue := ParamBox(aPergs, "Títulos vencidos em aberto", @aResp)
        If lSegue
            dVencDe  := aResp[1]
            dVencAte := aResp[2]
        EndIf
    EndIf

    If lSegue .And. dVencDe > dVencAte
        cErro  := "O vencimento inicial deve ser menor ou igual ao final."
        lSegue := .F.
    EndIf

    If lSegue
        If IsBlind()
            cArquivo := GeraSE1(dVencDe, dVencAte, @cErro)
        Else
            FWMsgRun(, {|| cArquivo := GeraSE1(dVencDe, dVencAte, @cErro) }, "Exportação", "Gerando planilha de títulos...")
        EndIf
    EndIf

    If !Empty(cArquivo)
        XlsEntrega(cArquivo)
    ElseIf !Empty(cErro)
        XlsAviso(cErro, .F.)
    EndIf

Return !Empty(cArquivo)

//-------------------------------------------------------------------
/*/{Protheus.doc} GeraSE1
Consulta os títulos e grava a planilha com destaque de atraso.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param dVencDe, date, Vencimento real inicial
@param dVencAte, date, Vencimento real final
@param cErro, character, Mensagem de retorno (por referência)
@return character, Caminho do arquivo gerado ou vazio
/*/
//-------------------------------------------------------------------
Static Function GeraSE1(dVencDe, dVencAte, cErro)

    Local cArquivo  := ""
    Local cAlias    := ""
    Local cAba      := "Vencidos"
    Local cTabela   := "Títulos vencidos de " + DtoC(dVencDe) + " a " + DtoC(dVencAte)
    Local nDiasCrit := SuperGetMV("MV_XDIASAT", .F., 30)   // lido uma vez, fora do laço
    Local aCols     := {}
    Local aPosDest  := {}
    Local oExec     := Nil
    Local oExcel    := Nil

    oExec := FWExecStatement():New(QrySE1())
    oExec:SetString(1, xFilial("SE1"))
    oExec:SetNumeric(2, 0)
    oExec:SetDate(3, dVencDe)
    oExec:SetDate(4, dVencAte)
    oExec:SetDate(5, dDataBase)
    oExec:SetString(6, "%-")         // tipos de abatimento (AB-, IR-, ...) terminam com "-"
    oExec:SetString(7, " ")
    cAlias := oExec:OpenAlias()

    If (cAlias)->(Eof())
        cErro := "Nenhum título vencido em aberto no período informado."
    Else
        aAdd(aCols, XlsCol("E1_PREFIXO", , XLS_CENTRO))
        aAdd(aCols, XlsCol("E1_NUM"))
        aAdd(aCols, XlsCol("E1_PARCELA", , XLS_CENTRO))
        aAdd(aCols, XlsCol("E1_TIPO", , XLS_CENTRO))
        aAdd(aCols, XlsCol("E1_CLIENTE"))
        aAdd(aCols, XlsCol("E1_LOJA", , XLS_CENTRO))
        aAdd(aCols, XlsCol("E1_NOMCLI"))
        aAdd(aCols, XlsCol("E1_VENCREA", , XLS_CENTRO, XLS_DATA))
        aAdd(aCols, XlsCol("DIASATRASO", "Dias em atraso", XLS_DIREITA, XLS_NUMERO, .F., {|cAli| dDataBase - (cAli)->E1_VENCREA }))
        aAdd(aCols, XlsCol("E1_VALOR", , XLS_DIREITA, XLS_MOEDA, .T.))
        aAdd(aCols, XlsCol("E1_SALDO", , XLS_DIREITA, XLS_MOEDA, .T.))

        // Posições (1..N) que recebem o estilo de célula quando o atraso é crítico
        aAdd(aPosDest, aScan(aCols, {|aCol| aCol[COL_CAMPO] == "DIASATRASO" }))
        aAdd(aPosDest, aScan(aCols, {|aCol| aCol[COL_CAMPO] == "E1_SALDO" }))

        oExcel := FWMsExcelEx():New()
        XlsEstilo(oExcel)

        // Estilo de célula: configurado ANTES dos AddRow que usam aCelStyle
        oExcel:SetCelBold(.T.)
        oExcel:SetCelFrColor("#9C0006")   // fonte
        oExcel:SetCelBgColor("#FFC7CE")   // fundo

        XlsAddAba(oExcel, cAba, cTabela, aCols, cAlias, {|cAli| DestacaSE1(cAli, aPosDest, nDiasCrit) })

        cArquivo := XlsArquivo("vencidos")
        If !XlsFinaliza(oExcel, cArquivo)
            cErro    := "Não foi possível gravar o arquivo " + cArquivo + "."
            cArquivo := ""
        EndIf
    EndIf

    (cAlias)->(DbCloseArea())
    oExec:Destroy()

Return cArquivo

//-------------------------------------------------------------------
/*/{Protheus.doc} DestacaSE1
Indica quais colunas da linha atual recebem o estilo de célula.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cAlias, character, Alias posicionado
@param aPosDest, array, Posições das colunas a destacar
@param nDiasCrit, numeric, Dias de atraso a partir dos quais destaca
@return array, Posições a destacar ou {} para linha sem destaque
/*/
//-------------------------------------------------------------------
Static Function DestacaSE1(cAlias, aPosDest, nDiasCrit)

    Local aEstilo := {}

    If dDataBase - (cAlias)->E1_VENCREA > nDiasCrit
        aEstilo := aClone(aPosDest)
    EndIf

Return aEstilo

//-------------------------------------------------------------------
/*/{Protheus.doc} QrySE1
Monta a query de títulos vencidos em aberto com parâmetros de bind.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@return character, Query tratada por ChangeQuery
/*/
//-------------------------------------------------------------------
Static Function QrySE1()

    Local cQuery := ""

    cQuery := "SELECT SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO,"
    cQuery += "       SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_NOMCLI, SE1.E1_VENCREA,"
    cQuery += "       SE1.E1_VALOR, SE1.E1_SALDO"
    cQuery += "  FROM " + RetSqlName("SE1") + " SE1"
    cQuery += " WHERE SE1.E1_FILIAL  = ?"
    cQuery += "   AND SE1.E1_SALDO   > ?"
    cQuery += "   AND SE1.E1_VENCREA BETWEEN ? AND ?"
    cQuery += "   AND SE1.E1_VENCREA < ?"
    cQuery += "   AND SE1.E1_TIPO NOT LIKE ?"
    cQuery += "   AND SE1.D_E_L_E_T_ = ?"
    cQuery += " ORDER BY SE1.E1_VENCREA, SE1.E1_CLIENTE, SE1.E1_LOJA"

Return ChangeQuery(cQuery)
```

## Exemplo 3 — Várias abas em sequência: pedidos e itens (XEXCMULT)

Arquivo `XEXCMULT.prw` = **Template base** + o código abaixo. Mostra a regra
mais importante da `FWMsExcelEx`: **cada aba é concluída antes da próxima**.
Uma query por aba, aberta e fechada em sequência.

```advpl
//-------------------------------------------------------------------
/*/{Protheus.doc} XEXCMULT
Exporta os pedidos de venda emitidos no período em duas abas:
"Pedidos" (SC5) e "Itens" (SC6).
@type User Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param dEmisDe, date, Emissão inicial (job); padrão primeiro dia do mês
@param dEmisAte, date, Emissão final (job); padrão dDataBase
@return logical, .T. quando a planilha foi gerada
@example U_XEXCMULT()
/*/
//-------------------------------------------------------------------
User Function XEXCMULT(dEmisDe, dEmisAte)

    Local cArquivo := ""
    Local cErro    := ""
    Local lSegue   := .T.
    Local aPergs   := {}
    Local aResp    := {}

    Default dEmisDe  := FirstDate(dDataBase)
    Default dEmisAte := dDataBase

    If !IsBlind()
        aAdd(aPergs, {1, "Emissão de",  dEmisDe,  "", "", "", "", 50, .T.})
        aAdd(aPergs, {1, "Emissão até", dEmisAte, "", "", "", "", 50, .T.})
        lSegue := ParamBox(aPergs, "Pedidos de venda", @aResp)
        If lSegue
            dEmisDe  := aResp[1]
            dEmisAte := aResp[2]
        EndIf
    EndIf

    If lSegue
        If IsBlind()
            cArquivo := GeraPed(dEmisDe, dEmisAte, @cErro)
        Else
            FWMsgRun(, {|| cArquivo := GeraPed(dEmisDe, dEmisAte, @cErro) }, "Exportação", "Gerando planilha de pedidos...")
        EndIf
    EndIf

    If !Empty(cArquivo)
        XlsEntrega(cArquivo)
    ElseIf !Empty(cErro)
        XlsAviso(cErro, .F.)
    EndIf

Return !Empty(cArquivo)

//-------------------------------------------------------------------
/*/{Protheus.doc} GeraPed
Gera as abas de pedidos e de itens, uma após a outra.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param dEmisDe, date, Emissão inicial
@param dEmisAte, date, Emissão final
@param cErro, character, Mensagem de retorno (por referência)
@return character, Caminho do arquivo gerado ou vazio
/*/
//-------------------------------------------------------------------
Static Function GeraPed(dEmisDe, dEmisAte, cErro)

    Local cArquivo := ""
    Local cAlias   := ""
    Local cPeriodo := DtoC(dEmisDe) + " a " + DtoC(dEmisAte)
    Local aColsPed := {}
    Local aColsIte := {}
    Local oExec    := Nil
    Local oExcel   := Nil

    // ---------- Aba 1: Pedidos (concluída antes de iniciar a aba 2) ----------
    oExec := FWExecStatement():New(QryPed())
    oExec:SetString(1, xFilial("SC5"))
    oExec:SetDate(2, dEmisDe)
    oExec:SetDate(3, dEmisAte)
    oExec:SetString(4, " ")
    cAlias := oExec:OpenAlias()

    If (cAlias)->(Eof())
        cErro := "Nenhum pedido de venda emitido no período " + cPeriodo + "."
    Else
        aAdd(aColsPed, XlsCol("C5_NUM"))
        aAdd(aColsPed, XlsCol("C5_CLIENTE"))
        aAdd(aColsPed, XlsCol("C5_LOJACLI", , XLS_CENTRO))
        aAdd(aColsPed, XlsCol("C5_EMISSAO", , XLS_CENTRO, XLS_DATA))
        aAdd(aColsPed, XlsCol("C5_CONDPAG", , XLS_CENTRO))

        oExcel := FWMsExcelEx():New()
        XlsEstilo(oExcel)
        XlsAddAba(oExcel, "Pedidos", "Pedidos emitidos de " + cPeriodo, aColsPed, cAlias)
    EndIf

    (cAlias)->(DbCloseArea())
    oExec:Destroy()

    // ---------- Aba 2: Itens (só depois que a aba 1 terminou) ----------
    If ValType(oExcel) == "O"
        oExec := FWExecStatement():New(QryItens())
        oExec:SetString(1, xFilial("SC5"))   // ON  SC5.C5_FILIAL
        oExec:SetString(2, " ")              // ON  SC5.D_E_L_E_T_
        oExec:SetString(3, xFilial("SC6"))   // WHERE SC6.C6_FILIAL
        oExec:SetDate(4, dEmisDe)
        oExec:SetDate(5, dEmisAte)
        oExec:SetString(6, " ")
        cAlias := oExec:OpenAlias()

        aAdd(aColsIte, XlsCol("C6_NUM"))
        aAdd(aColsIte, XlsCol("C6_ITEM", , XLS_CENTRO))
        aAdd(aColsIte, XlsCol("C6_PRODUTO"))
        aAdd(aColsIte, XlsCol("C6_DESCRI"))
        aAdd(aColsIte, XlsCol("C6_QTDVEN", , XLS_DIREITA, XLS_NUMERO, .T.))
        aAdd(aColsIte, XlsCol("C6_PRCVEN", , XLS_DIREITA, XLS_MOEDA))
        aAdd(aColsIte, XlsCol("C6_VALOR", , XLS_DIREITA, XLS_MOEDA, .T.))

        XlsAddAba(oExcel, "Itens", "Itens dos pedidos de " + cPeriodo, aColsIte, cAlias)

        (cAlias)->(DbCloseArea())
        oExec:Destroy()

        cArquivo := XlsArquivo("pedidos")
        If !XlsFinaliza(oExcel, cArquivo)
            cErro    := "Não foi possível gravar o arquivo " + cArquivo + "."
            cArquivo := ""
        EndIf
    EndIf

Return cArquivo

//-------------------------------------------------------------------
/*/{Protheus.doc} QryPed
Query dos cabeçalhos de pedidos de venda do período.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@return character, Query tratada por ChangeQuery
/*/
//-------------------------------------------------------------------
Static Function QryPed()

    Local cQuery := ""

    cQuery := "SELECT SC5.C5_NUM, SC5.C5_CLIENTE, SC5.C5_LOJACLI, SC5.C5_EMISSAO, SC5.C5_CONDPAG"
    cQuery += "  FROM " + RetSqlName("SC5") + " SC5"
    cQuery += " WHERE SC5.C5_FILIAL  = ?"
    cQuery += "   AND SC5.C5_EMISSAO BETWEEN ? AND ?"
    cQuery += "   AND SC5.D_E_L_E_T_ = ?"
    cQuery += " ORDER BY SC5.C5_NUM"

Return ChangeQuery(cQuery)

//-------------------------------------------------------------------
/*/{Protheus.doc} QryItens
Query dos itens dos pedidos de venda do período.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@return character, Query tratada por ChangeQuery
/*/
//-------------------------------------------------------------------
Static Function QryItens()

    Local cQuery := ""

    cQuery := "SELECT SC6.C6_NUM, SC6.C6_ITEM, SC6.C6_PRODUTO, SC6.C6_DESCRI,"
    cQuery += "       SC6.C6_QTDVEN, SC6.C6_PRCVEN, SC6.C6_VALOR"
    cQuery += "  FROM " + RetSqlName("SC6") + " SC6"
    cQuery += " INNER JOIN " + RetSqlName("SC5") + " SC5"
    cQuery += "    ON SC5.C5_FILIAL  = ?"
    cQuery += "   AND SC5.C5_NUM     = SC6.C6_NUM"
    cQuery += "   AND SC5.D_E_L_E_T_ = ?"
    cQuery += " WHERE SC6.C6_FILIAL  = ?"
    cQuery += "   AND SC5.C5_EMISSAO BETWEEN ? AND ?"
    cQuery += "   AND SC6.D_E_L_E_T_ = ?"
    cQuery += " ORDER BY SC6.C6_NUM, SC6.C6_ITEM"

Return ChangeQuery(cQuery)
```

> Atenção à ordem dos binds em `QryItens`: o `?` do `ON` vem antes dos `?`
> do `WHERE`. Os `SetString`/`SetDate` acima seguem essa ordem
> (1 = `C5_FILIAL`, 2 = `SC5.D_E_L_E_T_`, 3 = `C6_FILIAL`, 4/5 = período,
> 6 = `SC6.D_E_L_E_T_`).

## Exemplo 4 — TLPP tipado, pronto para job (xExcelSaldoEstoque)

Arquivo `XEXCEST.tlpp`, autocontido. Mostra: tipagem forte, `Try/Catch`
(exclusivo de TLPP), execução sem interface (schedule/job) gravando no
servidor e destaque de saldo negativo usando a API diretamente, sem os
auxiliares do template.

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

#define XLS_ESQUERDA     1
#define XLS_CENTRO       2
#define XLS_DIREITA      3
#define XLS_GERAL        1
#define XLS_NUMERO       2
#define XLS_MOEDA        3
#define XLS_REMOTE_HTML  5

//-------------------------------------------------------------------
/*/{Protheus.doc} xExcelSaldoEstoque
Exporta o saldo físico e financeiro por produto/armazém (SB2) para
planilha Excel com FWMsExcelEx. Destaca em vermelho saldos negativos.
Pode ser executada pelo menu ou via Schedule/job (sem interface).
@type User Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cLocalDe, character, Armazém inicial (padrão "")
@param cLocalAte, character, Armazém final (padrão "ZZ")
@return logical, .T. quando a planilha foi gerada
@example U_xExcelSaldoEstoque("01", "05")
/*/
//-------------------------------------------------------------------
User Function xExcelSaldoEstoque(cLocalDe as Character, cLocalAte as Character) as Logical

    Local cArquivo := ""  as Character
    Local cErro    := ""  as Character
    Local oErro           as Object

    Default cLocalDe  := ""
    Default cLocalAte := "ZZ"

    Try
        cArquivo := GeraSaldo(cLocalDe, cLocalAte, @cErro)
    Catch oErro
        cArquivo := ""
        cErro    := "Falha ao gerar a planilha de estoque: " + oErro:Description
    EndTry

    If !Empty(cArquivo)
        Entrega(cArquivo)
    ElseIf IsBlind()
        FWLogMsg("WARN", , "XLSEXPORT", "XEXCEST", , "02", cErro)
    Else
        MsgInfo(cErro, "Exportação")
    EndIf

Return !Empty(cArquivo)

//-------------------------------------------------------------------
/*/{Protheus.doc} GeraSaldo
Consulta os saldos e grava a planilha.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cLocalDe, character, Armazém inicial
@param cLocalAte, character, Armazém final
@param cErro, character, Mensagem de retorno (por referência)
@return character, Caminho do arquivo gerado ou vazio
/*/
//-------------------------------------------------------------------
Static Function GeraSaldo(cLocalDe as Character, cLocalAte as Character, cErro as Character) as Character

    Local cArquivo := ""                        as Character
    Local cAlias   := ""                        as Character
    Local cAba     := "Saldos"                  as Character
    Local cTabela  := "Saldo em estoque - Filial " + AllTrim(cFilAnt) as Character
    Local aLinha   := {}                        as Array
    Local aNegat   := {4, 5}                    as Array   // colunas Saldo e Valor
    Local aTamQtd  := TamSX3("B2_QATU")         as Array
    Local aTamVal  := TamSX3("B2_VATU1")        as Array
    Local nLinhas  := 0                         as Numeric
    Local oExec                                 as Object
    Local oExcel                                as Object

    oExec := FWExecStatement():New(QrySaldo())
    oExec:SetString(1, xFilial("SB1"))
    oExec:SetString(2, " ")
    oExec:SetString(3, xFilial("SB2"))
    oExec:SetString(4, cLocalDe)
    oExec:SetString(5, cLocalAte)
    oExec:SetString(6, " ")
    cAlias := oExec:OpenAlias()

    TCSetField(cAlias, "B2_QATU",  "N", aTamQtd[1], aTamQtd[2])
    TCSetField(cAlias, "B2_VATU1", "N", aTamVal[1], aTamVal[2])

    If (cAlias)->(Eof())
        cErro := "Nenhum saldo encontrado para os armazéns " + cLocalDe + " a " + cLocalAte + "."
    Else
        oExcel := FWMsExcelEx():New()

        oExcel:SetHeaderBold(.T.)
        oExcel:SetFrColorHeader("#FFFFFF")
        oExcel:SetBgColorHeader("#375623")
        oExcel:SetLineBgColor("#FFFFFF")
        oExcel:Set2LineBgColor("#E2EFDA")

        // Estilo de célula aplicado às posições de aNegat quando o saldo é negativo
        oExcel:SetCelBold(.T.)
        oExcel:SetCelFrColor("#9C0006")
        oExcel:SetCelBgColor("#FFC7CE")

        oExcel:AddWorkSheet(cAba)
        oExcel:AddTable(cAba, cTabela)
        oExcel:AddColumn(cAba, cTabela, AllTrim(FWX3Titulo("B2_COD")),   XLS_ESQUERDA, XLS_GERAL)
        oExcel:AddColumn(cAba, cTabela, AllTrim(FWX3Titulo("B1_DESC")),  XLS_ESQUERDA, XLS_GERAL)
        oExcel:AddColumn(cAba, cTabela, AllTrim(FWX3Titulo("B2_LOCAL")), XLS_CENTRO,   XLS_GERAL)
        oExcel:AddColumn(cAba, cTabela, AllTrim(FWX3Titulo("B2_QATU")),  XLS_DIREITA,  XLS_NUMERO, .T.)
        oExcel:AddColumn(cAba, cTabela, AllTrim(FWX3Titulo("B2_VATU1")), XLS_DIREITA,  XLS_MOEDA,  .T.)

        While !(cAlias)->(Eof())
            aLinha := {;
                AllTrim((cAlias)->B2_COD),;
                AllTrim((cAlias)->B1_DESC),;
                AllTrim((cAlias)->B2_LOCAL),;
                (cAlias)->B2_QATU,;
                (cAlias)->B2_VATU1;
            }

            If (cAlias)->B2_QATU < 0
                oExcel:AddRow(cAba, cTabela, aLinha, aNegat)
            Else
                oExcel:AddRow(cAba, cTabela, aLinha)
            EndIf

            nLinhas++
            (cAlias)->(DbSkip())
        EndDo

        cArquivo := Destino("saldo_estoque")
        oExcel:Activate()
        If !oExcel:GetXMLFile(cArquivo)
            cErro    := "Não foi possível gravar o arquivo " + cArquivo + "."
            cArquivo := ""
        EndIf
        oExcel:DeActivate()
        FreeObj(oExcel)

        FWLogMsg("INFO", , "XLSEXPORT", "XEXCEST", , "01", cValToChar(nLinhas) + " linhas exportadas")
    EndIf

    (cAlias)->(DbCloseArea())
    oExec:Destroy()

Return cArquivo

//-------------------------------------------------------------------
/*/{Protheus.doc} QrySaldo
Query de saldos por produto e armazém com parâmetros de bind.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@return character, Query tratada por ChangeQuery
/*/
//-------------------------------------------------------------------
Static Function QrySaldo() as Character

    Local cQuery := "" as Character

    cQuery := "SELECT SB2.B2_COD, SB1.B1_DESC, SB2.B2_LOCAL, SB2.B2_QATU, SB2.B2_VATU1"
    cQuery += "  FROM " + RetSqlName("SB2") + " SB2"
    cQuery += " INNER JOIN " + RetSqlName("SB1") + " SB1"
    cQuery += "    ON SB1.B1_FILIAL  = ?"
    cQuery += "   AND SB1.B1_COD     = SB2.B2_COD"
    cQuery += "   AND SB1.D_E_L_E_T_ = ?"
    cQuery += " WHERE SB2.B2_FILIAL  = ?"
    cQuery += "   AND SB2.B2_LOCAL BETWEEN ? AND ?"
    cQuery += "   AND SB2.D_E_L_E_T_ = ?"
    cQuery += " ORDER BY SB2.B2_COD, SB2.B2_LOCAL"

Return ChangeQuery(cQuery)

//-------------------------------------------------------------------
/*/{Protheus.doc} Destino
Caminho único do arquivo: servidor (MV_XDIRXLS) em job/WebApp ou
pasta temporária da estação no SmartClient.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cPrefixo, character, Prefixo do nome do arquivo
@return character, Caminho completo com extensão .xml
/*/
//-------------------------------------------------------------------
Static Function Destino(cPrefixo as Character) as Character

    Local cDir := "" as Character

    If IsBlind() .Or. GetRemoteType() == XLS_REMOTE_HTML
        cDir := AllTrim(SuperGetMV("MV_XDIRXLS", .F., "\spool\"))
        If Right(cDir, 1) != "\"
            cDir += "\"
        EndIf
        If !ExistDir(cDir)
            MakeDir(cDir)
        EndIf
    Else
        cDir := GetTempPath()
    EndIf

Return cDir + cPrefixo + "_" + DtoS(Date()) + "_" + StrTran(Time(), ":", "") + "_" + cValToChar(ThreadId()) + ".xml"

//-------------------------------------------------------------------
/*/{Protheus.doc} Entrega
Entrega a planilha conforme o contexto de execução.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cArquivo, character, Caminho completo do arquivo
@return nil
/*/
//-------------------------------------------------------------------
Static Function Entrega(cArquivo as Character)

    If IsBlind()
        FWLogMsg("INFO", , "XLSEXPORT", "XEXCEST", , "03", "Planilha gerada em " + cArquivo)
    ElseIf GetRemoteType() == XLS_REMOTE_HTML
        CpyS2TW(cArquivo, .T.)
    ElseIf MsgYesNo("Planilha gerada em " + cArquivo + CRLF + "Deseja abrir agora?", "Exportação")
        ShellExecute("open", cArquivo, "", GetTempPath(), 1)
    EndIf

Return Nil
```

> Em job/schedule o ambiente (empresa/filial) já vem preparado pelo
> agendador — não chame `RpcSetEnv` dentro da rotina. Para disparar por
> `StartJob`, prepare o ambiente na função chamadora.

## Parâmetros customizados sugeridos (SX6)

Os exemplos funcionam com os valores padrão abaixo caso o parâmetro não
exista (`SuperGetMV(..., .F., xPadrao)`). Crie-os no Configurador para
permitir ajuste sem recompilar.

| Parâmetro | Tipo | Padrão | Uso |
| --- | --- | --- | --- |
| `MV_XDIRXLS` | C | `\spool\` | Pasta do servidor (relativa ao RootPath) para planilhas geradas em job ou WebApp |
| `MV_XDIASAT` | N | `30` | Dias de atraso a partir dos quais o exemplo 2 destaca a célula |
