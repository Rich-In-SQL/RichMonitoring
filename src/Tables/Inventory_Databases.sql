CREATE TABLE [Inventory].[Databases] (
    [ID]                  INT            IDENTITY (1, 1) NOT NULL,
    [CensusDate]          DATETIME       NULL,
    [database_id]         INT            NULL,
    [database_name]       NVARCHAR (128) NULL,
    [create_date]         DATETIME       NULL,
    [compatibility_level] INT            NULL,
    [collation_name]      NVARCHAR (128) NULL,
    [is_read_only]        BIT            NULL,
    [is_auto_close_on]    BIT            NULL,
    [user_access_desc]    NVARCHAR (60)  NULL,
    [state_desc]          NVARCHAR (60)  NULL,
    [recovery_model_desc] NVARCHAR (60)  NULL,
    [log_reuse_wait_desc] NVARCHAR (60)  NULL,
    CONSTRAINT [PK_Databases_ID_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

