/** 
 * ------------------------- ATEN��O ------------------------- 
 * ANTES DE EXECUTAR ESTE SCRIPT, VOC� DEVER� EXECUTAR
 * O SCRIPT POVOANDO_DIMS_PRE_CARRGAVEIS.SQL NESTA MESMA PASTA,
 * QUE REALIZA O TRABALHO DE CARREGAMENTO DE ALGUMAS DIMENS�ES
 * COMO DIM_TEMPO, DIM_FAIXA_ETARIA, DIM_TRANSACAO, QUE S�O 
 * DIMENS�ES COM DADOS PR�-DEFINIDOS NECE�SS�RIOS PARA ESTA ETAPA */

/*--------------------------- PROCEDIMENTOS DE CARGA DO AMBIENTE OPERACIONAL PARA AREA DE STAGING ---------------------------*/

EXEC AMBIENTE_OLAP.SO_EXECUTA_PROCEDIMENTOS_DE_CARGA '20190721'

/* ------------------------------------------------------------------------------------------------------------ */

--- CARREGA DADOS DO AMBIENTE OPERACIONAL PARA AS TABELAS AUXILIARES DE CLIENTE E ACOMPANHANTE
CREATE PROCEDURE AMBIENTE_OLAP.SP_OLTP_CARREGA_CLIENTES_E_ACOMPANHANTES (@DATACARGA DATETIME)
AS
	BEGIN
		DECLARE @IDUSUARIO INT
		DECLARE @NOME VARCHAR(45)
		DECLARE @CPF VARCHAR(11)
		DECLARE @TELEFONE VARCHAR(13)
		DECLARE @GENERO VARCHAR(45)
		DECLARE @USUARIO VARCHAR(45)
		DECLARE @NASCIMENTO DATE
		DECLARE @IDADE INT
		DECLARE @VALORHORA NUMERIC(10,2)

		DECLARE USUARIO CURSOR FOR
		SELECT idUsuario, nome, cpf,telefone, genero, usuario, dataNascimento FROM AMBIENTE_OLTP.Usuario WHERE (data_atualizacao >= @DATACARGA)

		DELETE AMBIENTE_OLAP.TB_AUX_CLIENTE WHERE @DATACARGA = data_carga
		DELETE AMBIENTE_OLAP.TB_AUX_ACOMPANHANTE WHERE @DATACARGA = data_carga


		OPEN USUARIO
		FETCH USUARIO INTO @IDUSUARIO,@NOME,@CPF,@TELEFONE,@GENERO,@USUARIO,@NASCIMENTO

		WHILE (@@FETCH_STATUS = 0)
			BEGIN
				SET @IDADE = DATEDIFF(mm,@NASCIMENTO,@DATACARGA)/12

				IF (EXISTS (SELECT * FROM AMBIENTE_OLTP.Acompanhante WHERE @IDUSUARIO = idAcompanhante))
					BEGIN
						SET @VALORHORA = (SELECT valorHora FROM AMBIENTE_OLTP.Acompanhante WHERE @IDUSUARIO = idAcompanhante)

						INSERT INTO AMBIENTE_OLAP.TB_AUX_ACOMPANHANTE (data_carga,codigo,nome,cpf,telefone,genero,usuario,data_nascimento,idade,valor_hora)
						VALUES(@DATACARGA,@IDUSUARIO,@NOME,@CPF,@TELEFONE,@GENERO,@USUARIO,@NASCIMENTO,@IDADE,@VALORHORA)
					END
				ELSE 
					BEGIN

						INSERT INTO AMBIENTE_OLAP.TB_AUX_CLIENTE (data_carga,codigo,nome,cpf,telefone,genero,usuario,data_nascimento,idade)
						VALUES(@DATACARGA,@IDUSUARIO,@NOME,@CPF,@TELEFONE,@GENERO,@USUARIO,@NASCIMENTO,@IDADE)
					END
				FETCH USUARIO INTO @IDUSUARIO,@NOME,@CPF,@TELEFONE,@GENERO,@USUARIO,@NASCIMENTO
			END
			CLOSE USUARIO
			DEALLOCATE USUARIO
	END

GO
/* ------------------------------------------------------------------------------------------------------------ */

--- CARREGA DADOS DO AMBIENTE OPERACIONAL PARA AS TABELAS AUXILIARES DE ENDERECO, OPORTUNIDADE, SERVICO, TRANSACAO, TIPO DE ACOMPANHANMENTO
CREATE PROCEDURE AMBIENTE_OLAP.SP_OLTP_CARGAS_SIMPLES (@DATACARGA DATETIME)
AS
	BEGIN

		DELETE AMBIENTE_OLAP.TB_AUX_LOCALIDADE		  WHERE @DATACARGA = data_carga
		DELETE AMBIENTE_OLAP.TB_AUX_OPORTUNIDADE		  WHERE @DATACARGA = data_carga
		DELETE AMBIENTE_OLAP.TB_AUX_SERVICO			  WHERE @DATACARGA = data_carga
		DELETE AMBIENTE_OLAP.TB_AUX_TIPO_ACOMPANHAMENTO WHERE @DATACARGA = data_carga

		INSERT INTO AMBIENTE_OLAP.TB_AUX_LOCALIDADE (data_carga,codigo,estado,cidade,rua,bairro,id_servico)
		(SELECT @DATACARGA,idDetalhesEncontro,estado,cidade,rua,bairro,idServico FROM AMBIENTE_OLTP.DetalhesEncontro WHERE (data_atualizacao >= @DATACARGA))

		INSERT INTO AMBIENTE_OLAP.TB_AUX_OPORTUNIDADE (data_carga, codigo,titulo,descricao,status,eh_publica,id_tipo_acompanhamento,qtd_candidatos)
		(SELECT @DATACARGA,op.idOportunidade, op.titulo,op.descricao,op.status,op.EhPublica,op.idTipoAcompanhamento,
			isnull((SELECT COUNT(cd.idCandidatura) AS CANDIDATURA  FROM AMBIENTE_OLTP.Candidatura as cd
			Where cd.idOportunidade = op.idOportunidade GROUP BY cd.idOportunidade),0)
		FROM AMBIENTE_OLTP.Oportunidade as op WHERE (data_atualizacao >= @DATACARGA))

		INSERT INTO AMBIENTE_OLAP.TB_AUX_SERVICO(data_carga,codigo,id_cliente,id_acompanhante,id_oportunidade,valor_total,status)
		(SELECT @DATACARGA,se.idServico,se.idCliente,se.idAcompanhante,se.idOportunidade,
			(SELECT dt.valor FROM AMBIENTE_OLTP.DetalhesEncontro AS dt WHERE dt.idServico = se.idServico),
		status FROM AMBIENTE_OLTP.Servico as se WHERE (data_atualizacao >= @DATACARGA))

		INSERT INTO AMBIENTE_OLAP.TB_AUX_TIPO_ACOMPANHAMENTO (data_carga,codigo,tipo_acompanhamento,descricao)
		(SELECT @DATACARGA,idTipoAcompanhamento,TipoAcompanhamento,descricao FROM AMBIENTE_OLTP.TipoAcompanhamento WHERE (data_atualizacao >= @DATACARGA))

	END

GO
/* ------------------------------------------------------------------------------------------------------------ */


--- CARREGA DADOS DAS TABELAS AUXILIARES PARA TABELA AUXILIAR DO FATO
CREATE PROCEDURE AMBIENTE_OLAP.SP_CARREGA_FATO (@DATA_CARGA DATETIME)
AS
	BEGIN

		DECLARE @CODIGO INT, @DATA_SOLICITACAO DATETIME , @ID_ACOMPANHANTE INT, @ID_CLIENTE INT,
		@ID_TIPO_ACOMPANHAMENTO INT, @STATUS VARCHAR(50), @ID_TEMPO INT, @ID_LOCALIDADE INT,
		@ID_OPORTUNIDADE INT, @ID_TRANSACAO INT, @ID_FAIXA_ETARIA_ACOMPANHANTE INT, @ID_FAIXA_ETARIA_CLIENTE INT,
		@IDADE INT, @VALOR NUMERIC(10,2), @QTD_CANDIDATOS INT,@TIPO_PAGAMENTO VARCHAR(50)

		DECLARE servico CURSOR FOR
		SELECT codigo,id_cliente,id_acompanhante,id_oportunidade,valor_total,status
		FROM AMBIENTE_OLAP.TB_AUX_SERVICO

		DELETE AMBIENTE_OLAP.TB_AUX_FATO_ACOMPANHAMENTO WHERE @DATA_CARGA = data_carga

		OPEN servico
		FETCH servico INTO @CODIGO,@ID_CLIENTE,@ID_ACOMPANHANTE,@ID_OPORTUNIDADE,@VALOR,@STATUS

		WHILE(@@FETCH_STATUS = 0)
			BEGIN


				SET @ID_TEMPO			= (SELECT id FROM AMBIENTE_DIMENSIONAL.DIM_TEMPO WHERE data = CAST(@DATA_CARGA AS DATE))
				SET @ID_LOCALIDADE		= (SELECT codigo FROM AMBIENTE_OLAP.TB_AUX_LOCALIDADE WHERE id_servico = @CODIGO)
				SET @IDADE				= (SELECT idade FROM AMBIENTE_OLAP.TB_AUX_ACOMPANHANTE WHERE codigo = @ID_ACOMPANHANTE)
				SET @ID_FAIXA_ETARIA_ACOMPANHANTE = (SELECT id FROM AMBIENTE_DIMENSIONAL.DIM_FAIXA_ETARIA WHERE @IDADE >= idade_inicial AND @IDADE <= idade_final)
				SET @IDADE					      = (SELECT idade FROM AMBIENTE_OLAP.TB_AUX_CLIENTE WHERE codigo = @ID_CLIENTE)
				SET @ID_FAIXA_ETARIA_CLIENTE	  = (SELECT id FROM AMBIENTE_DIMENSIONAL.DIM_FAIXA_ETARIA WHERE @IDADE >= idade_inicial AND @IDADE <= idade_final)
				SET @ID_TIPO_ACOMPANHAMENTO       = (SELECT codigo FROM AMBIENTE_OLAP.TB_AUX_OPORTUNIDADE WHERE @ID_OPORTUNIDADE = codigo)

				SET @TIPO_PAGAMENTO = (SELECT tipoPagamento FROM AMBIENTE_OLTP.Transacao WHERE @CODIGO = idServico)
				IF (@TIPO_PAGAMENTO IS NOT NULL )
					SET @ID_TRANSACAO  = (SELECT ID FROM AMBIENTE_DIMENSIONAL.DIM_TRANSACAO WHERE tipo_pagamento = @TIPO_PAGAMENTO)
				ELSE
					SET @ID_TRANSACAO  = (SELECT ID FROM AMBIENTE_DIMENSIONAL.DIM_TRANSACAO WHERE tipo_pagamento = 'NAO REALIZADO')

				INSERT INTO AMBIENTE_OLAP.TB_AUX_FATO_ACOMPANHAMENTO (data_carga,id_tempo,id_cliente,id_acompanhante,id_localidade,id_oportunidade,id_servico,id_transacao,id_faixa_etaria_cliente,id_faixa_etaria_acompanhante,id_tipo_acompanhamento,qtd,valor)
				VALUES(@DATA_CARGA,@ID_TEMPO,@ID_CLIENTE,@ID_ACOMPANHANTE,@ID_LOCALIDADE,@ID_OPORTUNIDADE,@CODIGO,@ID_TRANSACAO,@ID_FAIXA_ETARIA_CLIENTE,@ID_FAIXA_ETARIA_ACOMPANHANTE,@ID_TIPO_ACOMPANHAMENTO,1,@VALOR)


				FETCH servico INTO @CODIGO,@ID_CLIENTE,@ID_ACOMPANHANTE,@ID_OPORTUNIDADE,@VALOR,@STATUS
			END
			CLOSE servico
			DEALLOCATE servico
	END

GO

CREATE PROCEDURE AMBIENTE_OLAP.SO_EXECUTA_PROCEDIMENTOS_DE_CARGA(@DATA_DE_CARGA DATETIME)
AS
BEGIN

	EXEC AMBIENTE_OLAP.SP_OLTP_CARREGA_CLIENTES_E_ACOMPANHANTES @DATA_DE_CARGA
	EXEC AMBIENTE_OLAP.SP_OLTP_CARGAS_SIMPLES @DATA_DE_CARGA
	EXEC AMBIENTE_OLAP.SP_CARREGA_FATO @DATA_DE_CARGA

END