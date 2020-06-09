-- [dormant] = [GSAAHSSRVWIN].[dbo].[ActivityLog]
-- [software] = [GSAAHSSRVWIN].[dbo].[QCheckSoftware]
-- [AdminUsers] = [GSAAHSSRVWIN].[dbo].[AdminUsers]
-- [DaveUsers] = [GSAAHSSRVWIN].[dbo].[QCheckUsers]


select a.[Server], 
    softM.ProductName    as [MS_ProductName],
    softM.Version        as [MS_Version],
    softM.CreateDate     as [MS_CreateDate],
    softM.LastChangeDate as [MS_LastChangeDate],
    softO.ProductName    as [ORA_ProductName],
    softO.Version        as [ORA_Version],
    softO.CreateDate     as [ORA_CreateDate],
    softO.LastChangeDate as [ORA_LastChangeDate],
    b.[User], b.[Domain], b.[LogonTime], b.[CreateDate], coalesce(b.[NoDays],999) as DaysPassed,
    c.[LogonTime] as AdminLogonTime, coalesce(c.[NoDays],999) as DaysPassedAdmin
from
    (
        select distinct [Server] from [GSAAHSSRVWIN].[dbo].[ActivityLog] (nolock)
    ) a
    left join (
        select [Server], ProductName, Version, CreateDate, LastChangeDate, row_number() over(partition by [Server] order by [LastChangeDate] desc) as rank
        from [GSAAHSSRVWIN].[dbo].[QCheckSoftware] (nolock)
        where [ProductName] like 'Microsoft SQL Server 2___ %'
		
    ) softM on a.[Server] = softM.[Server] and softM.rank = 1
    left join (
        select [Server], ProductName, Version, CreateDate, LastChangeDate, row_number() over(partition by [Server] order by [LastChangeDate] desc) as rank
        from [GSAAHSSRVWIN].[dbo].[QCheckSoftware] (nolock)
        where [ProductName] like '%Oracle%'
    ) softO on a.[Server] = softO.[Server] and softO.rank = 1
    left join (
        select *, datediff(day, LogonTime, getdate()) as NoDays
        from
        (
            select aa.*, row_number() over(partition by Server order by LogonTime desc) as rank
            from [GSAAHSSRVWIN].[dbo].[ActivityLog] (nolock) aa
                left join [GSAAHSSRVWIN].[dbo].[AdminUsers] bb on aa.[User] = bb.[Username]
            where bb.[Username] is null
        ) z where rank = 1
    ) b on a.[Server] = b.[Server]
    left join (
        select *, datediff(day, LogonTime, getdate()) as NoDays
        from
        (
            select aaa.*, row_number() over(partition by Server order by LogonTime desc) as rank
            from [GSAAHSSRVWIN].[dbo].[ActivityLog] (nolock) aaa
                inner join [GSAAHSSRVWIN].[dbo].[AdminUsers] bbb on aaa.[User] = bbb.[Username]
                left join [GSAAHSSRVWIN].[dbo].[QCheckUsers] ccc on aaa.[User] = ccc.[Username]
            where ccc.[Username] is null
        ) z where rank = 1
    ) c on a.[Server] = c.[Server] 
