CREATE TABLE [dbo].[configEmailTemplateDefault]
(
    [recnum] [int] NOT NULL IDENTITY(1, 1),
    [datestamp] [datetime] NULL,
    [pagePrimaryColor] [nvarchar] (7) NOT NULL,
    [pageSecondaryColor] [nvarchar] (7) NOT NULL,
    [pageFooterColor] [nvarchar] (7) NOT NULL,
    [fontFamily] [nvarchar] (255) NOT NULL,
    [fontFamilyUrl] [nvarchar] (255) NOT NULL,
    [fontPrimaryColor] [nvarchar] (7) NOT NULL,
    [fontFamilySecondary] [nvarchar] (255) NOT NULL,
    [fontFamilySecondaryUrl] [nvarchar] (255) NOT NULL,
    [fontFooterColor] [nvarchar] (7) NOT NULL,
    [logoImagesSrc] [nvarchar] (255) NOT NULL,
    [headerTitleText] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [headerTitleHref] [nvarchar] (255) NOT NULL,
    [brandingBarText] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [socialBarFacebookLink] [nvarchar] (255) NOT NULL,
    [socialBarTwitterLink] [nvarchar] (255) NOT NULL,
    [socialBarInstagramLink] [nvarchar] (255) NOT NULL,
    [socialBarYoutubeLink] [nvarchar] (255) NOT NULL,
    [addressBarText] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
) ON [PRIMARY]

ALTER TABLE [dbo].[configEmailTemplateDefault] ADD CONSTRAINT [PK_configEmailTemplateDefault] PRIMARY KEY CLUSTERED  ([recnum]) ON [PRIMARY]
GO
