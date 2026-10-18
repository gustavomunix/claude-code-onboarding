# Configuração do Projeto

Setup específico por projeto. Rodar uma vez na raiz de cada repositório novo.

---

## code-review-graph — configurar no projeto

Claude Code:

```bash
# Na raiz do projeto (onde está o .git):
code-review-graph install --platform claude-code --no-instructions --dry-run
code-review-graph install --platform claude-code --no-instructions
code-review-graph build
```

Rode o `--dry-run` antes e confira a lista. Sem as flags, o install no Claude:
- cria `.mcp.json` com o servidor MCP local;
- cria ou faz append no `CLAUDE.md` com instruções de uso do grafo;
- cria `.claude/skills/` com quatro skills de uso do grafo;
- cria `.claude/settings.json` com hooks `PostToolUse` e `SessionStart`, que
  atualizam o grafo;
- instala o hook git `pre-commit` com resumo de risco;
- adiciona `.code-review-graph/` ao `.gitignore`.

Sem TTY (rodado pelo Claude, por script ou CI), a pergunta sobre o
`CLAUDE.md` não aparece e a resposta é sim. Por isso o `--no-instructions`:
o `CLAUDE.md` vem do template (`setup/00-checklist.md`, Passo 4).
Não quer hooks nem `pre-commit`? Some `--no-hooks`. Aí o grafo só atualiza
com `code-review-graph update`, `watch` ou o daemon (abaixo).

Cursor (code-review-graph 2.3.9, já instalado via pipx nesta máquina):

```bash
pipx upgrade code-review-graph
code-review-graph install --platform cursor --no-hooks --no-instructions --dry-run
code-review-graph install --platform cursor --no-hooks --no-instructions
code-review-graph build
```

Sem as flags, o install no Cursor não grava só `.cursor/mcp.json`. Ele faz
append no `AGENTS.md`, cria `.cursorrules` e adiciona hooks em
`~/.cursor/hooks.json` (global, todos os projetos). Com as duas flags sobram
`.cursor/mcp.json` e a linha no `.gitignore`, que entra sempre.

O grafo é o mesmo: Tree-sitter → SQLite → o agente pergunta o blast radius
pelo MCP e lê só esses arquivos. Como ninguém reindexa no save,
rode `code-review-graph update` ou deixe `code-review-graph watch` aberto.
Reinicie o Cursor depois do install. Detalhe em `setup/08-multi-agente.md`.

Outras flags do 2.3.9: `codex`, `windsurf`, `zed`, `continue`, `opencode`,
`antigravity`, `gemini-cli`, `qwen`, `kiro`, `qoder`, `copilot`,
`copilot-cli`, `codebuddy`, `hermes`. Não há `grok`: o MCP do grafo no Grok
está no `setup/08-multi-agente.md`. Pre-commit só em Codex, Claude Code e Qoder.

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

Com os hooks do install, o Claude atualiza o grafo depois de cada edição.
Com `--no-hooks`, ou em outro agente, use uma das opções abaixo.

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

**Opção C — atualizar manualmente** (basta dizer no chat):
```
Update the code review graph
```

---

## Skills disponíveis após setup

O install grava quatro skills em `.claude/skills/` (sem `--no-skills`):

| Comando | O que faz |
|---|---|
| `/review-changes` | Revisa as mudanças com blast radius |
| `/explore-codebase` | Explora a estrutura do código pelo grafo |
| `/debug-issue` | Acha os arquivos relevantes para um bug |
| `/refactor-safely` | Checa o impacto antes de refatorar |

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
/review-changes
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

Windows (PowerShell):
```powershell
if (Select-String -Path .gitignore -Pattern '\.code-review-graph' -Quiet) { "ok" } else { "adicionar manualmente" }
```
