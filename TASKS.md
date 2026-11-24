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
- [x] **T-018** | Dono: `Codex` | Três salas conectadas por portas físicas (`arena.tscn/.gd`), diálogos editáveis em português (`story_dialogues.gd` + `story_dialog.tscn/.gd`), HUD dos três Pilares com visão em túnel, áudio reativo (`audio_manager.gd`), menu completo e finais de *"Três Turnos"*; validado (`T-018 (headless): 0 falha(s).`) e revisado.
- [x] **T-017** | Dono: `Codex` | Gameplay Vivo de *"Três Turnos"* (`player.tscn/.gd`, `care_station.tscn/.gd`, `enemy_base.tscn/.gd`, `ally_support.tscn/.gd`, `enemy_projectile.gd`, `slow_puddle.gd`): espada proporcional ao Pilar Corpo, interação `[E]`, 4 inimigos animados + Boss do Burnout de 2 Fases + colega aliado; validado (`T-017: 0 falha(s).`) e revisado.
- [x] **T-016** | Dono: `Codex` | 10 PNGs pixel art 32-bit de *"Três Turnos"* (`student_sheet`, `classmate_sheet`, `room_morning/afternoon/night`, `stations_sheet`, 3 inimigos + `boss_burnout_sheet`) gerados, importados e inspecionados + `game_manager.gd` refatorado para os 3 Pilares (`Corpo`, `Mente`, `Descanso`), validado (`T-016: 0 falha(s).`) e revisado.
- [x] **T-014** | Dono: `Codex` | Nitidez HD (`stretch/mode = "canvas_items"` + pixel snapping), expansão de animações 8 frames, *squash & stretch*, afterimages, poeira e telegrafia (commit `f216c80`).
- [x] **T-013** | Dono: `Codex` | Menu Principal completo, `CONFIGURAÇÕES.EXE` (volumes Música/SFX, Mudo, Tremor de Tela, Tela Cheia), Menu de Pausa (`ESC`/`P`) e telas finais (base preservada).
- [x] **T-012** | Dono: `Antigravity + Codex` | Pipeline de geração pixel art 32-bit em Godot + shaders de flash branco (`hit_flash.gdshader`).
- [x] **T-010** | Dono: `Codex` | Sintetizador 8-bit procedural (`audio_manager.gd`) com faixas estilo Bach, Chopin e Tchaikovsky + SFX em memória.
- [x] **T-009** | Dono: `Codex` | Componente `retro_window.gd` e arquitetura de UI retrô.
- [x] **T-000–T-008** | Dono: `Antigravity + Codex + Usuário` | Fundação do projeto Godot 4, orquestração e protótipo inicial da jam.
