# Estilo de Código e Atribuição — Configuração Global

Comentário que entra no repositório é público. A regra vale para qualquer
pessoa e qualquer agente. Não é preferência de um autor.

Claude lê `~/.claude/CLAUDE.md`. Grok lê `~/.grok/rules/estilo-codigo.md`.
O mesmo texto vai nos dois. O hook de bloqueio abaixo só existe no Claude:
o Grok não tem hook do tipo `prompt`.

---

## Remover atribuição do Claude em commits e PRs

Some o footer `🤖 Generated with Claude Code` e a linha
`Co-Authored-By: Claude...`.

Adicionar em `~/.claude/settings.json`:
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

Mesmo texto em `~/.claude/CLAUDE.md` e em `~/.grok/rules/estilo-codigo.md`:
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

Se já existir um `hooks.PreToolUse` no `settings.json` (ex: hook do RTK em
`Bash`), mesclar o array — não substituir.

---

## Verificar

```bash
jq '.attribution, (.hooks.PreToolUse[] | select(.matcher == "Write|Edit"))' ~/.claude/settings.json
```

Mudanças em `~/.claude/settings.json` só carregam em uma nova sessão —
reiniciar o Claude Code (ou `/hooks` para forçar reload) depois de editar.
