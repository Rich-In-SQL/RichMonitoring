CREATE TABLE [Inventory].[DatabaseSize] (
    [ID]            INT            IDENTITY (1, 1) NOT NULL,
    [CensusDate]    DATETIME       NULL,
    [database_name] NVARCHAR (128) NULL,
    [Size_MB]       BIGINT         NULL,
    [Size_GB]       BIGINT         NULL,
    CONSTRAINT [PK_DatabaseSize_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

