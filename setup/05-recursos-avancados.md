# Recursos Avançados do Claude Code

Funcionalidades built-in que mudam o workflow — especialmente com Opus em tarefas complexas.

---

## Plan Mode

Separa pesquisa de execução. Claude analisa e planeja sem modificar nada até você aprovar.
Essencial para mudanças multi-arquivo ou quando você quer que Claude "pense antes de agir".

**Ativar:**
- `Shift+Tab` duas vezes
- Ou digitar `/plan` no chat

**Desativar:** `Shift+Tab` novamente

**O que muda no Plan Mode:**
- Claude tem acesso apenas a ferramentas de leitura (Read, LS, Glob, Grep, WebSearch, Task)
- Ferramentas de escrita ficam bloqueadas (Edit, Write, Bash, MCP que modifica estado)
- Respostas são estruturadas, numeradas, com verbosidade consistente
- Ao sair do Plan Mode, Claude pede confirmação adicional antes de executar

**Opus Plan Mode** (selecionar no `/model` → opção 4):
- Usa Opus para planejar (1M de contexto, perguntas de clarificação, cria `plan.md`)
- Usa Sonnet para executar
- O `plan.md` pode ser editado antes da execução

**Onde planos ficam salvos** (configurar em `~/.claude/settings.json`):
```json
{ "plansDirectory": "~/.claude/plans" }
```

**Quando usar:**
- Refatorações que tocam múltiplos arquivos
- Mudanças em código que você não conhece bem
- Sempre que quiser ver o plano antes de executar

---

## Auto Plan Mode

Faz o Claude entrar em Plan Mode **automaticamente** antes de qualquer ação, sem você precisar ativar manualmente.

**Como ativar:**

```bash
# Salvar o system prompt em arquivo
cat > ~/.claude/auto-plan-mode.txt << 'EOF'
CRITICAL WORKFLOW REQUIREMENT

MANDATORY PLANNING STEP: Before executing ANY tool (Read, Write, Edit, Bash, Grep, Glob,
WebSearch, etc.), you MUST:

1. FIRST: Use exit_plan_mode tool to present your plan
2. WAIT: For explicit user approval before proceeding
3. ONLY THEN: Execute the planned actions

ZERO EXCEPTIONS: This applies to EVERY INDIVIDUAL USER REQUEST involving tool usage.

CRITICAL: APPROVAL DOES NOT CARRY OVER BETWEEN USER INSTRUCTIONS
Each new user message requiring tools = new planning step required.

WORKFLOW FOR EACH USER REQUEST: Plan → User Approval → Execute (NEVER: Execute → Plan)
EOF

# Usar na sessão:
claude --append-system-prompt "$(cat ~/.claude/auto-plan-mode.txt)"
```

O template completo está em `templates/auto-plan-mode.txt`.

**Quando usar:**
- Em codebases desconhecidas
- Para usuários que esquecem de ativar Plan Mode manualmente
- Quando o custo de um erro é alto

**Pode combinar com Plan Mode manual** — Auto Plan Mode aciona automaticamente, Plan Mode manual ainda funciona para pesquisa pura.

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

## CLAUDE.md Supremacy — O que isso significa na prática

O Claude Code trata o CLAUDE.md como **regras de sistema**, não sugestões:

| Fonte | Comportamento |
|---|---|
| CLAUDE.md | Regras imutáveis — definem os limites de operação |
| Prompt do usuário | Requisição — deve funcionar dentro das regras do CLAUDE.md |

**Implicações práticas:**
- Instruções no CLAUDE.md persistem durante **toda a sessão**
- Prompts raramente sobrescrevem diretivas do CLAUDE.md
- Use markdown para criar fronteiras claras entre módulos (previne "instruction bleed")
- Front-load contexto: liste arquivos permitidos e proibidos explicitamente no CLAUDE.md — é mais eficiente do que deixar Claude ler arquivos aleatórios

**Padrão do template:** use `## ▸ NOME DO MÓDULO` + `---` antes e depois para isolar cada módulo de instruções.

---

## Referência rápida de atalhos

| Ação | Atalho / Comando |
|---|---|
| Ativar Plan Mode | `Shift+Tab` duas vezes ou `/plan` |
| Sair do Plan Mode | `Shift+Tab` |
| Auto-accept edits no Plan Mode | `Shift+Tab` dentro do Plan Mode |
| Rewind | `Esc` duas vezes ou `/rewind` |
| Compactar contexto | `/compact` |
| Health check de tokens | `/token-optimizer quick` |
| Ativar Caveman | `/caveman full` |
| Stats de tokens | `ctx stats` |
