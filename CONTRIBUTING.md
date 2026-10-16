# Contribuindo para o EngPro AI Agent Skills

Obrigado por querer contribuir! Este guia contém todas as informações necessárias para adicionar, modificar ou melhorar skills neste repositório.

---

## Sumário

- [Estrutura do Repositório](#estrutura-do-repositório)
- [Anatomia de uma Skill](#anatomia-de-uma-skill)
  - [Estrutura de Diretório](#estrutura-de-diretório)
  - [Frontmatter YAML](#frontmatter-yaml)
  - [Corpo do SKILL.md](#corpo-do-skillmd)
  - [Arquivos de Referência](#arquivos-de-referência)
- [Referência de Frontmatter](#referência-de-frontmatter)
- [Regras Obrigatórias](#regras-obrigatórias)
- [Como Contribuir](#como-contribuir)
  - [Adicionando uma Nova Coleção](#adicionando-uma-nova-coleção)
  - [Adicionando uma Nova Skill a uma Coleção Existente](#adicionando-uma-nova-skill-a-uma-coleção-existente)
  - [Compatibilidade com a CLI skills](#compatibilidade-com-a-cli-skills)
- [Boas Práticas para Escrever Skills](#boas-práticas-para-escrever-skills)
  - [Progressive Disclosure](#progressive-disclosure)
  - [Escrevendo Boas Descriptions](#escrevendo-boas-descriptions)
  - [Estruturando Instruções](#estruturando-instruções)
  - [Referenciando Arquivos Auxiliares](#referenciando-arquivos-auxiliares)
- [Categorias de Skills](#categorias-de-skills)
- [Revisão e Segurança](#revisão-e-segurança)

---

## Estrutura do Repositório

```
agent-skills/
├── README.md                             # Documentação principal do projeto
├── CONTRIBUTING.md                       # Este arquivo (guia de contribuição)
├── SECURITY.md                           # Política de segurança
├── LICENSE                               # Licença MIT
├── skills/                               # Diretório raiz da coleção de skills
│   ├── <coleção>/                        # Coleção de skills (ex: advpl-tlpp)
│   │   ├── README.md                     # Índice e documentação da coleção
│   │   ├── <skill>/                      # Diretório de uma skill
│   │   │   ├── SKILL.md                  # Instruções da skill (obrigatório)
│   │   │   ├── references/               # Documentação de apoio (opcional)
│   │   │   ├── scripts/                  # Código executável (opcional)
│   │   │   └── assets/                   # Templates, ícones, etc. (opcional)
│   │   └── references/                   # Referências compartilhadas da coleção
└── ...
```

Cada diretório na raiz do repositório (exceto arquivos de configuração) representa uma **coleção de skills** voltada para uma linguagem, framework ou domínio específico.

---

## Anatomia de uma Skill

### Estrutura de Diretório

Cada skill é um diretório contendo obrigatoriamente um `SKILL.md` e opcionalmente subdiretórios de apoio:

```
minha-skill/
├── SKILL.md           # Instruções principais (obrigatório)
├── references/        # Documentação de apoio carregada sob demanda
│   ├── api-ref.md
│   └── patterns.md
├── scripts/           # Código executável (Python, Bash, etc.)
│   └── validate.sh
└── assets/            # Templates, ícones, fontes, etc.
    └── template.md
```

### Frontmatter YAML

Todo `SKILL.md` começa com um bloco YAML frontmatter que define os metadados da skill:

```yaml
---
name: nome-da-skill
description: >-
  O que a skill faz e quando deve ser invocada. Use quando o usuário pedir
  "frase trigger 1", "frase trigger 2" ou mencionar "termo relevante".
license: MIT
metadata:
  domain: customização
  maintainer: Área responsável
  author: Nome do autor
  version: '4.1.0'
  category: Categoria da skill
---
```

### Corpo do SKILL.md

Após o frontmatter, o corpo segue uma estrutura em Markdown:

```markdown
# Nome da Skill

## Overview
Breve descrição do que a skill faz e seu contexto.

## When to Use
Cenários específicos de quando a skill é acionada.

## Instructions

### Step 1: [Primeira Etapa]
Explicação clara do que acontece.

### Step 2: [Segunda Etapa]
Próximo passo com detalhes específicos.

## Examples
Cenários concretos de uso com entradas e saídas esperadas.

## Troubleshooting
Erros comuns, causas e soluções.
```

### Arquivos de Referência

Arquivos no diretório da skill devem ser referenciados no `SKILL.md` para que o agente saiba quando carregá-los:

```markdown
## Additional Resources
- Para detalhes completos da API, consulte [reference.md](references/reference.md)
- Para exemplos de uso, consulte [examples.md](references/examples.md)
```

Utilize tabelas quando houver múltiplas referências para facilitar a leitura:

```markdown
| Reference File | When to Read | Content |
| --- | --- | --- |
| [api-reference.md](references/api-reference.md) | Ao gerar código | Referência completa da API |
| [patterns.md](references/patterns.md) | Ao revisar padrões | Exemplos de antes/depois |
```

---

## Referência de Frontmatter

| Campo | Obrigatório | Descrição |
|-------|:-----------:|-----------|
| `name` | **Sim** | Nome único da skill em kebab-case, igual ao nome do diretório. Obrigatório para descoberta pela CLI `skills`. |
| `description` | **Sim** | O que a skill faz **e** quando usá-la (frases trigger). Máximo 1024 caracteres. |
| `license` | Recomendado | Licença da skill (ex: `MIT`). |
| `metadata` | Recomendado | Bloco de metadados da skill (ver campos abaixo). |
| `metadata.domain` | Recomendado | Domínio ou produto ao qual a skill pertence (ex: `Protheus`, `Carol`). |
| `metadata.maintainer` | Recomendado | Área ou time responsável pela manutenção da skill. |
| `metadata.author` | Recomendado | Nome do autor original da skill. |
| `metadata.version` | Recomendado | Versão da skill em formato semântico (ex: `'1.0.0'`). |
| `metadata.category` | Recomendado | Categoria da skill (ex: `code-generation`, `code-review`, `migration`). |
| `disable-model-invocation` | Não | `true` para impedir invocação automática — apenas via `/nome`. |
| `user-invocable` | Não | `false` para ocultar do menu `/` — apenas o agente invoca. |
| `allowed-tools` | Não | Ferramentas que o agente pode usar sem pedir permissão. |
| `context` | Não | `fork` para executar em um subagente isolado. |
| `agent` | Não | Tipo de subagente quando `context: fork` (ex: `Explore`, `Plan`). |
| `argument-hint` | Não | Dica de argumentos exibida no autocomplete (ex: `[issue-number]`). |
| `model` | Não | Modelo a ser usado quando a skill está ativa. |

> **Importante:** O campo `description` deve incluir **tanto** o que a skill faz **quanto** quando usá-la (frases trigger). Sem isso, o agente não saberá quando ativá-la automaticamente.

---

## Regras Obrigatórias

Ao criar ou modificar skills, estas regras são **invioláveis**:

| Regra | Correto | Incorreto |
|-------|---------|-----------|
| Nome do arquivo de skill | `SKILL.md` (case-sensitive) | `skill.md`, `SKILL.MD`, `Skill.md` |
| Nomes de pasta | `minha-skill` (kebab-case) | `Minha Skill`, `minha_skill`, `MinhaSkill` |
| README dentro de skill | Proibido — use `SKILL.md` ou `references/` | `minha-skill/README.md` |
| Triggers no description | Inclua frases que o usuário diria | Description sem triggers |
| Tags XML no frontmatter | Proibidas — `<` e `>` não podem aparecer | `<tag>` no YAML |

- **`SKILL.md` exatamente assim** — case-sensitive. Não usar `skill.md`, `SKILL.MD`, ou variações.
- **Nomes de pasta em kebab-case** — `minha-skill` ✅ | `Minha Skill` ❌ | `minha_skill` ❌ | `MinhaSkill` ❌
- **Sem `README.md` dentro de pastas de skill** — toda documentação vai no `SKILL.md` ou em `references/`. O `README.md` é reservado para o nível da coleção e do repositório.
- **`description` deve incluir triggers** — o campo description no frontmatter deve informar o que a skill faz **e** quando usá-la.
- **Sem tags XML no frontmatter** — caracteres `<` e `>` são proibidos no YAML frontmatter por questões de segurança.

---

## Como Contribuir

### Adicionando uma Nova Coleção

Uma coleção agrupa skills de uma mesma linguagem, framework ou domínio.

1. Crie um diretório na raiz com o nome da linguagem ou domínio (kebab-case)
2. Adicione um `README.md` documentando as skills da coleção (índice, categorias, referências)
3. Crie subdiretórios para cada skill contendo o respectivo `SKILL.md`

**Exemplo:**

```
nova-colecao/
├── README.md              # Índice e documentação da coleção
├── skill-alpha/
│   └── SKILL.md
├── skill-beta/
│   ├── SKILL.md
│   └── references/
│       └── api-ref.md
└── references/            # Referências compartilhadas entre skills
    └── shared-patterns.md
```

### Adicionando uma Nova Skill a uma Coleção Existente

1. Crie um diretório dentro da coleção com o nome da skill (kebab-case)
2. Crie o arquivo `SKILL.md` com frontmatter YAML e instruções completas
3. Se necessário, adicione um subdiretório `references/` com material de apoio
4. Atualize o `README.md` da coleção para incluir a nova skill na tabela de índice

**Checklist para nova skill:**

- [ ] Diretório em kebab-case
- [ ] `SKILL.md` com frontmatter YAML válido
- [ ] Campo `name` único no repositório e igual ao nome do diretório
- [ ] Campo `description` com frases trigger
- [ ] Instruções passo a passo no corpo do `SKILL.md`
- [ ] Referências em `references/` (se aplicável)
- [ ] `README.md` da coleção atualizado
- [ ] Sem `README.md` dentro da pasta da skill

### Compatibilidade com a CLI skills

A CLI usa diretamente as pastas `skills/<coleção>/<nome>/`, sem exigir pacote npm ou instalador próprio.

- Use `name` único entre as coleções e `description` válido no frontmatter.
- Mantenha referências e scripts dentro da skill: a CLI não copia pastas irmãs. Para documentação compartilhada externa à skill, use HTTPS e informe que o acesso exige internet.

Na raiz do repositório, com Node.js 22.20.0 ou superior, execute:

```sh
npx --yes --package=skills@1.7.2 -c "node ci/scripts/skills-cli-smoke.mjs"
```

O teste verifica descoberta, seleção individual e instalação das duas coleções para Copilot, Codex e Claude Code, preservando referências e scripts. Usa a cópia local e diretórios temporários removidos ao final, sem instalar skills no perfil pessoal. O download da CLI requer acesso ao npm.

---

## Boas Práticas para Escrever Skills

### Progressive Disclosure

Skills usam um sistema de **três níveis** que minimiza o uso de tokens mantendo expertise disponível:

1. **Frontmatter YAML** — sempre carregado no contexto do agente. Contém apenas o necessário para o agente saber quando a skill deve ser usada.
2. **Corpo do SKILL.md** — carregado quando o agente determina que a skill é relevante. Contém as instruções completas.
3. **Arquivos vinculados** — arquivos adicionais no diretório da skill que o agente carrega apenas quando necessário.

Mantenha o `SKILL.md` focado nas instruções essenciais (idealmente abaixo de **5.000 palavras**) e mova documentação detalhada, exemplos extensos e referências de API para `references/`.

### Escrevendo Boas Descriptions

O campo `description` é o mais crítico — determina quando o agente ativa a skill automaticamente.

**Exemplo de boa description:**

```yaml
description: >-
  Gera estruturas de telas MVC do Protheus. Use quando o usuário pedir para
  "criar uma tela CRUD", "gerar ModelDef e ViewDef" ou "montar um cadastro MVC".
```

**Exemplo de description ruim:**

```yaml
# Muito vaga — o agente não sabe quando ativar
description: Ajuda com código MVC.

# Sem triggers — o agente não consegue associar pedidos do usuário
description: Cria estruturas sofisticadas de interface do usuário.
```

**Dicas:**

- Inclua frases que os usuários realmente diriam ao solicitar a tarefa
- Mencione termos técnicos relevantes (nomes de classes, frameworks, comandos)
- Máximo de 1024 caracteres

### Estruturando Instruções

- **Seja específico e acionável** — prefira instruções concretas com comandos e exemplos a orientações vagas
- **Use passos numerados** — facilita o acompanhamento do progresso pelo agente
- **Inclua tratamento de erros** — documente erros comuns, causas e soluções na seção Troubleshooting
- **Forneça exemplos** — cenários concretos de entrada e saída esperada

### Referenciando Arquivos Auxiliares

- Referencie arquivos claramente com links Markdown relativos
- Descreva o conteúdo de cada arquivo para que o agente saiba **quando** carregá-lo
- Use tabelas para múltiplas referências (ver seção [Arquivos de Referência](#arquivos-de-referência))

---

## Categorias de Skills

Skills cobrem três grandes categorias de uso:

| Categoria | Descrição | Exemplos |
|-----------|-----------|----------|
| **Criação de Documentos e Assets** | Gerar outputs consistentes e de alta qualidade — código, documentação, relatórios | Geração de telas MVC, endpoints REST, documentação ProtheusDOC |
| **Automação de Workflows** | Processos multi-etapas que se beneficiam de metodologia consistente | Migração de código, revisão de qualidade, planejamento de implementação |
| **Inteligência de Domínio** | Conhecimento especializado aplicado a decisões de engenharia | Otimização SQL, refatoração com code smells, revisão de segurança |

---

## Revisão e Segurança

Toda contribuição é revisada manualmente. Para detalhes sobre a política de segurança, modelo de ameaças e como reportar vulnerabilidades, consulte [SECURITY.md](SECURITY.md).

Pontos de atenção durante a revisão:

- **Sem payloads maliciosos** — todo conteúdo deve ser texto legível e auditável
- **Sem acesso a credenciais** — skills não devem acessar ou exfiltrar variáveis de ambiente
- **Sem prompt injection** — instruções não devem tentar contornar limites de segurança do agente
- **Conformidade com as regras obrigatórias** — todas as regras da seção [Regras Obrigatórias](#regras-obrigatórias) são verificadas
