CREATE TABLE [Inventory].[SysAdmins] (
    [ID]          INT            IDENTITY (1, 1) NOT NULL,
    [CensusDate]  DATETIME       DEFAULT (getdate()) NULL,
    [Server_Name] NVARCHAR (255) NULL,
    [LoginName]   NVARCHAR (128) NULL,
    [sid]         VARBINARY (85) NULL,
    [Login_Type]  VARCHAR (50)   NULL,
    [Disabled]    BIT            NULL,
    [create_date] DATETIME       NULL,
    [modify_date] DATETIME       NULL,
    CONSTRAINT [PK_SysAdmins_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

