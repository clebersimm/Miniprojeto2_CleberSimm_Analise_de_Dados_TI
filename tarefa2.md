### Tarefa 2: Tratamento   

As máscaras de data que você vai precisar:

| Onde | Como vem | Como converter |
| :---- | :---- | :---- |
| DtHoraPedido, DtHoraIntegracaoERP | 11/16/2023 02:30 PM | TO\_TIMESTAMP(\<coluna\>, 'MM/DD/YYYY HH12:MI AM') |
| Os 4 marcos da entrega | 2023-11-16 | \<coluna\>::date |
| A chave da dim\_tempo | vira 20231116 | TO\_CHAR(\<a data\>, 'YYYYMMDD')::int |

ATENÇÃO: a data do pedido está no formato americano. Usar 'DD/MM/YYYY' faz o PostgreSQL LANÇAR ERRO nas datas com mês maior que 12\. O erro aparece na hora  e, nesse caso, o banco está te ajudando.

A regra dos números:

| Se o valor for | Faça |
| :---- | :---- |
| vazio ou '-' | grave NULL, nunca 0 |
| 'R$ 1.850,00' | tire 'R$' e o espaço, tire o ponto de milhar, troque a vírgula por ponto |
| '1850.00' | já está pronto, só converter |
| '1.200' (milhar, sem decimal) | tire o ponto antes de converter |
| texto para inteiro | CAST(\<x\> AS INTEGER) |

O valor em reais é um caso exigente: “R$ 1.850,00”, “1850.00”, “1.200”, “-” e vazio convivem na mesma coluna. A expressão abaixo já está pronta  use-a para vl\_liquido. A decisão que interessa continua sendo sua: reconhecer que “” e “-” viram NULL, e nunca 0\.

CASE WHEN TRIM(REPLACE(\<coluna\>,'R$','')) IN ('','-') THEN NULL  
     WHEN \<coluna\> LIKE '%,%'  
          THEN CAST(REPLACE(REPLACE(REPLACE(REPLACE(\<coluna\>,'R$',''),' ',''),'.',''),',','.')  
               AS DECIMAL(15,2))  
     ELSE CAST(REPLACE(REPLACE(\<coluna\>,'R$',''),' ','') AS DECIMAL(15,2)) END

O de-para das categorias. A ORDEM IMPORTA: “Ração Medicamentosa” contém “RA”, então se você testar RA antes de MED o item vai para a categoria errada e a P2 sai com o número trocado. Todo trecho testado é SEM acento, para o resultado não depender da instalação.  
Grave os valores da tabela abaixo EXATAMENTE como estão escritos, sem acento (Racao, Alimentacao, Servico, Nao Informado). É assim que eles ficam no banco, e é assim que a conferência espera encontrá-los. Como o PostgreSQL diferencia maiúscula de minúscula, compare sempre em UPPER e sem acento (TRANSLATE), dos dois lados vale aqui e no nome da loja.

| Ordem | Se contém | nome\_categoria | grupo\_categoria |
| :---- | :---- | :---- | :---- |
| 1 | MED | Medicamento | Saude e Higiene |
| 2 | PETISC | Petisco | Alimentacao |
| 3 | RA | Racao | Alimentacao |
| 4 | HIG | Higiene | Saude e Higiene |
| 5 | BRINQ | Brinquedo | Bem-estar |
| 6 | ACESS | Acessorio | Bem-estar |
| 7 | SERV | Servico | Bem-estar |
|  | nenhum dos acima | Nao Informado | Nao Informado |

O nome da loja. Parte 1, mecânica: REPLACE tira o sufixo “/SC” e o espaço duplo. Parte 2, decisão sua: erro de digitação, apelido e abreviação não saem com REPLACE  precisam de um CASE escrito à mão. São só três, e são estas as grafias que sobram depois da parte 1:

| Grafia que aparece na origem | Deve virar | Tipo |
| :---- | :---- | :---- |
| PATA AMIGA BLUMENAL CENTRO | PATA AMIGA BLUMENAU CENTRO | erro de digitação |
| PATA AMIGA FLORIPA NORTE | PATA AMIGA FLORIANOPOLIS NORTE | apelido |
| PATA AMIGA JGUA DO SUL | PATA AMIGA JARAGUA DO SUL | abreviação |

Acento e maiúscula neste banco: O PostgreSQL compara BYTE A BYTE: 'Timbo', 'TIMBO' e 'Timbó' são textos DIFERENTES. Confira com SELECT 'Timbo' \= 'TIMBO'; (devolve false). Por isso o lookup da loja precisa normalizar os dois lados com UPPER(TRANSLATE(...)). Atenção também ao UPPER: em alguns ambientes ele não maiusculiza letra acentuada, então tire o acento com TRANSLATE antes de comparar.


### Desenvolvimento   

Preenchimento do 03-dimensoes.sql   

