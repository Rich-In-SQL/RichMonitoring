CREATE TABLE [App].[UpdateLog] (
    [ID]          INT             IDENTITY (1, 1) NOT NULL,
    [UpgradeDate] DATETIME        NULL,
    [Version]     DECIMAL (16, 2) NULL,
    CONSTRAINT [PK_UpdateLog_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

