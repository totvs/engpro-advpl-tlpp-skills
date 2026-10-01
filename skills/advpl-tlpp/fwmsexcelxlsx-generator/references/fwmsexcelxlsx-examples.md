# FwMsExcelXlsx — Template base e exemplos de customização

Exemplos com a classe **padrão** `FwMsExcelXlsx` (`.xlsx` nativo). Todos usam
`User Function` (rotina pública da customização) e `Static Function`
(auxiliares privados), seguindo as boas práticas de programação
AdvPL/TLPP descritas no `SKILL.md`. Para a classe legada `FWMsExcelEx`, veja
[legacy-fwmsexcelex-examples.md](legacy-fwmsexcelex-examples.md) — somente
com pedido explícito do usuário.

## Sumário

- [Como usar este arquivo](#como-usar-este-arquivo)
- [Template base (.prw) — auxiliares reutilizáveis](#template-base-prw--auxiliares-reutilizáveis)
- [Exemplo 1 — Cadastro simples: clientes ativos (XLSXSA1)](#exemplo-1--cadastro-simples-clientes-ativos-xlsxsa1)
- [Exemplo 2 — Totais e coluna de situação: títulos vencidos (XLSXSE1)](#exemplo-2--totais-e-coluna-de-situação-títulos-vencidos-xlsxse1)
- [Exemplo 3 — Várias abas em sequência: pedidos e itens (XLSXMULT)](#exemplo-3--várias-abas-em-sequência-pedidos-e-itens-xlsxmult)
- [Exemplo 4 — TLPP para job com grande volume (xXlsxSaldoEstoque)](#exemplo-4--tlpp-para-job-com-grande-volume-xxlsxsaldoestoque)
- [Parâmetros customizados sugeridos (SX6)](#parâmetros-customizados-sugeridos-sx6)

## Como usar este arquivo

- Os exemplos 1, 2 e 3 são fontes `.prw` independentes. `Static Function` só é
  visível dentro do próprio fonte, então **cada `.prw` deve conter o bloco
  "Template base" inteiro** além da sua `User Function`.
- O exemplo 4 (TLPP) é autocontido.
- Ajuste os nomes ao padrão do cliente. Em `.prw`, nome de `User Function`
  com no máximo 8 caracteres.
- Depois de gerar, salve o fonte em Windows-1252 (CP1252) — o compilador do
  Protheus não aceita UTF-8 (veja o passo 10 do workflow no `SKILL.md`).

## Template base (.prw) — auxiliares reutilizáveis

Fluxo coberto pelos auxiliares: verificar a `printer.exe` → montar as abas a
partir de `aCols` → gravar o `.xlsx` no servidor → entregar conforme o
contexto (SmartClient, WebApp ou job).

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

// Ambiente
#define XLS_REMOTE_HTML  5         // GetRemoteType() do SmartClient HTML (WebApp)
#define XLS_PRINTER_MIN  "2.1.0"   // versão mínima da printer.exe para .xlsx

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
/*/{Protheus.doc} XlsPronto
Verifica se a printer.exe do AppServer suporta a geração de .xlsx.
Sem esta checagem a FwMsExcelXlsx lança exceção na geração.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cErro, character, Mensagem de retorno (por referência)
@return logical, .T. quando o ambiente atende
/*/
//-------------------------------------------------------------------
Static Function XlsPronto(cErro)

    Local lOk     := .F.
    Local cVersao := AllTrim(PrinterVersion():fromServer())

    lOk := XlsVersao(cVersao, XLS_PRINTER_MIN)

    If !lOk
        If Empty(cVersao)
            cVersao := "não encontrada"
        EndIf
        cErro := "A geração de planilhas .xlsx exige printer.exe " + XLS_PRINTER_MIN
        cErro += " ou superior no AppServer (versão atual: " + cVersao + ")."
        cErro += " Atualize a printer.exe pela Central de Downloads."
    EndIf

Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsVersao
Compara versões no formato N.N.N por segmento numérico
(comparação de string falharia em "10.0.0" x "2.1.0").
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cAtual, character, Versão instalada
@param cMinima, character, Versão mínima exigida
@return logical, .T. quando cAtual >= cMinima
/*/
//-------------------------------------------------------------------
Static Function XlsVersao(cAtual, cMinima)

    Local aAtual  := StrTokArr(cAtual, ".")
    Local aMinima := StrTokArr(cMinima, ".")
    Local nPos    := 0
    Local nAtual  := 0
    Local lOk     := !Empty(cAtual)
    Local lMaior  := .F.

    For nPos := 1 To Len(aMinima)
        If !lOk .Or. lMaior
            Exit
        EndIf

        nAtual := 0
        If nPos <= Len(aAtual)
            nAtual := Val(aAtual[nPos])
        EndIf

        If nAtual > Val(aMinima[nPos])
            lMaior := .T.
        ElseIf nAtual < Val(aMinima[nPos])
            lOk := .F.
        EndIf
    Next nPos

Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsFonte
Define a fonte padrão da planilha. Na FwMsExcelXlsx a fonte vale para
todos os estilos (título, cabeçalho e linhas). Chamar logo após New().
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param oExcel, object, Instância de FwMsExcelXlsx
@return nil
/*/
//-------------------------------------------------------------------
Static Function XlsFonte(oExcel)

    oExcel:SetFont("Calibri")
    oExcel:SetFontSize(11)

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsAddAba
Cria uma aba COMPLETA (aba, tabela, colunas e todas as linhas) a partir
de um alias de query já aberto. Termine esta aba antes de criar outra:
é obrigatório com SetWriteinFile(.T.) e mantém o código seguro em memória.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param oExcel, object, Instância de FwMsExcelXlsx
@param cAba, character, Nome da aba (até 30 caracteres)
@param cTabela, character, Título da tabela
@param aCols, array, Colunas montadas com XlsCol()
@param cAlias, character, Alias da query de origem
@return numeric, Quantidade de linhas gravadas
/*/
//-------------------------------------------------------------------
Static Function XlsAddAba(oExcel, cAba, cTabela, aCols, cAlias)

    Local nLinhas := 0
    Local nCol    := 0
    Local cTitulo := ""
    Local aLinha  := {}

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

        oExcel:AddRow(cAba, cTabela, aLinha)

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
Caminho completo e único do .xlsx no SERVIDOR (MV_XDIRXLS). A planilha é
montada pela printer.exe do AppServer; a cópia para a estação é feita
depois em XlsEntrega().
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cPrefixo, character, Prefixo do nome do arquivo
@return character, Caminho completo com extensão .xlsx
/*/
//-------------------------------------------------------------------
Static Function XlsArquivo(cPrefixo)

    Local cDir  := AllTrim(SuperGetMV("MV_XDIRXLS", .F., "\spool\"))
    Local cNome := ""

    If Right(cDir, 1) != "\"
        cDir += "\"
    EndIf
    If !ExistDir(cDir)
        MakeDir(cDir)
    EndIf

    cNome := Lower(cPrefixo) + "_" + DtoS(Date()) + "_" + StrTran(Time(), ":", "")
    cNome += "_" + cValToChar(ThreadId()) + ".xlsx"

Return cDir + cNome

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsFinaliza
Fecha a montagem, grava o arquivo e libera o objeto.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param oExcel, object, Instância de FwMsExcelXlsx com ao menos uma linha
@param cArquivo, character, Caminho completo do arquivo no servidor
@return logical, .T. quando o arquivo foi gravado
/*/
//-------------------------------------------------------------------
Static Function XlsFinaliza(oExcel, cArquivo)

    Local lOk := .F.

    oExcel:Activate()
    lOk := oExcel:GetXMLFile(cArquivo) .And. File(cArquivo)
    oExcel:DeActivate()
    FreeObj(oExcel)

Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} XlsEntrega
Entrega a planilha gravada no servidor conforme o contexto:
job mantém no servidor; WebApp baixa no navegador; SmartClient copia
para a pasta temporária da estação e oferece abrir.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cArquivo, character, Caminho completo do arquivo no servidor
@return nil
/*/
//-------------------------------------------------------------------
Static Function XlsEntrega(cArquivo)

    Local cDirLocal := ""
    Local cNome     := ""

    If IsBlind()
        FWLogMsg("INFO", , "XLSEXPORT", FunName(), , "01", "Planilha gerada em " + cArquivo)
    ElseIf GetRemoteType() == XLS_REMOTE_HTML
        CpyS2TW(cArquivo, .T.)
    Else
        cDirLocal := GetTempPath()
        cNome     := SubStr(cArquivo, RAt("\", cArquivo) + 1)
        If CpyS2T(cArquivo, cDirLocal, .T.)
            FErase(cArquivo)
            If MsgYesNo("Planilha gerada em " + cDirLocal + cNome + CRLF + "Deseja abrir agora?", "Exportação")
                ShellExecute("open", cDirLocal + cNome, "", cDirLocal, 1)
            EndIf
        Else
            MsgStop("Não foi possível copiar a planilha para a estação. Arquivo no servidor: " + cArquivo, "Exportação")
        EndIf
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

## Exemplo 1 — Cadastro simples: clientes ativos (XLSXSA1)

Arquivo `XLSXSA1.prw` = **Template base** + o código abaixo. Fluxo mínimo:
verificação da `printer.exe`, query parametrizada, colunas vindas do
dicionário, tratamento de "sem dados" e entrega por contexto.

```advpl
//-------------------------------------------------------------------
/*/{Protheus.doc} XLSXSA1
Exporta os clientes ativos (não bloqueados) da filial corrente para
planilha .xlsx usando FwMsExcelXlsx.
@type User Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@return logical, .T. quando a planilha foi gerada
@example U_XLSXSA1()
/*/
//-------------------------------------------------------------------
User Function XLSXSA1()

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

    If XlsPronto(@cErro)
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

            oExcel := FwMsExcelXlsx():New()
            XlsFonte(oExcel)
            XlsAddAba(oExcel, cAba, cTabela, aCols, cAlias)

            cArquivo := XlsArquivo("clientes")
            If !XlsFinaliza(oExcel, cArquivo)
                cErro    := "Não foi possível gravar o arquivo " + cArquivo + "."
                cArquivo := ""
            EndIf
        EndIf

        (cAlias)->(DbCloseArea())
        oExec:Destroy()
    EndIf

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

## Exemplo 2 — Totais e coluna de situação: títulos vencidos (XLSXSE1)

Arquivo `XLSXSE1.prw` = **Template base** + o código abaixo. Mostra
parâmetros via `ParamBox` (somente com interface), colunas calculadas,
colunas monetárias totalizadas e — como a `FwMsExcelXlsx` não tem estilo por
célula — uma **coluna "Situação"** que permite filtrar os casos críticos no
Excel.

```advpl
//-------------------------------------------------------------------
/*/{Protheus.doc} XLSXSE1
Exporta os títulos a receber vencidos e em aberto, classificando como
CRÍTICO os que ultrapassam MV_XDIASAT dias de atraso (padrão 30).
@type User Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param dVencDe, date, Vencimento real inicial (job); padrão dDataBase - 365
@param dVencAte, date, Vencimento real final (job); padrão dDataBase - 1
@return logical, .T. quando a planilha foi gerada
@example U_XLSXSE1()
/*/
//-------------------------------------------------------------------
User Function XLSXSE1(dVencDe, dVencAte)

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
Consulta os títulos e grava a planilha.
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
    Local oExec     := Nil
    Local oExcel    := Nil

    If XlsPronto(@cErro)
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
            aAdd(aCols, XlsCol("SITUACAO", "Situação", XLS_CENTRO, XLS_GERAL, .F., {|cAli| SituaSE1(cAli, nDiasCrit) }))
            aAdd(aCols, XlsCol("E1_VALOR", , XLS_DIREITA, XLS_MOEDA, .T.))
            aAdd(aCols, XlsCol("E1_SALDO", , XLS_DIREITA, XLS_MOEDA, .T.))

            oExcel := FwMsExcelXlsx():New()
            XlsFonte(oExcel)
            XlsAddAba(oExcel, cAba, cTabela, aCols, cAlias)

            cArquivo := XlsArquivo("vencidos")
            If !XlsFinaliza(oExcel, cArquivo)
                cErro    := "Não foi possível gravar o arquivo " + cArquivo + "."
                cArquivo := ""
            EndIf
        EndIf

        (cAlias)->(DbCloseArea())
        oExec:Destroy()
    EndIf

Return cArquivo

//-------------------------------------------------------------------
/*/{Protheus.doc} SituaSE1
Classifica o título conforme os dias de atraso.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cAlias, character, Alias posicionado
@param nDiasCrit, numeric, Dias de atraso a partir dos quais é crítico
@return character, "CRÍTICO" ou "EM ATRASO"
/*/
//-------------------------------------------------------------------
Static Function SituaSE1(cAlias, nDiasCrit)

    Local cSituacao := "EM ATRASO"

    If dDataBase - (cAlias)->E1_VENCREA > nDiasCrit
        cSituacao := "CRÍTICO"
    EndIf

Return cSituacao

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

> Precisa de cor de fundo na célula crítica? A `FwMsExcelXlsx` não oferece.
> Alternativas: a coluna "Situação" acima (filtrável/formatável no Excel), a
> `FwPrinterXlsx` (controle célula a célula) ou — só se o usuário pedir
> explicitamente — a legada `FWMsExcelEx` com `aCelStyle`.

## Exemplo 3 — Várias abas em sequência: pedidos e itens (XLSXMULT)

Arquivo `XLSXMULT.prw` = **Template base** + o código abaixo. Cada aba é
concluída antes da próxima (uma query por aba, aberta e fechada em
sequência), o que mantém o fonte compatível com `SetWriteinFile(.T.)`.

```advpl
//-------------------------------------------------------------------
/*/{Protheus.doc} XLSXMULT
Exporta os pedidos de venda emitidos no período em duas abas:
"Pedidos" (SC5) e "Itens" (SC6).
@type User Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param dEmisDe, date, Emissão inicial (job); padrão primeiro dia do mês
@param dEmisAte, date, Emissão final (job); padrão dDataBase
@return logical, .T. quando a planilha foi gerada
@example U_XLSXMULT()
/*/
//-------------------------------------------------------------------
User Function XLSXMULT(dEmisDe, dEmisAte)

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

    If XlsPronto(@cErro)
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

            oExcel := FwMsExcelXlsx():New()
            XlsFonte(oExcel)
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
            oExec:SetString(6, " ")              // WHERE SC6.D_E_L_E_T_
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

## Exemplo 4 — TLPP para job com grande volume (xXlsxSaldoEstoque)

Arquivo `XLSXEST.tlpp`, autocontido. Mostra tipagem forte, `Try/Catch`
(exclusivo de TLPP), execução sem interface (schedule/job), verificação da
`printer.exe` e **gravação direta em arquivo** com `SetWriteinFile(.T.)` —
evita estourar a memória do AppServer em volumes grandes.

```tlpp
#include "tlpp-core.th"
#include "totvs.ch"

#define XLS_ESQUERDA       1
#define XLS_CENTRO         2
#define XLS_DIREITA        3
#define XLS_GERAL          1
#define XLS_NUMERO         2
#define XLS_MOEDA          3
#define XLS_REMOTE_HTML    5
#define XLS_PRINTER_MIN    "2.1.0"

//-------------------------------------------------------------------
/*/{Protheus.doc} xXlsxSaldoEstoque
Exporta o saldo físico e financeiro por produto/armazém (SB2) para
planilha .xlsx com FwMsExcelXlsx. Pode ser executada pelo menu ou via
Schedule/job (sem interface).
@type User Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cLocalDe, character, Armazém inicial (padrão "")
@param cLocalAte, character, Armazém final (padrão "ZZ")
@return logical, .T. quando a planilha foi gerada
@example U_xXlsxSaldoEstoque("01", "05")
/*/
//-------------------------------------------------------------------
User Function xXlsxSaldoEstoque(cLocalDe as Character, cLocalAte as Character) as Logical

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
        FWLogMsg("WARN", , "XLSEXPORT", "XLSXEST", , "02", cErro)
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
    Local cPrinter := AllTrim(PrinterVersion():fromServer()) as Character
    Local aLinha   := {}                        as Array
    Local aTamQtd  := TamSX3("B2_QATU")         as Array
    Local aTamVal  := TamSX3("B2_VATU1")        as Array
    Local nLinhas  := 0                         as Numeric
    Local oExec                                 as Object
    Local oExcel                                as Object

    If !VersaoOk(cPrinter, XLS_PRINTER_MIN)
        cErro := "A geração de .xlsx exige printer.exe " + XLS_PRINTER_MIN + " ou superior no AppServer (atual: '" + cPrinter + "')."
    Else
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
            oExcel := FwMsExcelXlsx():New()

            // Grandes volumes: grava direto em arquivo (antes de qualquer AddRow)
            oExcel:SetWriteinFile(.T.)

            // Fonte global: com SetWriteinFile ativo precisa vir antes das linhas
            oExcel:SetFont("Calibri")
            oExcel:SetFontSize(11)

            oExcel:AddWorkSheet(cAba)
            oExcel:AddTable(cAba, cTabela)
            oExcel:AddColumn(cAba, cTabela, AllTrim(FWX3Titulo("B2_COD")),   XLS_ESQUERDA, XLS_GERAL)
            oExcel:AddColumn(cAba, cTabela, AllTrim(FWX3Titulo("B1_DESC")),  XLS_ESQUERDA, XLS_GERAL)
            oExcel:AddColumn(cAba, cTabela, AllTrim(FWX3Titulo("B2_LOCAL")), XLS_CENTRO,   XLS_GERAL)
            oExcel:AddColumn(cAba, cTabela, AllTrim(FWX3Titulo("B2_QATU")),  XLS_DIREITA,  XLS_NUMERO, .T.)
            oExcel:AddColumn(cAba, cTabela, AllTrim(FWX3Titulo("B2_VATU1")), XLS_DIREITA,  XLS_MOEDA,  .T.)
            oExcel:AddColumn(cAba, cTabela, "Situação",                      XLS_CENTRO,   XLS_GERAL)

            While !(cAlias)->(Eof())
                aLinha := {;
                    AllTrim((cAlias)->B2_COD),;
                    AllTrim((cAlias)->B1_DESC),;
                    AllTrim((cAlias)->B2_LOCAL),;
                    (cAlias)->B2_QATU,;
                    (cAlias)->B2_VATU1,;
                    Situacao((cAlias)->B2_QATU);
                }
                oExcel:AddRow(cAba, cTabela, aLinha)

                nLinhas++
                (cAlias)->(DbSkip())
            EndDo

            cArquivo := Destino("saldo_estoque")
            oExcel:Activate()
            If !oExcel:GetXMLFile(cArquivo) .Or. !File(cArquivo)
                cErro    := "Não foi possível gravar o arquivo " + cArquivo + "."
                cArquivo := ""
            EndIf
            oExcel:DeActivate()
            FreeObj(oExcel)

            FWLogMsg("INFO", , "XLSEXPORT", "XLSXEST", , "01", cValToChar(nLinhas) + " linhas exportadas")
        EndIf

        (cAlias)->(DbCloseArea())
        oExec:Destroy()
    EndIf

Return cArquivo

//-------------------------------------------------------------------
/*/{Protheus.doc} Situacao
Classifica o saldo físico do produto.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param nSaldo, numeric, Saldo físico
@return character, "NEGATIVO", "ZERADO" ou "OK"
/*/
//-------------------------------------------------------------------
Static Function Situacao(nSaldo as Numeric) as Character

    Local cSituacao := "OK" as Character

    If nSaldo < 0
        cSituacao := "NEGATIVO"
    ElseIf nSaldo == 0
        cSituacao := "ZERADO"
    EndIf

Return cSituacao

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
/*/{Protheus.doc} VersaoOk
Compara versões N.N.N por segmento numérico.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cAtual, character, Versão instalada
@param cMinima, character, Versão mínima exigida
@return logical, .T. quando cAtual >= cMinima
/*/
//-------------------------------------------------------------------
Static Function VersaoOk(cAtual as Character, cMinima as Character) as Logical

    Local aAtual  := StrTokArr(cAtual, ".")  as Array
    Local aMinima := StrTokArr(cMinima, ".") as Array
    Local nPos    := 0                       as Numeric
    Local nAtual  := 0                       as Numeric
    Local lOk     := !Empty(cAtual)          as Logical
    Local lMaior  := .F.                     as Logical

    For nPos := 1 To Len(aMinima)
        If !lOk .Or. lMaior
            Exit
        EndIf

        nAtual := 0
        If nPos <= Len(aAtual)
            nAtual := Val(aAtual[nPos])
        EndIf

        If nAtual > Val(aMinima[nPos])
            lMaior := .T.
        ElseIf nAtual < Val(aMinima[nPos])
            lOk := .F.
        EndIf
    Next nPos

Return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} Destino
Caminho único do .xlsx no servidor (MV_XDIRXLS).
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cPrefixo, character, Prefixo do nome do arquivo
@return character, Caminho completo com extensão .xlsx
/*/
//-------------------------------------------------------------------
Static Function Destino(cPrefixo as Character) as Character

    Local cDir := AllTrim(SuperGetMV("MV_XDIRXLS", .F., "\spool\")) as Character

    If Right(cDir, 1) != "\"
        cDir += "\"
    EndIf
    If !ExistDir(cDir)
        MakeDir(cDir)
    EndIf

Return cDir + cPrefixo + "_" + DtoS(Date()) + "_" + StrTran(Time(), ":", "") + "_" + cValToChar(ThreadId()) + ".xlsx"

//-------------------------------------------------------------------
/*/{Protheus.doc} Entrega
Entrega a planilha gravada no servidor conforme o contexto.
@type Static Function
@author Customizações ADVPL/TLPP
@since 01/10/2026
@param cArquivo, character, Caminho completo do arquivo no servidor
@return nil
/*/
//-------------------------------------------------------------------
Static Function Entrega(cArquivo as Character)

    Local cDirLocal := "" as Character
    Local cNome     := "" as Character

    If IsBlind()
        FWLogMsg("INFO", , "XLSEXPORT", "XLSXEST", , "03", "Planilha gerada em " + cArquivo)
    ElseIf GetRemoteType() == XLS_REMOTE_HTML
        CpyS2TW(cArquivo, .T.)
    Else
        cDirLocal := GetTempPath()
        cNome     := SubStr(cArquivo, RAt("\", cArquivo) + 1)
        If CpyS2T(cArquivo, cDirLocal, .T.)
            FErase(cArquivo)
            If MsgYesNo("Planilha gerada em " + cDirLocal + cNome + CRLF + "Deseja abrir agora?", "Exportação")
                ShellExecute("open", cDirLocal + cNome, "", cDirLocal, 1)
            EndIf
        Else
            MsgStop("Não foi possível copiar a planilha para a estação. Arquivo no servidor: " + cArquivo, "Exportação")
        EndIf
    EndIf

Return Nil
```

> Alternativa a `SetWriteinFile`: `oExcel:SetWriteinDB(.T., 200000)` (exige
> DBAccess ≥ 22.1.1.0), também antes de qualquer `AddRow`. Se
> retornar `.F.`, registre um `FWLogMsg("WARN", ...)` — a geração continua em
> memória. Não combine os dois modos.
>
> Em job/schedule o ambiente (empresa/filial) já vem preparado pelo
> agendador — não chame `RpcSetEnv` dentro da rotina.

## Parâmetros customizados sugeridos (SX6)

Os exemplos funcionam com os valores padrão abaixo caso o parâmetro não
exista (`SuperGetMV(..., .F., xPadrao)`). Crie-os no Configurador para
permitir ajuste sem recompilar.

| Parâmetro | Tipo | Padrão | Uso |
| --- | --- | --- | --- |
| `MV_XDIRXLS` | C | `\spool\` | Pasta do servidor (relativa ao RootPath) onde o `.xlsx` é gerado |
| `MV_XDIASAT` | N | `30` | Dias de atraso a partir dos quais o exemplo 2 classifica como CRÍTICO |
