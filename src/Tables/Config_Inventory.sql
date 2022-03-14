CREATE TABLE [Config].[Inventory] (
    [ID]              INT            IDENTITY (1, 1) NOT NULL,
    [StoredProcedure] NVARCHAR (255) NULL,
    [Description]     VARCHAR (255)  NULL,
    [RunOrder]        INT            NULL,
    [WeeklyUpdates]   VARCHAR (20)   NULL,
    [Active]          BIT            NULL,
    CONSTRAINT [PK_Inventory_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

