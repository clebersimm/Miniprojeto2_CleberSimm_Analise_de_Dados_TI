## Tarefa 4 : Construir a fato    

fato\_pedido  uma linha por pedido. 4.044 linhas. É um único INSERT ... SELECT, sem subconsulta: só SELECT, JOIN, LEFT JOIN e CASE WHEN.  
A regra que organiza o arquivo: a limpeza fica na dimensão, e a fato apenas procura a linha certa. Nenhuma FK fica nula  quando o dado falta, ela aponta para a linha \-1.  
As cinco colunas de dias, calculadas UMA vez aqui na carga. Atenção: são QUATRO intervalos do processo mais o TOTAL  a última linha da tabela não é um intervalo, é o processo inteiro, e é ela que responde a P1.

| Coluna | Marco de início | Marco de fim |
| :---- | :---- | :---- |
| dias\_integracao\_separacao | DtHoraIntegracaoERP | Dt Separacao Estoque |
| dias\_separacao\_nota | Dt Separacao Estoque | DtNotaFiscal |
| dias\_nota\_despacho | DtNotaFiscal | Dt\_Despacho\_Transportadora |
| dias\_despacho\_entrega | Dt\_Despacho\_Transportadora | DtEntregaCliente |
| dias\_total\_ate\_entrega | DtHoraIntegracaoERP | DtEntregaCliente |

Se o marco de FIM vier em branco, grave NULL  nunca 0\. AVG ignora NULL, mas soma o zero: um zero no lugar de “não aconteceu” faria o gargalo da P1 parecer mais rápido do que é.



Execução da tarefa 4, populando a tabela fato.   

1. Foi realizado um único INSERT ... SELECT para carregar a tabela fato_pedido a partir dos pedidos armazenados em stg_pedido.
2. As datas foram convertidas para formatos padronizados, gerando chaves substitutas no padrão numérico AAAAMMDD.
3. As lojas e categorias foram relacionadas às respectivas dimensões utilizando LEFT JOIN, preservando todos os pedidos carregados.
4. Nomes de lojas foram normalizados, removendo acentos, espaços duplicados, sufixos estaduais e corrigindo variações cadastrais.
5. Registros sem correspondência dimensional receberam a chave -1, evitando valores nulos nas chaves estrangeiras.
6. Os campos de desconto e canal de pedido foram padronizados mediante regras CASE, classificando diferentes formatos de preenchimento.
7. Quantidades e valores monetários foram convertidos para tipos numéricos, tratando registros vazios, hífens, símbolos monetários e separadores brasileiros.
8. Foram calculados os intervalos em dias entre integração, separação, emissão da nota, despacho e entrega ao cliente.
9. Registros sem datas necessárias permaneceram com intervalos nulos, evitando interpretações incorretas de etapas não realizadas.
10. Ao final, foram executadas conferências para validar a quantidade de pedidos, chaves estrangeiras, datas, canais e possíveis períodos negativos.


```sql
SELECT COUNT(*) AS linhas, '4044' AS esperado FROM fato_pedido;
```

```sql
linhas|esperado|
------+--------+
  4044|4044    |
```

```sql
-- Nenhuma FK pode ser nula, e nenhuma pode apontar para chave inexistente.
SELECT 'FK nula' AS teste, COUNT(*) AS deve_ser_zero FROM fato_pedido
WHERE sk_loja IS NULL OR sk_categoria IS NULL
   OR sk_tempo_pedido IS NULL OR sk_tempo_entrega IS NULL
UNION ALL SELECT 'FK orfa (loja)', COUNT(*)
FROM fato_pedido f LEFT JOIN dim_loja d ON d.sk_loja = f.sk_loja
WHERE d.sk_loja IS NULL
UNION ALL SELECT 'FK orfa (categoria)', COUNT(*)
FROM fato_pedido f LEFT JOIN dim_categoria d ON d.sk_categoria = f.sk_categoria
WHERE d.sk_categoria IS NULL
UNION ALL SELECT 'FK orfa (tempo da entrega)', COUNT(*)
FROM fato_pedido f LEFT JOIN dim_tempo d ON d.sk_tempo = f.sk_tempo_entrega
WHERE d.sk_tempo IS NULL;
```

```sql
teste                     |deve_ser_zero|
--------------------------+-------------+
FK nula                   |            0|
FK orfa (loja)            |            0|
FK orfa (categoria)       |            0|
FK orfa (tempo da entrega)|            0|
```

```sql
SELECT 'pedidos sem loja (na linha -1)' AS informativo, COUNT(*) AS valor,
       '3' AS esperado FROM fato_pedido WHERE sk_loja = -1
UNION ALL SELECT 'entregas ainda nao feitas (tempo na -1)', COUNT(*), '1953'
FROM fato_pedido WHERE sk_tempo_entrega = -1;
```

```sql
informativo                            |valor|esperado|
---------------------------------------+-----+--------+
pedidos sem loja (na linha -1)         |    3|3       |
entregas ainda nao feitas (tempo na -1)| 1953|1953    |
```

```sql
-- Ordem do CASE do canal (arquivo 04): o WhatsApp tem de aparecer na fato.
-- Se esta consulta voltar VAZIA, o CASE testou APP antes de WHATS e os pedidos
-- de WhatsApp foram parar dentro do App.
SELECT canal_pedido, COUNT(*) AS pedidos FROM fato_pedido
WHERE canal_pedido = 'WhatsApp' GROUP BY canal_pedido;
```

```sql
canal_pedido|pedidos|
------------+-------+
WhatsApp    |    414|
```

```sql
-- Periodo dos pedidos: deve ir de 01/09/2023 a 31/03/2024. Data minima ou
-- maxima fora disso indica mascara de data errada.
SELECT MIN(dt_pedido::date) AS primeiro_pedido, MAX(dt_pedido::date) AS ultimo_pedido,
       '2023-09-01 a 2024-03-31' AS esperado FROM fato_pedido;
```

```sql
primeiro_pedido|ultimo_pedido|esperado               |
---------------+-------------+-----------------------+
     2023-09-01|   2024-03-31|2023-09-01 a 2024-03-31|
```

```sql
-- Os dias nunca podem ser negativos: o processo e sequencial.
SELECT 'dias negativos' AS teste, COUNT(*) AS deve_ser_zero FROM fato_pedido
WHERE dias_integracao_separacao < 0 OR dias_separacao_nota < 0
   OR dias_nota_despacho < 0 OR dias_despacho_entrega < 0
   OR dias_total_ate_entrega < 0;
```

```sql
teste         |deve_ser_zero|
--------------+-------------+
dias negativos|            0|
```