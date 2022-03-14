CREATE TABLE [Inventory].[Logins] (
    [ID]                    INT            IDENTITY (1, 1) NOT NULL,
    [CensusDate]            DATETIME       DEFAULT (getdate()) NULL,
    [Server_Name]           NVARCHAR (255) NULL,
    [LoginName]             NVARCHAR (128) NULL,
    [principal_id]          INT            NULL,
    [sid]                   VARBINARY (85) NULL,
    [Login_Type]            VARCHAR (50)   NULL,
    [Disabled]              BIT            NULL,
    [create_date]           DATETIME       NULL,
    [modify_date]           DATETIME       NULL,
    [default_database_name] NVARCHAR (128) NULL,
    [default_language_name] NVARCHAR (128) NULL,
    [Sys_Admin_Flag]        BIT            NULL,
    CONSTRAINT [PK_Logins_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

