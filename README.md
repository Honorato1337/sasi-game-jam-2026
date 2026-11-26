# Três Turnos *(Manhã, Tarde e Noite)*

> **SASI: Game Jam 2026 — UFAC**  
> Tema: **Saúde em Jogo** · *Sinais, Equilíbrio e Conexões*  
> Engine: **Godot 4.7 (`GL Compatibility`)** · Foco em **Web (HTML5 / itch.io)** e Desktop (`1280×720`)  
> Jogar online: **[louishonorato1337.itch.io/tres-turnos](https://louishonorato1337.itch.io/tres-turnos)**

---

## Downloads Diretos (`.zip`)

| Plataforma | Arquivo | Tamanho aprox. | Download Direto |
| :--- | :--- | :--- | :--- |
| **Windows (`.exe`)** | `tres-turnos-windows.zip` | ~37 MB | [Baixar para Windows](https://github.com/Honorato1337/sasi-game-jam-2026/raw/master/releases/tres-turnos-windows.zip) |
| **Linux (`.x86_64`)** | `tres-turnos-linux.zip` | ~28 MB | [Baixar para Linux](https://github.com/Honorato1337/sasi-game-jam-2026/raw/master/releases/tres-turnos-linux.zip) |
| **macOS (`.app`)** | `tres-turnos-macos.zip` | ~59 MB | [Baixar para macOS](https://github.com/Honorato1337/sasi-game-jam-2026/raw/master/releases/tres-turnos-macos.zip) |
| **Web (HTML5)** | `tres-turnos-web.zip` | ~11 MB | [Baixar Build Web](https://github.com/Honorato1337/sasi-game-jam-2026/raw/master/releases/tres-turnos-web.zip) |

---

## Sobre o Jogo

**Três Turnos** é um jogo de ação e aventura top-down 2D em **pixel art 32-bit autoral** sobre a rotina de um estudante universitário preso em ciclos exaustivos de aulas, ônibus lotados, prazos e madrugadas em claro.

Quando o cansaço se acumula, o personagem tenta escapar ligando o videogame — e acaba entrando em uma alucinação dentro do próprio jogo, onde precisa enfrentar sombras que, aos poucos, se revelam como reflexos de si mesmo até o confronto final contra o próprio esgotamento.

Para vencer, não basta atacar: é preciso ler e equilibrar os **3 Pilares da Saúde**:

| Pilar | O que representa | Sinal no Controle | Como Recuperar |
| :--- | :--- | :--- | :--- |
| **Corpo** | Hidratação e alimentação | Abaixo de `40%`: espada mais curta, menos dano e passo mais lento | Beber água / lanchar (`[E]`) nas estações ou coletar gotas |
| **Mente** | Calma emocional e foco | Visão em túnel, aceleração/vibrato musical, batimento cardíaco e debuffs | Segurar `[R]` para respirar fundo ou contar com o **Colega Aliado (`[E]`)** |
| **Descanso** | Energia física e fôlego | Ao zerar: **Exaustão ofegante**, sem ataque/dash e velocidade reduzida | Pausar golpes, usar o canto de descanso (`[E]`) ou respirar (`[R]`) |

---

## Destaques

- **Narrativa em Cutscenes Animadas:**
  - Abertura com 3 semanas da rotina universitária sincronizadas à música e desgaste facial progressivo no retrato `48×48`.
  - Leitura cadenciada de *"Cansaço"* (Álvaro de Campos / Fernando Pessoa) com violão dedilhado.
  - Entrada pela TV CRT na alucinação e epílogo saindo da tela, reflexão no quarto, retorno à rotina saudável e encerramento com *"O Tempo"* (Mário Quintana).
- **3 Ciclos × 3 Turnos (9 Salas `960×540`):**
  - **Ciclo 1:** Inimigos 100% sombrios, representando o desgaste ainda invisível.
  - **Ciclos 2 e 3:** A névoa se dissipa gradualmente, revelando o próprio rosto do estudante até o **Boss do Burnout** na Sala 9.
- **Trilha Sonora Procedural em Bossa Nova Melancólica:**
  - Áudio gerado em tempo real via GDScript (`AudioStreamWAV` em memória, sem samples externos), com violão de nylon em clave sincopada (`7ª`, `9ª`, `13ª`, `m7(b5)`, `7(b9)`), baixo acústico, Rhodes, flauta suave e vassourinha discreta.
- **Pixel Art 32-bit e Tipografia:**
  - Todos os sprites, cenários, retratos e molduras 9-slice são gerados proceduralmente em `tools/generate_32bit_art.gd` e exibidos com nitidez pixel-perfect (`canvas_items` + filtro `Nearest`) e fonte **Pixelify Sans**.

---

## Controles

| Tecla / Ação | Função |
| :--- | :--- |
| `WASD` / `Setas` | Movimentação |
| `Espaço` / `Clique Esq.` | Golpe giratório 360° (ou **Golpe de Clareza** carregado) |
| `Shift` | Dash com breve invulnerabilidade |
| `R` *(segurar)* | Respiração profunda (recupera **Mente** e carrega **Clareza**) |
| `E` | Interagir (Água/Lanche, Descanso, Colega NPC e Pilares) |
| `P` / `Esc` | Pausar partida / Pular diálogos e cutscenes |

---

## Como Executar e Validar Localmente

1. Abra a pasta `sasi-game-jam-2026/` no **Godot 4.7+** e execute a cena principal (`F5`).
2. Para regenerar a arte 32-bit ou rodar a suíte automatizada via CLI (Windows PowerShell):

```powershell
# Gerar spritesheets e cenários 32-bit
godot --headless --path sasi-game-jam-2026 -s tools/generate_32bit_art.gd

# Validações automatizadas
godot --headless --path sasi-game-jam-2026 -s tools/validate_t016.gd
godot --headless --path sasi-game-jam-2026 -s tools/validate_t017.gd
godot --headless --path sasi-game-jam-2026 tools/validate_t018.tscn
```

---

## Estrutura do Repositório

```text
├── sasi-game-jam-2026/        # Raiz do projeto Godot 4 (res://)
│   ├── assets/                # Spritesheets 32-bit e fonte Pixelify Sans
│   ├── scenes/                # Player, inimigos, estações, arena e UI/cutscenes
│   ├── scripts/               # Autoloads (GameManager, AudioManager) e diálogos
│   ├── shaders/               # Vinheta de ansiedade e shader de ofuscamento/flash
│   └── tools/                 # Gerador de arte 32-bit e validadores T-016/T-017/T-018
├── GDD.md                     # Game Design Document
├── TASKS.md                   # Histórico de tarefas (T-000 a T-029)
├── CREDITS_AND_AI.md          # Créditos, licenças e transparência de uso de IA
└── ITCH_SUBMISSION_CHECKLIST.md
```

---

## Créditos & Transparência

- **Luiz Fernando** — Programador
- **Ana Souza** — Roteiro, Game Design e Artista
- **Jackeline Jansen Medeiros** — Roteiro
- **Ri Maciel** — Designer, Sonoplasta
- **Tipografia:** *Pixelify Sans* (SIL OFL 1.1).
- **Literatura:** *"Cansaço"* — Álvaro de Campos (Fernando Pessoa); *"O Tempo"* — Mário Quintana.
- **Desenvolvimento e Uso de IA:** Documentados integralmente em [`CREDITS_AND_AI.md`](CREDITS_AND_AI.md) conforme as regras do edital da **SASI: Game Jam 2026 (UFAC)**.
