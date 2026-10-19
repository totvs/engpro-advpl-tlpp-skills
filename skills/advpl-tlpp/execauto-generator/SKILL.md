---
name: execauto-generator
description: >-
  Use esta skill para gerar, revisar ou corrigir qualquer código de rotina automática
  (ExecAuto) em ADVPL/TLPP para o ERP Protheus. Ative SEMPRE que o usuário mencionar:
  MSExecAuto, ExecAuto, FWMVCRotAuto, FWLoadModel, rotina automática, GetModel, SetValue,
  CommitData, VldData, inclusão automática, alteração automática, exclusão automática,
  FINA040, MATA010, MATA020, MATA030, MATA103, MATA241, MATA410, MATA750, ou qualquer
  rotina Protheus chamada via código. Ative também para: importar dados via código,
  criar ou alterar registros programaticamente, processar títulos, pedidos, notas fiscais,
  movimentos de estoque, fornecedores, clientes, produtos, ou qualquer entidade do Protheus
  de forma automatizada. Ative para dúvidas como 'como chamar a rotina X via código',
  'como incluir registro na tabela Y', 'como automatizar o cadastro de Z'.
license: MIT
metadata:
  domain: Protheus
  maintainer: Squad ERP
  author: Fernando Vernier
  version: '2.0.0'
  category: code-generation
---

# ExecAuto Generator

Você é especialista em rotinas automáticas ADVPL/TLPP para o ERP Protheus (TOTVS).
Esta skill cobre os três padrões de ExecAuto existentes no Protheus e garante que
o código gerado seja correto, seguro e aderente às boas práticas oficiais da TOTVS.

---

## Os três padrões de ExecAuto

### Padrão 1 — Clássico com cabeçalho simples

Usado em rotinas sem itens. O bloco recebe **2 parâmetros** (`|x, y|`).

```advpl
Private lMsErroAuto    := .F.
Private lMsHelpAuto    := .T.
Private lAutoErrNoFile := .F.

AADD(aCab, {"CAMPO", VALOR, Nil})

lMsErroAuto := .F.
MSExecAuto({|x, y| ROTINA(x, y)}, aCab, nOpc)

If lMsErroAuto
    MostraErro()
EndIf
```

### Padrão 2 — Clássico com cabeçalho e itens

Usado em rotinas com itens (pedidos, notas, movimentos). O bloco recebe **3 ou 4 parâmetros**
dependendo da rotina. O array de itens é sempre um **array de arrays**.

```advpl
// Monta os itens: cada linha é um array adicionado ao array de itens
aLinha := {}
AADD(aLinha, {"CAMPO_ITEM", VALOR, Nil})
AADD(aItens, aLinha) // aItens é um array de arrays

lMsErroAuto := .F.

// 4 parâmetros: cabeçalho, itens, nOpc, [parâmetro extra opcional]
MSExecAuto({|a, b, c, d| MATA410(a, b, c, d)}, aCabec, aItens, nOpcX, .F.)

// 3 parâmetros: quando a rotina não exige parâmetro extra
MSExecAuto({|x, y, z| MATA241(x, y, z)}, _aCab1, _atotitem, 3)
```

### Padrão 3 — MVC

Duas abordagens dentro do padrão MVC:

#### 3a. FWLoadModel + GetModel + SetValue

Abordagem completa. Use quando precisar acessar **submodelos separados** ou quando
quiser controle total sobre cada campo.

```advpl
oModel := FWLoadModel("ROTINA")
oModel:SetOperation(MODEL_OPERATION_INSERT) // ou 3, 4, 5

oModel:Activate()

// Acessa cada submodelo pelo alias definido no MVC da rotina
oMasterMod := oModel:GetModel("ALIAS_MASTER")
oMasterMod:SetValue("CAMPO", VALOR)

oDetailMod := oModel:GetModel("ALIAS_DETAIL")
If oDetailMod != Nil
    oDetailMod:SetValue("CAMPO", VALOR)
EndIf

If oModel:VldData()
    If oModel:CommitData()
        // sucesso
    EndIf
Else
    aErro := oModel:GetErrorMessage() // retorna ARRAY de 9 posições
EndIf

oModel:DeActivate()
oModel:Destroy()
oModel := Nil
```

#### 3b. FWMVCRotAuto

Abordagem enxuta. Use quando o acesso direto ao model é suficiente ou quando
a rotina é uma customização própria com MVC.

```advpl
// Sintaxe completa:
// FWMVCRotAuto(oModel, cAlias, nOpcAuto, aAuto, lSeek, lPosaRot) -> lRetorno

Private aRotina     := StaticCall(MinhaRotina, MenuDef)
Private oModel      := StaticCall(MinhaRotina, ModelDef)
Private lMsErroAuto := .F.

AADD(aDados, {"CAMPO", VALOR, Nil})

lMsErroAuto := .F.
FWMVCRotAuto(oModel, "ALIAS", MODEL_OPERATION_INSERT, {{"ALIAS_FORM", aDados}})

// Com múltiplos forms (cabeçalho + itens):
FWMVCRotAuto(oModel, "ALIAS", MODEL_OPERATION_INSERT,;
    {{"ALIAS_MASTER", aCab}, {"ALIAS_DETAIL", aItens}})

If lMsErroAuto
    MostraErro()
EndIf
```

---

## Regras obrigatórias

### Variáveis de controle

| Variável | Escopo | Valor padrão | Finalidade |
|---|---|---|---|
| `lMsErroAuto` | Private | `.F.` | Sinaliza erro durante a execução |
| `lMsHelpAuto` | Private | `.T.` | Habilita captura de mensagens de erro |
| `lAutoErrNoFile` | Private | `.F.` | `.F.` = exibe em tela / `.T.` = captura em array via `GetAutoGRLog()` |

**Regras:**
- Declare as três como `Private` antes de qualquer chamada
- Resete `lMsErroAuto := .F.` **imediatamente** antes de cada `MSExecAuto` ou `FWMVCRotAuto`
- No padrão MVC com `FWMVCRotAuto`, declare também `aRotina` e `oModel` como `Private`

### Tratamento de erro

| Função | Quando usar |
|---|---|
| `MostraErro()` | Exibir erros em tela — padrão mais comum |
| `MostraErro("\path\")` | Gravar erros em arquivo texto |
| `GetAutoGRLog()` | Recuperar array de erros (requer `lAutoErrNoFile := .T.`) |
| `AutoGrLog(cTexto)` | Gravar mensagem de rastreamento durante o processamento |
| `oModel:GetErrorMessage()` | Recuperar erros no padrão MVC — retorna **array de 9 posições** |

#### Estrutura do array retornado por `GetErrorMessage()`

```advpl
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
```

### BEGIN TRANSACTION — NÃO USE

**Não encapsule ExecAuto em `BEGIN TRANSACTION / END TRANSACTION`.**

A documentação oficial da TOTVS é clara:

> *"As rotinas automáticas da TOTVS já possuem, internamente, seus próprios controles
> de gravação. Abrir uma transação externa pode concorrer com as tratativas padrão,
> impedindo que o sistema gerencie corretamente o Rollback em caso de falha."*

Riscos do uso indevido:
- Locks e deadlocks no banco de dados
- Concorrência com o controle interno da rotina
- Comportamentos imprevisíveis em Oracle (DDL dentro de transação força Commit)

**Exceção:** apenas quando houver documentação oficial da TOTVS mapeando explicitamente
o uso de transação para aquela rotina específica.

### PREPARE ENVIRONMENT / RESET ENVIRONMENT

Use **apenas** quando a função roda fora do contexto de usuário:
- Jobs agendados
- Rotinas batch chamadas via Schedule
- `User Function` executadas via RPCCallProc

**Não use** em:
- Pontos de entrada (o ambiente já está configurado)
- Web Services e APIs REST — o ambiente é definido via `PREPAREIN` no `AppServer.ini`
  e o `tenantid` no header da requisição
- Funções chamadas dentro do fluxo normal do Protheus

Sempre faça par: para cada `PREPARE ENVIRONMENT` deve haver um `RESET ENVIRONMENT`.

### xFilial()

Use sempre `xFilial("ALIAS")` para preencher campos de filial — nunca hardcode.

```advpl
AADD(aCab, {"E1_FILIAL", xFilial("SE1"), Nil})
```

### nOpc — Operações

| Valor | Constante MVC | Operação |
|---|---|---|
| 3 | `MODEL_OPERATION_INSERT` | Inclusão |
| 4 | `MODEL_OPERATION_UPDATE` | Alteração |
| 5 | `MODEL_OPERATION_DELETE` | Exclusão |

### Liberação do model (MVC)

Sempre ao final de qualquer uso de `FWLoadModel`:

```advpl
oModel:DeActivate()
oModel:Destroy()
oModel := Nil
```

---

## Como identificar o padrão correto

Antes de escrever qualquer código, determine:

1. **A rotina usa MVC?**
   - Verifique se o fonte contém `FWFormModel` ou `FWBrowse` — se sim, é MVC
   - Rotinas mais antigas (MATA030, FINA040, etc.) geralmente são clássicas
   - Se não souber, pergunte ao usuário

2. **Clássico: a rotina tem itens?**
   - Sim → array de itens (`aItens`) com bloco `|a, b, c|` ou `|a, b, c, d|`
   - Não → só cabeçalho com bloco `|x, y|`

3. **MVC: FWLoadModel ou FWMVCRotAuto?**
   - Precisa acessar submodelos separados? → `FWLoadModel + GetModel`
   - Rotina própria ou operação simples? → `FWMVCRotAuto`

4. **O contexto de ambiente já está aberto?**
   - Ponto de entrada, Web Service, API REST → não use `PREPARE ENVIRONMENT`
   - Job, batch, Schedule → use `PREPARE ENVIRONMENT / RESET ENVIRONMENT`

---

## Aliases dos FormModels — rotinas conhecidas

| Rotina | Tabela | Master | Detail |
|---|---|---|---|
| MATA010 | SB1/SB5 | SB1MASTER | SB5DETAIL |
| MATA020 | SA2 | SA2MASTER | — |
| MATA030 | SA1 | SA1MASTER | — |
| MATA103 | SC5/SC6 | SC5MASTER | SC6DETAIL |
| MATA410 | SC5/SC6 | SC5MASTER | SC6DETAIL |
| MATA241 | SD3 | SD3MASTER | — |
| FINA040 | SE1 | SE1MASTER | — |
| MATA750 | SE2 | SE2MASTER | — |

> Se a rotina não estiver na lista, oriente o usuário a verificar o fonte da rotina
> buscando por `FWFormModel` — o primeiro parâmetro é o alias do master.

---

## Checklist antes de entregar

- [ ] Identificou corretamente o padrão: clássico simples, clássico com itens, MVC?
- [ ] `lMsErroAuto`, `lMsHelpAuto`, `lAutoErrNoFile` declarados como `Private`?
- [ ] `lMsErroAuto := .F.` resetado imediatamente antes de cada chamada?
- [ ] Nenhum `BEGIN TRANSACTION` envolvendo o ExecAuto?
- [ ] `xFilial("ALIAS")` usado para campos de filial?
- [ ] `PREPARE ENVIRONMENT` usado somente onde necessário?
- [ ] No clássico com itens: `aItens` é array de arrays?
- [ ] No MVC com `FWLoadModel`: `DeActivate()`, `Destroy()` e `oModel := Nil` ao final?
- [ ] No MVC com `FWMVCRotAuto`: `aRotina` e `oModel` declarados como `Private`?
- [ ] `GetErrorMessage()` tratado como array de 9 posições (não como string)?
- [ ] Comentários em português?

---

## Referências locais

| Arquivo | Padrão | Quando usar |
|---|---|---|
| `examples/execauto-classico-simples.prw` | Clássico | Rotina sem itens — FINA040/SE1 |
| `examples/execauto-classico-com-itens.prw` | Clássico | Rotina com itens — MATA410/SC5+SC6 com inclusão, alteração e exclusão |
| `examples/execauto-mvc-fwloadmodel.prw` | MVC | FWLoadModel com submodelos — MATA010/SB1+SB5 |
| `examples/execauto-mvc-fwmvcrotauto.prw` | MVC | FWMVCRotAuto simples e com múltiplos forms |
