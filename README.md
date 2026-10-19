<h1 align="center">EngPro AI Agent Skills</h1>

<p align="center">
  <a href="https://agentskills.io"><img src="https://img.shields.io/badge/AI-Powered%20Skills-purple?style=flat-square&logo=openai" alt="ai powered" /></a>
  <a href="https://github.com/agentskills/agentskills/tree/main/skills-ref"><img src="https://img.shields.io/badge/AI%20Scan-Framework-yellow" alt="AI Security Framework" /></a>
  <a href="https://learn-cloudsecurity.cisco.com/ai-security-framework"><img src="https://img.shields.io/badge/AI%20Security-Framework-orange" alt="AI Security Framework" /></a>
  <a href="https://github.com/totvs/engpro-advpl-tlpp-skills/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" /></a>
</p>

<p align="left">
A Engenharia Protheus disponibiliza neste repositório um conjunto de skills para desenvolvimento de customizações em ADVPL/TLPP, este repositório será atualizado constantemente buscando sempre a auxliar na criação de código de qualidade. 

Estas skills foram desenvolvidas para o uso em agentes de IA seguindo o padrão aberto <a href="https://agentskills.io/">Agent Skills</a>.

Vale ressaltar que apenas o uso destas skills não garante a qualidade final de um código, e que na TOTVS acreditamos na integração Humanos e IA, por isso é recomendado que sempre haja uma curadoria humana.

IAs podem errar.
</p>

---

## Sumário

- [O que são Agent Skills?](#o-que-são-agent-skills)
  - [Categorias de Uso](#categorias-de-uso)
- [Agentes Suportados](#agentes-suportados)
- [Coleções Disponíveis](#coleções-disponíveis)
- [Como Usar](#como-usar)
  - [Instalação via CLI](#instalação-via-cli)
  - [Instalação Manual](#instalação-manual)
  - [Onde as Skills Ficam](#onde-as-skills-ficam)
- [`CLAUDE.md` e `AGENTS.md` — Instruções de Contexto](#claude-md-e-agents-md-instruções-de-contexto)
  - [O que são `CLAUDE.md` e `AGENTS.md`?](#o-que-são-claude-md-e-agents-md)
  - [Como Usar o `CLAUDE.md` e `AGENTS.md`](#como-usar-o-claude-md-e-agents-md)
- [Agentes Customizados](#agentes-customizados)
- [Contribuindo](#contribuindo)
- [Segurança](#segurança)
- [Licença](#licença)

---

## O que são Agent Skills?

Agent Skills são instruções estruturadas empacotadas como pastas simples contendo um arquivo `SKILL.md` — que orientam agentes de IA a executar tarefas de engenharia de software de forma consistente e com qualidade. Cada skill define um fluxo de trabalho completo — incluindo quando usar, instruções passo a passo, formato de saída e critérios de validação — permitindo que o agente atue como um especialista no domínio.

As skills funcionam através de um sistema de **progressive disclosure** em três níveis:

1. **Frontmatter YAML** — sempre carregado no contexto do agente. Contém apenas o necessário para o agente saber quando cada skill deve ser usada.
2. **Corpo do SKILL.md** — carregado quando o agente determina que a skill é relevante para a tarefa atual. Contém as instruções completas.
3. **Arquivos vinculados** — arquivos adicionais no diretório da skill que o agente pode navegar e consultar apenas quando necessário (referências, templates, scripts).

Esse design minimiza o uso de tokens enquanto mantém expertise especializada disponível.

> **Skills ensinam agentes de IA uma vez, e eles aplicam esse conhecimento de forma consistente em cada tarefa.** Em vez de re-explicar preferências, processos e expertise de domínio a cada conversa, skills permitem ensinar o agente uma vez e se beneficiar sempre.

### Categorias de Uso

Skills são versáteis e cobrem três grandes categorias:

| Categoria | Descrição | Exemplos |
|-----------|-----------|----------|
| **Criação de Documentos e Assets** | Gerar outputs consistentes e de alta qualidade — código, documentação, relatórios | Geração de telas MVC, endpoints REST, documentação ProtheusDOC |
| **Automação de Workflows** | Processos multi-etapas que se beneficiam de metodologia consistente | Migração de código, revisão de qualidade, planejamento de implementação |
| **Inteligência de Domínio** | Conhecimento especializado aplicado a decisões de engenharia | Otimização SQL, refatoração com code smells, revisão de segurança |

## Agentes Suportados

Instale skills em qualquer um desses agentes de IA para desenvolvimento de software:

|                     Populares                             |                            Promissores                                 |                   Corporativos                   |
| :-------------------------------------------------------: | :--------------------------------------------------------------------: | :-----------------------------------------------------: |
|         **[Claude Code](https://claude.ai/code)**         |                    **[Aider](https://aider.chat)**                     |   **[Amazon Q](https://aws.amazon.com/q/developer/)**   |
|        **[Cline](https://github.com/cline/cline)**        |               **[Antigravity](https://idx.google.com)**                |       **[Augment](https://www.augmentcode.com)**        |
|             **[Cursor](https://cursor.com)**              | **[Gemini CLI](https://ai.google.dev/gemini-api/docs/code-execution)** |    **[Droid (Factory.ai)](https://www.factory.ai)**     |
| **[GitHub Copilot](https://github.com/features/copilot)** |                  **[Kilo Code](https://kilocode.ai)**                  | **[OpenCode](https://github.com/opencode-ai/opencode)** |
|       **[Windsurf](https://codeium.com/windsurf)**        |                     **[Kiro](https://kiro.dev/)**                      |  **[Sourcegraph Cody](https://sourcegraph.com/cody)**   |
|                                                           |    **[OpenAI Codex](https://openai.com/index/introducing-codex/)**     |         **[Tabnine](https://www.tabnine.com)**          |
|                                                           |                    **[Roo Code](https://roo.dev)**                     |                                                         |
|                                                           |                    **[TRAE](https://docs.trae.ai)**                    |                                                         |

## Coleções Disponíveis

Cada diretório na raiz do repositório representa uma **coleção de skills** voltada para uma linguagem, framework ou domínio específico.

| Coleção | Descrição | Skills |
|---------|-----------|--------|
| [advpl-tlpp](skills/advpl-tlpp/) | Skills para o ecossistema **TOTVS Protheus ERP** — linguagens AdvPL e TLPP | 20 |
| [superpowers](skills/superpowers/) | Skills genéricas para agentes (recomendado o uso em conjunto com as outras skills) | 14 |

> Novas coleções para outras linguagens e frameworks serão adicionadas progressivamente.

## Como Usar

Você pode instalar as skills via CLI ou manualmente.

### Instalação via CLI

A CLI [skills](https://github.com/vercel-labs/skills) permite instalar diretamente do GitHub.

**Pré-requisitos:** [Node.js](https://nodejs.org/) **22.20.0 ou superior**, npm/npx e [Git](https://git-scm.com/) no terminal (requisitos da CLI 1.7.2).

Na **raiz do projeto que receberá as skills**, execute:

```sh
npx skills add totvs/engpro-advpl-tlpp-skills
```

Selecione as skills e os agentes no assistente interativo. As duas coleções são descobertas automaticamente. Para listar sem instalar, acrescente `--list`.

Para instalar todas as skills no projeto, por exemplo para GitHub Copilot:

```sh
npx skills add totvs/engpro-advpl-tlpp-skills --skill '*' --agent github-copilot --copy --yes
```

Troque o valor de `--agent` conforme o agente utilizado:

| Agente | `--agent` | Destino no projeto (CLI 1.7.2) |
|--------|-----------|-------------------------------|
| GitHub Copilot | `github-copilot` | `.agents/skills/` |
| OpenAI Codex | `codex` | `.agents/skills/` |
| Claude Code | `claude-code` | `.claude/skills/` |

- Para uma única skill, substitua `--skill '*'` por `--skill mvc-generator`.
- Acrescente `--global` para instalar no escopo pessoal. `--copy` evita links simbólicos e `--yes` confirma as escolhas.
- Evite `--all` se quiser apenas um agente: essa opção seleciona todos os agentes.
- No PowerShell, se `npx.ps1` estiver bloqueado, use `npx.cmd`.

Os arquivos de contexto em [`instructions/`](instructions/README.md) devem ser configurados separadamente, conforme a seção abaixo. A CLI não instala os agentes nem o TOTVS Developer Studio.

### Instalação Manual

Faça download do pacote de skills e coloque as pastas de skills no local apropriado para que seu agente de IA possa acessá-las.

| Pacote | Descrição | Versão |
|--------|-----------|--------|



> Para outras versões, consulte a página de [releases](https://github.com/totvs/engpro-advpl-tlpp-skills/releases).

### Onde as Skills Ficam

| Escopo | Caminhos suportados | Aplica-se a |
|--------|---------------------|-------------|
| Pessoal | `~/.claude/skills/<skill>/SKILL.md`<br>`~/.agents/skills/<skill>/SKILL.md`<br>`~/.copilot/skills/<skill>/SKILL.md` | Todos os seus projetos |
| Projeto | `.claude/skills/<skill>/SKILL.md`<br>`.github/skills/<skill>/SKILL.md`<br>`.agents/skills/<skill>/SKILL.md` | Apenas este projeto |
| Plugin | `<plugin>/skills/<skill>/SKILL.md` | Onde o plugin está habilitado |

## `CLAUDE.md` e `AGENTS.md` — Instruções de Contexto

Além das skills, este repositório fornece **CLAUDE.md** e **AGENTS.md** — arquivos de instruções de contexto que configuram o agente de IA com conhecimento fundamental sobre um ecossistema antes mesmo de ele começar a trabalhar. Enquanto skills ensinam *como fazer* tarefas específicas, CLAUDE.md e AGENTS.md ensinam *o que o agente precisa saber* sobre o projeto.

> **⚠️ Importante:** Os arquivos `CLAUDE.md` e `AGENTS.md` possuem **o mesmo conteúdo** — são equivalentes. A diferença é apenas o nome do arquivo, que existe para compatibilidade com diferentes agentes de IA. **Use apenas um deles**, conforme o agente que você utiliza:
>
> - **`CLAUDE.md`** — reconhecido nativamente pelo **Claude Code**.
> - **`AGENTS.md`** — reconhecido nativamente pelo **GitHub Copilot**, **Cursor**, **Windsurf** e outros agentes que seguem o [padrão aberto](https://agents.md/).
>
> Não é necessário (nem recomendado) usar ambos ao mesmo tempo no mesmo workspace.

### O que são `CLAUDE.md` e `AGENTS.md`?

Os arquivos [`CLAUDE.md`](instructions/CLAUDE.md) e [`AGENTS.md`](instructions/AGENTS.md) são **o mesmo conjunto de instruções de contexto para workspaces do ecossistema TOTVS Protheus ERP**, disponibilizados com dois nomes diferentes para compatibilidade com múltiplos agentes. Eles contêm:

| Seção | Conteúdo |
|-------|----------|
| **Linguagem e Ecossistema** | Identificação das linguagens AdvPL e TLPP, extensões de arquivo, idioma padrão |
| **Estrutura de Projeto** | Layout de diretórios típico de um projeto Protheus (fontes, testes, skills) |
| **Convenções de Código** | Notação Húngara, nomenclatura de arquivos, tabelas, campos e constantes multilíngue |
| **Padrões Obrigatórios** | Soft-delete, filtro por filial, prevenção de SQL injection, boas práticas de performance |
| **Padrão MVC** | Estrutura `MenuDef → ModelDef → ViewDef → BrowseDef` do framework Protheus |
| **TLPP Moderno** | Namespaces, type annotations, REST via annotations |
| **Build e Compilação** | RDMake, arquivos `.PRJ`, RPO |
| **Testes** | Framework TIR com estruturas e convenções |
| **Skills Disponíveis** | Catálogo resumido das skills de AdvPL/TLPP |
| **ProtheusDOC** | Padrão de documentação obrigatório para novo código |

Com essas informações carregadas, o agente já entende as convenções, restrições e boas práticas do projeto — sem que você precise explicar a cada conversa.

### Como Usar o `CLAUDE.md` e `AGENTS.md`

Escolha **um** dos dois arquivos conforme o agente que você utiliza e copie-o para a **raiz do seu repositório ou workspace**. A maioria dos agentes de IA detecta automaticamente arquivos de instruções na raiz do projeto.

| Arquivo | Agentes que reconhecem nativamente |
|---------|------------------------------------|
| [`CLAUDE.md`](instructions/CLAUDE.md) | Claude Code |
| [`AGENTS.md`](instructions/AGENTS.md) | GitHub Copilot, Cursor, Windsurf, Cline, Kilo Code, Roo Code e outros |

Caso o seu agente exija um caminho ou nome de arquivo específico, crie um link simbólico ou copie o arquivo para o local adequado.

> **Dica:** O CLAUDE.md e AGENTS.md complementam as skills. Use-os para dar contexto permanente ao agente e as skills para ensinar fluxos de trabalho específicos.

---

## Contribuindo

Quer contribuir com novas skills ou melhorar as existentes? Consulte o guia completo em [CONTRIBUTING.md](CONTRIBUTING.md) — com estrutura do projeto, anatomia de uma skill, regras obrigatórias, frontmatter, boas práticas e muito mais.

## Segurança

Este repositório segue uma política de segurança rigorosa — todas as skills são open source, auditáveis e revisadas manualmente. Para detalhes sobre o modelo de ameaças e como reportar vulnerabilidades, consulte [SECURITY.md](SECURITY.md).

## Licença

Este projeto é distribuído sob a licença [MIT](LICENSE).
