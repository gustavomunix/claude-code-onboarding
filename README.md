# Onboarding de projeto — Claude Code e outros agentes

Setup completo para o início de qualquer projeto com Claude Code.
Cobre ferramentas de otimização de tokens, CLAUDE.md otimizado, recursos avançados e higiene de contexto.

Cursor, Codex e Grok usam o mesmo stack só onde o upstream tem hook ou MCP.
O mapa está em `setup/08-multi-agente.md`. Headroom e JFrog Boost ficam de fora:
os dois comprimem a mesma saída de terminal que o RTK.

---

## Como usar

**Setup completo (primeira vez no computador):**
```
Read setup/00-checklist.md and run through each step for this project.
```

**Só configurar o projeto atual (ferramentas globais já instaladas):**
```
Read setup/03-projeto.md and configure this project.
```

---

## Estrutura

```
README.md
AGENTS.md                    ← regras curtas para Grok, Codex e Cursor
setup/
  00-checklist.md            ← ponto de entrada — checklist que o Claude segue
  01-ferramentas-globais.md  ← RTK + Caveman + code-review-graph
  02-plugins-claude.md       ← Token Optimizer + Context Mode
  03-projeto.md              ← configurar MCP e grafo por projeto
  04-sessao.md               ← sequência de abertura e comandos de controle
  05-recursos-avancados.md   ← Plan Mode, Auto Plan Mode, Rewind, CLAUDE.md Supremacy
  06-higiene-contexto.md     ← context poisoning, /context, sanity check, A.B.E
  07-estilo-codigo.md        ← atribuição em commits/PRs e bloqueio de comentários novos
  08-multi-agente.md         ← quem cobre o quê em Cursor, Codex e Grok
templates/
  CLAUDE.md                  ← template base para qualquer projeto
  auto-plan-mode.txt         ← system prompt para Auto Plan Mode
  .gitignore-additions       ← entradas para adicionar ao .gitignore
  scripts/
    write_files.sh           ← script de multi-file output (JSON → arquivos)
```

---

## Ferramentas de otimização cobertas

| Ferramenta | O que faz | Redução típica |
|---|---|---|
| **Caveman** | Comprime respostas do Claude | ~75% output |
| **RTK** | Filtra output de terminal (git, testes, ls) | ~80% input |
| **code-review-graph** | Lê só arquivos relevantes via grafo AST | ~82x por consulta |
| **Context Mode** | Sandbox para dados brutos — APIs, logs, snapshots | 94–99% por chamada |
| **Token Optimizer** | Audit estrutural + compactação com checkpoint | até 80%+ sessão |

Sessão de 2h que custaria ~$12 → ~$2–3 com o stack completo no Claude.
Nos outros agentes a cobertura é a da matriz em `setup/08-multi-agente.md`.
No Grok o Token Optimizer é beta e não restaura contexto na abertura.

---

## Recursos avançados do Claude Code

| Recurso | Como ativar | Para que serve |
|---|---|---|
| **Plan Mode** | `Shift+Tab` 2x ou `/plan` | Ver plano antes de executar |
| **Auto Plan Mode** | `claude --append-system-prompt "$(cat templates/auto-plan-mode.txt)"` | Plan Mode automático em toda ação |
| **Rewind** | `Esc` 2x ou `/rewind` | Desfazer contexto + arquivos |
| **Context Inspection** | `/context` | Ver tokens por componente |
| **Sanity Check** | Nome no CLAUDE.md → `What is my name?` | Verificar se CLAUDE.md está sendo lido |
| **Multi-File Output** | Dizer "multi-file output" | Claude gera JSON → `write_files.sh` cria tudo |

---

## CLAUDE.md — O que o template cobre

- **CLAUDE.md Supremacy** — instruções como regras de sistema, não sugestões
- **Módulos isolados** — separadores `---` e `## ▸` previnem instruction bleed
- **Controle de acesso** — arquivos obrigatórios, proibidos e nunca-ler
- **Token optimization** — instruções para usar code-review-graph e Context Mode
- **Automation Rules** — gatilhos por palavra-chave com IMPERATIVE (Multi-File Output + seus scripts)
- **Sanity check** — slot para nome verificável
- **Known Context** — máximo 5 itens não-inferíveis do código

---

## Higiene de contexto

O arquivo `setup/06-higiene-contexto.md` cobre:
- Padrões de contaminação de contexto (context bleeding, instruction contamination)
- Prevenção com CLAUDE.md modular
- Remédios: Rewind, /clear, nova sessão, compact + reframe
- `/context` para inspeção e otimização de tokens
- CLAUDE.md dinâmico para tarefas isoladas
- Directory crawling — separação de contexto por subpasta

---

## Requisitos

- Node.js ≥ 18
- Python 3.x + pip
- Claude Code CLI ≥ v1.0.86
- `jq` (para o script write_files.sh)

---

*Todas as ferramentas rodam 100% localmente. Nenhuma envia dados para servidores externos.*
