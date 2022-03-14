CREATE TABLE [Inventory].[RunLog] (
    [ID]            INT            IDENTITY (1, 1) NOT NULL,
    [EventDate]     DATETIME       DEFAULT (getdate()) NULL,
    [ProcedureName] NVARCHAR (128) NULL,
    [Action]        VARCHAR (100)  NULL,
    CONSTRAINT [PK_RunLog_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

