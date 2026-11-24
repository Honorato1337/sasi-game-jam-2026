extends RefCounted
## Para editar a história, encontre abaixo a cena que deseja mudar.
## Edite o texto entre aspas em "speaker" (nome) e "text" (fala).
## Em "portrait", use "student" para o Estudante ou "classmate" para o Colega.
## Para adicionar falas, copie uma linha inteira, incluindo a vírgula.
## Mantenha as chaves das cenas e prefira falas curtas para caber na caixa.

const SEQUENCES: Dictionary = {
	"room_1_morning": [
		{"speaker": "Estudante", "portrait": "student", "text": "Mal abri os olhos e meu corpo já pesa como no fim do dia."},
		{"speaker": "Estudante", "portrait": "student", "text": "Na minha cabeça, a mochila vira armadura. E o lápis, espada."},
		{"speaker": "Estudante", "portrait": "student", "text": "Antes de enfrentar o dia, preciso beber água. A garrafa está ali. [E]"},
	],
	"room_2_afternoon": [
		{"speaker": "Estudante", "portrait": "student", "text": "No laboratório, cada notificação parece acrescentar outra tarefa à lista."},
		{"speaker": "Estudante", "portrait": "student", "text": "Meu colega está perto da bancada. Posso pedir ajuda. [E]"},
	],
	"classmate_help": [
		{"speaker": "Colega", "portrait": "classmate", "text": "Senta aqui um instante. Quer me dizer o que está pesando?"},
		{"speaker": "Colega", "portrait": "classmate", "text": "Vamos por partes. Eu fico com você enquanto a gente abre caminho."},
	],
	"room_3_night": [
		{"speaker": "Estudante", "portrait": "student", "text": "Já é madrugada. A Sombra do Burnout se ergue entre os três pilares."},
		{"speaker": "Estudante", "portrait": "student", "text": "Corpo, Mente, Descanso. Se um vacilar, corro até ele. Ainda dá tempo de respirar."},
	],
	"victory": [
		{"speaker": "Estudante", "portrait": "student", "text": "A luz voltou pela janela. Pela primeira vez hoje, consigo largar a espada."},
		{"speaker": "Estudante", "portrait": "student", "text": "Amanhã eu começo com água, uma pausa e uma mensagem para quem caminha comigo."},
	],
}
