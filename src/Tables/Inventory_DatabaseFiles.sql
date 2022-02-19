CREATE TABLE [Inventory].[DatabaseFiles] (
    [ID]                INT            IDENTITY (1, 1) NOT NULL,
    [CensusDate]        DATETIME       DEFAULT (getdate()) NULL,
    [DataBaseName]      NVARCHAR (128) NULL,
    [file_id]           INT            NULL,
    [name]              NVARCHAR (128) NULL,
    [type_desc]         NVARCHAR (60)  NULL,
    [size]              INT            NULL,
    [max_size]          INT            NULL,
    [State]             NVARCHAR (60)  NULL,
    [growth]            INT            NULL,
    [is_percent_growth] BIT            NULL,
    [physical_name]     NVARCHAR (260) NULL,
    CONSTRAINT [PK_DatabaseFiles_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

