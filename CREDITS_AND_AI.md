# Créditos e Uso de Inteligência Artificial

> Documento vivo para cumprir os itens **8.3 (IV)** e **12.4** do Edital SASI Nº 01/2026 na página do itch.io.

## 1. Equipe
- **Nome(s) e função(ões):** *(preencher)*

## 2. Assets de Terceiros (Sprites, Fontes, Áudio, Shaders)
| Asset | Autor / Fonte | Licença | Onde foi usado |
| :--- | :--- | :--- | :--- |
| *(ex.: Fonte Pixel)* | *(ex.: Kenney)* | *(CC0)* | *(UI / HUD)* |

## 3. Uso de Ferramentas de Inteligência Artificial (Item 12.4)
> *"Os participantes deverão informar, no itch.io, a utilização de ferramentas de inteligência artificial na elaboração dos projetos, quando aplicável, indicando sua finalidade e contribuição no desenvolvimento da proposta."*

| Ferramenta | Finalidade | Contribuição no Projeto |
| :--- | :--- | :--- |
| Antigravity (Google) | Orquestração, arquitetura GDScript, revisão de código e planejamento | Estruturação de tarefas, GDD, revisão técnica e checklist de entrega |
| OpenAI Codex | Implementação assistida de scripts/cenas em GDScript | Scripts base de gerenciamento (`GameManager` em `scripts/autoload/game_manager.gd` e `AudioManager` em `scripts/autoload/audio_manager.gd`), configuração do projeto e implementação de InputMap, BPM, hábitos, vida do Núcleo e ondas (T-005 e T-006) |
| OpenAI Codex | T-007: implementação e prototipagem visual | Cena e controle de Seu Antônio, pixel art procedural, anel de respiração, arcos de ataque e validação headless no Godot |
| OpenAI Codex | Implementação e prototipagem visual da T-008 | Arena, Núcleo do Cuidado, quatro ondas, inimigos e aliados, com pixel art procedural em GDScript e validação headless no Godot |
| OpenAI Codex | Implementação, design visual e redação da interface da T-009 | HUD de Sinais, coração pixel art procedural, shader da vinheta, janelas retrô, Caderno de Rotina, telas de título e fim de jogo, integração e validação headless do fluxo |
| OpenAI Codex | Composição, síntese e integração do áudio da T-010 | Quatro trilhas chiptune originais com referência ao estilo de Bach, Chopin e Tchaikovsky, dez efeitos 8-bit sintetizados em memória, resposta ao BPM e validação headless no Godot. O áudio foi gerado em GDScript sem gravações, partituras ou samples de terceiros. |
| OpenAI Codex | Refinamento visual procedural e validação integrada da T-011 | Animações pixel art de dois quadros, flashes de impacto, aura de Clareza, tremor de câmera alinhado à grade de pixels, faíscas 8-bit, pulso do Núcleo e indicador de alcance da Rede de Apoio, implementados em GDScript sem assets externos. Teste integrado no Godot 4.7.2 headless. |
| OpenAI Codex | Direção de arte procedural e implementação da T-012, etapa 1 | Gerador em GDScript, pátio de ardósia e sete spritesheets originais em pixel art. Paletas, matrizes de pixels e animações criadas para o projeto. |
| OpenAI Codex | Integração visual e validação da T-012, etapa 2 | Integração dos oito PNGs originais do projeto nas cenas Godot, animação dos sprites, sombras, iluminação aditiva, partículas ambientais e shader de flash branco. Implementação da suíte de validação headless dos sprites e do fluxo de jogo. |
| OpenAI Codex | Implementação, design de interface, redação e testes da T-013 | Menu principal, pausa, instruções, configurações, créditos e resumos de partida em janelas retrô. Navegação por teclado e mouse, ajustes de áudio, tremor e tela cheia, e ampliação da validação no Godot. As miniaturas e o som de confirmação reutilizam assets originais do projeto. |
| OpenAI Codex | Pixel art procedural, implementação visual e testes da T-014 | Oito quadros de Seu Antônio no gerador GDScript, ajustes de nitidez e miniaturas, animações e efeitos de movimento, respiração e combate, aviso do chefe, cálculo de dano, sinal de acerto e validação no Godot. As contribuições reutilizam a arte original do projeto e foram produzidas sem assets externos. |
| OpenAI Codex | T-016, arte e programação de Três Turnos | Dez PNGs originais desenhados em matrizes de pixels e GDScript. O estudante usa `assets/warrior_stark_pixel.png` como referência visual de cabelo e figurino. Codex implementou o GameManager de Corpo, Mente e Descanso e o teste headless dedicado. |
| OpenAI Codex | T-017, implementação, efeitos visuais e validação do gameplay de Três Turnos | Controle do estudante e combate integrado aos Pilares, estações com instruções retrô, recrutamento e pulso do colega, IA dos quatro inimigos, efeitos procedurais de perigo e projéteis, e validador headless dedicado. As cenas reutilizam os sprites originais da T-016. |
| OpenAI Codex | T-018, implementação, integração, redação e validação de Três Turnos | Montagem das três salas, portas e objetivos, diálogos editáveis em português, HUD dos Pilares e visão em túnel, menus e finais, efeitos de combate e gotas de água, três novos efeitos sonoros sintetizados e adaptação da trilha pelos Pilares. Reutiliza a arte e as trilhas originais do projeto. Validação automatizada no Godot 4.7.2 headless e desktop. |
