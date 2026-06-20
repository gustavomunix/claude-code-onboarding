# Checklist de Setup — Novo Projeto Claude Code

> Diga ao Claude: "Siga este checklist para configurar o projeto."
> Claude vai executar cada passo na ordem correta.

---

## Passo 1 — Verificar ferramentas globais

```bash
rtk --version 2>/dev/null && echo "RTK: ok" || echo "RTK: INSTALAR (ver setup/01-ferramentas-globais.md)"
code-review-graph --version 2>/dev/null && echo "CRG: ok" || echo "CRG: INSTALAR (ver setup/01-ferramentas-globais.md)"
node --version 2>/dev/null && echo "Node: ok" || echo "Node: INSTALAR (>=18 necessário)"
```

Verificar plugins instalados:
```bash
python3 -c "
import json
s = json.load(open('/root/.claude/settings.json' if __import__('os').path.exists('/root/.claude/settings.json') else __import__('os').path.expanduser('~/.claude/settings.json')))
plugins = s.get('enabledPlugins', {})
for name, key in [('Caveman','caveman'), ('Token Optimizer','token-optimizer'), ('Context Mode','context-mode')]:
    found = any(key in k for k in plugins)
    print(f\"{'✓' if found else '✗ INSTALAR'} {name}\")
"
```

---

## Passo 2 — Instalar o que estiver faltando

- Se RTK ou code-review-graph faltarem → seguir **setup/01-ferramentas-globais.md**
- Se Caveman faltar → instalar pelo bash (está em setup/01-ferramentas-globais.md)
- Se Token Optimizer ou Context Mode faltarem → instalar pelo chat (setup/02-plugins-claude.md)

---

## Passo 3 — Configurar o projeto atual

```bash
# Na raiz do projeto:
code-review-graph install --platform claude-code
code-review-graph build
```

Depois no chat:
```
Build the code review graph for this project
```

---

## Passo 4 — Criar CLAUDE.md do projeto

Gerar CLAUDE.md baseado no template:
```
Read templates/CLAUDE.md from the onboarding guide and generate a
CLAUDE.md for this project. Analyze the project structure first.
Keep it under 80 lines.
```

---

## Passo 5 — Sequência de abertura (toda sessão)

```
/caveman full
/token-optimizer quick
Update the code review graph
ctx stats
```

Se `/token-optimizer quick` mostrar issues, rodar `/token-optimizer` e aceitar correções.

---

## Verificação final

```
/context-mode:ctx-doctor
/token-optimizer quick
```

Tudo com `[x]` e Quality S ou A = pronto para trabalhar.
