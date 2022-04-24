CREATE TABLE Inventory.sysconfigurations
(
    ID INT IDENTITY(1,1) NOT NULL,
    CensusDate DATETIME,
    Configuration_ID INT,
    Name nvarchar(35),
    value SQL_VARIANT,
    [minimum] SQL_VARIANT, 
    [maximum] SQL_VARIANT, 
    [value_in_use] SQL_VARIANT, 
    [description] nvarchar(255), 
    [is_dynamic] BIT, 
    [is_advanced] BIT
)

ALTER TABLE Inventory.sysconfigurations ADD CONSTRAINT PK_sysconfigurations_ID PRIMARY KEY (ID)