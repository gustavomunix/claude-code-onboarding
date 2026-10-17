# Estilo de Código e Atribuição — Configuração Global

Comentário que entra no repositório é público. A regra vale para qualquer
pessoa e qualquer agente. Não é preferência de um autor.

O mesmo texto (seção "Bloquear comentários novos") vai em cada agente:

| Agente | Onde fica a regra | Hook de bloqueio |
|---|---|---|
| Claude Code (WSL) | `~/.claude/CLAUDE.md` | Sim, em `~/.claude/settings.json` |
| Claude Code (Windows) | `C:\Users\<você>\.claude\CLAUDE.md` | Sim, em `C:\Users\<você>\.claude\settings.json` |
| Grok | `~/.grok/rules/estilo-codigo.md` | Não: o Grok não tem hook do tipo `prompt` |
| opencode | `~/.config/opencode/estilo-codigo.md`, listado no campo `instructions` do `~/.config/opencode/opencode.jsonc` | Não |
| Cursor | Interface: Cursor Settings → Rules → User Rules. Colar o texto | Não (sem hook do tipo `prompt`) |
| Zed | Interface: Rules Library. Colar o texto como regra padrão | Não |

A linha do opencode vale para o WSL. No Windows, não foi aplicada: o
`C:\Users\<você>\.config\opencode\opencode.json` existe sem o campo
`instructions`.

No opencode, não use o `~/.config/opencode/AGENTS.md`: o Caveman gerencia
esse arquivo. O campo `instructions` aceita uma lista de caminhos:

```jsonc
"instructions": [
  "/home/<você>/.config/opencode/estilo-codigo.md"
]
```

Cursor e Zed guardam as regras globais na interface, não num arquivo. Nenhum
agente consegue gravá-las por você. A atribuição em commits (seção seguinte) é
configuração só do Claude.

---

## Remover atribuição do Claude em commits e PRs

Some o footer `🤖 Generated with Claude Code` e a linha
`Co-Authored-By: Claude...`.

Adicionar em `~/.claude/settings.json` (e no do Windows, se usar os dois):
```json
{
  "attribution": {
    "commit": "",
    "pr": ""
  }
}
```

---

## Bloquear comentários novos no código

Mesmo texto em cada lugar da tabela do início:
```markdown
# Estilo de código

Comentário no código do repositório é público. Vale para qualquer autor e
qualquer agente.

- Não adicionar comentários (`//`, `/* */`, `#`, etc.) a menos que o pedido
  peça explícito.
- Código se explica por nomes e estrutura.
- Comentário que já existe fica. Não criar novo.
```

Isso sozinho é só uma instrução — não garante nada. Para de fato bloquear,
adicionar um hook `PreToolUse` em `~/.claude/settings.json`:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "You are a lint gate. Inspect this Write/Edit tool call: $ARGUMENTS . Look ONLY at newly added lines (for Write: the whole `content`; for Edit: `new_string` minus whatever already existed in `old_string`). Decide whether those NEW lines introduce any brand-new code comment — line comments (//, #, --, ;) or block comments (/* */, <!-- -->, \"\"\" for docstrings). BLOCK (ok:false) only if a genuinely new comment is being added. Do NOT block when: the comment already existed and is merely being preserved/moved; the string is inside actual code/data (a URL with //, a shebang #!, a regex, a JSON key, CSS content property, a string literal); or the file is Markdown/prose. When blocking, set reason to: 'Comentario novo detectado. Regra global: nao adicionar comentarios (// /* # etc.) salvo pedido explicito. Remova o comentario ou reescreva sem ele.' When unsure, allow (ok:true).",
            "continueOnBlock": true
          }
        ]
      }
    ]
  }
}
```

> **`continueOnBlock: true` é obrigatório.** Sem isso, quando o hook
> bloqueia (`ok:false`) o turno termina e é preciso mandar "continue" para
> retomar. Com `continueOnBlock: true`, o motivo do bloqueio volta pro
> Claude e ele corrige na hora, sem intervenção.

Escrita via Bash ou NotebookEdit não passa por este hook.

Se já existir um `hooks.PreToolUse` no `settings.json` (ex: o
`native-hook` do proxy do Caveman, sem matcher), mesclar o array — não substituir.

---

## Verificar

```bash
jq '.attribution, (.hooks.PreToolUse[] | select(.matcher == "Write|Edit"))' ~/.claude/settings.json
ls ~/.grok/rules/estilo-codigo.md
grep -A2 '"instructions"' ~/.config/opencode/opencode.jsonc
```

No Windows (PowerShell):
```powershell
Get-Content $env:USERPROFILE\.claude\settings.json | ConvertFrom-Json | Select-Object attribution
```

Cursor e Zed: abra a tela de regras e confira se o texto está lá.

Mudanças em `~/.claude/settings.json` só carregam em uma nova sessão —
reiniciar o Claude Code (ou `/hooks` para forçar reload) depois de editar.
