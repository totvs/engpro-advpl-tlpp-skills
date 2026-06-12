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
  - [Onde as Skills Ficam](#onde-as-skills-ficam)
  - [Instalação como Plugin (Claude Code e Copilot)](#instalação-como-plugin-claude-code-e-copilot)
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

### Instalação como Plugin (Claude Code e Copilot)

Este repositório também é um **plugin de agente** no formato aberto compartilhado por **Claude Code**, **GitHub Copilot CLI** e **VS Code**. Em vez de copiar pastas manualmente, você instala todas as skills ADVPL/TLPP de uma vez como o plugin `advpl-tlpp`.

A instalação é feita **diretamente a partir do repositório no GitHub** (o plugin ainda não está publicado em um marketplace público).

#### Instalação no Claude Code (a partir do repo)

São dois passos: adicionar o repositório como **marketplace** e depois **instalar** o plugin do catálogo.

**1. Adicione o repositório como marketplace** — o Claude lê o `.claude-plugin/marketplace.json` e registra o catálogo com o nome `engpro-advpl-tlpp-skills`:

```text
/plugin marketplace add totvs/engpro-advpl-tlpp-skills
```

> Formato `owner/repo` do GitHub (o repositório precisa ser público ou você ter acesso). Também funciona com a URL completa — `/plugin marketplace add https://github.com/totvs/engpro-advpl-tlpp-skills` — e dá para fixar uma branch/tag com `#ref` (ex.: `...engpro-advpl-tlpp-skills.git#v1.0.0`).

**2. Instale o plugin** (`plugin@marketplace`):

```text
/plugin install advpl-tlpp@engpro-advpl-tlpp-skills
```

Instala no escopo **User** (todos os seus projetos) por padrão. Para escolher o escopo, use o menu interativo: `/plugin` → aba **Discover** → **Enter** no plugin → **User / Project / Local**.

**3. Ative e use** — rode `/reload-plugins` para ativar sem reiniciar. As skills ficam com o namespace do plugin (ex.: `/advpl-tlpp:mvc-generator`, `/advpl-tlpp:code-review`, `/advpl-tlpp:sql-optimization`) e o Claude também as invoca automaticamente conforme o contexto. Veja os componentes em `/plugin` → aba **Installed**.

**Atualizar e gerenciar:**

```text
/plugin marketplace update engpro-advpl-tlpp-skills    # puxa a versão mais nova do repo
/plugin list                                           # lista plugins instalados
/plugin disable advpl-tlpp@engpro-advpl-tlpp-skills    # desativa sem remover
/plugin uninstall advpl-tlpp@engpro-advpl-tlpp-skills  # remove
```

| Escopo | Onde vale | Compartilhado |
| ------ | --------- | ------------- |
| User (padrão) | Todos os seus projetos | Não — só você |
| Project | Este repositório | Sim — grava em `.claude/settings.json` |
| Local | Este repositório | Não — só você |

**Sugerir a instalação automaticamente para o time:** no `.claude/settings.json` do projeto onde o plugin será usado, adicione o marketplace em `extraKnownMarketplaces`. Ao confiar na pasta, o Claude Code propõe instalar:

```json
{
  "extraKnownMarketplaces": {
    "engpro-advpl-tlpp-skills": {
      "source": { "source": "github", "repo": "totvs/engpro-advpl-tlpp-skills" }
    }
  }
}
```

**Testar localmente antes de instalar** (clone o repositório e rode):

```bash
claude --plugin-dir ./engpro-advpl-tlpp-skills
```

> ⚠️ Plugins executam código com seus privilégios — instale apenas de fontes confiáveis. Se o comando `/plugin` não existir, atualize o Claude Code (`npm install -g @anthropic-ai/claude-code@latest`).

#### Instalação no VS Code / GitHub Copilot

O **mesmo plugin** funciona no VS Code e no GitHub Copilot CLI — o formato de manifesto é compartilhado. O Copilot/VS Code detecta o manifesto dedicado em [`.github/plugin/plugin.json`](.github/plugin/plugin.json) automaticamente ao apontar para este repositório.

- **VS Code:** instale a partir da barra lateral de Extensions (seção de plugins de agente), apontando para o repositório. Veja a [documentação oficial](https://code.visualstudio.com/docs/agent-customization/agent-plugins).
- **GitHub Copilot CLI:** carregue o plugin a partir do repositório conforme a [referência de plugins do Copilot CLI](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference).

As skills ficam disponíveis pelo mesmo nome (`advpl-tlpp:mvc-generator`, etc.).

> **Manifestos:** o plugin tem dois manifestos equivalentes — [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json) (Claude Code) e [`.github/plugin/plugin.json`](.github/plugin/plugin.json) (VS Code / Copilot) — além do catálogo [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json). Ambos apontam para as skills de [`skills/advpl-tlpp/`](skills/advpl-tlpp/) (a coleção `superpowers` não é incluída). **Mantenha os dois manifestos em sincronia** ao alterar `name`/`version`/`skills`; a CI valida isso via [`ci/scripts/plugin-validate.sh`](ci/scripts/plugin-validate.sh).

#### Roadmap: publicação no marketplace da comunidade

> **Status:** planejado. No momento o plugin é instalado pela URL do GitHub (acima). A publicação no marketplace público da comunidade (`anthropics/claude-plugins-community`) está no roadmap.

Quando for publicar, o fluxo será:

1. Validar localmente com o CLI oficial: `claude plugin validate` (o mesmo check roda no pipeline de revisão). A CI deste repositório já executa uma validação leve via [`ci/scripts/plugin-validate.sh`](ci/scripts/plugin-validate.sh).
2. Garantir `version` em [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json) — plugins aprovados são fixados por commit SHA e a versão controla as atualizações.
3. Submeter pelo formulário in-app: [claude.ai](https://claude.ai/admin-settings/directory/submissions/plugins/new) (orgs Team/Enterprise) ou [Console](https://platform.claude.com/plugins/submit) (autores individuais).

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
