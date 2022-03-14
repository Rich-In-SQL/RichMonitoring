CREATE TABLE [Config].[AppConfig] (
    [ID]                INT             IDENTITY (1, 1) NOT NULL,
    [ConfigName]        VARCHAR (100)   NULL,
    [ConfigDescription] VARCHAR (500)   NULL,
    [StringValue]       VARCHAR (200)   NULL,
    [INTValue]          INT             NULL,
    [BoolValue]         BIT             NULL,
    [DecimalValue]      DECIMAL (16, 2) NULL,
    [DateValue]         DATE            NULL,
    [DateTimeValue]     DATETIME        NULL,
    [Active]            BIT             DEFAULT ((1)) NULL
);

