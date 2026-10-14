/* =========================================================
   1. CRIACAO DO BANCO DE DADOS
   ========================================================= */

USE master;
GO

IF DB_ID('aeronautica_db') IS NOT NULL
BEGIN
    ALTER DATABASE aeronautica_db
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE aeronautica_db;
END;
GO

CREATE DATABASE aeronautica_db;
GO

USE aeronautica_db;
GO


/* =========================================================
   2. CRIACAO DA TABELA DE MATERIAIS
   ========================================================= */

CREATE TABLE materiais (
    id INT PRIMARY KEY,
    nome VARCHAR(250) NOT NULL,
    descricao VARCHAR(MAX),
    medida VARCHAR(25) NOT NULL,
    estoque_minimo INT NOT NULL DEFAULT 0,
    ativo INT NOT NULL DEFAULT 1
);
GO


/* =========================================================
   3. CRIACAO DA TABELA DE FORNECEDORES
   ========================================================= */

CREATE TABLE fornecedores (
    id INT PRIMARY KEY,
    nome VARCHAR(250) NOT NULL,
    contato VARCHAR(250),
    telefone VARCHAR(25),
    ativo INT NOT NULL DEFAULT 1
);
GO


/* =========================================================
   4. CRIACAO DAS TABELAS DE ENTRADAS E SAIDAS
   ========================================================= */

CREATE TABLE entradas (
    id INT IDENTITY(1,1) PRIMARY KEY,
    id_material INT NOT NULL,
    id_fornecedor INT NOT NULL,
    data_entrada DATE NOT NULL,
    quantidade INT NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    nota_fiscal VARCHAR(50),

    CONSTRAINT FK_entradas_materiais
        FOREIGN KEY (id_material)
        REFERENCES materiais(id),

    CONSTRAINT FK_entradas_fornecedores
        FOREIGN KEY (id_fornecedor)
        REFERENCES fornecedores(id),

    CONSTRAINT CK_entradas_quantidade
        CHECK (quantidade > 0),

    CONSTRAINT CK_entradas_preco
        CHECK (preco >= 0)
);
GO

CREATE TABLE saidas (
    id INT IDENTITY(1,1) PRIMARY KEY,
    id_material INT NOT NULL,
    data_saida DATE NOT NULL,
    quantidade INT NOT NULL,
    destino VARCHAR(50),

    CONSTRAINT FK_saidas_materiais
        FOREIGN KEY (id_material)
        REFERENCES materiais(id),

    CONSTRAINT CK_saidas_quantidade
        CHECK (quantidade > 0)
);
GO


/* =========================================================
   5. IMPORTACAO DOS MATERIAIS
   Crie o arquivo materiais.csv com os dados do roteiro.
   Formato: campos separados por ponto e virgula.
   ========================================================= */

BULK INSERT materiais
FROM 'C:\Dados\materiais.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    TABLOCK
);
GO


/* =========================================================
   6. IMPORTACAO DOS FORNECEDORES
   Crie o arquivo fornecedores.csv com os dados do roteiro.
   ========================================================= */

BULK INSERT fornecedores
FROM 'C:\Dados\fornecedores.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    TABLOCK
);
GO


/* =========================================================
   7. PROCEDIMENTO PARA REGISTRAR ENTRADA DE MATERIAIS
   ========================================================= */

CREATE PROCEDURE registrar_entrada
    @p_id_material INT,
    @p_id_fornecedor INT,
    @p_data_entrada DATE,
    @p_quantidade INT,
    @p_preco DECIMAL(10,2),
    @p_nota_fiscal VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO entradas (
        id_material,
        id_fornecedor,
        data_entrada,
        quantidade,
        preco,
        nota_fiscal
    )
    VALUES (
        @p_id_material,
        @p_id_fornecedor,
        @p_data_entrada,
        @p_quantidade,
        @p_preco,
        @p_nota_fiscal
    );
END;
GO


/* =========================================================
   8. REGISTRO DAS ENTRADAS DE MATERIAIS
   ========================================================= */

EXEC registrar_entrada
    1, 1, '2023-10-25', 100, 5.50, 'NF001';

EXEC registrar_entrada
    2, 2, '2023-10-26', 50, 12.00, 'NF002';

EXEC registrar_entrada
    7, 7, '2023-10-27', 40, 18.90, 'NF150';
GO


/* =========================================================
   9. PROCEDIMENTO PARA REGISTRAR SAIDA DE MATERIAIS
   ========================================================= */

CREATE PROCEDURE registrar_saida
    @p_id_material INT,
    @p_data_saida DATE,
    @p_quantidade INT,
    @p_destino VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO saidas (
        id_material,
        data_saida,
        quantidade,
        destino
    )
    VALUES (
        @p_id_material,
        @p_data_saida,
        @p_quantidade,
        @p_destino
    );
END;
GO


/* =========================================================
   10. REGISTRO DAS SAIDAS DE MATERIAIS
   ========================================================= */

EXEC registrar_saida
    3, '2023-11-01', 50, 'OP003';

EXEC registrar_saida
    6, '2023-11-05', 20, 'OP010';
GO


/* =========================================================
   11. PROCEDIMENTO PARA INATIVAR MATERIAIS
   ========================================================= */

CREATE PROCEDURE inativar_material
    @p_id_material INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE materiais
    SET ativo = 0
    WHERE id = @p_id_material;
END;
GO


/* =========================================================
   12. INATIVACAO DE MATERIAIS
   ========================================================= */

EXEC inativar_material 4;
EXEC inativar_material 10;
GO


/* =========================================================
   13. PROCEDIMENTO PARA INATIVAR FORNECEDORES
   ========================================================= */

CREATE PROCEDURE inativar_fornecedor
    @p_id_fornecedor INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE fornecedores
    SET ativo = 0
    WHERE id = @p_id_fornecedor;
END;
GO


/* =========================================================
   14. INATIVACAO DE FORNECEDORES
   ========================================================= */

EXEC inativar_fornecedor 4;
EXEC inativar_fornecedor 10;
GO


/* =========================================================
   15. FUNCAO PARA CALCULAR O ESTOQUE
   ========================================================= */

CREATE FUNCTION calcular_estoque (
    @p_id_material INT
)
RETURNS INT
AS
BEGIN
    DECLARE @total_entradas INT;
    DECLARE @total_saidas INT;

    SELECT @total_entradas = ISNULL(SUM(quantidade), 0)
    FROM entradas
    WHERE id_material = @p_id_material;

    SELECT @total_saidas = ISNULL(SUM(quantidade), 0)
    FROM saidas
    WHERE id_material = @p_id_material;

    RETURN @total_entradas - @total_saidas;
END;
GO


/* =========================================================
   16. VALIDACAO DA FUNCAO DE ESTOQUE
   ========================================================= */

SELECT dbo.calcular_estoque(1) AS estoque_material_1;
SELECT dbo.calcular_estoque(2) AS estoque_material_2;
SELECT dbo.calcular_estoque(7) AS estoque_material_7;
GO


/* =========================================================
   17. CRIACAO DA VIEW DE CONSULTA DE ESTOQUE
   ========================================================= */

CREATE VIEW consultar_estoque
AS
SELECT
    id,
    nome,
    medida,
    estoque_minimo,
    dbo.calcular_estoque(id) AS estoque_atual
FROM materiais;
GO


/* =========================================================
   18. CONSULTA DO ESTOQUE DE TODOS OS MATERIAIS
   ========================================================= */

SELECT *
FROM consultar_estoque
ORDER BY nome ASC;
GO


/* =========================================================
   19. CONSULTAS PARA CONFERIR AS TABELAS
   ========================================================= */

SELECT * FROM materiais ORDER BY id;
SELECT * FROM fornecedores ORDER BY id;
SELECT * FROM entradas ORDER BY id;
SELECT * FROM saidas ORDER BY id;
GO


/* =========================================================
   20. EXPORTACAO DOS DADOS DE ENTRADAS
   O arquivo sera salvo no caminho indicado.
   ========================================================= */

SELECT
    id,
    id_material,
    id_fornecedor,
    data_entrada,
    quantidade,
    preco,
    nota_fiscal
FROM entradas
ORDER BY id;
GO

/*
Para exportar para CSV pelo SSMS:
1. Execute a consulta acima.
2. No painel de resultados, clique com o botao direito.
3. Selecione Save Results As...
4. Salve como entradas.csv.
*/


/* =========================================================
   21. EXPORTACAO DOS DADOS DE SAIDAS
   ========================================================= */

SELECT
    id,
    id_material,
    data_saida,
    quantidade,
    destino
FROM saidas
ORDER BY id;
GO

/*
Para exportar para CSV pelo SSMS:
1. Execute a consulta acima.
2. No painel de resultados, clique com o botao direito.
3. Selecione Save Results As...
4. Salve como saidas.csv.
*/


/* =========================================================
   22. CONSULTA FINAL DO ESTOQUE
   ========================================================= */

SELECT
    m.id,
    m.nome,
    m.medida,
    m.estoque_minimo,
    dbo.calcular_estoque(m.id) AS estoque_atual,
    CASE
        WHEN dbo.calcular_estoque(m.id) < m.estoque_minimo
            THEN 'ESTOQUE ABAIXO DO MINIMO'
        ELSE 'ESTOQUE NORMAL'
    END AS situacao
FROM materiais AS m
ORDER BY m.nome ASC;
GO