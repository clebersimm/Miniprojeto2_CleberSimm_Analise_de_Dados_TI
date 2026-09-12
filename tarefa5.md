## Tarefa 5 : Responder e recomendar   

Escreva as cinco consultas e confira se os totais fecham com a origem. Depois, no README, responda cada pergunta em texto, com o número ao lado, e feche com uma recomendação de onde abrir a próxima loja  dizendo também o que os dados não sustentam.


### Desenvolvimento    

Respostas das perguntas realizadas.   

**DEPOIS DO 05 - AS RESPOSTAS**





#### P1

**P1 : Onde está o gargalo da entrega?** Qual o tempo médio, em dias, entre o pedido entrar no ERP e chegar na casa do cliente? E qual dos quatro intervalos do processo  Integração → Separação, Separação → Nota, Nota → Despacho, Despacho → Entrega  é o mais lento? O gargalo é o mesmo nos três portes de loja?  

```sql
SELECT
    l.porte,
    ROUND(AVG(f.dias_integracao_separacao)::numeric, 2) AS media_integracao_separacao,
    ROUND(AVG(f.dias_separacao_nota)::numeric, 2)        AS media_separacao_nota,
    ROUND(AVG(f.dias_nota_despacho)::numeric, 2)         AS media_nota_despacho,
    ROUND(AVG(f.dias_despacho_entrega)::numeric, 2)      AS media_despacho_entrega,
    ROUND(AVG(f.dias_total_ate_entrega)::numeric, 2)     AS media_total_ate_entrega
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
WHERE f.sk_loja <> -1
GROUP BY l.porte
UNION ALL
SELECT
    'Total Rede' AS porte,
    ROUND(AVG(f.dias_integracao_separacao)::numeric, 2),
    ROUND(AVG(f.dias_separacao_nota)::numeric, 2),
    ROUND(AVG(f.dias_nota_despacho)::numeric, 2),
    ROUND(AVG(f.dias_despacho_entrega)::numeric, 2),
    ROUND(AVG(f.dias_total_ate_entrega)::numeric, 2)
FROM fato_pedido f
WHERE f.sk_loja <> -1
ORDER BY media_total_ate_entrega DESC;
```

```sql
porte     |media_integracao_separacao|media_separacao_nota|media_nota_despacho|media_despacho_entrega|media_total_ate_entrega|
----------+--------------------------+--------------------+-------------------+----------------------+-----------------------+
Pequena   |                      3.02|                0.69|               8.53|                  2.86|                  15.16|
Total Rede|                      2.13|                0.64|               4.11|                  2.14|                   9.00|
Media     |                      1.98|                0.62|               3.34|                  2.03|                   7.95|
Grande    |                      1.96|                0.64|               3.32|                  2.01|                   7.93|
```

#### P2

**P2 : Qual categoria concentra o faturamento?** Do faturamento total da rede, quanto vem de cada categoria de produto? Agrupe pelo nome padronizado, nunca pela grafia crua, e mostre também o percentual do total. A categoria campeã é a mesma nos três portes de loja?  


```sql
SELECT
    (SELECT ROUND(SUM(vl_liquido)) FROM fato_pedido)             AS total_na_fato,
    (SELECT ROUND(SUM(f.vl_liquido)) FROM fato_pedido f
       JOIN dim_categoria c ON c.sk_categoria = f.sk_categoria)  AS total_pela_P2;
```


```sql
SELECT
    c.nome_categoria,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento,
    ROUND(
        (SUM(f.vl_liquido) * 100.0) / (SELECT SUM(vl_liquido) FROM fato_pedido),
        2
    ) AS perc_faturamento
FROM fato_pedido f
JOIN dim_categoria c ON c.sk_categoria = f.sk_categoria
GROUP BY c.nome_categoria
ORDER BY faturamento DESC;
-- Cruzamento por porte de loja para verificar a categoria campea
SELECT
    l.porte,
    c.nome_categoria,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento,
    ROUND(
        (SUM(f.vl_liquido) * 100.0) / SUM(SUM(f.vl_liquido)) OVER (PARTITION BY l.porte),
        2
    ) AS perc_porte
FROM fato_pedido f
JOIN dim_categoria c ON c.sk_categoria = f.sk_categoria
JOIN dim_loja l ON l.sk_loja = f.sk_loja
WHERE f.sk_loja <> -1
GROUP BY l.porte, c.nome_categoria
ORDER BY l.porte, faturamento DESC;
```

```sql
porte  |nome_categoria|faturamento|perc_porte|
-------+--------------+-----------+----------+
Grande |Racao         |  468186.60|     59.92|
Grande |Medicamento   |  135928.72|     17.40|
Grande |Petisco       |   56003.89|      7.17|
Grande |Servico       |   41775.77|      5.35|
Grande |Higiene       |   39253.11|      5.02|
Grande |Acessorio     |   26423.80|      3.38|
Grande |Brinquedo     |   13822.08|      1.77|
Media  |Racao         |  443131.62|     60.14|
Media  |Medicamento   |  128625.36|     17.46|
Media  |Petisco       |   51173.37|      6.94|
Media  |Servico       |   37051.79|      5.03|
Media  |Higiene       |   34716.87|      4.71|
Media  |Acessorio     |   27991.06|      3.80|
Media  |Brinquedo     |   14192.11|      1.93|
Pequena|Racao         |  164197.55|     59.92|
Pequena|Medicamento   |   41349.95|     15.09|
Pequena|Petisco       |   21291.38|      7.77|
Pequena|Higiene       |   18166.47|      6.63|
Pequena|Servico       |   15173.81|      5.54|
Pequena|Acessorio     |   10246.53|      3.74|
Pequena|Brinquedo     |    3620.37|      1.32|
```

#### P3

**P3 : O desconto funciona igual em todo canal?** Compare o ticket médio COM e SEM desconto dentro de cada canal de venda (App, Site, Loja Física, Telefone, WhatsApp). Se o desconto derruba o ticket em um canal e não em outro, a política não deveria ser a mesma nos dois. Diga também quanto cada canal representa do faturamento.  


```sql
SELECT
    canal_pedido,
    COUNT(sk_pedido) AS total_pedidos,
    ROUND(SUM(vl_liquido), 2) AS faturamento,
    ROUND(
        (SUM(vl_liquido) * 100.0) / (SELECT SUM(vl_liquido) FROM fato_pedido),
        2
    ) AS perc_faturamento,
    ROUND(AVG(CASE WHEN houve_desconto = 'Sim' THEN vl_liquido END)::numeric, 2) AS ticket_com_desconto,
    ROUND(AVG(CASE WHEN houve_desconto = 'Nao' THEN vl_liquido END)::numeric, 2) AS ticket_sem_desconto,
    ROUND(
        (
            (AVG(CASE WHEN houve_desconto = 'Sim' THEN vl_liquido END) - 
             AVG(CASE WHEN houve_desconto = 'Nao' THEN vl_liquido END))
            * 100.0 / AVG(CASE WHEN houve_desconto = 'Nao' THEN vl_liquido END)
        )::numeric,
        2
    ) AS variacao_ticket_perc
FROM fato_pedido
GROUP BY canal_pedido
ORDER BY faturamento DESC;
```

```sql
canal_pedido |total_pedidos|faturamento|perc_faturamento|ticket_com_desconto|ticket_sem_desconto|variacao_ticket_perc|
-------------+-------------+-----------+----------------+-------------------+-------------------+--------------------+
App          |         1273|  552134.43|           30.79|             488.04|             167.63|              191.14|
Site         |         1032|  450569.37|           25.13|             501.92|             189.68|              164.61|
Loja Fisica  |          824|  360677.22|           20.11|             494.04|             197.55|              150.08|
WhatsApp     |          414|  188678.63|           10.52|             514.33|             179.26|              186.91|
Telefone     |          264|  123419.29|            6.88|             514.02|             195.23|              163.29|
Nao Informado|          237|  117829.57|            6.57|             561.59|             206.95|              171.37|
```


#### P4

**P4 : Qual praça de atendimento concentra o faturamento?** Atenção: uma loja entrega em mais de uma praça. O rateio precisa ser feito pelo percentual do público, e a soma por praça tem de fechar com o faturamento da rede. Cruze o faturamento rateado com o número de domicílios com pet de cada praça.  

```sql
SELECT
    p.nome_praca,
    p.regional,
    p.domicilios_com_pet,
    ROUND(SUM(f.vl_liquido * b.fator_publico), 2) AS faturamento_rateado,
    ROUND(
        (SUM(f.vl_liquido * b.fator_publico) * 100.0) / (SELECT SUM(vl_liquido) FROM fato_pedido),
        2
    ) AS perc_faturamento,
    ROUND(
        (SUM(f.vl_liquido * b.fator_publico) / p.domicilios_com_pet)::numeric,
        2
    ) AS faturamento_por_domicilio_pet
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
JOIN bridge_loja_praca b ON b.cod_loja = l.cod_loja
JOIN dim_praca p ON p.sk_praca = b.sk_praca
GROUP BY p.nome_praca, p.regional, p.domicilios_com_pet
ORDER BY faturamento_rateado DESC;
```

```sql
nome_praca          |regional      |domicilios_com_pet|faturamento_rateado|perc_faturamento|faturamento_por_domicilio_pet|
--------------------+--------------+------------------+-------------------+----------------+-----------------------------+
Vale do Itajai      |Regional Leste|            148000|          633746.09|           35.34|                         4.28|
Grande Florianopolis|Regional Leste|            132000|          283546.75|           15.81|                         2.15|
Norte Industrial    |Regional Norte|             96000|          175431.90|            9.78|                         1.83|
Litoral Sul         |Regional Sul  |             58000|          137051.20|            7.64|                         2.36|
Litoral Norte       |Regional Norte|             61000|          128872.75|            7.19|                         2.11|
Extremo Oeste       |Regional Oeste|             63000|           98359.18|            5.48|                         1.56|
Carbonifera         |Regional Sul  |             67000|           88707.42|            4.95|                         1.32|
Serra Catarinense   |Regional Oeste|             44000|           80477.64|            4.49|                         1.83|
Meio-Oeste          |Regional Oeste|             51000|           58955.63|            3.29|                         1.16|
Foz do Itajai       |Regional Leste|             74000|           46749.72|            2.61|                         0.63|
Planalto Norte      |Regional Norte|             33000|           31100.84|            1.73|                         0.94|
Planalto Serrano    |Regional Oeste|             29000|           29323.10|            1.64|                         1.01|
```


#### P5  

**P5 : Onde abrir a próxima loja, e o que os dados NÃO permitem afirmar?**   
1) Ranqueie as lojas por itens vendidos por mil habitantes da cidade  não em valor absoluto  e cruze com o tempo médio de entrega.   
2) A faixa de franquia no cadastro é a de hoje: o passado foi sobrescrito. Mostre o faturamento por faixa ATUAL e explique por que isso não responde “quanto veio de lojas que JÁ ERAM Ouro na data do pedido”.  
3) Meça o que ficou de fora: pedidos sem loja identificada, entregas ainda não concluídas, itens e valores em branco.


1) Ranqueie as lojas por itens vendidos por mil habitantes da cidade  não em valor absoluto  e cruze com o tempo médio de entrega.   

```sql
-- (a) Ranking de lojas por itens por mil habitantes e tempo medio de entrega
SELECT
    l.nome_loja,
    l.cidade,
    l.populacao_cidade,
    SUM(f.qt_itens) AS total_itens_vendidos,
    ROUND(
        (SUM(f.qt_itens) * 1000.0) / l.populacao_cidade,
        2
    ) AS itens_por_mil_hab,
    ROUND(AVG(f.dias_total_ate_entrega)::numeric, 2) AS media_dias_entrega,
    COUNT(f.sk_pedido) AS total_pedidos,
    COUNT(f.dias_total_ate_entrega) AS pedidos_entregues
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
WHERE f.sk_loja <> -1
GROUP BY l.nome_loja, l.cidade, l.populacao_cidade
ORDER BY itens_por_mil_hab DESC;
```

```sql
nome_loja                           |cidade                   |populacao_cidade|total_itens_vendidos|itens_por_mil_hab|media_dias_entrega|total_pedidos|pedidos_entregues|
------------------------------------+-------------------------+----------------+--------------------+-----------------+------------------+-------------+-----------------+
Pata Amiga Rio dos Cedros           |Rio dos Cedros           |           11322|                 474|            41.87|             14.24|           61|               29|
Pata Amiga Presidente Getulio       |Presidente Getúlio       |           16359|                 570|            34.84|             14.16|           88|               43|
Pata Amiga Ibirama                  |Ibirama                  |           18613|                 597|            32.07|             15.39|           98|               54|
Pata Amiga Itapoa                   |Itapoá                   |           20586|                 534|            25.94|             15.39|           84|               36|
Pata Amiga Santo Amaro da Imperatriz|Santo Amaro da Imperatriz|           22357|                 530|            23.71|             15.88|           85|               50|
Pata Amiga Taio                     |Taió                     |           18173|                 352|            19.37|             14.57|           59|               30|
Pata Amiga Timbo                    |Timbó                    |           45011|                 804|            17.86|              7.70|          123|               60|
Pata Amiga Gaspar                   |Gaspar                   |           71133|                1189|            16.72|              8.01|          181|               96|
Pata Amiga Otacilio Costa           |Otacílio Costa           |           18227|                 289|            15.86|             15.61|           44|               18|
Pata Amiga Ituporanga               |Ituporanga               |           25748|                 354|            13.75|             16.53|           51|               19|
Pata Amiga Rio do Sul               |Rio do Sul               |           73135|                 885|            12.10|              8.35|          149|               86|
Pata Amiga Sao Joaquim              |São Joaquim              |           27234|                 320|            11.75|             15.07|           45|               27|
Pata Amiga Laguna                   |Laguna                   |           46122|                 541|            11.73|              8.51|           80|               45|
Pata Amiga Indaial                  |Indaial                  |           71987|                 750|            10.42|              7.74|          128|               65|
Pata Amiga Ararangua                |Araranguá                |           68274|                 689|            10.09|              8.25|          107|               68|
Pata Amiga Tubarao                  |Tubarão                  |          105511|                 889|             8.43|              7.69|          157|               83|
Pata Amiga Jaragua do Sul           |Jaraguá do Sul           |          184579|                1507|             8.16|              8.01|          239|              120|
Pata Amiga Curitibanos              |Curitibanos              |           39061|                 308|             7.89|              8.65|           47|               20|
Pata Amiga Sao Bento do Sul         |São Bento do Sul         |           87310|                 567|             6.49|              8.18|          105|               55|
Pata Amiga Concordia                |Concórdia                |           74641|                 470|             6.30|              7.74|           89|               39|
Pata Amiga Blumenau Centro          |Blumenau                 |          361855|                2002|             5.53|              7.80|          315|              154|
Pata Amiga Xanxere                  |Xanxerê                  |           52034|                 284|             5.46|              8.17|           54|               29|
Pata Amiga Palhoca                  |Palhoça                  |          168259|                 844|             5.02|              7.69|          172|               85|
Pata Amiga Sao Miguel do Oeste      |São Miguel do Oeste      |           41520|                 186|             4.48|              8.00|           42|               25|
Pata Amiga Brusque                  |Brusque                  |          143270|                 558|             3.89|              7.63|          122|               63|
Pata Amiga Criciuma                 |Criciúma                 |          217392|                 822|             3.78|              8.07|          152|               76|
Pata Amiga Lages                    |Lages                    |          158846|                 593|             3.73|              7.69|          107|               61|
Pata Amiga Sao Jose Kobrasol        |São José                 |          250181|                 929|             3.71|              8.01|          155|               75|
Pata Amiga Chapeco                  |Chapecó                  |          254235|                 824|             3.24|              7.85|          159|               82|
Pata Amiga Joinville Sul            |Joinville                |          597658|                1888|             3.16|              7.83|          309|              156|
Pata Amiga Itajai Praia             |Itajaí                   |          264054|                 798|             3.02|              7.98|          159|               96|
Pata Amiga Florianopolis Norte      |Florianópolis            |          537213|                1426|             2.65|              8.02|          275|              144|
```

2) A faixa de franquia no cadastro é a de hoje: o passado foi sobrescrito. Mostre o faturamento por faixa ATUAL e explique por que isso não responde “quanto veio de lojas que JÁ ERAM Ouro na data do pedido”.  

```sql
-- (b) Faturamento por faixa ATUAL de franquia (SCD Tipo 1)
SELECT
    COALESCE(l.faixa_franquia, 'Sem Loja Identificada') AS faixa_franquia_atual,
    COUNT(DISTINCT l.cod_loja) AS total_lojas,
    COUNT(f.sk_pedido) AS total_pedidos,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento_total,
    ROUND(
        (SUM(f.vl_liquido) * 100.0) / (SELECT SUM(vl_liquido) FROM fato_pedido),
        2
    ) AS perc_faturamento
FROM fato_pedido f
LEFT JOIN dim_loja l ON l.sk_loja = f.sk_loja
GROUP BY l.faixa_franquia
ORDER BY faturamento_total DESC;
```

```sql
faixa_franquia_atual|total_lojas|total_pedidos|faturamento_total|perc_faturamento|
--------------------+-----------+-------------+-----------------+----------------+
Ouro                |         15|         2316|       1011264.38|           56.39|
Diamante            |          5|          818|        382209.74|           21.31|
Prata               |          8|          719|        314812.03|           17.55|
Bronze              |          4|          188|         84036.06|            4.69|
Nao Informado       |          1|            3|           986.30|            0.05|
```

3) Meça o que ficou de fora: pedidos sem loja identificada, entregas ainda não concluídas, itens e valores em branco.   

```sql
-- (c) Medir o que ficou de fora (auditoria de incompletude)
SELECT
    'Pedidos sem loja identificada (linha -1)' AS metrica,
    COUNT(*) AS quantidade_pedidos,
    ROUND(SUM(vl_liquido), 2) AS faturamento_impactado,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM fato_pedido), 2) AS perc_pedidos
FROM fato_pedido
WHERE sk_loja = -1
UNION ALL
SELECT
    'Entregas ainda nao concluidas (tempo entrega -1)',
    COUNT(*),
    ROUND(SUM(vl_liquido), 2),
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM fato_pedido), 2)
FROM fato_pedido
WHERE sk_tempo_entrega = -1
UNION ALL
SELECT
    'Pedidos com quantidade de itens nula/em branco',
    COUNT(*),
    ROUND(SUM(vl_liquido), 2),
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM fato_pedido), 2)
FROM fato_pedido
WHERE qt_itens IS NULL
UNION ALL
SELECT
    'Pedidos com valor liquido nulo/em branco',
    COUNT(*),
    0.00,
    ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM fato_pedido), 2)
FROM fato_pedido
WHERE vl_liquido IS NULL;
```

```sql
metrica                                         |quantidade_pedidos|faturamento_impactado|perc_pedidos|
------------------------------------------------+------------------+---------------------+------------+
Pedidos sem loja identificada (linha -1)        |                 3|               986.30|        0.07|
Entregas ainda nao concluidas (tempo entrega -1)|              1953|            873892.40|       48.29|
Pedidos com quantidade de itens nula/em branco  |               257|            119711.86|        6.36|
Pedidos com valor liquido nulo/em branco        |               121|                 0.00|        2.99|
```