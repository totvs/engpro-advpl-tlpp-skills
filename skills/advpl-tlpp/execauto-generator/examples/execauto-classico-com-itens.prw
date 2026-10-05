#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} xInputSC5
    Exemplo de ExecAuto clássico com cabeçalho + itens.
    Demonstra inclusão, alteração e exclusão de Pedido de Venda (SC5/SC6) via MATA410.
    Quando a rotina possui itens, o bloco de código recebe 4 parâmetros: |a, b, c, d|
    @type  Function
    @author Fernando Vernier
    @since 01/06/2025
/*/
User Function xInputSC5()

    Local nOpcX     := 3        // 3=Inclusão | 4=Alteração | 5=Exclusão
    Local cDoc      := ""       // Número do pedido (necessário para alteração/exclusão)
    Local cA1Cod    := "000001"
    Local cA1Loja   := "01"
    Local cB1Cod    := "000001"
    Local cF4TES    := "501"
    Local cE4Codigo := "001"
    Local aCabec    := {}
    Local aItens    := {}
    Local aLinha    := {}
    Local nX        := 0

    Private lMsErroAuto    := .F.
    Private lMsHelpAuto    := .T.
    Private lAutoErrNoFile := .F.

    PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" MODULO "FAT" TABLES "SC5","SC6","SA1","SB1","SF4","SE4"

        //--------------------------------------------------------------------
        // INCLUSÃO
        //--------------------------------------------------------------------
        IF nOpcX == 3

            cDoc   := GetSxeNum("SC5", "C5_NUM")
            RollBackSx8()

            aCabec := {}
            aItens := {}

            AADD(aCabec, {"C5_NUM"    , cDoc      , Nil})
            AADD(aCabec, {"C5_TIPO"   , "N"       , Nil})
            AADD(aCabec, {"C5_CLIENTE", cA1Cod    , Nil})
            AADD(aCabec, {"C5_LOJACLI", cA1Loja   , Nil})
            AADD(aCabec, {"C5_LOJAENT", cA1Loja   , Nil})
            AADD(aCabec, {"C5_CONDPAG", cE4Codigo , Nil})

            For nX := 1 To 1
                aLinha := {}
                AADD(aLinha, {"C6_ITEM"   , StrZero(nX, 2) , Nil})
                AADD(aLinha, {"C6_PRODUTO", cB1Cod          , Nil})
                AADD(aLinha, {"C6_QTDVEN" , 1               , Nil})
                AADD(aLinha, {"C6_PRCVEN" , 1000            , Nil})
                AADD(aLinha, {"C6_PRUNIT" , 1000            , Nil})
                AADD(aLinha, {"C6_VALOR"  , 1000            , Nil})
                AADD(aLinha, {"C6_TES"    , cF4TES          , Nil})
                AADD(aItens, aLinha) // aItens é um array de arrays (cada linha = um item)
            Next nX

            lMsErroAuto := .F.

            // Rotinas com itens usam 4 parâmetros no bloco: |a, b, c, d|
            // Parâmetros: cabeçalho, itens, nOpc, lParam adicional (opcional, varia por rotina)
            MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcX, .F.)

            If lMsErroAuto
                MostraErro()
            Else
                ConOut("Pedido incluído com sucesso: " + cDoc)
            EndIf

        //--------------------------------------------------------------------
        // ALTERAÇÃO
        //--------------------------------------------------------------------
        ELSEIF nOpcX == 4

            aCabec := {}
            aItens := {}
            aLinha := {}

            AADD(aCabec, {"C5_NUM"    , cDoc      , Nil})
            AADD(aCabec, {"C5_TIPO"   , "N"       , Nil})
            AADD(aCabec, {"C5_CLIENTE", cA1Cod    , Nil})
            AADD(aCabec, {"C5_LOJACLI", cA1Loja   , Nil})
            AADD(aCabec, {"C5_LOJAENT", cA1Loja   , Nil})
            AADD(aCabec, {"C5_CONDPAG", cE4Codigo , Nil})

            For nX := 1 To 1
                aLinha := {}
                // LINPOS indica qual linha será alterada (referencia C6_ITEM)
                AADD(aLinha, {"LINPOS"    , "C6_ITEM" , StrZero(nX, 2)})
                AADD(aLinha, {"AUTDELETA" , "N"       , Nil})
                AADD(aLinha, {"C6_PRODUTO", cB1Cod    , Nil})
                AADD(aLinha, {"C6_QTDVEN" , 2         , Nil})
                AADD(aLinha, {"C6_PRCVEN" , 2000      , Nil})
                AADD(aLinha, {"C6_PRUNIT" , 2000      , Nil})
                AADD(aLinha, {"C6_VALOR"  , 4000      , Nil})
                AADD(aLinha, {"C6_TES"    , cF4TES    , Nil})
                AADD(aItens, aLinha)
            Next nX

            lMsErroAuto := .F.

            MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcX, .F.)

            If lMsErroAuto
                MostraErro()
            Else
                ConOut("Pedido alterado com sucesso: " + cDoc)
            EndIf

        //--------------------------------------------------------------------
        // EXCLUSÃO
        //--------------------------------------------------------------------
        ELSEIF nOpcX == 5

            aCabec := {}
            aItens := {}

            AADD(aCabec, {"C5_NUM"    , cDoc      , Nil})
            AADD(aCabec, {"C5_TIPO"   , "N"       , Nil})
            AADD(aCabec, {"C5_CLIENTE", cA1Cod    , Nil})
            AADD(aCabec, {"C5_LOJACLI", cA1Loja   , Nil})
            AADD(aCabec, {"C5_LOJAENT", cA1Loja   , Nil})
            AADD(aCabec, {"C5_CONDPAG", cE4Codigo , Nil})

            lMsErroAuto := .F.

            // Exclusão: bloco com 3 parâmetros |a, b, c|, sem itens relevantes
            MSExecAuto({|a, b, c| MATA410(a, b, c)}, aCabec, aItens, 5)

            If lMsErroAuto
                MostraErro()
            Else
                ConOut("Pedido excluído com sucesso: " + cDoc)
            EndIf

        EndIf

    RESET ENVIRONMENT

Return .T.
