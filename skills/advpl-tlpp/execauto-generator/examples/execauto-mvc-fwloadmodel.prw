#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FWMVCDef.ch"

/*/{Protheus.doc} xInputSB1
    Exemplo de ExecAuto MVC via FWLoadModel + GetModel + SetValue.
    Demonstra inclusão e alteração de Produto (SB1/SB5) via MATA010.

    Diferença-chave do padrão MVC:
    - Os campos são setados via GetModel("ALIAS"):SetValue(), não em array direto no model
    - O model pode ter submodelos (ex: SB5DETAIL para complemento do produto)
    - GetErrorMessage() retorna um ARRAY de 9 posições, não uma string
    @type  Function
    @author Fernando Vernier
    @since 01/06/2025
/*/
User Function xInputSB1()

    Local oModel   := Nil
    Local oSB1Mod  := Nil
    Local oSB5Mod  := Nil
    Local aErro    := {}
    Local cMessage := ""
    Local lOk      := .F.
    Local cCod     := "PROD001"
    Local cDesc    := "PRODUTO TESTE MVC"
    Local cTipo    := "PA"
    Local cUM      := "UN"
    Local cLocPad  := "01"
    Local cCEME    := "001"

    Private lMsErroAuto := .F.

    PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" MODULO "EST"

        //--------------------------------------------------------------------
        // INCLUSÃO via FWLoadModel
        //--------------------------------------------------------------------
        oModel := FWLoadModel("MATA010")
        oModel:SetOperation(MODEL_OPERATION_INSERT) // ou o número 3

        oModel:Activate()

        // Acessa o submodelo master pelo alias definido no MVC da rotina
        oSB1Mod := oModel:GetModel("SB1MASTER")
        oSB1Mod:SetValue("B1_COD"   , cCod   )
        oSB1Mod:SetValue("B1_DESC"  , cDesc  )
        oSB1Mod:SetValue("B1_TIPO"  , cTipo  )
        oSB1Mod:SetValue("B1_UM"    , cUM    )
        oSB1Mod:SetValue("B1_LOCPAD", cLocPad)

        // Acessa submodelo de detalhe (complemento do produto), se existir
        oSB5Mod := oModel:GetModel("SB5DETAIL")
        If oSB5Mod != Nil
            oSB5Mod:SetValue("B5_CEME", cCEME)
        EndIf

        // VldData() executa todas as validações do model antes de gravar
        If oModel:VldData()

            // CommitData() retorna .T. se gravou com sucesso
            If oModel:CommitData()
                lOk := .T.
            Else
                lOk := .F.
            EndIf

        Else
            lOk := .F.
        EndIf

        If lOk
            ConOut("Produto incluído com sucesso: " + cCod)
        Else
            // GetErrorMessage() retorna ARRAY com 9 posições — não é string
            aErro := oModel:GetErrorMessage()

            cMessage := "Form origem: "    + "[" + cValToChar(aErro[1]) + "] | "
            cMessage += "Campo origem: "   + "[" + cValToChar(aErro[2]) + "] | "
            cMessage += "Form erro: "      + "[" + cValToChar(aErro[3]) + "] | "
            cMessage += "Campo erro: "     + "[" + cValToChar(aErro[4]) + "] | "
            cMessage += "Id erro: "        + "[" + cValToChar(aErro[5]) + "] | "
            cMessage += "Mensagem: "       + "[" + cValToChar(aErro[6]) + "] | "
            cMessage += "Solução: "        + "[" + cValToChar(aErro[7]) + "] | "
            cMessage += "Valor novo: "     + "[" + cValToChar(aErro[8]) + "] | "
            cMessage += "Valor anterior: " + "[" + cValToChar(aErro[9]) + "]"

            ConOut("Erro na inclusão: " + cMessage)
        EndIf

        // Sempre desativar, destruir e limpar o model ao final
        oModel:DeActivate()
        oModel:Destroy()
        oModel := Nil

        //--------------------------------------------------------------------
        // ALTERAÇÃO via FWLoadModel
        //--------------------------------------------------------------------
        lOk    := .F.
        aErro  := {}
        oModel := FWLoadModel("MATA010")
        oModel:SetOperation(MODEL_OPERATION_UPDATE) // ou o número 4

        oModel:Activate()

        oSB1Mod := oModel:GetModel("SB1MASTER")
        // Em UPDATE, os campos-chave devem ser setados para localizar o registro
        oSB1Mod:SetValue("B1_COD" , cCod           )
        oSB1Mod:SetValue("B1_DESC", "NOVO DESC MVC" )

        If oModel:VldData()
            If oModel:CommitData()
                lOk := .T.
            EndIf
        EndIf

        If lOk
            ConOut("Produto alterado com sucesso: " + cCod)
        Else
            aErro    := oModel:GetErrorMessage()
            cMessage := "Erro na alteração — Mensagem: [" + cValToChar(aErro[6]) + "]"
            ConOut(cMessage)
        EndIf

        oModel:DeActivate()
        oModel:Destroy()
        oModel := Nil

    RESET ENVIRONMENT

Return Nil
