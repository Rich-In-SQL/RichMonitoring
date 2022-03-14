CREATE TABLE [dbo].[JobHistory_Archive] (
    [ID]         INT             IDENTITY (1, 1) NOT NULL,
    [JobName]    NVARCHAR (128)  NULL,
    [Message]    NVARCHAR (4000) NULL,
    [Run_Date]   INT             NULL,
    [Run_Time]   INT             NULL,
    [Run_Status] INT             NULL,
    [Date_Added] DATETIME        DEFAULT (getdate()) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

