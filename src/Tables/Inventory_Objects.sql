CREATE TABLE [Inventory].[Objects] (
    [ID]                    INT            IDENTITY (1, 1) NOT NULL,
    [CensusDate]            DATETIME       DEFAULT (getdate()) NULL,
    [DatabaseName]          NVARCHAR (128) NULL,
    [ParentObjectName]      NVARCHAR (128) NULL,
    [ObjectName]            NVARCHAR (128) NULL,
    [ObjectDefinition]      NVARCHAR (MAX) NULL,
    [SchemaName]            NVARCHAR (128) NULL,
    [ObjectType]            NVARCHAR (128) NULL,
    [ObjectTypeDescription] NVARCHAR (128) NULL,
    [create_date]           DATETIME       NULL,
    [modify_date]           DATETIME       NULL,
    CONSTRAINT [PK_Objects_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

