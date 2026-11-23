# AGENTS.md — SASI: Game Jam 2026 (UFAC)

Este repositório é compartilhado entre **Você (Diretor Criativo)**, **Antigravity (Orquestrador / Arquiteto / Revisor)** e **Codex (Implementador)**.

## 1. Contexto da Game Jam
- **Evento:** SASI: Game Jam (3ª Semana Acadêmica de Sistemas de Informação — UFAC)
- **Desenvolvimento:** 23/11/2026 às 17h00 até 26/11/2026 às 15h00 (horário do Acre)
- **Entrega:** Plataforma **itch.io** (priorizar build **Web/HTML5** jogável direto no navegador + fallback Desktop se necessário)
- **Avaliação:** 27/11/2026 pela manhã (presencial, 100 pontos divididos igualmente em: Criatividade/Conceito, Aderência ao Tema/Desafio, Jogabilidade/UX [1º desempate], Execução Técnica/Audiovisual/Apresentação)

## 2. Papéis e Orquestração
- **Antigravity (Orquestrador):**
  - Mantém `GDD.md`, `TASKS.md` e a arquitetura do projeto em Godot.
  - Define tarefas pequenas e isoladas no `TASKS.md` com arquivos-alvo e critérios de aceite claros.
  - Revisa alterações (`git diff`), verifica coerência de cenas/scripts e mantém `CREDITS_AND_AI.md` e `ITCH_SUBMISSION_CHECKLIST.md` atualizados.
- **Codex (Implementador):**
  - Executa apenas a tarefa atribuída no `TASKS.md` (ou solicitada diretamente pelo Orquestrador/usuário).
  - Respeita o escopo de arquivos da tarefa para evitar conflitos em `.tscn` e `project.godot`.
  - Atualiza o status da tarefa em `TASKS.md` para `PARA REVISÃO` ao concluir e resume o que foi feito e como testar.
- **Diretor Criativo (Usuário):**
  - Define direção criativa, aprova o GDD, testa o jogo no editor Godot, valida *game feel* e apresenta no dia 27/11.

## 3. Convenções Técnicas (Godot 4 / GDScript)
- **Raiz do projeto Godot:** `sasi-game-jam-2026/` (`res://` aponta para esta pasta).
- **Engine:** Godot 4.x (GDScript, renderizador `Compatibility`).
- **Estilo:** Use tipagem estática em GDScript (`var speed: float = 200.0`, `func move(delta: float) -> void:`) sempre que possível.
- **Arquitetura desacoplada:**
  - Comunique sistemas via `signal` e `Autoload` (Singletons) enxutos (ex.: `GameManager`, `AudioManager`), evitando acoplamento rígido entre nós.
  - Mantenha cenas pequenas e reutilizáveis (`scenes/player/`, `scenes/ui/`, `scenes/levels/`, `scripts/`, `assets/`).
- **Cuidado com arquivos do Godot Editor:**
  - Evite editar `project.godot` ou arquivos `.tscn` complexos em paralelo. Se uma tarefa precisar de nós novos na cena principal, especifique exatamente no `TASKS.md` ou crie uma subcena independente (`.tscn` + `.gd`) para ser instanciada.
  - Não apague arquivos `.uid` nem `.import` já gerados pelo editor sem necessidade.
- **Foco em Web/itch.io:**
  - Evite dependências nativas/GDExtension que quebrem exportação Web (HTML5).
  - Garanta que o jogo funcione bem em resolução 16:9 escalável (ex.: `1280x720` com stretch mode `canvas_items`).

## 4. Regras Obrigatórias do Edital
- **Assets de terceiros (Item 8.3 IV e 12.2):** Todo asset externo adicionado ao projeto (arte, fonte, música, SFX, shader) deve ser imediatamente registrado em `CREDITS_AND_AI.md` com autor e licença.
- **Uso de IA (Item 12.4):** Toda contribuição de IA (código, design, geração de assets, textos) deve ser registrada de forma transparente em `CREDITS_AND_AI.md` para publicação no itch.io.
