# ANÁLISE DE DADOS COM PYTHON \[T1\]

## Mini-Projeto Avaliativo \- Módulo 2 \- Semana 7

**SUMÁRIO**

[1\. CONTEXTUALIZAÇÃO	1](#1.-contextualizaÇÃo)

[2\. DESAFIO	1](#2.-desafio)

[3\. RESULTADOS ESPERADOS (ENTREGA)	3](#3.-resultados-esperados-\(entrega\))

[4\. REQUISITOS DAS TAREFAS	4](#4.-requisitos-das-tarefas)

[4.1. GRAVAÇÃO DE VÍDEO	7](#4.1.-gravaÇÃo-de-vÍdeo)

[5\. CRITÉRIOS DE AVALIAÇÃO	8](#5.-critÉrios-de-avaliaÇÃo)

[6\. ENCARTE \- AS BASES QUE VOCÊ RECEBEU	10](#6.-encarte---as-bases-que-vocÊ-recebeu)

[7\. ENCARTE \- O MODELO QUE VOCÊ DEVE CONSTRUIR	11](#7.-encarte---o-modelo-que-vocÊ-deve-construir)

[8\. ENCARTE \- NÚMEROS DE CONFERÊNCIA	14](#8.-encarte---nÚmeros-de-conferÊncia)

 

# **1\. CONTEXTUALIZAÇÃO**

A Pata Amiga é uma rede catarinense de *pet shops*. Começou com uma loja em Blumenau, em 2009, e hoje tem 32 lojas espalhadas pelo estado, de Itapoá a São Miguel do Oeste.  
Em setembro de 2023, a rede ligou a operação de pedidos com entrega  app, site, telefone, WhatsApp e a própria loja física. Em sete meses foram 4.044 pedidos. A diretoria quer usar esses sete meses para decidir o próximo ciclo: onde está o gargalo da entrega, qual categoria sustenta o faturamento, se a política de desconto funciona igual em todo canal, e onde abrir a próxima loja.  
O dado existe. O problema é que ele está em três sistemas que não se falam: a plataforma de e-commerce (os pedidos e os marcos da entrega), o cadastro de lojas do franchising, e a planilha de praças de atendimento que o time de expansão mantém à parte. Cada um escreve do seu jeito: a mesma loja aparece com acento, sem acento, em caixa alta e com erro de digitação; a mesma categoria tem várias grafias; data e dinheiro vêm como texto.  
Reorganizar dados não parece grande coisa até você ver o que aparece do outro lado. Quando as três bases finalmente conversam, frases assim saltam da tela: que o gargalo não está na entrega, e sim entre a nota fiscal e o despacho; que uma praça concentra faturamento muito acima do seu número de domicílios com *pet*.

# **2\. DESAFIO**

Você foi contratado como analista de dados da Pata Amiga. A diretora foi direta: “Não quero um painel bonito. Quero cinco respostas, com número, e quero saber de onde veio cada número.”

**As cinco perguntas de negócio**

* **P1 : Onde está o gargalo da entrega?** Qual o tempo médio, em dias, entre o pedido entrar no ERP e chegar na casa do cliente? E qual dos quatro intervalos do processo  Integração → Separação, Separação → Nota, Nota → Despacho, Despacho → Entrega  é o mais lento? O gargalo é o mesmo nos três portes de loja?  
    
* **P2 : Qual categoria concentra o faturamento?** Do faturamento total da rede, quanto vem de cada categoria de produto? Agrupe pelo nome padronizado, nunca pela grafia crua, e mostre também o percentual do total. A categoria campeã é a mesma nos três portes de loja?  
    
* **P3 : O desconto funciona igual em todo canal?** Compare o ticket médio COM e SEM desconto dentro de cada canal de venda (App, Site, Loja Física, Telefone, WhatsApp). Se o desconto derruba o ticket em um canal e não em outro, a política não deveria ser a mesma nos dois. Diga também quanto cada canal representa do faturamento.  
    
* **P4 : Qual praça de atendimento concentra o faturamento?** Atenção: uma loja entrega em mais de uma praça. O rateio precisa ser feito pelo percentual do público, e a soma por praça tem de fechar com o faturamento da rede. Cruze o faturamento rateado com o número de domicílios com pet de cada praça.  
    
* **P5 : Onde abrir a próxima loja, e o que os dados NÃO permitem afirmar?**   
1) Ranqueie as lojas por itens vendidos por mil habitantes da cidade  não em valor absoluto  e cruze com o tempo médio de entrega.   
2) A faixa de franquia no cadastro é a de hoje: o passado foi sobrescrito. Mostre o faturamento por faixa ATUAL e explique por que isso não responde “quanto veio de lojas que JÁ ERAM Ouro na data do pedido”.  
3) Meça o que ficou de fora: pedidos sem loja identificada, entregas ainda não concluídas, itens e valores em branco.

Nenhuma dessas perguntas é respondível hoje. Não por falta de dados ou por falta de organização do dado. Seu desafio técnico é construir o modelo dimensional que torna as cinco respondíveis.

**O que chegou até você**

A área de staging já está montada no banco dw\_pata\_amiga, com três tabelas carregadas exatamente como vieram dos sistemas de origem. Elas não podem ser alteradas: nada de UPDATE, nada de ALTER. Todo tratamento acontece nos INSERT das dimensões e do fato.

* Todas as colunas são VARCHAR. Data é texto. Valor em reais é texto. Quantidade é texto.  
* Os nomes das colunas não estão em snake\_case. Vieram do sistema de origem, com espaço, ponto e parêntese. Neste banco, esses nomes só funcionam entre aspas duplas: "Cod Loja", "QTD.Itens", "ValorLiquidoPedido(R$)".  
* As datas do pedido e as datas do processo estão em formatos diferentes, e as duas convivem na mesma tabela. A plataforma de e-commerce é de um fornecedor norte-americano e nunca foi localizada: as datas de pedido vêm em MM/DD/AAAA com AM/PM. Os quatro marcos da entrega, não: vêm em AAAA-MM-DD.  
* A mesma loja aparece escrita de dezenas de maneiras: com acento, sem acento, em caixa alta, com “/SC” no fim, com espaço sobrando e com erro de digitação.  
* A mesma categoria de produto tem várias grafias: “Ração”, “RACAO”, “Rac.”, “Alimento Seco”  e uma pegadinha: “Ração Medicamentosa” não é ração, é medicamento.  
* “Houve desconto?” e “canal do pedido” chegam com dezenas de grafias cada um, incluindo vazio. São poucos valores distintos, mas sujos.  
* Marco de processo em branco não é erro: é processo em aberto. 1.953 pedidos ainda não foram entregues até o fim da janela.


# **3\. RESULTADOS ESPERADOS (ENTREGA)**

A entrega tem duas partes, submetidas em lugares diferentes.

**1\) O projeto um repositório público no GitHub, contendo:**

- README.md o documento principal. Explica o case, o modelo que você construiu, as decisões que tomou e as cinco respostas com os números. É por ele que a correção começa.  
- Os seus scripts SQL, na ordem em que devem ser rodados, com comentários. Quem clonar o repositório tem de conseguir reproduzir o seu banco do zero.  
- O diagrama do modelo (estrela), em imagem, dentro do README. Veja abaixo o que ele precisa mostrar.


* **Prazo de entrega: 14/09/2026, até as 22h.**  
- **Peso na média do módulo: 25%.**

O trabalho é individual. Você pode conversar com os colegas sobre o problema é assim que se trabalha , mas o texto, o SQL e o vídeo devem ser seus.

**Sobre o diagrama do modelo**

Não há ferramenta obrigatória. Você poderá usar draw.io (diagrams.net), dbdiagram.io, Excalidraw, Lucidchart, PowerPoint  ou desenhar à mão e fotografar. O que vale é estar legível e correto. Exporte em PNG ou JPG e coloque a imagem dentro do README.

O diagrama deve mostrar quatro informações:

- A fato\_pedido no centro, com o grão escrito ao lado (“1 linha \= 1 pedido”).  
- As dimensões em volta, ligadas à fato: dim\_tempo, dim\_loja e dim\_categoria.  
- A dim\_tempo ligada DUAS vezes (data do pedido e data da entrega): é a mesma tabela em dois papéis, e o diagrama precisa deixar isso visível.  
- A dim\_praca ligada à dim\_loja através da bridge\_loja\_praca, e não direto à fato  é o único caminho indireto do modelo.

Não há necessidade de listar todas as colunas de cada tabela: o nome da tabela, a chave e dois ou três atributos bastam. Avalia-se a estrutura, não o capricho do desenho.

# **4\. REQUISITOS DAS TAREFAS**

**De quanto SQL você precisa**

Não é preciso SQL avançado. Esta é a lista fechada do que o projeto inteiro usa se você se pegar precisando de algo fora dela, provavelmente há um caminho mais simples:

* CREATE TABLE, INSERT INTO ... VALUES, INSERT INTO ... SELECT  
* SELECT, SELECT DISTINCT, WHERE, GROUP BY, HAVING, ORDER BY  
* JOIN e LEFT JOIN  
* CASE WHEN ... THEN ... ELSE ... END  
* agregação: SUM, COUNT, COUNT(DISTINCT ...), MAX, AVG, ROUND  
* texto e conversão: UPPER, TRIM, REPLACE, TRANSLATE, SUBSTRING, CAST e TO\_TIMESTAMP(\<coluna\>, 'MM/DD/YYYY HH12:MI AM') para converter data  
* distância entre duas datas, em dias: \<data de fim\>::date \- \<data de inicio\>::date

Você não precisa criar funções nem procedures, e não vai usar CTE, window function, trigger ou índice. Nas suas tabelas, basta declarar a PRIMARY KEY.  
Use Subconsulta só nas perguntas de negócio. Na carga das dimensões e do fato não use nenhuma: se você precisou de uma para achar a linha da dimensão, é sinal de que a grafia crua não foi guardada onde deveria.  
Não crie camada intermediária. As únicas tabelas do seu banco devem ser as três stg\_ que já vieram prontas, as duas dimensões entregues, as dimensões que você criar e a sua fato. Sem view, sem tabela auxiliar, sem UPDATE.

**Tarefa 1 : Diagnóstico da origem**

Abra as três tabelas e escreva, no README, o que está errado em cada uma. Quantas grafias de loja existem? Quantas de categoria? Quantos pedidos vieram sem código de loja? Quantos sem nome de loja? Quantos marcos de processo estão em branco? Este diagnóstico vale nota, e é ele que orienta todo o resto. Confira as contagens com o quadro da seção 8\.

**Tarefa 2 : Tratamento**

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

**Tarefa 3 : Construir as dimensões**

Duas dimensões já vêm prontas no 02-dimensoes-prontas.sql: dim\_tempo e dim\_loja. Você não constrói nenhuma das duas, mas precisa usá-las corretamente.  
Você constrói duas dimensões e uma tabela ponte: dim\_categoria, dim\_praca e bridge\_loja\_praca. Os campos de cada uma estão na seção 7\.

* A PK é uma surrogate key inteira (INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY).  
* A chave natural (a grafia, o código da praça) fica como atributo.  
* Toda dimensão tem a linha \-1 \= “Nao Informado”, inserida ANTES do INSERT ... SELECT, para nenhuma FK ficar nula.  
* Na dim\_categoria, guarde a GRAFIA CRUA em categoria\_origem: é por ela que a fato encontra a linha, com um JOIN de uma linha só. Esse é o padrão central da semana.

**Tarefa 4 : Construir a fato**

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

**Se você travar no arquivo 04**

O 04 é o único ponto do projeto em que tudo depende de um comando só: sem a fato carregada, nenhuma das cinco perguntas sai, e o README fica sem números. Para isso não custar a sua entrega inteira, existe uma saída combinada: se até 10/09 você não tiver o 04 rodando com 4.044 linhas, peça ajuda ao professor. 

**Tarefa 5 : Responder e recomendar**

Escreva as cinco consultas e confira se os totais fecham com a origem. Depois, no README, responda cada pergunta em texto, com o número ao lado, e feche com uma recomendação de onde abrir a próxima loja  dizendo também o que os dados não sustentam.

## **4.1. GRAVAÇÃO DE VÍDEO**

Além do desenvolvimento das tarefas você deverá gravar um vídeo, com tempo máximo de 5 minutos, abordando os seguintes questionamentos:

* Qual o objetivo do modelo dimensional que você construiu? Mostre o diagrama e demonstre o funcionamento: rode uma das cinco consultas e mostre o resultado na tela.  
* O que deve ser feito para reproduzir o seu banco do zero? Mostre em que ordem os scripts precisam ser executados.  
* Como você organizou as tarefas antes de começar a construir o modelo?  
* Quais decisões de tratamento você tomou  máscara de data, de-para das grafias, padronização do nome da loja  e por que tomou cada uma?  
* O que os dados NÃO permitem afirmar? E o que você melhoraria no seu SQL se tivesse mais tempo?

Você poderá gravar na vertical ou na horizontal. É importante que apareça seu rosto e esteja em um local com boa iluminação. Para realizar a entrega do vídeo, coloque em uma pasta do Google Drive em modo leitor para qualquer pessoa com o link, e compartilhe o mesmo na submissão do projeto no AVA. Uma dica interessante é você inserir o vídeo no readme.md do seu projeto no repositório do GitHub.

# **5\. CRITÉRIOS DE AVALIAÇÃO**

A tabela abaixo apresenta os critérios que serão avaliados durante a correção do projeto. A tabela abaixo possui variação de nota de 0 (zero) a 10 (dez) como nota mínima e máxima, e possui peso de 25% sobre a avaliação do módulo.

| Apresentação do Projeto |  |  |  |  |
| :---: | ----- | ----- | ----- | ----- |

| Nº | Critério de Avaliação | 0 | 2,00 |  |
| :---- | ----- | ----- | ----- | ----- |
| **1** | **Gravação de vídeo** | Não foi realizada a gravação do vídeo.  | O vídeo responde aos cinco questionamentos listados no item 4.1 e mostrou o diagrama do modelo, demonstrando ao menos uma das cinco consultas rodando. |  |

| Uso do GitHub e Readme.md |  |  |  |  |
| :---: | ----- | ----- | ----- | ----- |

| Nº | Critério de Avaliação | 0 | 0,50 | 1,00 |
| :---: | :---: | :---: | :---: | :---: |
| **2** | **Versionamento com branches e commits** | O repositório do projeto não apresenta branches e commits. | O repositório do projeto apresenta parte das branches e commits distintos e nomeadas padronizadamente para cada funcionalidade desenvolvida. | O repositório do projeto apresenta branches e commits distintos e nomeados padronizadamente para cada etapa desenvolvida (setup, autenticação, autorização). |
| **3** | **Diagnóstico da Origem no README**  | Não apresentou o diagnóstico no README ou omitiu a contagem da maioria dos itens solicitados. Os números apresentados estão incorretos ou inconsistentes com os dados de origem.  | Registrou o diagnóstico no README, mas omitiu a contagem de um dos itens (ex.: não contou marcos de processo em branco) ou apresentou divergências pontuais nas métricas apuradas.  | Registrou com precisão no README a contagem exata de todos os quatro itens da origem: grafias de loja, grafias de categoria, pedidos sem código de loja e marcos de processo em branco.  |
| **4** | **Respostas e Análise Crítica no README**  | Não respondeu às cinco perguntas no README, os números divergiram da origem tratada, ou não incluiu a leitura crítica e a recomendação final.  | Respondeu às cinco perguntas com números bateram com a origem, porém a leitura crítica foi superficial (ou omitiu limitações do que os dados *não* permitem afirmar) ou a recomendação final foi genérica/ausente.  | Apresentou as cinco respostas no README com reconciliação numérica perfeita em relação à origem, acompanhadas de uma leitura crítica bem fundamentada sobre as limitações dos dados e uma recomendação final clara e acionável.  |

| Desenvolvimento do Projeto |  |  |  |  |
| :---: | ----- | ----- | ----- | ----- |

| Nº | Critério de Avaliação | 0 | 1,5 | 3,00 |
| :---: | ----- | ----- | ----- | ----- |
| **5** | **Modelo dimensional**  | O grão da tabela fato não possui 4.044 linhas, há chaves estrangeiras (FKs) nulas na fato, faltam os registros de linha `-1` nas dimensões ou a tabela ponte não aplica/implementa o fator de rateio.  | Respeitou o grão de 4.044 linhas e tratou as FKs nulas, mas esqueceu a linha `-1` em alguma dimensão ou a tabela ponte possui erros no cálculo/aplicação do fator de rateio.  | O Modelo possui tabela fato estritamente com 4.044 linhas, todas as dimensões possuem o registro de linha `-1`, nenhuma FK está nula e a tabela ponte aplica o fator de rateio perfeitamente.  |
| **6** | **Tratamento dos dados** | Falhou na conversão/máscara de datas, não aplicou a regra dos números, inverteu a ordem lógica do de-para de categoria ou realizou o *lookup* antes da padronização do nome da loja.  | Aplicou a maioria das regras, mas cometeu uma falha pontual (ex.: padronizou o nome da loja somente após o *lookup*, ou errou a precedência da ordem lógica na regra do de-para).  | Executou todo o pipeline de ETL corretamente: máscara de data no formato adequado, regra dos números aplicada, de-para de categoria na ordem lógica correta e padronização do nome da loja realizada obrigatoriamente antes do *lookup*.  |

**Atenção: erros que custam nota:**

* FK nula na fato em vez da linha \-1.  
* Total de pedidos diferente de 4.044 na fato: mais que isso é JOIN duplicando, menos é JOIN descartando linha.  
* Percentual ou taxa gravados calculados dentro da fato eles não são aditivos.  
* Soma por praça sem o fator de rateio: o faturamento estoura o total da rede.  
* Etapa não cumprida gravada como 0 em vez de NULL.

Serão desconsiderados e atribuída a nota 0 (zero) os projetos que apresentarem plágio de soluções encontradas na internet ou de outros colegas. Lembre-se: você está livre para utilizar outras soluções como base, mas não é permitida a cópia.

# **6\. ENCARTE \- AS BASES QUE VOCÊ RECEBEU**

Três tabelas, todas com todas as colunas em texto. Confira as contagens depois de rodar o 01-carga-staging.sql:

| Tabela | O que é | Linhas |
| :---- | :---- | :---- |
| stg\_pedido | Os pedidos \+ os 4 marcos do processo de entrega | 4.044 |
| stg\_loja | Cadastro das 32 lojas  a foto de hoje | 32 |
| stg\_loja\_praca | Loja × praça de atendimento, com o % do público | 48 |

Os defeitos plantados, e o que cada um cobra:

| Defeito | Onde | Conceito cobrado |
| :---- | :---- | :---- |
| Todas as colunas são texto | todas as stg\_ | staging × área de apresentação |
| Nomes fora de snake\_case | Cod Loja, QTD.Itens | identificador entre delimitador |
| Dois formatos de data na MESMA tabela | stg\_pedido | a máscara certa por coluna |
| 37 grafias para 7 categorias | CategoriaProduto | dimensão guarda a grafia crua |
| “Ração Medicamentosa” não é ração | CategoriaProduto | a ordem do CASE importa |
| Dezenas de grafias de loja | Loja-Nome | padronizar antes do lookup |
| Cod Loja vazio em 39% das linhas | stg\_pedido | resolver por nome |
| 3 pedidos sem loja identificada | stg\_pedido | linha \-1; nunca FK nula |
| Sim/não escrito de muitas maneiras | HouveDesconto | padronizar na carga da fato |
| Canal escrito de muitas maneiras | CanalPedido | padronizar; WHATS antes de APP |
| Números em formatos misturados | todas as numéricas | a regra dos números |
| Loja em mais de uma praça | stg\_loja\_praca | bridge table com fator |
| Cadastro só com a foto de hoje | stg\_loja | o passado foi sobrescrito (limite da P5) |
| 2 datas por pedido na fato | stg\_pedido | role-playing dimension |
| Marco em branco \= processo aberto | stg\_pedido | FK → \-1, e NULL nos dias |
| Número do pedido sem atributos | NumeroPedido | dimensão degenerada |

# **7\. ENCARTE \- O MODELO QUE VOCÊ DEVE CONSTRUIR**

Uma fato, quatro dimensões e uma ponte. Duas dimensões já vêm prontas, elas estão aqui para você saber o que tem dentro, não para construir.

**FATO\_PEDIDO \-\> grão \-\> 1 pedido : 4.044 linhas**

| Coluna | Tipo | O que é |
| :---- | :---- | :---- |
| sk\_pedido | INT | PK da fato, gerada automaticamente. |
| numero\_pedido | VARCHAR(20) | Número do pedido. Dimensão degenerada: código sem atributo, que por isso fica na fato. |
| sk\_tempo\_pedido | INT | FK para dim\_tempo  quando o cliente fez o pedido. |
| sk\_tempo\_entrega | INT | FK para dim\_tempo  quando chegou ao cliente. Vale \-1 se a entrega ainda não aconteceu (1.953 pedidos). |
| sk\_loja | INT | FK para dim\_loja. Vale \-1 nos 3 pedidos sem loja identificada. |
| sk\_categoria | INT | FK para dim\_categoria, encontrada pela grafia crua. |
| houve\_desconto | VARCHAR(15) | Sim / Nao / Nao Informado. Padronizado na carga da fato. |
| canal\_pedido | VARCHAR(20) | App / Site / Loja Fisica / Telefone / WhatsApp / Nao Informado. |
| dt\_pedido | DATETIME/ TIMESTAMP | Data e hora do pedido. |
| qt\_itens | INT | Itens do pedido. Aditiva. |
| vl\_liquido | DECIMAL(15,2) | Valor faturado, em reais. Aditiva. É a métrica de faturamento. |
| dias\_integracao\_separacao | INT | Dias entre o ERP e a separação. Calculado na carga. |
| dias\_separacao\_nota | INT | Dias entre a separação e a nota fiscal. |
| dias\_nota\_despacho | INT | Dias entre a nota e o despacho. |
| dias\_despacho\_entrega | INT | Dias entre o despacho e a entrega. |
| dias\_total\_ate\_entrega | INT | Dias do ERP até a entrega. Resposta direta da P1. |

Repare no que NÃO está nessa lista. A stg\_pedido também traz o valor bruto, o desconto em reais, unidades devolvidas, itens cancelados, peso e frete  e nenhuma das cinco perguntas usa. Há UMA coluna de dinheiro na fato, e não três. Escolher o que não entra também é modelagem.

**Como padronizar o desconto e o canal**

Essas duas colunas não viram dimensão: são dois domínios de poucos valores, sem nada pendurado neles, e por isso ficam na própria fato. A padronização é feita UMA vez, no INSERT do arquivo 04\. Use as duas tabelas abaixo.  
O desconto chega escrito de 17 maneiras, e todas caem em três valores. Compare em UPPER e sem espaço nas pontas (TRIM):

| Se o valor for | Grave |
| :---- | :---- |
| S, SIM, 1, X, TRUE, V | Sim |
| N, NAO, 0, FALSE, F | Nao |
| vazio, ou qualquer outra coisa | Nao Informado |

No canal, A ORDEM DO CASE IMPORTA: “WHATSAPP” contém “APP”. Se você testar APP antes de WHATS, os pedidos de WhatsApp vão para dentro do App e a P3 sai errada. Confira no 00-conferencia.sql: o WhatsApp tem de aparecer na fato, com 414 pedidos.

| Ordem | Se contém | Grave |
| :---- | :---- | :---- |
| 1 | WHATS | WhatsApp |
| 2 | APP | App |
| 3 | SITE | Site |
| 4 | LOJA | Loja Fisica |
| 5 | TEL | Telefone |
|  | nenhum dos acima | Nao Informado |

**DIM\_TEMPO:  JÁ VEM PRONTA  236 linhas**

A chave é a própria data em número: 16/11/2023 vira 20231116\. Por isso a fato monta a FK com uma conversão, sem JOIN. São 235 dias mais a linha \-1. A fato usa a mesma dimensão em dois papéis (pedido e entrega): isso se chama role-playing dimension.

**DIM\_LOJA:  JÁ VEM PRONTA  33 linhas**

| Coluna | Tipo | O que é |
| :---- | :---- | :---- |
| sk\_loja | INT | PK. |
| cod\_loja | VARCHAR(10) | Código da loja. É a chave natural  e é por ela que a ponte liga. |
| chave\_loja | VARCHAR(80) | O nome padronizado, em caixa alta e sem acento. É por ele que a fato encontra a loja. |
| nome\_loja | VARCHAR(80) | O nome de exibição, para o relatório. |
| cidade / uf / mesorregiao | VARCHAR | Localização. A mesorregião permite agrupar acima da cidade. |
| populacao\_cidade | INT | População da cidade. É o denominador da P5. |
| area\_venda\_m2 | INT | Área de venda, em m². |
| porte | VARCHAR(20) | Pequena, Média ou Grande, pela área. Agrupa a P1 e a P2. |
| faixa\_franquia | VARCHAR(15) | Bronze, Prata, Ouro ou Diamante. É a foto de HOJE  e é isso que limita a P5. |
| formato\_loja | VARCHAR(20) | Padrão, Completa ou Megastore. |

**DIM\_CATEGORIA \-\> grão: uma grafia da origem  38 linhas (37 grafias \+ a \-1)**

O PostgreSQL compara byte a byte, então separa 'Racao' de 'RACAO' e 'Ração' como grafias distintas: são 37 grafias mais a linha \-1 \= 38 linhas. O outro teste, e é o que mais importa, é o das 7 categorias padronizadas mais a linha \-1 \= 8\.

| Coluna | Tipo | O que é |
| :---- | :---- | :---- |
| sk\_categoria | INT | PK. |
| categoria\_origem | VARCHAR(50) | A grafia CRUA, como veio da origem. É por ela que a fato encontra a linha. |
| nome\_categoria | VARCHAR(30) | O nome padronizado. É por ele que se agrupa na P2. |
| grupo\_categoria | VARCHAR(20) | Alimentacao, Saude e Higiene, Bem-estar. |

**DIM\_PRACA \+ BRIDGE\_LOJA\_PRACA  13 e 48 linhas**

Uma loja entrega em mais de uma praça. Se você puser uma sk\_praca dentro da dim\_loja, terá de escolher UMA e vai perder as outras; dentro da fato, o mesmo problema. A ligação N:N não cabe em FK nenhuma: precisa de uma tabela própria, com o fator de rateio dentro.

| Coluna | Tipo | O que é |
| :---- | :---- | :---- |
| sk\_praca | INT | PK da dim\_praca. |
| cod\_praca | VARCHAR(10) | Código da praça. Chave natural. |
| nome\_praca | VARCHAR(60) | Nome da praça de atendimento. |
| regional | VARCHAR(30) | Regional a que a praça pertence. |
| domicilios\_com\_pet | INT | Vem como '148.000': o ponto é milhar, não decimal. |

| Coluna (bridge) | Tipo | O que é |
| :---- | :---- | :---- |
| cod\_loja | VARCHAR(10) | O CÓDIGO da loja, não a sk\_loja. A chave natural atravessa recargas. |
| sk\_praca | INT | FK para dim\_praca. |
| fator\_publico | DECIMAL(6,4) | 0,85 \= 85% do público daquela loja. Os fatores de uma loja somam 1,00, sempre. |

Na P4 você multiplica o faturamento da loja pelo fator antes de somar por praça. Sem isso, o faturamento de quem atende duas praças seria contado duas vezes e a soma estouraria o total da rede.

# **8\. ENCARTE \- NÚMEROS DE CONFERÊNCIA**

Estes números foram conferidos rodando o projeto inteiro. Use-os para saber se você está no caminho certo  o arquivo 00-conferencia.sql traz cada um deles com a consulta pronta.

| Etapa | O que conferir | Esperado |
| :---- | :---- | :---- |
| Depois do 01 | stg\_pedido / stg\_loja / stg\_loja\_praca | 4.044 / 32 / 48 |
| Depois do 01 | pedidos sem Cod Loja preenchido | 1.575 (\~39%) |
| Depois do 01 | pedidos sem nome de loja | 3 |
| Depois do 01 | marcos em branco (separação/nota/despacho/entrega) | 1.077 / 1.338 / 1.665 / 1.953 |
| Depois do 02 | dim\_tempo / dim\_loja | 236 / 33 |
| Depois do 03 | dim\_categoria | 38 linhas (37 grafias \+ a \-1) |
| Depois do 03 | categorias padronizadas (nome\_categoria distintos) | 8 \= 7 \+ a linha \-1 |
| Depois do 03 | dim\_praca / bridge\_loja\_praca | 13 / 48 |
| Depois do 03 | soma do fator por loja na ponte | 1,00 em todas |
| Depois do 04 | fato\_pedido | 4.044 |
| Depois do 04 | FKs nulas ou órfãs | 0 |
| Depois do 04 | pedidos na linha \-1 de loja | 3 |
| Depois do 04 | pedidos com entrega não concluída (tempo \-1) | 1.953 |
| Depois do 04 | período dos pedidos | 01/09/2023 a 31/03/2024 |
| Depois do 05 | faturamento total da rede | 1.793.309 |
| Depois do 05 | soma rateada por praça \+ pedidos sem loja − total | 0 |

Sobre os percentuais: no PostgreSQL a divisão de inteiro por inteiro TRUNCA. Use 100.0 / 1000.0 (com ponto) para a conta ser decimal. E ROUND(x, casas) exige x numérico.

# **9\. ANEXOS- Base de Dados para Utilização no Mini-Projeto:**

Seguem os links para utilização, a saber:

Pasta 01:   
[https://drive.google.com/drive/folders/19rmY\_q3bnra4OQxIYOMEzDFjdxAfGoCc?usp=sharing](https://drive.google.com/drive/folders/19rmY_q3bnra4OQxIYOMEzDFjdxAfGoCc?usp=sharing) 

Pasta 02:  
[https://drive.google.com/drive/folders/12cW0DdE3qXbUcaAzkbHcl5DqyJ76b8kP?usp=drive\_link](https://drive.google.com/drive/folders/12cW0DdE3qXbUcaAzkbHcl5DqyJ76b8kP?usp=drive_link) 

Pasta 03:  
[https://drive.google.com/drive/folders/1YUUv002d2qHmD2zh8HTG29K1E1g7XMbx](https://drive.google.com/drive/folders/1YUUv002d2qHmD2zh8HTG29K1E1g7XMbx)   
