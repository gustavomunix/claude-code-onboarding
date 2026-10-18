# Recursos Avançados do Claude Code

Funcionalidades built-in que mudam o workflow — especialmente com Opus em tarefas complexas.

---

## Plan Mode

Separa pesquisa de execução. Claude analisa e planeja sem modificar nada até você aprovar.
Essencial para mudanças multi-arquivo ou quando você quer que Claude "pense antes de agir".

**Ativar:**
- `Shift+Tab` alterna os modos: default → auto-accept → plan. Do default, aperte duas vezes
- Ou digitar `/plan` no chat

**Desativar:** `Shift+Tab` de novo, até voltar ao default

**O que muda no Plan Mode:**
- Claude tem acesso apenas a ferramentas de leitura (Read, Glob, Grep, WebSearch, WebFetch, Agent)
- Só ferramentas de leitura e comandos read-only; nenhuma edição (Edit, Write, Bash que muda estado, MCP que modifica estado)
- Ao sair do Plan Mode, Claude pede confirmação adicional antes de executar

**Opus Plan Mode:**
```
/model opusplan
```
- Usa Opus para planejar
- Usa Sonnet para executar

**Onde planos ficam salvos:** o padrão já é `~/.claude/plans`. Para guardar os
planos dentro do projeto, use `plansDirectory` no `.claude/settings.json` do
projeto. O campo só aceita caminho relativo ao projeto:
```json
{ "plansDirectory": ".claude/plans" }
```

**Quando usar:**
- Refatorações que tocam múltiplos arquivos
- Mudanças em código que você não conhece bem
- Sempre que quiser ver o plano antes de executar

**Abrir sempre em Plan Mode:**
```bash
claude --permission-mode plan
```

Vale para codebases desconhecidas ou quando o custo de um erro é alto.

---

## Rewind

Reverte contexto do Claude E estado do código para um ponto anterior da conversa.
Disponível desde v2.0.0.

**Ativar:**
- Pressionar `Esc` duas vezes
- Ou digitar `/rewind`

**O que o Rewind mostra:**
- Histórico de turnos da conversa
- Para cada turno: o que você pediu + arquivos modificados (diff estilo git)

**O que o Rewind desfaz:**
- Edições de arquivo feitas pelo Claude após o ponto selecionado
- Histórico de contexto da conversa

**O que o Rewind NÃO desfaz:**
- Arquivos mudados por comando Bash (`rm`, `mv`, scripts)
- Comandos bash que afetam sistemas externos (`git push`, `npm publish`)
- Alterações feitas por você fora do Claude Code
- Operações de rede (APIs, banco de dados)

**Quando usar:**
- Depois de um mal-entendido que se propagou por vários turnos
- Quando uma abordagem não está funcionando
- Para explorar alternativas sem perder o contexto anterior
- Como "cura" para contextos contaminados — rewind, depois /compact

**Combinar com Plan Mode:**
Plan Mode primeiro → reveja o plano → execute sabendo que pode fazer Rewind se algo der errado.

---

## CLAUDE.md — O que ele é na prática

O CLAUDE.md é contexto. O Claude Code carrega o arquivo no início da sessão e
o modelo tenta seguir. Não é regra imutável: um prompt pode contrariar, e o
modelo pode errar.

**Implicações práticas:**
- Instruções no CLAUDE.md ficam no contexto durante **toda a sessão**
- Para garantir um comportamento, use hook ou permissão no `settings.json`
- Use markdown para criar fronteiras claras entre módulos (previne "instruction bleed")
- Front-load contexto: liste arquivos permitidos e proibidos explicitamente no CLAUDE.md — é mais eficiente do que deixar Claude ler arquivos aleatórios

**Padrão do template:** use `## ▸ NOME DO MÓDULO` + `---` antes e depois para isolar cada módulo de instruções.

---

## Referência rápida de atalhos

| Ação | Atalho / Comando |
|---|---|
| Auto-accept edits | `Shift+Tab` uma vez, a partir do default |
| Ativar Plan Mode | `Shift+Tab` duas vezes, a partir do default, ou `/plan` |
| Sair do Plan Mode | `Shift+Tab` até voltar ao default |
| Abrir sempre em Plan Mode | `claude --permission-mode plan` |
| Planejar com Opus, executar com Sonnet | `/model opusplan` |
| Rewind | `Esc` duas vezes ou `/rewind` |
| Compactar contexto | `/compact` |
| Health check de tokens | `/token-optimizer:quick` |
| Reativar Caveman | `/caveman` (o hook já ativa o modo padrão) |
| Economia do Context Mode | `/context-mode:ctx-stats` |
