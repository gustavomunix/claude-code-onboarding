# Checklist de Setup — Novo Projeto Claude Code

> Diga ao Claude: "Siga este checklist para configurar o projeto."
> Claude vai executar cada passo na ordem correta.
>
> Cursor, Codex ou Grok: não siga os slash commands daqui.
> Abra `setup/08-multi-agente.md` e use a seção do agente.

---

## Passo 1 — Verificar ferramentas globais

```bash
node --version 2>/dev/null && echo "Node: ok" || echo "Node: INSTALAR (>=22.13, ver setup/01-ferramentas-globais.md)"
code-review-graph --version 2>/dev/null && echo "CRG: ok" || echo "CRG: INSTALAR (ver setup/01-ferramentas-globais.md)"
jq --version 2>/dev/null && echo "jq: ok" || echo "jq: INSTALAR (ver setup/01-ferramentas-globais.md)"
caveman status 2>/dev/null && echo "Proxy Caveman: ok" || echo "Proxy Caveman: opcional (ver setup/01-ferramentas-globais.md)"
```

Verificar plugins instalados:
```bash
python3 -c "
import json, os
s = json.load(open(os.path.expanduser('~/.claude/settings.json')))
plugins = s.get('enabledPlugins', {})
for name, key in [('Caveman','caveman'), ('Token Optimizer','token-optimizer'), ('Context Mode','context-mode')]:
    found = any(key in k for k in plugins)
    print(f\"{'✓' if found else '✗ INSTALAR'} {name}\")
"
```

---

## Passo 2 — Instalar o que estiver faltando

Siga esta ordem:

1. Node, se faltar → **setup/01-ferramentas-globais.md**, seção Node. Os hooks
   dos plugins e o proxy dependem dele.
2. code-review-graph e `jq`, se faltarem → **setup/01-ferramentas-globais.md**.
3. Caveman, se faltar → instalar o plugin (**setup/01-ferramentas-globais.md**).
   Não usar o `install.sh` nem `npx @caveman-ai/cli@latest` sem `--only`
   (outros agentes: `--only <agente>`, ver **setup/08-multi-agente.md**).
4. Proxy do Caveman, módulo `input` (opcional, só no Claude do WSL) →
   **setup/01-ferramentas-globais.md**. RTK não é usado: o proxy comprime a
   mesma saída.
5. `defaultMode` do Caveman → **setup/01-ferramentas-globais.md**
   (`~/.config/caveman/config.json`; no Windows, `%APPDATA%\caveman\config.json`).
6. Token Optimizer e Context Mode, se faltarem → **setup/02-plugins-claude.md**.
   Ligue o auto-update nos três marketplaces.
7. Statusline combinada (Caveman + Token Optimizer) → **setup/02-plugins-claude.md**.
8. Atribuição em commits/PRs e bloqueio de comentários novos →
   **setup/07-estilo-codigo.md** (configuração global, uma vez por máquina).
9. Claude do Windows, se usar → **setup/08-multi-agente.md**, seção
   "Windows e WSL". Cada lado tem a sua cópia de plugins e ferramentas.

---

## Passo 3 — Configurar o projeto atual

> **Se o projeto atual for este próprio guia de onboarding**
> (`claude-code-onboarding`), pule os Passos 3 e 4. O guia não tem código para
> o grafo, e o install criaria `.mcp.json`, `.claude/` e um hook `pre-commit`.

Rodado pelo Claude (sem TTY), o install do grafo grava `CLAUDE.md` sem
perguntar. O `--no-instructions` evita isso. Detalhe do que ele cria em
**setup/03-projeto.md**.

```bash
# Na raiz do projeto:
code-review-graph install --platform claude-code --no-instructions
code-review-graph build
```

Depois, feche e reabra o Claude no projeto. Aceite o MCP `code-review-graph`
quando ele perguntar. Sem isso, o grafo não funciona.

---

## Passo 4 — Criar CLAUDE.md do projeto

> **Não gerar CLAUDE.md se o projeto atual for este próprio guia de
> onboarding** (`claude-code-onboarding`) — ele não tem stack de aplicação
> e o arquivo gerado é só artefato de teste do checklist, sem valor para
> commitar. Pule este passo.

Antes de gerar, verificar se `CLAUDE.md` já está no `.gitignore` do
projeto:
```bash
grep -qx 'CLAUDE.md' .gitignore 2>/dev/null && echo "ignorado: ok gerar sem risco" || echo "NÃO ignorado: CLAUDE.md normalmente deve ser commitado — confirmar com o usuário antes de gerar se isso não é o esperado"
```

Gerar CLAUDE.md baseado no template:
```
Read templates/CLAUDE.md from the onboarding guide and generate a
CLAUDE.md for this project. Analyze the project structure first.
Keep it under 80 lines.
```

---

## Passo 5 — Sequência de abertura (toda sessão)

```
/token-optimizer:quick
Update the code review graph
/context-mode:ctx-stats
```

O Caveman já entra no modo padrão pelo hook (`defaultMode`). Não precisa de
`/caveman`.

Se `/token-optimizer:quick` mostrar issues, rodar `/token-optimizer` e aceitar correções.

---

## Verificação final

```
/context-mode:ctx-doctor
/token-optimizer:quick
```

Tudo com `[OK]` no ctx-doctor e Quality S ou A = pronto para trabalhar.
