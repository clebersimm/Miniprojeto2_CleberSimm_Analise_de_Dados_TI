### Tarefa 1.

Carga dos arquivos de banco de dados que já estão prontos para o uso **01-carga-staging.sql**

**Observação:** Utilizando usuário e senha de banco simples somente para facilitar o uso das consultas.   

Carregar os dados para dentro do banco de dados, executando os scripts de 01-carga-staging.sql: **psql -U postgres -d postgres < 01-carga-staging.sql**     
Carregar os scripts de 02-dimensoes-prontas.sql: **psql -U postgres -d postgres < 02-dimensoes-prontas.sql**    

Confirmar que os dados foram carregados de forma correta, através da execução do script 00-conferencia.sql: 

**psql -U postgres -d postgres < 00-conferencia.sql**

Resultado: 
```sql
     tabela     | linhas | esperado 
----------------+--------+----------
 stg_pedido     |   4044 |     4044
 stg_loja       |     32 |       32
 stg_loja_praca |     48 |       48
(3 rows)

                  diagnostico                   | valor |      esperado      
------------------------------------------------+-------+--------------------
 pedidos sem nome de loja (vao para a -1)       |     3 | 3
 pedidos sem Cod Loja preenchido                |  1575 | 1575  (~39%)
 grafias distintas de categoria (no PostgreSQL) |    37 | 37
 grafias distintas de CanalPedido               |    20 | (conte)
 grafias distintas de HouveDesconto             |    17 | (conte)
 grafias distintas de nome de loja              |   128 | (conte e descreva)
(6 rows)
.
.
.
```

#### Diagnóstico da origem   

**Resultado**   

|Pergunta|Resposta|
|---|---|
|Quantas gráfias de lojas existem?|128|
|Quantas de categoria?|37|
|Quantos pedidos vieram sem código de loja?|1575|
|Quantos sem nome de loja?|3|
|Quantos marcos de processo estão em branco?|6033 - detalhamento abaixo|
|Grafias distintas de canal de pedido|20|


**Desenvolvimento**

- **Quantas gráfias de lojas existem?** Sem o tratamento de dados, o sistema apresenta 128 registros de nomes diferentes, utilizando a consulta abaixo: 
Esta consulta também responde a pergunta **Quantos sem nome de loja?**

```sql
select
	sp."Loja-Nome",count(1)
from
	stg_pedido sp
group by sp."Loja-Nome"
order by sp."Loja-Nome"
```

Conforme a amostragem abaixo da consulta acima:    

```sql
Loja-Nome                           |count|
------------------------------------+-----+
                                    |    3|
Pata Amiga Ararangua                |   39|
PATA AMIGA ARARANGUA                |   19|
pata amiga araranguá                |   22|
Pata Amiga Araranguá                |   27|
Pata Amiga Blumenal Centro          |   41|
pata amiga blumenau centro          |   50|
 Pata Amiga Blumenau Centro         |   50|
.
.
.
128 rows
```
- **Quantas de categoria?** Apresenta um totald de 37, sem o tratamento dos dados.   

```sql
select
	sp."CategoriaProduto",count(1)
from
	stg_pedido sp
group by sp."CategoriaProduto"
order by sp."CategoriaProduto"

CategoriaProduto   |count|
-------------------+-----+
acessorio          |   43|
Acessorio          |   37|
ACESSORIO          |   60|
Acessório          |   53|
Acessorios         |   70|
brinquedo          |   49|
Brinquedo          |   42|
BRINQUEDO          |   50|
Brinquedos         |   51|
.
.
.
37 rows
```

- **Quantos pedidos vieram sem código de loja?**  Total de 1575

```sql
select
	count(1)
from
	stg_pedido sp
where
	TRIM(sp."Cod Loja") = '' or
	sp."Cod Loja" is null

count|
-----+
 1575|
```   

- **Canal pedido** total de 20

```sql
select
	sp."CanalPedido",count(1)
from
	stg_pedido sp
group by sp."CanalPedido"
order by sp."CanalPedido"

CanalPedido   |count|
--------------+-----+
              |  237|
app           |  312|
App           |  316|
APP           |  325|
App Pata Amiga|  320|
.
.
.
20 rows
```

- **Quantos marcos de processo estão em branco?**  Realizando a pesquisa por cada marco que está em branco. 

Data separação em branco = 1077   
Nota fiscal em bracno 1338   
Total despachos em branco = 1665   
Total de entregas para clientes = em branco 1953

```sql
select
	sum(case when sp."Dt Separacao Estoque" is null or trim(sp."Dt Separacao Estoque") = '' then 1 else 0 end) as total_dt_separacao_estoque,
	sum(case when sp."DtNotaFiscal" is null or trim(sp."DtNotaFiscal") = '' then 1 else 0 end) as total_nota_fiscal,
	sum(case when sp."Dt_Despacho_Transportadora" is null or trim(sp."Dt_Despacho_Transportadora") = '' then 1 else 0 end) as total_despacho,
	sum(case when sp."DtEntregaCliente" is null or trim(sp."DtEntregaCliente") = '' then 1 else 0 end) as total_entrega_cliente
from
	stg_pedido sp

total_dt_separacao_estoque|total_nota_fiscal|total_despacho|total_entrega_cliente|
--------------------------+-----------------+--------------+---------------------+
                      1077|             1338|          1665|                 1953|
```