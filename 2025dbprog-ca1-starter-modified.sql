use S00233718
go
-- a version of Padraig Harte's starter code for a SQL Server project
-- included here so that all of my changes are recorded (and should be used in testing my code for the project)

CREATE TABLE [Dbo].[DoctorTBL](
	[DoctorID] [int] IDENTITY(1,1) NOT NULL,
	[DoctorName] [varchar](50) NULL,
	[DoctorSpeciality] [varchar](50) NULL,
	[DoctorBleepID] [char](10) NULL,
	[COVID19Vacinated] [bit] NULL,
 CONSTRAINT [PK_Doctor_table] PRIMARY KEY CLUSTERED 
(
	[DoctorID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO


CREATE TABLE [Dbo].[WarDTBL](
	[WardID] [int] IDENTITY(1,1) NOT NULL,
	[WardName] [varchar](50) NULL,
	[WardManager] [int] NULL,
	[WardCapacity] [tinyint] NULL,
	[WardSpeciality] [char](20) NULL,
	[WardStatus] [char](15) NULL,
 CONSTRAINT [PK_WarD_table] PRIMARY KEY CLUSTERED 
(
	[WarDID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO

CREATE TABLE [Dbo].[PatientTBL](
	[PatientID] [int] IDENTITY(1,1) NOT NULL,
	[PatientFname] [varchar](35) NULL,
	[PatientLname] [varchar](35) NULL,
	[PatientWarD] [int] NULL,
	[PatientDependency] [char](5) NULL,
	PatientCOVIDStatus [char] (8), 
 CONSTRAINT [PK_Patient_table] PRIMARY KEY CLUSTERED 
(
	[PatientID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO

CREATE TABLE [Dbo].[NurseTBL](
	[NurseID] [int] IDENTITY(100000,1) NOT NULL,
	[NurseName] [varchar](50) NULL,
	[NurseSpeciality] [varchar](50) NULL,
	[NurseWarD] [int] NULL,
	COVID19Vacinated bit,
 CONSTRAINT [PK_Nurse_table] PRIMARY KEY CLUSTERED 
(
	[NurseID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_NULLS ON
GO

CREATE TABLE [Dbo].[CareTeamTBL](
	[CareTeamID] [int] NOT NULL,
	[PatientID] [int] NULL,
	[DateFormed] [date] NULL,
	[DateFinished] [date] NULL,
 CONSTRAINT [PK_care_team] PRIMARY KEY CLUSTERED 
(
	[CareTeamID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_NULLS ON
GO

ALTER TABLE [dbo].[CareTeamTBL] ADD  CONSTRAINT [DF_CareTeamTBL_DateFormed]  DEFAULT (getdate()) FOR [DateFormed]
GO

CREATE TABLE [Dbo].[TheatreBookingTBL](
	[BookingID] [int] NOT NULL,
	[PatientID] [int] NULL,
	[CareTeamID] [int] NULL,
	[DateReservereD] [date] NULL,
	[ReservationCode] [char](9) NULL,
 CONSTRAINT [PK_theatre_bookingTBL] PRIMARY KEY CLUSTERED 
(
	[BookingID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_NULLS ON
GO

CREATE TABLE [dbo].[NurseCareTeamMembersTBL](
	[CareTeamID] [int] NOT NULL,
	[MemberID] [int] NOT NULL,
	[DateJoineD] [smalldatetime] NULL,
	[CurrentMember] [bit] NOT NULL,
 CONSTRAINT [PK_NurseCareTeamMembersTBL] PRIMARY KEY CLUSTERED 
(
	[CareTeamID] ASC,
	[MemberID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[NurseCareTeamMembersTBL] ADD  CONSTRAINT [DF_careteam_members_table_Date_joineD]  DEFAULT (getdate()) FOR [DateJoineD]
GO

ALTER TABLE [dbo].[NurseCareTeamMembersTBL] ADD  CONSTRAINT [DF_careteam_members_current_member]  DEFAULT ((1)) FOR [CurrentMember]
GO

ALTER TABLE [dbo].[NurseCareTeamMembersTBL]  WITH CHECK ADD  CONSTRAINT [FK_care_team_members_table_Nurse_table] FOREIGN KEY([MemberID])
REFERENCES [dbo].[NurseTBL] ([NurseID])
GO

ALTER TABLE [dbo].[NurseCareTeamMembersTBL] CHECK CONSTRAINT [FK_care_team_members_table_Nurse_table]
GO


CREATE TABLE [dbo].[DoctorCareTeamMembersTBL](
	[CareTeamID] [int] NOT NULL,
	[MemberID] [int] NOT NULL,
	[DateJoineD] [smalldatetime] NULL,
	[CurrentMember] [bit] NOT NULL,
 CONSTRAINT [PK_DoctorCareTeamMembersTBL] PRIMARY KEY CLUSTERED 
(
	[CareTeamID] ASC,
	[MemberID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[DoctorCareTeamMembersTBL] ADD  CONSTRAINT [DF_care_team_members_table_Date_joineD]  DEFAULT (getdate()) FOR [DateJoineD]
GO

ALTER TABLE [dbo].[DoctorCareTeamMembersTBL] ADD  CONSTRAINT [DF_care_team_members_current_member]  DEFAULT ((1)) FOR [CurrentMember]
GO

ALTER TABLE [dbo].[DoctorCareTeamMembersTBL]  WITH CHECK ADD  CONSTRAINT [FK_care_team_members_table_Doctor_table] FOREIGN KEY([MemberID])
REFERENCES [dbo].[DoctorTBL] ([DoctorID])
GO

ALTER TABLE [dbo].[DoctorCareTeamMembersTBL] CHECK CONSTRAINT [FK_care_team_members_table_Doctor_table]
GO

ALTER TABLE [Dbo].[PatientTBL]  WITH CHECK ADD  CONSTRAINT [FK_Patient_table_WarD_table] FOREIGN KEY([PatientWard])
REFERENCES [Dbo].[WarDTBL] ([WarDID])
GO

ALTER TABLE [Dbo].[NurseTBL]  WITH CHECK ADD  CONSTRAINT [FK_Nurse_table_WarD_table] FOREIGN KEY([NurseWarD])
REFERENCES [Dbo].[WarDTBL] ([WarDID])
GO

ALTER TABLE [Dbo].[CareTeamTBL]  WITH CHECK ADD  CONSTRAINT [FK_care_team_Patient_table] FOREIGN KEY([PatientID])
REFERENCES [Dbo].[PatientTBL] ([PatientID])
GO

ALTER TABLE [Dbo].[TheatreBookingTBL]  WITH CHECK ADD  CONSTRAINT [FK_theatre_bookingTBL_care_team] FOREIGN KEY([CareTeamID])
REFERENCES [Dbo].[CareTeamTBL] ([CareTeamID])
GO

ALTER TABLE [Dbo].[TheatreBookingTBL]  WITH CHECK ADD  CONSTRAINT [FK_theatre_bookingTBL_Patient_table] FOREIGN KEY([PatientID])
REFERENCES [Dbo].[PatientTBL] ([PatientID])
GO


ALTER TABLE [dbo].[DoctorCareTeamMembersTBL]  WITH CHECK ADD  CONSTRAINT [FK_DoctorCareTeamMembersTBL_CareTeamTBL] 
FOREIGN KEY([CareTeamID])
REFERENCES [dbo].[CareTeamTBL] ([CareTeamID])
GO

ALTER TABLE [dbo].[DoctorCareTeamMembersTBL] CHECK CONSTRAINT [FK_DoctorCareTeamMembersTBL_CareTeamTBL]
GO

ALTER TABLE [dbo].[NurseCareTeamMembersTBL]  WITH CHECK ADD  CONSTRAINT [FK_NurseCareTeamMembersTBL_CareTeamTBL] 
FOREIGN KEY([CareTeamID])
REFERENCES [dbo].[CareTeamTBL] ([CareTeamID])
GO

ALTER TABLE [dbo].[NurseCareTeamMembersTBL] CHECK CONSTRAINT [FK_NurseCareTeamMembersTBL_CareTeamTBL]
GO


