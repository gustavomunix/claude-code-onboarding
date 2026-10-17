# CLAUDE.md

> **Para o Claude:** Este arquivo é o contexto do projeto. Siga as instruções durante toda a sessão.
> Cada seção é um módulo independente. Leia tudo antes de começar qualquer tarefa.
>
> **Para o humano:** Substitua os blocos `[...]` com dados reais do projeto.
> Remova seções que não se aplicam. Alvo: ≤ 100 linhas no arquivo final.
> CLAUDE.md é contexto, não trava. Para garantir um comportamento, use hook ou permissão no `settings.json`.
> Para comprimir após preencher: `/caveman-compress CLAUDE.md`. O comando envia o texto do arquivo ao provedor do modelo.

---

## ▸ REGRAS GLOBAIS

- ALL instructions in this file MUST BE FOLLOWED. Not optional unless explicitly stated.
- DO NOT edit more code than necessary.
- DO NOT WASTE TOKENS — no preamble, no summaries unless asked.
- DO NOT re-read files already in context. Use diff only.
- DO NOT create abstractions or features beyond what was explicitly requested.
- ASK FOR CLARIFICATION only when a decision cannot be inferred from code or context.
- When uncertain about any instruction in this file: ASK before proceeding.

---

## ▸ VISÃO DO PROJETO

[Descrição em 2–3 linhas: o que é, qual stack, qual problema resolve.]

**Stack:** [ex: Next.js 14 + TypeScript + PostgreSQL + Tailwind]
**Package manager:** [npm / pnpm / yarn / bun]
**Entry point:** [ex: src/app/page.tsx]

---

## ▸ COMANDOS PRINCIPAIS

```bash
[dev]    # ex: pnpm dev
[build]  # ex: pnpm build
[test]   # ex: pnpm test
[lint]   # ex: pnpm lint && pnpm tsc --noEmit
```

---

## ▸ ESTRUTURA DO PROJETO

```
[só o essencial — máximo 8 linhas]
src/
  [módulo principal]/
  [módulo 2]/
```

---

## ▸ CONVENÇÕES

- Comentário no código é público. Não adicionar comentário novo, qualquer autor ou agente, a menos que o pedido peça. Comentário que já existe fica.
- [Nomes: ex. camelCase funções, PascalCase componentes]
- [Testes: ex. `__tests__/` ou `.test.ts` ao lado do arquivo]
- [Imports: ex. absolutos via `@/`]
- [Qualquer outra convenção não-óbvia do projeto]

---

## ▸ ARQUIVOS — CONTROLE DE ACESSO

**SEMPRE ler antes de alterar código relacionado:**
- `[config central]` — [motivo]
- `[types/schema]` — [motivo]
- `[entry/routes]` — [motivo]

**NÃO modificar sem instrução explícita:**
- `[gerado automaticamente — ex: prisma/migrations/]`
- `[lock files — ex: pnpm-lock.yaml]`

**NÃO ler sob nenhuma circunstância (a menos que explicitamente pedido):**
- `[arquivo sensível ou irrelevante]`
- `[arquivo que causa context pollution]`

---

## ▸ OTIMIZAÇÃO DE TOKENS

Use cada ferramenta abaixo só se ela estiver ativa no projeto.

**code-review-graph** — se o projeto tiver `.code-review-graph/`, verificar impacto antes de ler arquivos:
```
Check blast radius of [arquivo] before modifying
```

**Context Mode** — para dados grandes (logs, APIs, snapshots) — nunca jogar bruto no contexto.
Para arquivo, usar `ctx_execute_file` com `path` e `language: "python"`. O conteúdo chega como `FILE_CONTENT`:
```python
# processar e retornar só o que importa
print(len(FILE_CONTENT.splitlines()))
```

**Saída de terminal** — no Claude do WSL, se o proxy do Caveman (módulo `input`) estiver ligado, ele comprime a saída de terminal. Para testes, sempre pedir:
```
Run [comando]. Show failures only.
```

---

## ▸ AUTOMAÇÕES

> Cada bloco abaixo define uma ação que deve ser executada IMEDIATAMENTE quando o usuário
> mencionar a frase de gatilho — sem perguntas, sem clarificações.
> Delete esta seção se não houver automação.

<!--
MODELO para automações adicionais:

### [Nome da Automação]
- IMPERATIVE: When user mentions "[frase de gatilho]" or similar, IMMEDIATELY [ação].
- Execute: `bash ".claude/scripts/[script].sh" [args]`
- ASSUME DEFAULTS: [o que assumir quando não especificado]
- NO CLARIFICATION unless [condição muito específica].
-->

---

## ▸ CONTEXTO CONHECIDO

> Máximo 5 itens — só o que o Claude não pode inferir do código.
> Delete esta seção se não houver nada relevante.

- [ex: "Auth usa JWT em cookies httpOnly — não usar localStorage"]
- [ex: "Migrations manuais — nunca rodar `prisma db push` em produção"]
- [ex: "Variável X está deprecada — usar Y em vez disso"]

---

<!-- Template: github.com/gustavomunix/claude-code-onboarding | Atualizado: [data] -->
