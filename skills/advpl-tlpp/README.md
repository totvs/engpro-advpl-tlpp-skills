# Skills de Agente AdvPL/TLPP

Uma coleção de **20 skills** de agente IA para o ecossistema **TOTVS Protheus ERP**, abrangendo as linguagens de programação **AdvPL** e **TLPP** (TOTVS Language Plus Plus). Essas skills orientam assistentes de IA em fluxos de trabalho estruturados para geração de código, migração, revisão de qualidade, testes e documentação dentro da plataforma Protheus.

---

## Sumário

- [Skills por Categoria](#skills-por-categoria)
  - [Geração de Código](#geração-de-código)
  - [Migração e Modernização](#migração-e-modernização)
  - [Qualidade de Código e Revisão](#qualidade-de-código-e-revisão)
  - [Testes](#testes)
  - [Documentação e Planejamento](#documentação-e-planejamento)
- [Referências](#referências)
  - [Referências Compartilhadas](#referências-compartilhadas)
  - [Referências por Skill](#referências-por-skill)
- [Referência Rápida: Qual Skill Usar?](#referência-rápida-qual-skill-usar)

---

## Skills por Categoria

### Geração de Código

Skills que geram estruturas de código prontas para produção seguindo padrões do framework TOTVS.

| Skill | Descrição |
|-------|-----------|
| [mvc-generator](mvc-generator/SKILL.md) | Gera estruturas de telas MVC do Protheus — `ModelDef`, `ViewDef`, `MenuDef` e função de Browse — para padrões de entidade única (Modelo 1) e mestre-detalhe (Modelo 3) usando `FWFormModel` (`MPFormModel`), `FWFormView` e `FWMBrowse`. |
| [tlpp-rest-endpoint-generator](tlpp-rest-endpoint-generator/SKILL.md) | Gera endpoints REST em TLPP usando roteamento baseado em anotações (`@Get`, `@Post`, `@Put`, `@Patch`, `@Delete`) com o objeto `oRest`. Segue os padrões da API TOTVS TTALK incluindo paginação, modelo de erro e documentação Swagger. |
| [fwrest-client-generator](fwrest-client-generator/SKILL.md) | Gera código AdvPL/TLPP que **consome** APIs REST externas usando a classe cliente `FWRest`. Cobre os verbos `GET`, `POST`, `PUT`, `DELETE`, construção de headers, parâmetros de query/path, serialização de body JSON, autenticação (No Auth, HTTP Basic, Bearer/JWT, OAuth 2.0), timeout, SSL, tratamento de status codes e padrões try/catch em TLPP. |
| [entry-point-designer](entry-point-designer/SKILL.md) | Projeta e documenta Pontos de Entrada do Protheus com assinaturas adequadas de `User Function`, layouts de parâmetros `PARAMIXB`, especificações de valores de retorno e padrões de programação defensiva. |
| [query-builder](query-builder/SKILL.md) | Constrói consultas SQL otimizadas e seguras para tabelas do Protheus. Inclui filtros obrigatórios (`D_E_L_E_T_`, filial), design de consultas orientado a índices, prevenção de SQL injection e padrões tanto de SQL Embarcado (`TCQuery`) quanto de Workarea (`DBSelectArea`/`DBSeek`). |

### Migração e Modernização

Skills que orientam a migração incremental de padrões legados para frameworks modernos.

| Skill | Descrição |
|-------|-----------|
| [advpl-to-tlpp-migration](advpl-to-tlpp-migration/SKILL.md) | Migra código AdvPL legado (`.prw`) para TLPP moderno (`.tlpp`). Abrange mudança de extensão de arquivo, `#include "tlpp-core.th"`, adoção de namespaces, anotações de tipo, Try-Catch, migração REST de WsRESTful, identificadores longos, JSON inline, parâmetros nomeados, modificadores de acesso e remoção de `StaticCall`. |

### Qualidade de Código e Revisão

Skills que aplicam padrões de qualidade, detectam problemas e melhoram código existente.

| Skill | Descrição |
|-------|-----------|
| [code-review](code-review/SKILL.md) | Revisão abrangente de código AdvPL/TLPP cobrindo 8 categorias: Segurança (SQL injection, credenciais), Performance (workareas, loops), Construções Legadas/Depreciadas, Acesso a Metadados, Documentação ProtheusDOC, Clean Code, verificações específicas de TLPP e Compilação. Gera achados classificados por severidade com referências a regras do SonarQube. |
| [sql-code-review](sql-code-review/SKILL.md) | Revisão de código focada em SQL cobrindo prevenção de injection, controle de acesso, proteção de dados, análise de estrutura de consultas, estratégia de índices, detecção de anti-patterns e boas práticas específicas para PostgreSQL, SQL Server e Oracle. |
| [refactor](refactor/SKILL.md) | Refatoração cirúrgica de código para melhorar a manutenibilidade sem alterar o comportamento. Aborda 15 code smells (métodos longos, código duplicado, condicionais aninhados, números mágicos, etc.) com padrões seguros de extração e orientações específicas para AdvPL/TLPP. |
| [refactor-method-complexity-reduce](refactor-method-complexity-reduce/SKILL.md) | Redução direcionada da complexidade cognitiva em um método específico através da extração de métodos auxiliares focados. Analisa condicionais aninhados, blocos repetidos e expressões booleanas complexas, e então reestrutura o método como um orquestrador de alto nível. |
| [sql-optimization](sql-optimization/SKILL.md) | Otimização de performance SQL incluindo tuning de consultas, estratégia de índices, paginação, operações em lote, análise de plano de execução e tuning de banco de dados específico do Protheus. Funciona com PostgreSQL, SQL Server e Oracle. |
| [utf8-to-cp1252-conversion](utf8-to-cp1252-conversion/SKILL.md) | Converte fontes AdvPL/TLPP de UTF-8 para Windows-1252 (CP1252) após geração de código. O compilador Protheus exige CP1252 — inclui scripts nativos sem dependências (Bash+iconv para Linux/macOS e PowerShell+.NET para Windows) com detecção de BOM, backup, processamento em lote e integração com CI/CD. |

### Testes

Skills que geram scripts de testes automatizados tanto para lógica de negócio quanto para validação de interface.

| Skill | Descrição |
|-------|-----------|
| [tir-test-generator](tir-test-generator/SKILL.md) | Gera scripts de teste end-to-end **TIR** (TOTVS Interface Robot) em Python para telas do Protheus SmartClient/Webapp. Abrange testes de telas CRUD, testes de telas MVC, interação com grid, telas de parâmetros de relatório, validação de campos e asserções de caixas de mensagem usando `tir.Webapp`. |

### Documentação e Planejamento

Skills para documentar código e planejar trabalhos de implementação.

| Skill | Descrição |
|-------|-----------|
| [documentation-writer](documentation-writer/SKILL.md) | Gera blocos de comentários ProtheusDOC (`/*/{Protheus.doc}`) para código-fonte AdvPL/TLPP. Abrange funções, classes e métodos com todas as tags suportadas (`@type`, `@param`, `@return`, `@author`, `@since`, `@example`, etc.) seguindo o padrão oficial TOTVS. |
| [data-dictionary-lookup](data-dictionary-lookup/SKILL.md) | Consulta o dicionário de dados do ERP Protheus TOTVS (tabelas SX2, campos SX3, índices SIX, parâmetros SX6, tabelas genéricas SX5, gatilhos SX7, perguntas SX1, relacionamentos SX9, consultas padrão SXB, grupos SXG/SXA). Também utilizado durante refatorações, migrações ou melhorias de código para validação de impacto no dicionário. |
| [context-map](context-map/SKILL.md) | Gera um mapa de contexto de todos os arquivos relevantes para uma tarefa antes de implementar mudanças. Identifica arquivos a modificar, dependências, arquivos de teste, padrões de referência e produz uma avaliação de risco para as mudanças planejadas. |
| [create-implementation-plan](create-implementation-plan/SKILL.md) | Cria arquivos de plano de implementação faseado e legíveis por máquina para features, refatorações, upgrades ou mudanças de arquitetura. Os planos são estruturados para execução autônoma por agentes de IA ou humanos, com tarefas atômicas, critérios de validação e declarações de dependência. |
| [advpl-tlpp-sdd](advpl-tlpp-sdd/SKILL.md) | Spec-Driven Development para projetos/features Protheus em 4 fases adaptativas — **Specify, Design, Tasks, Execute** — que se auto-dimensionam conforme a complexidade (Small/Medium/Large/Complex). Cria tarefas atômicas com critérios de verificação, commits atômicos, rastreabilidade de requisitos e memória persistente entre sessões. Suporta inicialização de projetos, mapeamento de codebases brownfield, quick fixes e pausar/retomar trabalho. |

---

## Referências

### Referências Compartilhadas

Materiais de referência utilizados por múltiplas skills.

| Referência | Usado Por | Descrição |
|------------|-----------|-----------|
| [references/advpl-tlpp-skills-reference.md](references/advpl-tlpp-skills-reference.md) | `AGENTS.md`, `CLAUDE.md` | Catálogo completo em inglês de todas as skills AdvPL/TLPP com descrições, referências por skill e tabela de referência rápida. Utilizado pelos arquivos de instrução de agentes como índice canônico das skills disponíveis. |
| [references/sonarqube-rules-reference.md](references/sonarqube-rules-reference.md) | `code-review`, `entry-point-designer` | Referência completa de regras do SonarQube para AdvPL/TLPP organizada em 5 grupos: Segurança (G1), Performance (G2), Legado/Depreciado (G3), Acesso a Metadados (G4) e Compilação (G5) — com IDs de regras e níveis de severidade. |

### Referências por Skill

Materiais de referência específicos de cada skill.

| Skill | Referência | Descrição |
|-------|------------|-----------|
| `advpl-to-tlpp-migration` | [advpl-tlpp-feature-comparison.md](advpl-to-tlpp-migration/references/advpl-tlpp-feature-comparison.md) | Comparação de funcionalidades entre AdvPL e TLPP. |
| `advpl-to-tlpp-migration` | [tlpp-migration-patterns.md](advpl-to-tlpp-migration/references/tlpp-migration-patterns.md) | Padrões de migração de AdvPL para TLPP. |
| `code-review` | [code-quality-patterns.md](code-review/references/code-quality-patterns.md) | Padrões de qualidade de código — performance, construções legadas, acesso a metadados e compilação. |
| `code-review` | [documentation-and-conventions.md](code-review/references/documentation-and-conventions.md) | Documentação ProtheusDOC, convenções de Clean Code e padrões específicos de TLPP. |
| `code-review` | [security-review-patterns.md](code-review/references/security-review-patterns.md) | Padrões de revisão de segurança incluindo prevenção de SQL injection e vulnerabilidades (SonarQube G1). |
| `data-dictionary-lookup` | [column-reference.md](data-dictionary-lookup/references/column-reference.md) | Referência detalhada de todas as colunas das tabelas SX* (SX2, SX3, SIX, SX6, SX5, SX7, SX1, SX9, SXB) com tipos, valores possíveis e descrições funcionais. |
| `data-dictionary-lookup` | [sql-queries.md](data-dictionary-lookup/references/sql-queries.md) | Consultas SQL completas para as 9 tabelas do dicionário, consultas combinadas e regras obrigatórias de `execute-sql` (TRIM, d_e_l_e_t_, lowercase). |
| `mvc-generator` | [mvc-api-reference.md](mvc-generator/references/mvc-api-reference.md) | Referência da API MVC — parâmetros de `FWFormStruct`, opções de layout de view e códigos de ação do `MenuDef`. |
| `mvc-generator` | [mvc-code-templates.md](mvc-generator/references/mvc-code-templates.md) | Templates completos de código AdvPL/TLPP para telas MVC do Protheus (Modelo 1 e Modelo 3). |
| `query-builder` | [cross-database-compatibility.md](query-builder/references/cross-database-compatibility.md) | Compatibilidade multi-banco (PostgreSQL, MSSQL, Oracle) e tradução de dialeto via `ChangeQuery()`. |
| `query-builder` | [query-patterns-and-examples.md](query-builder/references/query-patterns-and-examples.md) | Padrões de consulta e exemplos de código completos com padrões de workarea. |
| `refactor` | [code-smells-and-patterns.md](refactor/references/code-smells-and-patterns.md) | Exemplos de antes/depois para 15 code smells e 4 design patterns em AdvPL/TLPP. |
| `sql-code-review` | [database-specific-best-practices.md](sql-code-review/references/database-specific-best-practices.md) | Boas práticas específicas por banco de dados e padrões ANSI SQL para compatibilidade multi-banco. |
| `sql-code-review` | [sql-performance-and-quality-patterns.md](sql-code-review/references/sql-performance-and-quality-patterns.md) | Padrões de performance e qualidade SQL — análise de estrutura de consultas e otimização. |
| `sql-code-review` | [sql-security-patterns.md](sql-code-review/references/sql-security-patterns.md) | Padrões de segurança SQL — prevenção de injection, consultas parametrizadas e práticas seguras. |
| `sql-optimization` | [sql-optimization.md](sql-optimization/references/sql-optimization.md) | Otimização SQL específica para o Protheus. |
| `sql-optimization` | [sql-optimization-patterns.md](sql-optimization/references/sql-optimization-patterns.md) | Padrões de otimização SQL. |
| `tir-test-generator` | [tir-setup-and-best-practices.md](tir-test-generator/references/tir-setup-and-best-practices.md) | Setup e boas práticas para testes TIR. |
| `tir-test-generator` | [tir-test-patterns.md](tir-test-generator/references/tir-test-patterns.md) | Padrões de testes TIR. |
| `tir-test-generator` | [tir-webapp-methods-reference.md](tir-test-generator/references/tir-webapp-methods-reference.md) | Referência de métodos `tir.Webapp`. |
| `tlpp-rest-endpoint-generator` | [tlpp-rest-endpoint-templates.md](tlpp-rest-endpoint-generator/references/tlpp-rest-endpoint-templates.md) | Templates completos de endpoints CRUD e funções auxiliares para APIs REST em TLPP. |
| `tlpp-rest-endpoint-generator` | [ttalk-standards-and-configuration.md](tlpp-rest-endpoint-generator/references/ttalk-standards-and-configuration.md) | Padrões TOTVS TTALK, configuração do servidor REST e troubleshooting. |
| `fwrest-client-generator` | [fwrest-api-reference.md](fwrest-client-generator/references/fwrest-api-reference.md) | Referência da API da classe `FWRest` — construtor, métodos, propriedades e códigos de retorno. |
| `fwrest-client-generator` | [fwrest-authentication-patterns.md](fwrest-client-generator/references/fwrest-authentication-patterns.md) | Padrões de autenticação para `FWRest` — No Auth, HTTP Basic, Bearer Token/JWT e OAuth 2.0. |
| `fwrest-client-generator` | [fwrest-client-templates.md](fwrest-client-generator/references/fwrest-client-templates.md) | Templates completos de código cliente `FWRest` para `GET`, `POST`, `PUT` e `DELETE`. |
| `advpl-tlpp-sdd` | [project-init.md](advpl-tlpp-sdd/references/project-init.md) · [brownfield-mapping.md](advpl-tlpp-sdd/references/brownfield-mapping.md) | Inicialização de projetos novos e mapeamento de codebases brownfield existentes. |
| `advpl-tlpp-sdd` | [specify.md](advpl-tlpp-sdd/references/specify.md) · [discuss.md](advpl-tlpp-sdd/references/discuss.md) · [design.md](advpl-tlpp-sdd/references/design.md) · [tasks.md](advpl-tlpp-sdd/references/tasks.md) | Fases do pipeline SDD — especificação, discussão de áreas cinzas, design arquitetural e breakdown de tarefas. |
| `advpl-tlpp-sdd` | [implement.md](advpl-tlpp-sdd/references/implement.md) · [validate.md](advpl-tlpp-sdd/references/validate.md) · [quick-mode.md](advpl-tlpp-sdd/references/quick-mode.md) | Execução, validação/UAT interativo e modo rápido (quick mode) para tarefas pequenas. |
| `advpl-tlpp-sdd` | [state-management.md](advpl-tlpp-sdd/references/state-management.md) · [session-handoff.md](advpl-tlpp-sdd/references/session-handoff.md) · [roadmap.md](advpl-tlpp-sdd/references/roadmap.md) · [concerns.md](advpl-tlpp-sdd/references/concerns.md) · [context-limits.md](advpl-tlpp-sdd/references/context-limits.md) · [code-analysis.md](advpl-tlpp-sdd/references/code-analysis.md) · [coding-principles.md](advpl-tlpp-sdd/references/coding-principles.md) | Gestão de estado entre sessões, handoff, roadmap, concerns, limites de contexto, análise de código e princípios de codificação. |

---

## Referência Rápida: Qual Skill Usar?

| Eu quero... | Use esta skill |
|-------------|----------------|
| Criar uma nova tela CRUD (MVC clássico) | `mvc-generator` |
| Construir uma API REST | `tlpp-rest-endpoint-generator` |
| Consumir uma API REST externa | `fwrest-client-generator` |
| Customizar uma rotina padrão | `entry-point-designer` |
| Escrever uma consulta SQL para o Protheus | `query-builder` |
| Migrar `.prw` para `.tlpp` | `advpl-to-tlpp-migration` |
| Revisar qualidade de código | `code-review` |
| Revisar código SQL | `sql-code-review` |
| Melhorar estrutura de código | `refactor` |
| Reduzir complexidade de método | `refactor-method-complexity-reduce` |
| Otimizar performance SQL | `sql-optimization` |
| Criar testes de UI/E2E | `tir-test-generator` |
| Adicionar documentação ProtheusDOC | `documentation-writer` |
| Consultar dicionário de dados do Protheus | `data-dictionary-lookup` |
| Mapear arquivos antes de implementar | `context-map` |
| Planejar uma implementação | `create-implementation-plan` |
| Conduzir um projeto/feature com Spec-Driven Development | `advpl-tlpp-sdd` |
| Converter encoding de fontes para CP1252 | `utf8-to-cp1252-conversion` |

