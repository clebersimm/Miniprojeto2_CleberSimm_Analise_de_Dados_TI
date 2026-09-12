-- =====================================================================================
--  ARQUIVO 4:  A TABELA FATO
--  Case: Pata Amiga - rede de petshops de SC  |  PostgreSQL 16
-- =====================================================================================
--  Rode depois de: 03-dimensoes.sql
--
--  UMA fato, UM unico INSERT ... SELECT. A tabela ja existe, vazia (arquivo 02).
--  4.044 linhas = 4.044 pedidos.
--
--  Regra geral: a limpeza dos dados fica nas dimensoes; a fato apenas procura a
--  linha correta (por JOIN). Nenhuma FK fica nula: quando o dado falta, ela
--  aponta para a linha -1 (CASE WHEN ... IS NULL THEN -1).
--
--  Sugestao: comece pelo esqueleto (numero_pedido + as duas FKs de tempo +
--  FROM), rode e confira 4.044 linhas; depois acrescente as colunas aos poucos.
-- =====================================================================================

-- >>> ESCREVA AQUI o INSERT INTO fato_pedido (...) SELECT ... FROM stg_pedido ...
--
--  Roteiro das colunas:
--
--  * sk_tempo_pedido / sk_tempo_entrega: a chave e a data no formato AAAAMMDD.
--    Monte com TO_CHAR(<a data>, 'YYYYMMDD')::int. A data do PEDIDO vem no
--    formato americano com AM/PM: a mascara e 'MM/DD/YYYY HH12:MI AM'
--    (TO_TIMESTAMP). Usar 'DD/MM/YYYY' faz o PostgreSQL LANCAR ERRO nas datas
--    com mes maior que 12. Os marcos da entrega ja vem em ISO: ::date basta.
--    Entrega em branco -> -1.
--
--  * sk_loja, sk_categoria: vem de LEFT JOIN; se nao achou par, -1.
--
--  * LOJA (LEFT JOIN dim_loja): limpe o nome no ON. REPLACE tira '/SC' e o espaco
--    duplo; um CASE resolve 3 grafias (digitacao, apelido, abreviacao). O
--    PostgreSQL compara byte a byte, entao normalize acento e caixa com
--    UPPER(TRANSLATE(..., 'ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç',
--    'AAAAEEIOOOUUCaaaaeeiooouuc')). A chave_loja da dim_loja ja veio em caixa
--    alta e sem acento.
--
--  * CATEGORIA (LEFT JOIN dim_categoria): uma linha so -
--    ON dc.categoria_origem = p."CategoriaProduto".
--
--  * houve_desconto e canal_pedido: padronize com CASE e grave na PROPRIA fato
--    (nao ha dimensao para eles). O de-para completo dos dois campos esta no
--    ENUNCIADO, na secao 7 ("Como padronizar o desconto e o canal").
--    A ordem importa: 'WHATSAPP' contem 'APP',
--    entao teste WHATS antes de APP. No desconto, tire o acento com TRANSLATE
--    antes do UPPER.
--
--  * dinheiro e itens: '' e '-' viram NULL; tire "R$" e trate o milhar.
--
--  * os lags em dias: em PostgreSQL, data - data ja da o numero de dias. Etapa
--    nao cumprida grava NULL, nunca 0. Use ::date em volta da integracao.

INSERT INTO fato_pedido (
    numero_pedido,
    sk_tempo_pedido,
    sk_tempo_entrega,
    sk_loja,
    sk_categoria,
    houve_desconto,
    canal_pedido,
    dt_pedido,
    qt_itens,
    vl_liquido,
    dias_integracao_separacao,
    dias_separacao_nota,
    dias_nota_despacho,
    dias_despacho_entrega,
    dias_total_ate_entrega
)
SELECT
    p."NumeroPedido" AS numero_pedido,
    TO_CHAR(TO_TIMESTAMP(p."DtHoraPedido", 'MM/DD/YYYY HH12:MI AM'), 'YYYYMMDD')::int AS sk_tempo_pedido,
    CASE 
        WHEN p."DtEntregaCliente" IS NULL OR TRIM(p."DtEntregaCliente") IN ('', '-') THEN -1
        ELSE TO_CHAR(p."DtEntregaCliente"::date, 'YYYYMMDD')::int
    END AS sk_tempo_entrega,
    COALESCE(l.sk_loja, -1) AS sk_loja,
    COALESCE(c.sk_categoria, -1) AS sk_categoria,
    CASE 
        WHEN UPPER(TRIM(TRANSLATE(p."HouveDesconto", 'ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç', 'AAAAEEIOOOUUCaaaaeeiooouuc'))) IN ('S', 'SIM', '1', 'X', 'TRUE', 'V') THEN 'Sim'
        WHEN UPPER(TRIM(TRANSLATE(p."HouveDesconto", 'ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç', 'AAAAEEIOOOUUCaaaaeeiooouuc'))) IN ('N', 'NAO', '0', 'FALSE', 'F') THEN 'Nao'
        ELSE 'Nao Informado'
    END AS houve_desconto,
    CASE 
        WHEN UPPER(TRIM(p."CanalPedido")) LIKE '%WHATS%' THEN 'WhatsApp'
        WHEN UPPER(TRIM(p."CanalPedido")) LIKE '%APP%'   THEN 'App'
        WHEN UPPER(TRIM(p."CanalPedido")) LIKE '%SITE%'  THEN 'Site'
        WHEN UPPER(TRIM(p."CanalPedido")) LIKE '%LOJA%'  THEN 'Loja Fisica'
        WHEN UPPER(TRIM(p."CanalPedido")) LIKE '%TEL%'   THEN 'Telefone'
        ELSE 'Nao Informado'
    END AS canal_pedido,
    TO_TIMESTAMP(p."DtHoraPedido", 'MM/DD/YYYY HH12:MI AM') AS dt_pedido,
    CASE 
        WHEN TRIM(p."QTD.Itens") IN ('', '-') THEN NULL
        ELSE CAST(TRIM(p."QTD.Itens") AS INTEGER)
    END AS qt_itens,
    CASE 
        WHEN TRIM(REPLACE(p."ValorLiquidoPedido(R$)", 'R$', '')) IN ('', '-') THEN NULL
        WHEN p."ValorLiquidoPedido(R$)" LIKE '%,%'
             THEN CAST(REPLACE(REPLACE(REPLACE(REPLACE(p."ValorLiquidoPedido(R$)", 'R$', ''), ' ', ''), '.', ''), ',', '.') AS DECIMAL(15,2))
        ELSE CAST(REPLACE(REPLACE(p."ValorLiquidoPedido(R$)", 'R$', ''), ' ', '') AS DECIMAL(15,2))
    END AS vl_liquido,
    CASE 
        WHEN p."Dt Separacao Estoque" IS NULL OR TRIM(p."Dt Separacao Estoque") IN ('', '-') THEN NULL
        ELSE (p."Dt Separacao Estoque"::date - TO_TIMESTAMP(p."DtHoraIntegracaoERP", 'MM/DD/YYYY HH12:MI AM')::date)
    END AS dias_integracao_separacao,
    CASE 
        WHEN p."Dt Separacao Estoque" IS NULL OR TRIM(p."Dt Separacao Estoque") IN ('', '-')
          OR p."DtNotaFiscal" IS NULL OR TRIM(p."DtNotaFiscal") IN ('', '-') THEN NULL
        ELSE (p."DtNotaFiscal"::date - p."Dt Separacao Estoque"::date)
    END AS dias_separacao_nota,
    CASE 
        WHEN p."DtNotaFiscal" IS NULL OR TRIM(p."DtNotaFiscal") IN ('', '-')
          OR p."Dt_Despacho_Transportadora" IS NULL OR TRIM(p."Dt_Despacho_Transportadora") IN ('', '-') THEN NULL
        ELSE (p."Dt_Despacho_Transportadora"::date - p."DtNotaFiscal"::date)
    END AS dias_nota_despacho,
    CASE 
        WHEN p."Dt_Despacho_Transportadora" IS NULL OR TRIM(p."Dt_Despacho_Transportadora") IN ('', '-')
          OR p."DtEntregaCliente" IS NULL OR TRIM(p."DtEntregaCliente") IN ('', '-') THEN NULL
        ELSE (p."DtEntregaCliente"::date - p."Dt_Despacho_Transportadora"::date)
    END AS dias_despacho_entrega,
    CASE 
        WHEN p."DtEntregaCliente" IS NULL OR TRIM(p."DtEntregaCliente") IN ('', '-') THEN NULL
        ELSE (p."DtEntregaCliente"::date - TO_TIMESTAMP(p."DtHoraIntegracaoERP", 'MM/DD/YYYY HH12:MI AM')::date)
    END AS dias_total_ate_entrega
FROM stg_pedido p
LEFT JOIN dim_loja l ON l.chave_loja = (
    CASE 
        WHEN UPPER(TRIM(REPLACE(REPLACE(TRANSLATE(p."Loja-Nome", 'ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç', 'AAAAEEIOOOUUCaaaaeeiooouuc'), '/SC', ''), '  ', ' '))) = 'PATA AMIGA BLUMENAL CENTRO'
             THEN 'PATA AMIGA BLUMENAU CENTRO'
        WHEN UPPER(TRIM(REPLACE(REPLACE(TRANSLATE(p."Loja-Nome", 'ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç', 'AAAAEEIOOOUUCaaaaeeiooouuc'), '/SC', ''), '  ', ' '))) = 'PATA AMIGA FLORIPA NORTE'
             THEN 'PATA AMIGA FLORIANOPOLIS NORTE'
        WHEN UPPER(TRIM(REPLACE(REPLACE(TRANSLATE(p."Loja-Nome", 'ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç', 'AAAAEEIOOOUUCaaaaeeiooouuc'), '/SC', ''), '  ', ' '))) = 'PATA AMIGA JGUA DO SUL'
             THEN 'PATA AMIGA JARAGUA DO SUL'
        ELSE UPPER(TRIM(REPLACE(REPLACE(TRANSLATE(p."Loja-Nome", 'ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç', 'AAAAEEIOOOUUCaaaaeeiooouuc'), '/SC', ''), '  ', ' ')))
    END
)
LEFT JOIN dim_categoria c ON c.categoria_origem = p."CategoriaProduto";

-- =====================================================================================
--  Confira o resultado com o 00-conferencia.sql (bloco "DEPOIS DO 04").
-- =====================================================================================

SELECT COUNT(*) AS linhas, '4044' AS esperado FROM fato_pedido;
-- Mais que 4.044 indica JOIN duplicando; menos, JOIN descartando linha.

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

-- Estes valores nao sao zero, e estao corretos assim.
SELECT 'pedidos sem loja (na linha -1)' AS informativo, COUNT(*) AS valor,
       '3' AS esperado FROM fato_pedido WHERE sk_loja = -1
UNION ALL SELECT 'entregas ainda nao feitas (tempo na -1)', COUNT(*), '1953'
FROM fato_pedido WHERE sk_tempo_entrega = -1;

-- Ordem do CASE do canal (arquivo 04): o WhatsApp tem de aparecer na fato.
-- Se esta consulta voltar VAZIA, o CASE testou APP antes de WHATS e os pedidos
-- de WhatsApp foram parar dentro do App.
SELECT canal_pedido, COUNT(*) AS pedidos FROM fato_pedido
WHERE canal_pedido = 'WhatsApp' GROUP BY canal_pedido;

-- Periodo dos pedidos: deve ir de 01/09/2023 a 31/03/2024. Data minima ou
-- maxima fora disso indica mascara de data errada.
SELECT MIN(dt_pedido::date) AS primeiro_pedido, MAX(dt_pedido::date) AS ultimo_pedido,
       '2023-09-01 a 2024-03-31' AS esperado FROM fato_pedido;

-- Os dias nunca podem ser negativos: o processo e sequencial.
SELECT 'dias negativos' AS teste, COUNT(*) AS deve_ser_zero FROM fato_pedido
WHERE dias_integracao_separacao < 0 OR dias_separacao_nota < 0
   OR dias_nota_despacho < 0 OR dias_despacho_entrega < 0
   OR dias_total_ate_entrega < 0;