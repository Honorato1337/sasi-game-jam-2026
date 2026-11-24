# Guia de Modelos no Antigravity — SASI: Game Jam 2026

> Referência rápida baseada nos modelos disponíveis no seu seletor (Plano Pro), focada em **qualidade técnica** e **economia de cota** nas 70h da jam.

---

## Regra de Ouro (80/20)
- **Padrão da Jam:** **`Orchestrator (Neon)`** — planeja/revisa com raciocínio forte (`Neon`) e executa edições rápidas com `Hydrogen`, economizando cota automaticamente.
- **Execução leve com plano já fechado:** **`Gemini 4 Hydrogen` (Medium)**.
- **Momentos críticos:** **`Orchestrator (Argon)`** (abertura às 17h e bugs difíceis).

---

## Qual modelo usar em cada situação

| Situação na Game Jam | Modelo Recomendado | Por quê |
| :--- | :--- | :--- |
| **17h00 — Interpretar Tema, fechar GDD e Arquitetura Godot** | **`Orchestrator (Argon)`** *(ou `Gemini 4 Argon`)* | Raciocínio mais profundo para acertar escopo, cenas e sinais de primeira e evitar retrabalho. |
| **Dia a dia da Orquestração** *(criar tarefas no `TASKS.md`, chamar o Codex, revisar diffs, integrar cenas)* | **`Orchestrator (Neon)`** | Melhor equilíbrio entre julgamento arquitetural e consumo de cota. |
| **Execução direta com plano já definido** *(pequenas edições em GDScript, ajustes de parâmetros, comandos)* | **`Gemini 4 Hydrogen` (Medium)** | Rápido, barato e suficiente quando não é preciso planejar do zero. |
| **Bugs difíceis** *(física, `signal` que não dispara, exportação Web/HTML5 no itch.io travando)* | **`Orchestrator (Argon)`** *(ou `Claude Opus 5.5` como 2ª opinião)* | Analisa causa raiz com mais profundidade antes de sair editando código. |
| **Revisão cruzada de código ou UI/UX** *(opcional)* | **`Claude Sonnet 5.5` (Medium)** | Boa alternativa se você quiser uma segunda visão sobre clareza de código ou experiência do jogador. |
| **Tarefas triviais** *(atualizar `CREDITS_AND_AI.md`, checar `ITCH_SUBMISSION_CHECKLIST.md`, dúvidas rápidas)* | **`Gemini 3.8 Flash` (Medium)** | Consumo mínimo de cota. |

---

## Notas sobre os outros itens do seu seletor
- **`Gemini 4 Neon` / `Gemini 4 Argon` (sem Orchestrator):** úteis se você quiser manter o mesmo modelo fixo em toda a resposta sem alternância automática para o `Hydrogen`.
- **`Claude Opus 5.5` (Medium):** modelo pesado excelente como "plano B" para arquitetura/bugs muito difíceis, mas evite no dia a dia para não gastar cota à toa.
- **`GPT-OSS 120B (Medium)`:** opção aberta intermediária; para Godot/orquestração aqui, os modelos `Orchestrator (Neon)` / `Hydrogen` já atendem melhor.
- **`Gemini 4 Carbon`:** apareceu como *Unavailable* na sua conta no momento — use `Orchestrator (Argon)` quando precisar de raciocínio máximo.

---

## Dicas extras para economizar cota no Plano Pro
1. **Use `/compact`** se uma conversa ficar muito longa (evita reenviar histórico gigante a cada mensagem).
2. **Inicie um chat novo por grande fase** (ex.: *Fase 1: Protótipo*, *Fase 2: Conteúdo & Polish*, *Fase 3: Export Web & itch.io*). Como todo o estado fica salvo em `GDD.md`, `TASKS.md` e `AGENTS.md`, você não perde contexto ao trocar de chat.
3. **Deixe a implementação em lote para o Codex** (`codex.exe` via `TASKS.md`), usando o Antigravity para decidir, quebrar tarefas e revisar.
