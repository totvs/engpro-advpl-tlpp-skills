# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo. Veja [standard-version](https://github.com/conventional-changelog/standard-version) para diretrizes de commits.

## [Não lançado]

### Adicionado

* Guia de instalação direta do GitHub com `npx skills`, incluindo seleção de skills, agentes, escopos e orientações para Windows.
* Teste de compatibilidade com a CLI `skills` 1.7.2, usando instalações temporárias no Windows e Linux.

### Corrigido

* Links para a referência compartilhada do SonarQube permanecem acessíveis após a instalação independente das skills, via HTTPS.

## [1.0.0] (2026-05-25)

### 🎉 Release Inicial

Primeiro release público do repositório **EngPro AI Agent Skills** — um repositório curado, seguro e validado de skills para agentes de IA, seguindo o padrão aberto [Agent Skills](https://agentskills.io/).

### Features

#### Coleção `advpl-tlpp` (20 skills)

* **advpl-tlpp-sdd:** skill de Spec-Driven Development especializada para o ecossistema TOTVS Protheus — planejamento e implementação de projetos/features AdvPL/TLPP com 4 fases adaptativas (Specify → Design → Tasks → Execute), auto-dimensionamento por complexidade, tarefas atômicas com critérios de verificação, commits rastreáveis e memória persistente entre sessões
* **advpl-to-tlpp-migration:** skill para migração de código AdvPL legado para TLPP, com comparação de features e patterns de migração
* **code-review:** skill de revisão de código com patterns de qualidade, convenções de documentação e revisão de segurança
* **context-map:** skill para mapeamento de contexto de projetos AdvPL/TLPP
* **create-implementation-plan:** skill para criação de planos de implementação estruturados
* **data-dictionary-lookup:** skill para consulta ao dicionário de dados do Protheus (SX3), incluindo referências de colunas e queries SQL prontas
* **documentation-writer:** skill para geração de documentação técnica
* **entry-point-designer:** skill para design de entry points de programas Protheus
* **mvc-generator:** skill para geração de código MVC com referência completa da API e templates de código
* **query-builder:** skill para construção de queries com compatibilidade cross-database e exemplos de patterns
* **refactor:** skill de refatoração de código AdvPL/TLPP
* **refactor-method-complexity-reduce:** skill para redução de complexidade de métodos
* **sql-code-review:** skill de revisão de código SQL com boas práticas
* **sql-optimization:** skill de otimização de queries SQL
* **tir-test-generator:** skill para geração de testes automatizados TIR
* **tlpp-rest-endpoint-generator:** skill para geração de endpoints REST em TLPP
* **utf8-to-cp1252-conversion:** skill para conversão de encoding de fontes AdvPL/TLPP de UTF-8 para Windows-1252 (CP1252), com scripts nativos para Linux/macOS e Windows

#### Coleção `superpowers` (14 skills)

* **brainstorming:** skill para sessões de brainstorming estruturadas
* **dispatching-parallel-agents:** skill para despacho de agentes paralelos
* **executing-plans:** skill para execução de planos de implementação
* **finishing-a-development-branch:** skill para finalização de branches de desenvolvimento
* **receiving-code-review:** skill para recebimento e aplicação de code reviews
* **requesting-code-review:** skill para solicitação de code reviews
* **subagent-driven-development:** skill para desenvolvimento orientado a sub-agentes
* **systematic-debugging:** skill para debugging sistemático
* **test-driven-development:** skill para desenvolvimento orientado a testes
* **using-git-worktrees:** skill para uso de git worktrees
* **using-superpowers:** skill meta para uso do sistema de superpowers
* **verification-before-completion:** skill para verificação antes de conclusão de tarefas
* **writing-plans:** skill para escrita de planos de implementação
* **writing-skills:** skill para criação de novas skills

#### Instruções de Agentes

* **AGENTS.md:** diretrizes de desenvolvimento AdvPL/TLPP para agentes compatíveis com o padrão Agents.md, incluindo conformidade SonarQube
* **CLAUDE.md:** diretrizes de desenvolvimento AdvPL/TLPP para Claude Code/Claude, incluindo conformidade SonarQube

#### Infraestrutura

* **README:** documentação completa do repositório com instruções de uso, coleções disponíveis e guia de contribuição
* **CONTRIBUTING.md:** guia de contribuição para o projeto
* **SECURITY.md:** política de segurança do projeto
* **LICENSE:** licença MIT
