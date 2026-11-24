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
- [x] **T-024** | Dono: `Antigravity` | Limpeza da tela inicial (`title_end_screens.gd`: remoção de `"SASI: GAME JAM 2026 • UFAC"` e `"W/S ou Mouse..."`, reequilíbrio vertical) e textura orgânica nos botões 9-slice (`retro_window.gd`: `48×28` com veios horizontais, dithering Bayer, cantos 2px chanfrados, rebites e desgaste sutil nas bordas); validado em headless e desktop `1280×720` (`0 falha(s).`) com inspeção visual.
- [x] **T-023** | Dono: `Antigravity` | Bordas pixeladas 9-slice (`retro_window.gd`: `pixel_panel_box`, `pixel_button_box`, `pixel_focus_box`, `pixel_card_box`, barras e slider com chanfro pixelado; `story_dialog.gd`; `care_station.gd`) e remoção da borda/contorno preto no título e textos da tela inicial (`title_end_screens.gd`), mantendo Pixelify Sans; validado em `validate_t017.gd` e `validate_t018.tscn` headless e desktop `1280×720` (`0 falha(s).`) com inspeção visual.
- [x] **T-022** | Dono: `Antigravity` | Tipografia **Pixelify Sans** (`PixelifySans-Regular.ttf`, `PixelifySans-Bold.ttf`, `OFL.txt`): aplicada globalmente via `project.godot` `[gui] theme/custom_font` e `Bold` em títulos/cabeçalhos (`retro_window.gd`, `title_end_screens.gd`), glifos conferidos e ajuste visual em `hud.gd` + `.ttf.import`; registrada em `CREDITS_AND_AI.md` e validada em headless (`T-017` e `T-018`) e desktop `1280×720` (`0 falha(s).`).
- [x] **T-021** | Dono: `Antigravity` | Ataque giratório 360° (`player.gd`): espadada normal e Golpe de Clareza atingem todos os inimigos (e projéteis na Clareza) ao redor dentro do alcance com recuo radial e arco circular animado; validado em `validate_t017.gd` e `validate_t018.tscn` (`0 falha(s).`).
- [x] **T-020** | Dono: `Antigravity` | Tela inicial dedicada em pixel art 32-bit (`title_bg.png` via `generate_32bit_art.gd`) com personagens animados no terraço, logo `"TRÊS TURNOS"`, cursor animado, `JOGAR`, `CONFIGURAÇÕES`, `COMO JOGAR`, `CRÉDITOS & SAÚDE` e `SAIR`, além de `CONFIGURAÇÕES` completa (`HSlider` pixel art em `retro_window.gd`, resolução, restaurar padrões, hover/sons de foco e persistência em `user://settings.cfg`); validado em headless e desktop `1280×720` (`0 falha(s).`) com inspeção visual.
- [x] **T-019** | Dono: `Antigravity` | Remoção das janelas estilo sistema operacional (`retro_window.gd`, `hud.gd`, `story_dialog.gd`, `title_end_screens.gd`, `habit_terminal.gd`): substituição por molduras RPG em pixel art limpas, desobstrução da Porta Norte e correção de alinhamento/espaçamento no HUD; validado em headless e desktop `1280×720` (`0 falha(s).`) com capturas visuais inspecionadas.
- [x] **T-018** | Dono: `Codex` | Três salas conectadas por portas físicas (`arena.tscn/.gd`), diálogos editáveis em português (`story_dialogues.gd` + `story_dialog.tscn/.gd`), HUD dos três Pilares com visão em túnel, áudio reativo (`audio_manager.gd`), menu completo e finais de *"Três Turnos"*; validado (`T-018 (headless): 0 falha(s).`) e revisado.
- [x] **T-017** | Dono: `Codex` | Gameplay Vivo de *"Três Turnos"* (`player.tscn/.gd`, `care_station.tscn/.gd`, `enemy_base.tscn/.gd`, `ally_support.tscn/.gd`, `enemy_projectile.gd`, `slow_puddle.gd`): espada proporcional ao Pilar Corpo, interação `[E]`, 4 inimigos animados + Boss do Burnout de 2 Fases + colega aliado; validado (`T-017: 0 falha(s).`) e revisado.
- [x] **T-016** | Dono: `Codex` | 10 PNGs pixel art 32-bit de *"Três Turnos"* (`student_sheet`, `classmate_sheet`, `room_morning/afternoon/night`, `stations_sheet`, 3 inimigos + `boss_burnout_sheet`) gerados, importados e inspecionados + `game_manager.gd` refatorado para os 3 Pilares (`Corpo`, `Mente`, `Descanso`), validado (`T-016: 0 falha(s).`) e revisado.
- [x] **T-014** | Dono: `Codex` | Nitidez HD (`stretch/mode = "canvas_items"` + pixel snapping), expansão de animações 8 frames, *squash & stretch*, afterimages, poeira e telegrafia (commit `f216c80`).
- [x] **T-013** | Dono: `Codex` | Menu Principal completo, `CONFIGURAÇÕES.EXE` (volumes Música/SFX, Mudo, Tremor de Tela, Tela Cheia), Menu de Pausa (`ESC`/`P`) e telas finais (base preservada).
- [x] **T-012** | Dono: `Antigravity + Codex` | Pipeline de geração pixel art 32-bit em Godot + shaders de flash branco (`hit_flash.gdshader`).
- [x] **T-010** | Dono: `Codex` | Sintetizador 8-bit procedural (`audio_manager.gd`) com faixas estilo Bach, Chopin e Tchaikovsky + SFX em memória.
- [x] **T-009** | Dono: `Codex` | Componente `retro_window.gd` e arquitetura de UI retrô.
- [x] **T-000–T-008** | Dono: `Antigravity + Codex + Usuário` | Fundação do projeto Godot 4, orquestração e protótipo inicial da jam.
