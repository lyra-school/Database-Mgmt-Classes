alter proc Q1E
as
/* 
keep clustered index on CharityID as it's used in an equality operation and otherwise
no other column is being searched
very high fill factor and no pad index as the IDs are added in order (clustered index) and the table is
not often updated
*/
ALTER TABLE [dbo].[CharityTBL] ADD  CONSTRAINT [PK_CharityTBL] PRIMARY KEY CLUSTERED 
(
	[CharityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
/*
CharityID column is the only one being searched, however, since the table is constantly being added to,
it's better to keep a clustered index on the identity column (ContributionID) to speed up inserts
this excludes CharityID column from having a clustered index (instead getting a non-clustered index)
and the DateOfContribution column from having an index at all, as a non-clustered index is ineffective
on sorted columns that require a clustered index

since the table is often inserted into, fill factor is 65% and pad index is ON to leave some space in
both the branches and index pages to avoid external fragmentation due to the possibility of inserted values
being out of order
*/
CREATE NONCLUSTERED INDEX [NC_CharityID_ContributionsTBL] ON [dbo].[ContributionsTBL]
(
	[CharityID] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 65, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
/* below index is the aforementioned ContributionID clustered index
had to make it anew because SQL Server Management Studio
is not letting me change it from non-clustered to clustered
*/
CREATE UNIQUE CLUSTERED INDEX [Clustered_PK_ContributionsTBL] ON [dbo].[ContributionsTBL]
(
	[ContributionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
/*
FunderID column is the only one being searched and, to speed up inserts, it should stay as a clustered index
since it's also the identity column of the table

very high fill factor and no pad index as, due to the property of it being an ID column, the index
will always be in order
*/
ALTER TABLE [dbo].[FunderTBL] ADD  CONSTRAINT [PK_FunderTBL] PRIMARY KEY CLUSTERED 
(
	[FunderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]