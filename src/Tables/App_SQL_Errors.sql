CREATE TABLE [App].[SQL_Errors] (
    [ID]               INT             IDENTITY (1, 1) NOT NULL,
    [Username]         NVARCHAR (256)  NULL,
    [Error_Number]     INT             NULL,
    [Error_State]      INT             NULL,
    [Error_Severity]   INT             NULL,
    [Error_Line]       INT             NULL,
    [Stored_Procedure] NVARCHAR (2000) NULL,
    [Error_Message]    NVARCHAR (2000) NULL,
    [EventDate]        DATETIME        NULL,
    CONSTRAINT [PK_SQLErrors_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

