#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} xInputSE1
    Exemplo de ExecAuto clássico com cabeçalho simples (sem itens).
    Demonstra a inclusão de um título a receber (SE1) via FINA040.
    @type  Function
    @author Fernando Vernier
    @since 01/06/2025
/*/
User Function xInputSE1()

    Local aCab := {}

    // Variáveis de controle — sempre Private, sempre declaradas antes da chamada
    Private lMsErroAuto    := .F.
    Private lMsHelpAuto    := .T.
    Private lAutoErrNoFile := .F. // .F. = exibe erro em tela via MostraErro()
                                  // .T. = captura erros em array via GetAutoGRLog()

    PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" MODULO "FIN"

        // Monta o array de cabeçalho — {"CAMPO", VALOR, Nil}
        AADD(aCab, {"E1_FILIAL"  , xFilial("SE1") , Nil})
        AADD(aCab, {"E1_TIPO"    , "NF"            , Nil})
        AADD(aCab, {"E1_NATUREZ" , "001"           , Nil})
        AADD(aCab, {"E1_CLIFOR"  , "000001"        , Nil})
        AADD(aCab, {"E1_LOJA"    , "01"            , Nil})
        AADD(aCab, {"E1_NUM"     , "000001"        , Nil})
        AADD(aCab, {"E1_PARCELA" , "001"           , Nil})
        AADD(aCab, {"E1_EMISSAO" , Date()          , Nil})
        AADD(aCab, {"E1_VENCTO"  , Date() + 30     , Nil})
        AADD(aCab, {"E1_VALOR"   , 1000.00         , Nil})
        AADD(aCab, {"E1_MOEDA"   , 1               , Nil})

        // Reseta a variável de controle imediatamente antes da chamada
        lMsErroAuto := .F.

        // nOpc: 3=Inclusão | 4=Alteração | 5=Exclusão
        MSExecAuto({|x, y| FINA040(x, y)}, aCab, 3)

        If lMsErroAuto
            MostraErro() // Exibe erros em tela
        Else
            ConOut("SE1 incluído com sucesso!")
        EndIf

    RESET ENVIRONMENT

Return Nil
