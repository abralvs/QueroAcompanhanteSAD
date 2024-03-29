/** 
 * UNIVERSIDADE FEDERAL DE SERGIPE 
 * DEPARTAMENTO DE SISTEMAS DE INFORMA??O - DSI

 * SISTEMAS DE APOIO A DECISÃO -SAD
 * PROJETAR AMBIENTE DE SUPORTE A DECISÃO BASEADO EM SISTEMA DE ACOMPANHANTES
 * ABRAÃO ALVES, IGOR BRUNO E GABRIEL SANTANA
 * 19/08/2019
 **/
USE QUEROACOMPANHANTE_SAD;
--- --------------------------------------------------------------------
-- 01 - Quantos serviÃ§os de acompanhamentos foram criados ? por perÃodo?
--- --------------------------------------------------------------------

CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_01_QTD_DE_ACOMPANHAMENTOS (@DATA_INICIO DATETIME,@DATA_LIMITE DATETIME)
AS
BEGIN
    DECLARE @QTD_ACOMPANHAMENTOS INT

    SET @QTD_ACOMPANHAMENTOS = (SELECT COUNT(FATO.QTD) FROM FATO_ACOMPANHAMENTO AS FATO
                                JOIN AMBIENTE_DIMENSIONAL.DIM_TEMPO AS TEMPO ON (TEMPO.id = FATO.id_tempo) AND
								(TEMPO.Data >= @DATA_INICIO) AND (TEMPO.Data <= @DATA_LIMITE))
    IF (@QTD_ACOMPANHAMENTOS IS NOT NULL)
        SELECT @QTD_ACOMPANHAMENTOS AS 'ACOMPANHAMENTOS CRIADOS'
    ELSE
        SELECT 0 AS 'ACOMPANHAMENTOS CRIADOS'
END

GO


/* 
	- QUESTIONAMENTO 02
	- MEDIA DE CANDIDATOS POR OPORTUNIDADES PUBLICAS
*/
CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_02_MEDIA_CANDIDATOS_VAGAS_PUBLICAS(@INICIO_PERIODO DATETIME, @FIM_PERIODO DATETIME)
AS
BEGIN
    SELECT AVG(FA.ID_OPORTUNIDADE) AS 'MEDIA' FROM AMBIENTE_DIMENSIONAL.FATO_ACOMPANHAMENTO FA
                                            INNER JOIN AMBIENTE_DIMENSIONAL.DIM_OPORTUNIDADE DO
                                                       ON FA.ID_OPORTUNIDADE = DO.ID
                                            INNER JOIN AMBIENTE_DIMENSIONAL.DIM_TEMPO DT
                                                       ON FA.ID_TEMPO = DT.ID
    WHERE EH_PUBLICA = 1 AND (DT.DATA >= @INICIO_PERIODO AND DT.DATA <= @FIM_PERIODO);
END

GO

--- --------------------------------------------------------------------------------------
-- 03 - Quantos serviÃ§os de acompanhamentos foram concluÃ­dos no primeiro semestre de 2019?
--- --------------------------------------------------------------------------------------

CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_03_QTD_DE_ACOMPANHAMENTOS_CONCLUIDO (@DATA_INICIO DATETIME,@DATA_LIMITE DATETIME)
AS
BEGIN
    DECLARE @QTD_ACOMPANHAMENTOS INT

    SET @QTD_ACOMPANHAMENTOS = (SELECT COUNT(FATO.QTD) FROM FATO_ACOMPANHAMENTO AS FATO
	JOIN AMBIENTE_DIMENSIONAL.DIM_SERVICO DS ON FATO.ID_SERVICO = DS.ID AND DS.status = 'CONCLUIDA'
    JOIN AMBIENTE_DIMENSIONAL.DIM_TEMPO AS TEMPO ON (TEMPO.id = FATO.id_tempo) AND
    (TEMPO.Data >= @DATA_INICIO) AND (TEMPO.Data <= @DATA_LIMITE))

    
	IF (@QTD_ACOMPANHAMENTOS IS NOT NULL)
        SELECT @QTD_ACOMPANHAMENTOS AS 'ACOMPANHAMENTOS CONCLUIDOS'
    ELSE
        SELECT 0 AS 'ACOMPANHAMENTOS CONCLUIDOS'

END

GO

/*
	- QUESTIONAMENTO 04
	- QUANTIDADE DE SERVICOS CANCELADOS NO PERIODO
*/
CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_04_SERVICO_CANCELADO_PERIODO(@INICIO_PERIODO DATETIME, @FIM_PERIODO DATETIME)
AS
BEGIN
    SELECT COUNT(FA.ID_SERVICO) AS 'QUANTIDADE DE SERVIÇOS CANCELADOS' FROM AMBIENTE_DIMENSIONAL.FATO_ACOMPANHAMENTO FA
                                         INNER JOIN AMBIENTE_DIMENSIONAL.DIM_SERVICO DS
                                                    ON FA.ID_SERVICO = DS.ID
                                         INNER JOIN AMBIENTE_DIMENSIONAL.DIM_TEMPO DT
                                                    ON FA.ID_TEMPO = DT.ID
    WHERE DS.STATUS = 'CANCELADA' AND (DT.DATA >= @INICIO_PERIODO AND DT.DATA <= @FIM_PERIODO);
END

GO

--- -------------------------------------------------------------------------
-- 05 - Quantas transaÃ§Ãµes foram feitas em 2019 ? e qual o valor total delas?
--- -------------------------------------------------------------------------

CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_05_QTD_E_VALOR_TRANSACOES (@DATA_INICIO DATETIME,@DATA_LIMITE DATETIME)
AS
BEGIN	
	DECLARE @QTD_TRANSACOES INT, @VALOR_TRANSACOES NUMERIC(10,2)
	
	SELECT @QTD_TRANSACOES = COUNT(FATO.QTD), @VALOR_TRANSACOES = SUM(FATO.VALOR)FROM FATO_ACOMPANHAMENTO AS FATO 
	JOIN AMBIENTE_DIMENSIONAL.DIM_SERVICO DS ON FATO.ID_SERVICO = DS.ID AND DS.status = 'CONCLUIDA'
	JOIN DIM_TEMPO AS TEMPO ON (TEMPO.id = FATO.id_tempo) AND (TEMPO.Data >= @DATA_INICIO) AND (TEMPO.Data <= @DATA_LIMITE)

	IF (@QTD_TRANSACOES IS NOT NULL OR @VALOR_TRANSACOES IS NOT NULL )
		SELECT @QTD_TRANSACOES AS 'QUANTIDADE DE TRANSACOES', @VALOR_TRANSACOES AS 'VALOR TOTAL' 
	ELSE
		SELECT 0 AS 'QUANTIDADE DE TRANSACOES', 0 AS 'VALOR TOTAL'
END

GO

/* 
	- QUESTIONAMENTO 06
	- QUANTIDADE DE ACOMPANHAMENTOS PAGOS EM DINHEIRO
	- VALOR TOTAL DESSA QUANTIDADE.
*/

GO

CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_06_QTD_ESPECIE_TOTAL_VALOR(@INICIO_PERIODO DATETIME, @FIM_PERIODO DATETIME)
AS
BEGIN
	SELECT COUNT(FATO.QTD) AS QUANTIDADE_ESPECIE, SUM(FATO.VALOR) AS TOTA FROM FATO_ACOMPANHAMENTO AS FATO
	JOIN AMBIENTE_DIMENSIONAL.DIM_TEMPO AS TEMPO ON (TEMPO.id = FATO.id_tempo) AND (TEMPO.Data >= @INICIO_PERIODO) AND (TEMPO.Data <= @FIM_PERIODO)
    JOIN AMBIENTE_DIMENSIONAL.DIM_TRANSACAO AS TRANS ON (TRANS.id = FATO.id_transacao) AND (TRANS.tipo_pagamento = 'EM ESPECIE')

END

GO

--- ------------------------------------------------------------------------------------------------------
-- 07 - Quantas transaÃ§Ãµes foram feitas via cartÃ£o de crÃ©dito/dÃ©bito? qual o valor total delas ? por perÃ­odo ?
--- -------------------------------------------------------------------------------------------------------
CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_07_QTD_E_VALOR_TRANSACOES_POR_CARTAO (@DATA_INICIO DATETIME,@DATA_LIMITE DATETIME)
AS
BEGIN
    DECLARE @QTD_TRANSACOES INT, @VALOR_TRANSACOES NUMERIC(10,2)

    SELECT @QTD_TRANSACOES = COUNT(FATO.QTD), @VALOR_TRANSACOES = SUM(FATO.VALOR) FROM FATO_ACOMPANHAMENTO AS FATO
	JOIN AMBIENTE_DIMENSIONAL.DIM_TEMPO AS TEMPO ON (TEMPO.id = FATO.id_tempo) AND (TEMPO.Data >= @DATA_INICIO) AND (TEMPO.Data <= @DATA_LIMITE)
    JOIN AMBIENTE_DIMENSIONAL.DIM_TRANSACAO AS TRANS ON (TRANS.id = FATO.id_transacao) AND (TRANS.tipo_pagamento = 'CARTAO CREDITO/DEBITO')

    IF (@QTD_TRANSACOES IS NOT NULL OR @VALOR_TRANSACOES IS NOT NULL )
        SELECT @QTD_TRANSACOES AS 'QUANTIDADE DE TRANSACOES POR CARTAO', @VALOR_TRANSACOES AS 'VALOR TOTAL'
    ELSE
        SELECT 0 AS 'QUANTIDADE DE TRANSACOES POR CARTAO', 0 AS 'VALOR TOTAL'
END

GO


/*
	- QUESTIONAMENTO 08
	- MEDIA DE VALORES DE ACOMPANHAMENTOS NO DIA
*/
CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_08_MEDIA_ACOMPANHENTO_DIA(@DATA DATETIME)
AS
BEGIN
    SELECT AVG(FA.VALOR) FROM AMBIENTE_DIMENSIONAL.FATO_ACOMPANHAMENTO FA
                                  INNER JOIN AMBIENTE_DIMENSIONAL.DIM_TEMPO DT
                                             ON FA.ID_TEMPO = DT.ID
    WHERE DT.DATA = @DATA;
END

GO

--- ------------------------------------------------------
-- 09 - Qual a faixa etÃ¡ria da maior parte dos clientes ?
--- ------------------------------------------------------

CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_09_FAIXA_ETARIA_CLIENTES
AS
BEGIN
    DECLARE @FAIXA_ETARIA_CLIENTE VARCHAR(100)
    DECLARE @QTD_CLIENTES INT

    SELECT TOP 1 @QTD_CLIENTES = COUNT(FATO.QTD), @FAIXA_ETARIA_CLIENTE = FX.descricao FROM FATO_ACOMPANHAMENTO AS FATO
	JOIN AMBIENTE_DIMENSIONAL.DIM_FAIXA_ETARIA AS FX ON (FX.id = FATO.id_faixa_etaria_cliente) GROUP BY FX.descricao

    IF (@FAIXA_ETARIA_CLIENTE IS NOT NULL OR @QTD_CLIENTES IS NOT NULL )
        SELECT @FAIXA_ETARIA_CLIENTE AS 'FAIXA ETARIA', @QTD_CLIENTES AS 'QUANTIDADE DE CLIENTES'
    ELSE
        SELECT 0 AS 'FAIXA ETARIA', 0 AS 'QUANTIDADE DE CLIENTES'
END

GO

--- ----------------------------------------------------------
-- 09 - Qual a faixa etÃ¡ria da maior parte dos acompanhantes ?
--- ----------------------------------------------------------

CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_09_FAIXA_ETARIA_ACOMPANHANTES
AS
BEGIN
    DECLARE @FAIXA_ETARIA_ACOMPANHANTE VARCHAR(100)
    DECLARE @QTD_ACOMPANHANTES INT

    SELECT TOP 1 @QTD_ACOMPANHANTES = COUNT(FATO.QTD), @FAIXA_ETARIA_ACOMPANHANTE = FX.descricao FROM FATO_ACOMPANHAMENTO AS FATO
                                                                                                          JOIN AMBIENTE_DIMENSIONAL.DIM_FAIXA_ETARIA AS FX ON (FX.id = FATO.id_faixa_etaria_acompanhante) GROUP BY FX.descricao

    IF (@FAIXA_ETARIA_ACOMPANHANTE IS NOT NULL OR @QTD_ACOMPANHANTES IS NOT NULL )
        SELECT @FAIXA_ETARIA_ACOMPANHANTE AS 'FAIXA ETARIA', @QTD_ACOMPANHANTES AS 'QUANTIDADE DE ACOMPANHANTES'
    ELSE
        SELECT 0 AS 'FAIXA ETARIA', 0 AS 'QUANTIDADE DE ACOMPANHANTES'
END

GO
--------------------------------------------------------------------------------------------------------------
-- 10 - Quais os tipos mais comuns de acompanhamento solicitado ?
--------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_10_TIPOS_MAIS_COMUNS_ACOMPANHAMENTO
AS
BEGIN
    SELECT TOP 2 COUNT(FATO.QTD) AS 'QUANTIDADE', FT.tipo_acompanhamento FROM AMBIENTE_DIMENSIONAL.FATO_ACOMPANHAMENTO AS FATO
	JOIN AMBIENTE_DIMENSIONAL.DIM_OPORTUNIDADE AS OP ON (FATO.id_oportunidade = OP.id) AND (OP.eh_publica = 0)
    JOIN AMBIENTE_DIMENSIONAL.DIM_TIPO_ACOMPANHAMENTO AS FT ON (FT.ID = FATO.ID_TIPO_ACOMPANHAMENTO) GROUP BY FT.tipo_acompanhamento;
END

 GO
--- ----------------------------------------------------------------------------------------------------------
-- 11 - Qual o tipo de serviÃ§o de acompanhamento sÃ£o ofertadas o maior nÃºmero de oportunidades ? por perÃ­odo ?
--- ----------------------------------------------------------------------------------------------------------

CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_11_TIPO_MAIS_COMUM_DE_ACOMPANHAMENTO (@DATA_INICIO DATETIME,@DATA_LIMITE DATETIME)
AS
BEGIN
    DECLARE @QTD_OPORTUNIDADES INT, @TIPO_ACOMPANHAMENTO VARCHAR(100)

    SELECT TOP 1 @QTD_OPORTUNIDADES = COUNT(FATO.QTD),@TIPO_ACOMPANHAMENTO = TIPO.tipo_acompanhamento FROM FATO_ACOMPANHAMENTO AS FATO
	JOIN AMBIENTE_DIMENSIONAL.DIM_OPORTUNIDADE AS OP ON (FATO.id_oportunidade = OP.id) AND (OP.eh_publica = 1)
    JOIN AMBIENTE_DIMENSIONAL.DIM_TEMPO AS TEMPO ON (TEMPO.id = FATO.id_tempo) AND (TEMPO.Data >= @DATA_INICIO) AND (TEMPO.Data <= @DATA_LIMITE)
    JOIN AMBIENTE_DIMENSIONAL.DIM_TIPO_ACOMPANHAMENTO AS TIPO ON (TIPO.id = FATO.id_tipo_acompanhamento) GROUP BY TIPO.tipo_acompanhamento


    IF (@QTD_OPORTUNIDADES IS NOT NULL OR @TIPO_ACOMPANHAMENTO IS NOT NULL )
        SELECT @TIPO_ACOMPANHAMENTO AS 'TIPO',@QTD_OPORTUNIDADES AS 'QUANTIDADE'
    ELSE
        SELECT 0 AS 'TIPO', 0 AS 'QUANTIDADE'

END

GO

--------------------------------------------------------------------------------------------------------------
-- 12 - Quais os tipos de serviÃ§o de acompanhamento ofertados possuem o maior nÃºmero candidatos?
--------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_12_TIPOS_COM_MAIS_CANDIDATOS
AS
BEGIN
    SELECT TOP 2 SUM(FO.QTD_CANDIDATOS) AS 'QUANTIDADE', FT.tipo_acompanhamento FROM AMBIENTE_DIMENSIONAL.FATO_ACOMPANHAMENTO AS FATO
                                                               JOIN AMBIENTE_DIMENSIONAL.DIM_TIPO_ACOMPANHAMENTO AS FT ON (FT.ID = FATO.ID_TIPO_ACOMPANHAMENTO)
                                                               JOIN AMBIENTE_DIMENSIONAL.DIM_OPORTUNIDADE AS FO ON (FT.ID = FATO.ID_OPORTUNIDADE)
    GROUP BY FT.tipo_acompanhamento;
END
GO

--- ------------------------------------------------------------------------------------------
-- 13 - Quais os estados em que sÃ£o realizadas o maior nÃºmero de Acompanhamentos? por perÃ­odo?
--- ------------------------------------------------------------------------------------------

CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_13_ESTADOS_MAIS_COMUNS (@DATA_INICIO DATETIME,@DATA_LIMITE DATETIME)
AS
BEGIN

    SELECT TOP 5 LOC.estado AS 'ESTADO',COUNT(FATO.QTD) AS 'QUANTIDADE DE ACOMPANHAMENTOS' FROM FATO_ACOMPANHAMENTO AS FATO
    JOIN AMBIENTE_DIMENSIONAL.DIM_TEMPO AS TEMPO ON (TEMPO.id = FATO.id_tempo) AND 
					(TEMPO.Data >= @DATA_INICIO) AND (TEMPO.Data <= @DATA_LIMITE)
    JOIN AMBIENTE_DIMENSIONAL.DIM_LOCALIDADE AS LOC ON (LOC.id = FATO.id_localidade) 
					GROUP BY LOC.estado ORDER BY 'QUANTIDADE DE ACOMPANHAMENTOS' DESC
END

GO

/*
	- QUESTIONAMENTO 14
	- NUMERO DE ACOMPANHAMENTOS POR CIDADE EM UM PERIODO DE TEMPO
*/
CREATE PROCEDURE AMBIENTE_DIMENSIONAL.SP_14_ACOMPANHAMENTOS_CIDADE(@CIDADE VARCHAR(45), @INICIO_PERIODO DATETIME, @FIM_PERIODO DATETIME)
AS
BEGIN
    SELECT COUNT(FA.ID_ACOMPANHANTE) AS 'QUANTIDADE' FROM AMBIENTE_DIMENSIONAL.FATO_ACOMPANHAMENTO FA
                                              INNER JOIN AMBIENTE_DIMENSIONAL.DIM_ACOMPANHANTE DA
                                                         ON FA.ID_ACOMPANHANTE = DA.ID
                                              INNER JOIN AMBIENTE_DIMENSIONAL.DIM_LOCALIDADE DL
                                                         ON FA.ID_LOCALIDADE = DL.ID
                                              INNER JOIN AMBIENTE_DIMENSIONAL.DIM_TEMPO DT
                                                         ON FA.ID_TEMPO = DT.ID
    WHERE DL.CIDADE = @CIDADE AND (DT.DATA >= @INICIO_PERIODO AND DT.DATA <= @FIM_PERIODO);
END

GO

EXEC AMBIENTE_DIMENSIONAL.SP_01_QTD_DE_ACOMPANHAMENTOS '20160721', '20190721'
EXEC AMBIENTE_DIMENSIONAL.SP_02_MEDIA_CANDIDATOS_VAGAS_PUBLICAS '20160721', '20190721'
EXEC AMBIENTE_DIMENSIONAL.SP_03_QTD_DE_ACOMPANHAMENTOS_CONCLUIDO '20160721', '20190721'
EXEC AMBIENTE_DIMENSIONAL.SP_04_SERVICO_CANCELADO_PERIODO '20160721', '20190721'
EXEC AMBIENTE_DIMENSIONAL.SP_05_QTD_E_VALOR_TRANSACOES '20160721', '20190721'
EXEC AMBIENTE_DIMENSIONAL.SP_06_QTD_ESPECIE_TOTAL_VALOR '20160721', '20190721'
EXEC AMBIENTE_DIMENSIONAL.SP_07_QTD_E_VALOR_TRANSACOES_POR_CARTAO '20160721', '20190721'
EXEC AMBIENTE_DIMENSIONAL.SP_08_MEDIA_ACOMPANHENTO_DIA '20190827'
EXEC AMBIENTE_DIMENSIONAL.SP_09_FAIXA_ETARIA_CLIENTES
EXEC AMBIENTE_DIMENSIONAL.SP_09_FAIXA_ETARIA_ACOMPANHANTES
EXEC AMBIENTE_DIMENSIONAL.SP_10_TIPOS_MAIS_COMUNS_ACOMPANHAMENTO
EXEC AMBIENTE_DIMENSIONAL.SP_11_TIPO_MAIS_COMUM_DE_ACOMPANHAMENTO '20160721', '20190721'
EXEC AMBIENTE_DIMENSIONAL.SP_12_TIPOS_COM_MAIS_CANDIDATOS
EXEC AMBIENTE_DIMENSIONAL.SP_13_ESTADOS_MAIS_COMUNS '20160721', '20210721'
EXEC AMBIENTE_DIMENSIONAL.SP_14_ACOMPANHAMENTOS_CIDADE 'itabaiana','20160721', '20190721'

