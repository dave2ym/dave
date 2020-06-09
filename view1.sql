-- [ dormant] = [GSAAHSSRVWIN].[dbo].[ActivityLog]
-- [ software] = [GSAAHSSRVWIN].[dbo].[QCheckSoftware]
-- [ AdminUsers] = [GSAAHSSRVWIN].[dbo].[AdminUsers]
-- [ DaveUsers] = [GSAAHSSRVWIN].[dbo].[QCheckUsers]

select a.[Server], 
    hasMsSql = case when soft.[hasMsSql] = 1 then 'true' else 'false' end,
    hasOracle = case when soft.[hasOracle] = 1 then 'true' else 'false' end, b.[User], b.[Domain], b.[LogonTime], b.[CreateDate], coalesce(b.[NoDays],999) as DaysPassed,
    c.[LogonTime] as AdminLogonTime, coalesce(c.[NoDays],999) as DaysPassedAdmin
from
    (
        select distinct [Server] from [dormant]
    ) a
    left join (
        select [Server],
            max(case when [ProductName] like '%Microsoft%SQL%' then 1 else null end) as [hasMsSql],
            max(case when [ProductName] like '%Oracle%' then 1 else null end) as [hasOracle]
        from [software]
        group by [Server]
    ) soft on a.[Server] = soft.[Server]
    left join (
        select *, datediff(day, LogonTime, getdate()) as NoDays
        from
        (
            select aa.*, row_number() over(partition by Server order by LogonTime desc) as rank
            from [dormant] aa
                left join [AdminUsers] bb on aa.[User] = bb.[Username]
            where bb.[Username] is null
        ) z where rank = 1
    ) b on a.[Server] = b.[Server]
    left join (
        select *, datediff(day, LogonTime, getdate()) as NoDays
        from
        (
            select aaa.*, row_number() over(partition by Server order by LogonTime desc) as rank
            from [dormant] aaa
                inner join [AdminUsers] bbb on aaa.[User] = bbb.[Username]
                left join [DaveUsers] ccc on aaa.[User] = ccc.[Username]
            where ccc.[Username] is null
        ) z where rank = 1
    ) c on a.[Server] = c.[Server] 