# Ferramentas Globais — Instalação

Instale uma vez. Ficam disponíveis em todos os projetos.

---

## RTK — Rust Token Killer

Filtra output de terminal (git, testes, ls) antes de chegar ao contexto do Claude. Redução média: 80%.

```bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | sh
```

Ativar hook global no Claude Code:
```bash
rtk init -g
# Responda 'y' quando perguntar sobre settings.json
```

Se o modo interativo não funcionar, adicione manualmente ao `~/.claude/settings.json`:
```json
"hooks": {
  "PreToolUse": [{
    "matcher": "Bash",
    "hooks": [{ "type": "command", "command": "rtk hook claude" }]
  }]
}
```

Verificar:
```bash
rtk gain     # deve mostrar estatísticas (mesmo zeradas)
```

> **Atenção:** existe um pacote chamado `rtk` (Rust Type Kit) que não é este.
> Se `rtk gain` der erro, desinstale com `cargo uninstall rtk` e reinstale pelo curl acima.

---

## Caveman

Comprime respostas do Claude (~75% de redução de output). Não afeta o raciocínio, só o texto final.

```bash
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
```

O installer detecta Claude Code e instala o plugin automaticamente.
Se não conseguir, rode dentro do chat:
```
/plugin marketplace add JuliusBrussee/caveman
/plugin install caveman@caveman
```

Verificar (dentro do chat):
```
/caveman
```

---

## code-review-graph

Constrói um mapa estrutural do código (AST + dependências). O Claude consulta o grafo e lê só os arquivos relevantes. Redução: de 951K tokens para ~2K por consulta em projetos grandes.

```bash
pip install code-review-graph
# ou para instalação isolada:
pipx install code-review-graph
```

Verificar:
```bash
code-review-graph --version
```

> Suporta: Python, JS/TS, Go, Rust, Java, C/C++, C#, Ruby, Kotlin, Swift, PHP, Scala, Jupyter.

---

## RTK — Comandos úteis após instalação

```bash
rtk gain                  # tokens economizados até agora
rtk gain --graph          # gráfico ASCII dos últimos 30 dias
rtk init --show           # confirma que o hook está ativo
rtk git status            # testar filtro no git status
```

---

## Verificação conjunta

```bash
rtk --version && echo "RTK ok"
code-review-graph --version && echo "CRG ok"
```

Dentro do Claude Code:
```
/caveman
```

---

## Outros agentes

O install acima é o do Claude. A tabela de 18 ferramentas do RTK está no
README `develop` (`rtk init -g --agent cursor`, `rtk init -g --codex`, e o
resto). Grok não entra. Nesta máquina o binário em `~/.local/bin/rtk` é
0.51.0 e o hook do Claude já aponta para `rtk hook claude`.

Comandos, o que o Cursor recebe do grafo, e o adapter Grok do Token Optimizer:
`setup/08-multi-agente.md`.
