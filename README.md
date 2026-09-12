# Análise de Dados com Python [T1] - Mini projeto 2

Documento de requisitos em [Mini-projeto](Mini-projeto.md)   

## Contextualização   

"A Pata Amiga é uma rede catarinense de pet shops. Começou com uma loja em Blumenau, em 2009, e hoje tem 32 lojas espalhadas pelo estado, de Itapoá a São Miguel do Oeste.
Em setembro de 2023, a rede ligou a operação de pedidos com entrega app, site, telefone, WhatsApp e a própria loja física. Em sete meses foram 4.044 pedidos. A diretoria quer usar esses sete meses para decidir o próximo ciclo: onde está o gargalo da entrega, qual categoria sustenta o faturamento, se a política de desconto funciona igual em todo canal, e onde abrir a próxima loja.
O dado existe. O problema é que ele está em três sistemas que não se falam: a plataforma de e-commerce (os pedidos e os marcos da entrega), o cadastro de lojas do franchising, e a planilha de praças de atendimento que o time de expansão mantém à parte. Cada um escreve do seu jeito: a mesma loja aparece com acento, sem acento, em caixa alta e com erro de digitação; a mesma categoria tem várias grafias; data e dinheiro vêm como texto.
Reorganizar dados não parece grande coisa até você ver o que aparece do outro lado. Quando as três bases finalmente conversam, frases assim saltam da tela: que o gargalo não está na entrega, e sim entre a nota fiscal e o despacho; que uma praça concentra faturamento muito acima do seu número de domicílios com pet."



## Desenvolvimento do desafio   

Iniciando com a configuração do ambiente, escolhido utilizar o PostgreSQL com container docker (docker-compose) para iniciar uma nova instancia do banco de dados, desta forma com isolamento.  

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


## Tarefa 2: Tatamento  && Tarefa 3: Contruir as dimensões

As tarefas 2 e 3 podem ser resolvidas em uma única tarefa, pois o tratamento de dados está diretamente relacionado com a atividade de popular as tabelas de dimensão.

Iniciando o processo com a dim_categoria, com inclusão da categoria "Nao Informado", depois disso executado INSERT com select na tabela. Para confirmar a criação correta é executado o SQL abaixo: 

```sql
SELECT 'dim_categoria'     AS tabela, COUNT(*) AS linhas,
       '38 no PostgreSQL - varia por banco' AS esperado FROM dim_categoria
UNION ALL SELECT 'dim_praca',         COUNT(*), '13  (12 pracas + a -1)' FROM dim_praca
UNION ALL SELECT 'bridge_loja_praca', COUNT(*), '48' FROM bridge_loja_praca;
```

Com resultado:   

```sql
tabela           |linhas|esperado                          |
-----------------+------+----------------------------------+
dim_categoria    |    38|38 no PostgreSQL - varia por banco|
dim_praca        |    13|13  (12 pracas + a -1)            |
bridge_loja_praca|    48|48                                |
```

Consulta de categorias padronizadas: 

```sql
SELECT COUNT(DISTINCT nome_categoria) AS categorias_padronizadas,
       '8 = as 7 categorias + a linha -1' AS esperado FROM dim_categoria;
```

Resultado: 

```sql
categorias_padronizadas|esperado                        |
-----------------------+--------------------------------+
                      8|8 = as 7 categorias + a linha -1|
```

Consulta para verificar resultados vazios: 

```sql
SELECT categoria_origem, nome_categoria FROM dim_categoria
WHERE nome_categoria = 'Nao Informado' AND sk_categoria <> -1;
```

Resultado: 

```sql
categoria_origem|nome_categoria|
----------------+--------------+
```

Consulta para verificar ordem do case:   

```sql
-- Ordem do CASE, teste 1: "Racao Medicamentosa" deve ser Medicamento.
-- Se aparecer 'Racao' na segunda coluna, o CASE testou RA antes de MED.
SELECT categoria_origem, nome_categoria, 'Medicamento' AS esperado
FROM dim_categoria WHERE UPPER(categoria_origem) LIKE '%MEDICAMENTOSA%';
```
Resultado:   

```sql
categoria_origem   |nome_categoria|esperado   |
-------------------+--------------+-----------+
Racao Medicamentosa|Medicamento   |Medicamento|
Ração Medicamentosa|Medicamento   |Medicamento|
```

Consulta da tabela ponte:  

```sql
-- A ponte: o fator deve somar 1,00 em cada loja. A consulta deve voltar VAZIA.
SELECT cod_loja, ROUND(SUM(fator_publico), 4) AS soma_dos_fatores
FROM bridge_loja_praca GROUP BY cod_loja
HAVING ROUND(SUM(fator_publico), 4) <> 1;
```

Resultado:   

```sql
cod_loja|soma_dos_fatores|
--------+----------------+
```

Consulta pelas lojas e pracas:  

```sql
-- As 32 lojas devem estar na ponte, e toda praca deve ter pelo menos uma loja.
SELECT 'lojas na ponte' AS teste, COUNT(DISTINCT cod_loja) AS valor, '32' AS esperado
FROM bridge_loja_praca
UNION ALL SELECT 'pracas na ponte', COUNT(DISTINCT sk_praca), '12' FROM bridge_loja_praca;
```

Resultado: 

```sql
teste          |valor|esperado|
---------------+-----+--------+
lojas na ponte |   32|32      |
pracas na ponte|   12|12      |
```

Consulta linha -1 nas dimensões:   

```sql
-- Toda dimensao precisa da linha -1. As duas devem aparecer aqui.
SELECT 'dim_categoria' AS dimensao, COUNT(*) AS tem_a_linha_menos_1
FROM dim_categoria WHERE sk_categoria = -1
UNION ALL SELECT 'dim_praca',       COUNT(*) FROM dim_praca       WHERE sk_praca = -1;
```

Resultado: 

```sql
dimensao     |tem_a_linha_menos_1|
-------------+-------------------+
dim_categoria|                  1|
dim_praca    |                  1|
```

### Configuração do ambiente   

Executando o banco de dados utilizando container do PostgreSQL - 16.    
Para inciar o banco de dados:
```bash
docker compose up -d
docker compose ps
```

Para carregar os arquivos de banco de dados:   

```bash
docker compose exec -T postgres \
  psql -U postgres -d postgres < 01-carga-staging.sql
docker compose exec -T postgres \
  psql -U postgres -d dw_pata_amiga < 02-dimensoes-prontas.sql
```

