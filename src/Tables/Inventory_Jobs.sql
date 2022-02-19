CREATE TABLE [Inventory].[Jobs] (
    [ID]             INT              IDENTITY (1, 1) NOT NULL,
    [CensusDate]     DATETIME         NULL,
    [JobName]        NVARCHAR (128)   NULL,
    [job_id]         UNIQUEIDENTIFIER NULL,
    [enabled]        BIT              NULL,
    [start_step_id]  INT              NULL,
    [step_id]        INT              NULL,
    [step_name]      NVARCHAR (128)   NULL,
    [subsystem]      VARCHAR (40)     NULL,
    [command]        NVARCHAR (MAX)   NULL,
    [On_Success]     VARCHAR (17)     NULL,
    [On_Failure]     VARCHAR (17)     NULL,
    [schedule_id]    INT              NULL,
    [FrequencyType]  VARCHAR (45)     NULL,
    [Interval]       VARCHAR (6)      NULL,
    [freq_type]      VARCHAR (24)     NULL,
    [DailyFrequency] VARCHAR (24)     NULL,
    [Interval2]      VARCHAR (26)     NULL,
    [StartTime]      VARCHAR (8)      NULL,
    [EndTime]        VARCHAR (8)      NULL,
    CONSTRAINT [PK_Jobs_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

