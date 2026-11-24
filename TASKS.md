# TASKS.md — Quadro de Orquestração

> **Fluxo:** `BACKLOG` → `EM PROGRESSO` → `PARA REVISÃO` → `CONCLUÍDO`
> Sempre especifique: **ID**, **Dono**, **Arquivos-alvo**, **Descrição** e **Critério de Pronto**.

## EM PROGRESSO
*(Vazio)*

## PARA REVISÃO
*(Vazio)*

## BACKLOG
*(Vazio)*

## CONCLUÍDO
- [x] **T-011** | Dono: `Codex` | Polimento visual 8-bit e *juice* (`player.gd`, `enemy_base.gd`, `arena.gd`): animação 2 frames, flashes de impacto, aura ciano de Clareza, *screen shake* pixel-snapped, partículas/faíscas 8-bit, pulso do Núcleo e raio da aura de apoio; 30 verificações integradas aprovadas em Godot 4.7.2 headless com zero erros de script.
- [x] **T-010** | Dono: `Codex` | Sintetizador 8-bit procedural (`audio_manager.gd`) com 4 faixas chiptune (Menu, Bach, Chopin, Tchaikovsky), 10 SFX 8-bit, reação dinâmica de pitch/vibrato/heartbeat ao BPM e síntese distribuída entre frames para Web, validado em Godot 4.7.2 headless e revisado.
- [x] **T-009** | Dono: `Codex` | HUD de Sinais (`hud.tscn/.gd`), janela retrô reutilizável (`retro_window.gd`), Caderno Retrô entre ondas (`habit_terminal.tscn/.gd`), telas de Título/Vitória/Derrota (`title_end_screens.tscn/.gd`) e integração na arena implementados, validados em Godot 4.7.2 headless e revisados.
- [x] **T-008** | Dono: `Codex` | Arena Única (`640x360`), Núcleo do Cuidado, spawner das 4 ondas, 4 tipos de inimigos (`enemy_base.tscn/.gd`) e Aliados de Conexão (`ally_support.tscn/.gd`) implementados, validados em Godot 4.7.2 headless e revisados.
- [x] **T-007** | Dono: `Codex` | Protagonista Seu Antônio implementado em `sasi-game-jam-2026/scenes/player/player.tscn` e `player.gd` (movimento, ataque, dash, respiração `R` com `BreathRing`, Golpe de Clareza e tremor em sobrecarga/exaustão), validado em Godot 4.7.2 headless e revisado.
- [x] **T-006** | Dono: `Codex` | `GameManager` expandido com matemática completa de BPM, `SignalLevel`, exaustão, Golpe de Clareza, Núcleo, ondas, hábitos e `_ensure_input_map()` (`sasi-game-jam-2026/scripts/autoload/game_manager.gd`), validado em Godot 4.7.2 headless e revisado.
- [x] **T-005** | Dono: `Codex` | `project.godot` configurado (`640x360` -> `1280x720`, `viewport` + `keep`, `Nearest`, Autoloads `GameManager` e `AudioManager`).
- [x] **T-004** | Dono: `Codex` | Script base `AudioManager` criado em `sasi-game-jam-2026/scripts/autoload/audio_manager.gd` e revisado pelo Antigravity.
- [x] **T-003** | Dono: `Codex` | Script base `GameManager` criado em `sasi-game-jam-2026/scripts/autoload/game_manager.gd` e revisado pelo Antigravity.
- [x] **T-002** | Dono: `Usuário + Antigravity` | Projeto Godot 4 (`GL Compatibility`) criado em `sasi-game-jam-2026/` com estrutura de pastas (`scenes/`, `scripts/`, `assets/`, `audio/`).
- [x] **T-001** | Dono: `Antigravity + Usuário + Equipe` | Conceito final definido (*O Que Mantém de Pé* / *Entre Fôlego e Rotina*) e `GDD.md` preenchido com alinhamento aos 3 Mundos e critérios do edital.
- [x] **T-000** | Dono: `Antigravity` | Estrutura inicial de orquestração (`AGENTS.md`, `TASKS.md`, `GDD.md`, `CREDITS_AND_AI.md`, `ITCH_SUBMISSION_CHECKLIST.md`, `.gitignore`).
