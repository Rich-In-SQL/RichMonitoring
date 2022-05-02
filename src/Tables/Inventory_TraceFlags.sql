CREATE TABLE Inventory.TraceFlags
(
ID INT IDENTITY(1,1),
CensusDate DATETIME DEFAULT GETDATE(),
[TraceFlag] INT,
[Status] BIT,
[Global] BIT,
[Session] BIT
);

ALTER TABLE Inventory.TraceFlags ADD CONSTRAINT PK_TraceFlags_ID PRIMARY KEY (ID)