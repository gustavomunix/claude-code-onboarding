# Configuração do Projeto

Setup específico por projeto. Rodar uma vez na raiz de cada repositório novo.

---

## code-review-graph — configurar no projeto

Claude Code:

```bash
# Na raiz do projeto (onde está o .git):
code-review-graph install --platform claude-code
code-review-graph build
```

O que acontece no Claude:
- Cria `.mcp.json` com o servidor MCP local
- Cria `CLAUDE.md` com instruções de uso do grafo
- Cria `.claude/skills/` com slash commands de revisão
- Adiciona `.code-review-graph/` ao `.gitignore`

Cursor (code-review-graph 2.3.9, já instalado via pipx nesta máquina):

```bash
pip install -U code-review-graph
code-review-graph install --platform cursor
code-review-graph build
```

No Cursor isso grava só `.cursor/mcp.json`. Sem skill, sem hook, sem
pre-commit. O grafo é o mesmo: Tree-sitter → SQLite → o agente pergunta o
blast radius pelo MCP e lê só esses arquivos. Como ninguém reindexa no save,
rode `code-review-graph update` ou deixe `code-review-graph watch` aberto.
Reinicie o Cursor depois do install. Detalhe em `setup/08-multi-agente.md`.

Outras flags do 2.3.9: `codex`, `windsurf`, `zed`, `continue`, `opencode`,
`antigravity`, `gemini-cli`, `qwen`, `kiro`, `qoder`, `copilot`,
`copilot-cli`, `codebuddy`, `hermes`. Não há `grok`. O Grok importa o
`.mcp.json` do install Claude. Pre-commit só em Codex, Claude Code e Qoder.

Desinstalar remove só arquivo do CRG:

```bash
code-review-graph uninstall --dry-run
code-review-graph uninstall --keep-user-configs --repo .
```

No chat, confirme a construção:
```
Build the code review graph for this project
```

---

## Aceitar o MCP quando Claude Code perguntar

Ao abrir o projeto, Claude Code vai perguntar:

> *"Trust this folder? Allow MCP server 'code-review-graph'?"*

Responda **sim** (ou clique Allow). Sem isso, o grafo não funciona.

---

## Manter o grafo atualizado

**Opção A — watch automático** (para sessões longas):
```bash
code-review-graph watch
```

**Opção B — daemon persistente** (para projetos em uso constante):
```bash
crg-daemon add .
crg-daemon start
crg-daemon status
```

**Opção C — atualizar manualmente** (padrão, basta dizer no chat):
```
Update the code review graph
```

---

## Slash commands disponíveis após setup

| Comando | O que faz |
|---|---|
| `/code-review-graph:build-graph` | Constrói ou reconstrói o grafo |
| `/code-review-graph:review-delta` | Revisa mudanças desde o último commit |
| `/code-review-graph:review-pr` | Revisão completa de PR com blast-radius |

---

## Verificar se está funcionando

```bash
code-review-graph status
```

Deve mostrar:
- Total de arquivos indexados
- Linguagens detectadas
- Data da última build

---

## Como usar durante o trabalho

**Antes de refatorar — checar impacto:**
```
Check blast radius of src/auth/middleware.ts before I start refactoring
```

**Ao debugar — evitar ler a codebase inteira:**
```
Debug mode. Here's the error: [cole o stack trace].
Don't read the whole codebase. Use the graph to find only the relevant files.
```

**Antes de abrir PR:**
```
/code-review-graph:review-delta
```

---

## .gitignore — entradas necessárias

Adicionar ao `.gitignore` do projeto:
```
.code-review-graph/
```

O installer já faz isso automaticamente. Verifique com:
```bash
grep ".code-review-graph" .gitignore && echo "ok" || echo "adicionar manualmente"
```
