

CandleBot:

# importante

# se mercado rapido - ok
# se mercado lento - muitos trades falsos

# perdeu a capacidade de ganhar no mercado lento
# achar estrategia para ganhar lento e rapido



# fazer funcao para estatistica de trades
# vai chegando orderns
# memorizo evt entrada
# memorizo evt saida
# fecho volatilidade
# OHLC.
# O (Open) – preço de abertura
# H (High)  – máxima
# L (Low) – mínima
# C (Close) – preço de fechamento


# medir velocidade de subida
# ver reversao
# estimar
#
# # fazer codigo para entrar qndo ocorre mudanca
# fazer vela em 1 segundo
# se tendencia igual por mais do que 3 segundos pode entrar
# quando vela mudar entao vender
#
# considerar um thresold minido de 1 pip para entradas e saidas
# observar stop los e gain



# indicators
# cross_mma

# calcular se o candle deve ficar acima ou abaixo
# fazer a media ponderada
# usar no lugar do close














open order
close order
check order
monitor orders
strategies
- follower


----
monitor alvo tb
check source x dest x vol

---
montar correlacionador
- bolsas x exchanges

-
usar um server redis
- fazer statisticas
qtde x num evts e sum resultado




----
notes
----
	##
	## muita atencao
	# sempre garantir o assign entre parenteses de expressoes
	# [12] pry(main)> a= true or false and false
	# => false
	# [13] pry(main)> a= (true or false and false)
	# => false
	# [14] pry(main)> a= (true or false && false)
	# => true
	# [15] pry(main)> a= (true || false && false)
	# => true
	# [16] pry(main)> a= true || false && false
	# => true
	#eh diferente