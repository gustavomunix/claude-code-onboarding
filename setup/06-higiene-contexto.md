# Higiene de Contexto — Evitar e Remediar Contaminação

O contexto contaminado é o principal motivo de resultados inconsistentes e comportamentos
inexplicáveis em sessões longas. Este guia cobre prevenção e remédios.

---

## Context Poisoning — O que é

Quando Claude cria associações indesejadas entre ações dentro de uma sessão.

**Exemplo clássico:**
Você pediu "update code" seguido de "deploy". Claude associa as duas ações.
Nas próximas vezes que você pedir update, ele tenta fazer deploy junto — mesmo quando não quer.

**Padrões comuns de contaminação:**

| Padrão | Como acontece |
|---|---|
| Context bleeding | Transição entre tarefas sem marcação explícita |
| Implicit assumptions | Claude assume preferências de um projeto para outro |
| Instruction contamination | Muitos tipos de instrução competindo ao mesmo tempo |
| Contradictory guidance | Instruções que se conflitam sem hierarquia clara |
| Temporal confusion | Instruções antigas de início de sessão contaminando tarefas atuais |

---

## Prevenção

**No CLAUDE.md:**
- Use `## ▸ NOME DO MÓDULO` e `---` para isolar módulos — previne instruction bleed
- Seja explícito sobre o que Claude deve e não deve assumir
- Liste arquivos proibidos para prevenir context pollution por leitura desnecessária

**Durante a sessão:**
- Anuncie explicitamente quando mudar de tipo de tarefa:
  ```
  Switching context: this is a separate task, not related to what we were doing.
  ```
- Use sessões separadas para tipos de trabalho muito diferentes
- Faça `/compact` regularmente — não deixe a sessão engordar

**CLAUDE.md dinâmico:**
- Para tarefas específicas, peça ao Claude para modificar o CLAUDE.md temporariamente
- Ao terminar: `Revert CLAUDE.md to its previous state`
- Backup antes: `cp CLAUDE.md CLAUDE.md.backup`

---

## Sanity Check — Verificar se CLAUDE.md está sendo lido

Adicione seu nome no topo do CLAUDE.md:

```markdown
# CLAUDE.md — [SEU NOME]
```

Então pergunte: `What is my name?`

Se Claude souber: tudo ok. Se não: algo está errado (CLAUDE.md no lugar errado, typo no nome do arquivo, contexto lotado).

**Pontos de verificação ao longo do arquivo:**
Para sessões longas onde o contexto pode lotar, coloque checkpoints em seções críticas:
```markdown
## ▸ CHECKPOINT: Se você leu até aqui, diga "checkpoint-A ok" quando perguntar.
```

---

## Remédios quando o contexto já foi contaminado

**Opção 1 — Rewind** (mais preciso):
```
Esc Esc  (ou /rewind)
```
Selecione o turno anterior à contaminação. Desfaz contexto + alterações de arquivo.

**Opção 2 — Clear** (limpa tudo):
```
/clear
```
Reinicia o contexto completamente. Perde o histórico da sessão.

**Opção 3 — Nova sessão** (mais limpo):
Fecha e reabre o Claude Code. Ideal para quando o contexto está muito degradado.

**Opção 4 — Compact + Reframe** (preserva progresso):
```
/compact
```
Depois: `Forget any associations between [ação A] and [ação B]. From now on, treat them independently.`

---

## /context — Inspecionar o que está no contexto

Comando disponível desde v1.0.86. Mostra breakdown do consumo de tokens por componente.

```
/context
```

**O que mostra:**
| Componente | O que é |
|---|---|
| System Prompt | Instruções base do Claude Code |
| System tools | Ferramentas built-in |
| MCP tools | Servidores MCP ativos |
| Memory files | CLAUDE.md e outros arquivos de contexto |
| Custom Agents | Definições de subagentes |
| Messages | Histórico da conversa atual |

**Uso estratégico:**

```
/context
```
Depois perguntar ao Claude: `Where is my context potentially inefficient?`
Ele vai sugerir otimizações baseado no que vê.

**Desabilitar MCPs não usados** para liberar espaço:
1. `/mcp` lista os servidores.
2. Escolha o servidor que não está em uso → Disable.
3. `/context` mostra a economia.

---

## Directory Crawling — Separação de contexto por subpasta

Claude lê automaticamente TODOS os CLAUDE.md que encontrar subindo na estrutura de diretórios.

**Usar a favor:**
- Projeto com múltiplos módulos → cada módulo com seu CLAUDE.md especializado
- Para isolar contexto: spawnar instância do Claude em subdiretório com CLAUDE.md próprio

**Armadilha:**
- Se o CLAUDE.md do projeto raiz for muito específico, ele contamina todas as subpastas
- Solução: CLAUDE.md da raiz deve ser leve e não-específico; CLAUDE.md das subpastas são os detalhados

---

## A.B.E — Always Be Experimenting

A ferramenta evolui rápido. O que não funciona hoje pode funcionar amanhã.
O que funciona hoje pode deixar de funcionar.

- Documente o que descobrir (mesmo que seja "isso não funciona")
- Experimente variações de CLAUDE.md para o seu workflow específico
- Compartilhe descobertas — a comunidade avança junto

Engenheiros que empurram os limites dessas ferramentas hoje constroem o playbook que todos vão usar amanhã.
