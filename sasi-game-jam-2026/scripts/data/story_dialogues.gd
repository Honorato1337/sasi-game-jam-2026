extends RefCounted
## Para editar a história, encontre abaixo a cena que deseja mudar.
## Edite o texto entre aspas em "speaker" (nome) e "text" (fala).
## Em "portrait", use "student" para o Estudante ou "classmate" para o Colega.
## Para adicionar falas, copie uma linha inteira, incluindo a vírgula.
## Mantenha as chaves das cenas e prefira falas curtas para caber na caixa.

const SEQUENCES: Dictionary = {
	"room_1_morning": [
		{"speaker": "Estudante", "portrait": "student", "text": "Peraí... eu caí dentro do jogo?! Que viagem é essa, tô até de espada na mão..."},
		{"speaker": "Estudante", "portrait": "student", "text": "Que vultos são esses no meu quarto? Meu corpo tá pesado demais hoje..."},
		{"speaker": "Estudante", "portrait": "student", "text": "Tô com a boca seca desde cedo. Melhor beber uma água ali antes de ir. [E]"},
	],
	"room_2_afternoon": [
		{"speaker": "Estudante", "portrait": "student", "text": "O lab à tarde... só de olhar pra essas bancadas já bate o peso das entregas."},
		{"speaker": "Estudante", "portrait": "student", "text": "Ó, tem colega meu ali no canto! Vou pedir uma força antes que eu trave. [E]"},
	],
	"classmate_help": [
		{"speaker": "Colega", "portrait": "classmate", "text": "Ei, calma! Respira comigo... você não precisa carregar o semestre nas costas."},
		{"speaker": "Colega", "portrait": "classmate", "text": "Deixa que eu te ajudo aqui. Fica perto de mim pra esfriar um pouco a cabeça."},
	],
	"room_3_night": [
		{"speaker": "Estudante", "portrait": "student", "text": "Já escureceu e minha cabeça continua a mil... parece que esse dia não acaba."},
		{"speaker": "Estudante", "portrait": "student", "text": "Não adianta só bater. Se eu não cuidar do corpo e descansar, não saio daqui."},
	],
	"room_4_c2_morning": [
		{"speaker": "Estudante", "portrait": "student", "text": "De manhã de novo?! Não acredito que voltei pro começo... pera, olha aquilo."},
		{"speaker": "Estudante", "portrait": "student", "text": "A fumaça tá baixando... esse cabelo ruivo, essa mochila nas costas... sou eu?!"},
	],
	"room_5_c2_afternoon": [
		{"speaker": "Estudante", "portrait": "student", "text": "Outra tarde preso no lab... quanto mais eu corro, mais cobrança aparece!"},
		{"speaker": "Estudante", "portrait": "student", "text": "Não dá pra resolver tudo no grito. Só preciso aguentar firme até bater o sinal!"},
	],
	"room_6_c2_night": [
		{"speaker": "Estudante", "portrait": "student", "text": "Mais uma madrugada em claro... cada descuido meu virou sombra nessa sala."},
		{"speaker": "Estudante", "portrait": "student", "text": "Um gole d'água, uma pausa, puxar o ar [R]... eu não vou pifar aqui dentro."},
	],
	"room_7_c3_morning": [
		{"speaker": "Estudante", "portrait": "student", "text": "A fumaça sumiu de vez... olha pra eles. Todos eles têm o meu rosto."},
		{"speaker": "Estudante", "portrait": "student", "text": "Nunca teve monstro nenhum aqui. Era só eu me cobrando até não sobrar nada."},
	],
	"room_8_c3_afternoon": [
		{"speaker": "Estudante", "portrait": "student", "text": "Última aula do dia. Chega de me atropelar tentando dar conta de tudo."},
		{"speaker": "Estudante", "portrait": "student", "text": "Só segurar a onda até o último sinal... dessa vez respeitando o meu limite."},
	],
	"room_9_c3_night": [
		{"speaker": "Estudante", "portrait": "student", "text": "Olha o meu estado... esse gigante aí na frente é tudo que eu engoli calado."},
		{"speaker": "Estudante", "portrait": "student", "text": "Chega de me deixar pra depois. Vou manter os pilares acesos, respirar [R] e sair!"},
	],
	"respite_1": [
		{"speaker": "Colega", "portrait": "classmate", "text": "Passamos do primeiro aperto. Vem cá, pega um vento aqui fora... sem pressa."},
		{"speaker": "Estudante", "portrait": "student", "text": "Nossa, eu precisava desse silêncio... Vou anotar uma meta ali no caderno [E]."},
	],
	"respite_2": [
		{"speaker": "Colega", "portrait": "classmate", "text": "Olha o tanto que você já segurou. Descansa um pouco, ninguém tá te cobrando aqui."},
		{"speaker": "Estudante", "portrait": "student", "text": "Valeu por ficar comigo. Vou escolher mais um cuidado ali [E] antes de voltar."},
	],
	"respite_ally_chat": [
		{"speaker": "Colega", "portrait": "classmate", "text": "A faculdade importa, mas você vem primeiro. Tamo junto até amanhecer!"},
	],
	"victory": [
		{"speaker": "Estudante", "portrait": "student", "text": "Passou... o peso soltou do peito. Eu só precisava parar de brigar comigo mesmo."},
		{"speaker": "Estudante", "portrait": "student", "text": "A luz da TV tá me chamando... acho que finalmente posso voltar pro meu quarto."},
	],
}
