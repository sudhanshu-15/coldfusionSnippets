CREATE TABLE [dbo].[correspondenceRead]
(
[recnum] [int] NOT NULL IDENTITY(1, 1),
[idnumber] [int] NOT NULL,
[correspondenceID] [int] NOT NULL,
[communicationType] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[datestamp] [datetime] NULL,
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[correspondenceRead] ADD CONSTRAINT [PK_correspondenceRead] PRIMARY KEY CLUSTERED  ([recnum])  ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_correspondenceRead_correspondenceID] ON [dbo].[correspondenceRead] ([correspondenceID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_correspondenceRead_idnumber_recnum] ON [dbo].[correspondenceRead] ([idnumber], [recnum])  ON [PRIMARY]
GO
ALTER TABLE [dbo].[correspondenceRead] ADD CONSTRAINT [FK_correspondenceRead_table2] FOREIGN KEY ([idnumber]) REFERENCES [dbo].[table2] ([idnumber])
GO