# TASKS.md — Quadro de Orquestração

> **Fluxo:** `BACKLOG` → `EM PROGRESSO` → `PARA REVISÃO` → `CONCLUÍDO`
> Sempre especifique: **ID**, **Dono**, **Arquivos-alvo**, **Descrição** e **Critério de Pronto**.

## EM PROGRESSO
- [ ] **T-004** | Dono: `Codex` | **Arquivos-alvo:** `sasi-game-jam-2026/scripts/autoload/audio_manager.gd`, `TASKS.md`
  - **Descrição:** Criar um script base `AudioManager` (`extends Node`) com tipagem estática em GDScript contendo:
    - Um `AudioStreamPlayer` para música de fundo (`music_player`) com suporte a loop/troca de faixa (`play_music(stream: AudioStream, volume_db: float = 0.0) -> void`, `stop_music() -> void`)
    - Pool pequeno de `AudioStreamPlayer` (ex.: 8 players) para SFX simultâneos sem corte (`play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void`)
    - Controle simples de mute/volume (`set_muted(muted: bool) -> void`)
  - **Critério de Pronto:** Script salvo em `sasi-game-jam-2026/scripts/autoload/audio_manager.gd`, seguindo `AGENTS.md`, e status de `T-004` movido para `PARA REVISÃO` no `TASKS.md`.

## PARA REVISÃO
*(Vazio)*

## BACKLOG
- [ ] **T-001** | Dono: `Antigravity + Usuário` | Definir conceito do jogo às 17h00 a partir do tema/desafio oficial e preencher `GDD.md`.

## CONCLUÍDO
- [x] **T-003** | Dono: `Codex` | Script base `GameManager` criado em `sasi-game-jam-2026/scripts/autoload/game_manager.gd` e revisado pelo Antigravity.
- [x] **T-002** | Dono: `Usuário + Antigravity` | Projeto Godot 4 (`GL Compatibility`) criado em `sasi-game-jam-2026/` com estrutura de pastas (`scenes/`, `scripts/`, `assets/`, `audio/`).
- [x] **T-000** | Dono: `Antigravity` | Estrutura inicial de orquestração (`AGENTS.md`, `TASKS.md`, `GDD.md`, `CREDITS_AND_AI.md`, `ITCH_SUBMISSION_CHECKLIST.md`, `.gitignore`).
