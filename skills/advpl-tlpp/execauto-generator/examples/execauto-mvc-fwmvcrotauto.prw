#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FWMVCDef.ch"

/*/{Protheus.doc} xRotAutoZZ1
    Exemplo de ExecAuto MVC via FWMVCRotAuto.
    Mais enxuto que FWLoadModel: indicado quando não há necessidade de
    acessar submodelos separadamente ou quando a rotina é uma customização própria.

    Sintaxe:
    FWMVCRotAuto(oModel, cAlias, nOpcAuto, aAuto, lSeek, lPosaRot) -> lRetorno

    Parâmetros:
    - oModel    : Objeto do modelo (StaticCall ou FWLoadModel)
    - cAlias    : Alias do browse principal
    - nOpcAuto  : 3=Inclusão | 4=Alteração | 5=Exclusão (ou MODEL_OPERATION_*)
    - aAuto     : Array com os dados — {{"ALIAS_FORM", aDados}}
                  Para múltiplos forms: {{"ZZ2MASTER", aCab}, {"ZZ3DETAIL", aItens}}
    - lSeek     : .T. = posiciona o arquivo principal com base nos dados fornecidos
    - lPosaRot  : .T. = nOpc não é calculado com base no aRotina

    @type  Function
    @author Fernando Vernier
    @since 01/06/2025
/*/
User Function xRotAutoZZ1()

    Local aArea         := GetArea()
    Local aDados        := {}
    Local aErro         := {}
    Local cMessage      := ""

    // FWMVCRotAuto exige aRotina e oModel como Private
    Private aRotina     := StaticCall(zModel1, MenuDef)
    Private oModel      := StaticCall(zModel1, ModelDef)
    Private lMsErroAuto := .F.

    //--------------------------------------------------------------------
    // INCLUSÃO via FWMVCRotAuto — model simples (sem itens)
    //--------------------------------------------------------------------
    AADD(aDados, {"ZZ1_DESC", "TESTE ROT AUTO", Nil})

    lMsErroAuto := .F.

    FWMVCRotAuto(oModel,;               // Model da rotina
                 "ZZ1",;               // Alias do browse principal
                 MODEL_OPERATION_INSERT,; // Operação: 3=Inclusão
                 {{"FORMZZ1", aDados}}) // {{"ALIAS_DO_FORM", aArray}}

    If lMsErroAuto
        MostraErro()
    Else
        ConOut("Registro incluído com sucesso!")
    EndIf

    //--------------------------------------------------------------------
    // EXCLUSÃO via FWMVCRotAuto — informando apenas a chave
    //--------------------------------------------------------------------
    Local aChave := {}
    AADD(aChave, {"ZZ1_COD", "000001", Nil})

    lMsErroAuto := .F.

    FWMVCRotAuto(oModel,;
                 "ZZ1",;
                 MODEL_OPERATION_DELETE,; // Operação: 5=Exclusão
                 {{"FORMZZ1", aChave}},;
                 .T.)                    // lSeek = .T.: posiciona pelo dado fornecido

    If lMsErroAuto
        MostraErro()
    Else
        ConOut("Registro excluído com sucesso!")
    EndIf

    //--------------------------------------------------------------------
    // INCLUSÃO com múltiplos forms (cabeçalho + itens)
    //--------------------------------------------------------------------
    Local aAutoCab  := {}
    Local aAutoItens := {}

    AADD(aAutoCab,   {"ZZ2_COD" , "000001"    , Nil})
    AADD(aAutoCab,   {"ZZ2_DESC", "CABECALHO" , Nil})
    AADD(aAutoItens, {"ZZ3_ITEM", "01"        , Nil})
    AADD(aAutoItens, {"ZZ3_DESC", "ITEM 01"   , Nil})

    lMsErroAuto := .F.

    FWMVCRotAuto(oModel,;
                 "ZZ2",;
                 MODEL_OPERATION_INSERT,;
                 {{"ZZ2MASTER", aAutoCab}, {"ZZ3DETAIL", aAutoItens}})

    If lMsErroAuto
        MostraErro()
    Else
        ConOut("Cabeçalho e itens incluídos com sucesso!")
    EndIf

    RestArea(aArea)

Return Nil
