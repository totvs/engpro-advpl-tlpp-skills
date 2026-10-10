---
name: sql-optimization
description: 'Universal SQL performance optimization assistant for comprehensive query tuning, indexing strategies, and database performance analysis across SQL databases (PostgreSQL, SQL Server, Oracle). Provides execution plan analysis, pagination optimization, batch operations, and performance monitoring guidance. Use when user says "optimize SQL", "slow query", "index strategy", "execution plan analysis".'
license: MIT
metadata:
  domain: Protheus
  maintainer: Customizações ADVPL/TLPP
  author: Thalion Starforge
  version: '4.2.0'
  category: Code Quality and Review
---

# SQL Performance Optimization Assistant

Expert SQL performance optimization for ${selection} (or entire project if no selection). Focus on universal SQL optimization techniques that work across PostgreSQL, SQL Server, Oracle, and other SQL databases.

## Core Optimization Areas

This skill covers query performance analysis, index strategy, subquery optimization, JOIN optimization, pagination, aggregation, query anti-patterns, batch operations, temporary tables, index management, and performance monitoring.

For all universal SQL optimization patterns with BAD/GOOD code examples, see [sql-optimization-patterns.md](references/sql-optimization-patterns.md).

## Universal Optimization Checklist

### Query Structure
- [ ] Avoiding SELECT * in production queries
- [ ] Using appropriate JOIN types (INNER vs LEFT/RIGHT)
- [ ] Filtering early in WHERE clauses
- [ ] Using EXISTS instead of IN for subqueries when appropriate
- [ ] Avoiding functions in WHERE clauses that prevent index usage

### Index Strategy
- [ ] Creating indexes on frequently queried columns
- [ ] Using composite indexes in the right column order
- [ ] Avoiding over-indexing (impacts INSERT/UPDATE performance)
- [ ] Using covering indexes where beneficial
- [ ] Creating partial indexes for specific query patterns

### Data Types and Schema
- [ ] Using appropriate data types for storage efficiency
- [ ] Normalizing appropriately (3NF for OLTP, denormalized for OLAP)
- [ ] Using constraints to help query optimizer
- [ ] Partitioning large tables when appropriate

### Query Patterns
- [ ] Using LIMIT/TOP for result set control
- [ ] Implementing efficient pagination strategies
- [ ] Using batch operations for bulk data changes
- [ ] Avoiding N+1 query problems
- [ ] Using prepared statements for repeated queries

### Performance Testing
- [ ] Testing queries with realistic data volumes
- [ ] Analyzing query execution plans
- [ ] Monitoring query performance over time
- [ ] Setting up alerts for slow queries
- [ ] Regular index usage analysis

## 📝 Optimization Methodology

1. **Identify**: Use database-specific tools to find slow queries
2. **Analyze**: Examine execution plans and identify bottlenecks
3. **Optimize**: Apply appropriate optimization techniques
4. **Test**: Verify performance improvements
5. **Monitor**: Continuously track performance metrics
6. **Iterate**: Regular performance review and optimization

Focus on measurable performance improvements and always test optimizations with realistic data volumes and query patterns.

---

## Protheus SQL Optimization

The TOTVS Protheus ERP has specific database access patterns and constraints that require targeted optimization strategies. This covers cross-database compatibility, high-volume table optimization, SIX index alignment, `FWExecStatement`/`TCSqlExec` performance (preferred over legacy `TCQuery`), and Workarea vs. Embedded SQL decision guidance.

For complete Protheus-specific optimization patterns, code examples, and the high-volume table reference, see [sql-optimization.md](references/sql-optimization.md).

### Protheus-Specific Optimization Checklist

- [ ] Queries on SD1/SD2/SE1/SE2/CT2 include branch filter and use indexed columns
- [ ] `SELECT *` is not used — only necessary columns are selected
- [ ] `D_E_L_E_T_ = ' '` is present on every Protheus table query
- [ ] No `%nolock%` / lock hint in embedded SQL (not translated — fails at runtime)
- [ ] No `FWExecStatement`, `TCQuery` or `TCSqlExec` calls inside loops — batch with `:SetIn()` or a single statement
- [ ] Temporary aliases opened by `FWExecStatement:OpenAlias()` (or legacy `TCQuery ... New Alias`) are closed after use and `:Destroy()` is called
- [ ] `RetSqlName()` is used instead of hardcoded table names (e.g., `SA1010`)
- [ ] Complex reports use SQL with proper JOINs instead of nested workarea loops
- [ ] `FWExecStatement` is used when user input is part of the query
- [ ] Index usage verified against SIX dictionary entries
- [ ] No `IIF()` in SQL construction — use `CASE WHEN` or `If/Else/EndIf` in AdvPL logic

> Refer to [references/sonarqube-rules-reference.md](../references/sonarqube-rules-reference.md) for the complete SonarQube rules reference.
