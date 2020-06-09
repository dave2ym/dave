-- [dormant] = [GSAAHSSRVWIN].[dbo].[ActivityLog]
-- [software] = [GSAAHSSRVWIN].[dbo].[QCheckSoftware]
-- [AdminUsers] = [GSAAHSSRVWIN].[dbo].[AdminUsers]
-- [DaveUsers] = [GSAAHSSRVWIN].[dbo].[QCheckUsers]

select a.[Server], 
    hasMsSql = case when softM.[hasMsSql] = 1 then 'true' else 'false' end,
    hasOracle = case when softO.[hasOracle] = 1 then 'true' else 'false' end,
    b.[User], b.[Domain], b.[LogonTime], b.[CreateDate], coalesce(b.[NoDays],999) as DaysPassed,
    c.[LogonTime] as AdminLogonTime, coalesce(c.[NoDays],999) as DaysPassedAdmin
from
    (
        select distinct [Server] from [GSAAHSSRVWIN].[dbo].[ActivityLog]
    ) a
    left join (
        select distinct [Server], 1 as [hasMsSql]
        from [GSAAHSSRVWIN].[dbo].[QCheckSoftware]
        where [ProductName] like '%Microsoft%SQL%'
    ) softM on a.[Server] = softM.[Server]
    left join (
        select distinct [Server], 1 as [hasOracle]
        from [GSAAHSSRVWIN].[dbo].[QCheckSoftware]
        where [ProductName] like '%Oracle%'
    ) softO on a.[Server] = softO.[Server]
    left join (
        select *, datediff(day, LogonTime, getdate()) as NoDays
        from
        (
            select aa.*, row_number() over(partition by Server order by LogonTime desc) as rank
            from [GSAAHSSRVWIN].[dbo].[ActivityLog] aa
                left join [GSAAHSSRVWIN].[dbo].[AdminUsers] bb on aa.[User] = bb.[Username]
            where bb.[Username] is null
        ) z where rank = 1
    ) b on a.[Server] = b.[Server]
    left join (
        select *, datediff(day, LogonTime, getdate()) as NoDays
        from
        (
            select aaa.*, row_number() over(partition by Server order by LogonTime desc) as rank
            from [GSAAHSSRVWIN].[dbo].[ActivityLog] aaa
                inner join [GSAAHSSRVWIN].[dbo].[AdminUsers] bbb on aaa.[User] = bbb.[Username]
                left join [GSAAHSSRVWIN].[dbo].[QCheckUsers] ccc on aaa.[User] = ccc.[Username]
            where ccc.[Username] is null
        ) z where rank = 1
    ) c on a.[Server] = c.[Server] 