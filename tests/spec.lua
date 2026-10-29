local root='skin/Lunar/@Resources/Scripts/'
local A=dofile(root..'Astronomy.lua')
local N=dofile(root..'Alerts.lua')
local F=dofile(root..'Format.lua')
local count=0
local function check(condition,message)
    count=count+1
    assert(condition,message)
end
check(F.rainmeter('Iluminación · PRÓXIMA')=='Iluminaci[\\243]n [\\183] PR[\\211]XIMA','Unicode boundary encoding')
local maxError=0
for _,f in ipairs(fixtures) do
    local events=A.events(f[1])
    local best=math.huge
    for _,e in ipairs(events) do
        if e.quarter==f[2] then best=math.min(best,math.abs(e.time-f[1])) end
    end
    maxError=math.max(maxError,best)
    check(best<=120,'USNO event tolerance exceeded: '..f[1]..' error '..best)
    local phase=A.phase(f[1])
    local expected=({0,.5,1,.5})[f[2]+1]
    check(math.abs(phase.fraction-expected)<.02,'principal phase illumination')
    check(phase.index==f[2]*2,'phase name at principal phase')
end
for _,fixture in ipairs(illuminationFixtures or {}) do
    check(math.abs(A.phase(fixture[1]).fraction-fixture[2])<=.02,'USNO intermediate illumination')
end
-- Gregorian boundaries, epoch, leap years, and full-moon selection transitions.
check(A.utc(2000,1,1)==946684800,'UTC epoch')
check(A.utc(2024,3,1)-A.utc(2024,2,28)==172800,'leap day')
check(A.utc(2025,1,1)-A.utc(2024,12,31)==86400,'year rollover')
check(A.utc(2026,3,1)-A.utc(2026,2,28)==86400,'non-leap month')
check(not A.supported(A.utc(1999,12,31)),'lower support limit')
check(not A.supported(A.utc(2051,1,1)),'upper support limit')
local full=A.event(332,2)
local events=A.events(full)
local _,before=A.surrounding(events,full-1,2)
local _,after=A.surrounding(events,full+1,2)
check(before.time==full and after.time>full+25*86400,'next event transition')
local d,h=A.countdown(full,full-86400-3600)
check(d==1 and h==1,'days and hours')
d,h=A.countdown(full,full-3599)
check(d==0 and h==0,'under an hour floors to zero')
d,h=A.countdown(full,full+1)
check(d==0 and h==0,'past countdown clamp')
-- Real timestamp-to-local conversion through Fengari's JS Date, not a fake offset.
check(F.date(A.utc(2026,11,24,14,53),'en','iso',true)=='2026-11-24  ·  11:53 (local time)','Chile summer full moon')
check(F.date(A.utc(2026,6,29,23,56),'en','iso',true)=='2026-06-29  ·  19:56 (local time)','Chile winter full moon')
check(F.date(A.utc(2026,12,24,1,28),'en','iso',true)=='2026-12-23  ·  22:28 (local time)','full moon previous local date')
check(F.date(A.utc(2026,4,5,2,59),'en','iso',true)=='2026-04-04  ·  23:59 (local time)','Chile DST fall before')
check(F.date(A.utc(2026,4,5,3,0),'en','iso',true)=='2026-04-04  ·  23:00 (local time)','Chile DST fall repeat')
check(F.date(A.utc(2026,9,6,3,59),'en','iso',true)=='2026-09-05  ·  23:59 (local time)','Chile DST spring before')
check(F.date(A.utc(2026,9,6,4,0),'en','iso',true)=='2026-09-06  ·  01:00 (local time)','Chile DST spring skip')
check(F.date(A.utc(2026,11,24,14,53),'es','dmy',false)=='24/11/2026  ·  11:53 AM (hora local)','Spanish and 12-hour display')
check(F.date(A.utc(2026,11,24,14,53),'es','long',true):find('noviembre')~=nil,'Spanish month')
-- Notification policy uses UTC, independent of local DST clock repetition.
-- Calendar arrows keep LOCAL noon across month/year/leap and DST boundaries.
for _,case in ipairs({
    {2024,2,28,1,'2024-02-29'}, {2024,2,29,1,'2024-03-01'},
    {2025,1,1,-1,'2024-12-31'}, {2026,12,31,1,'2027-01-01'},
    {2026,3,1,-1,'2026-02-28'}
}) do
    local start=os.time({year=case[1],month=case[2],day=case[3],hour=12})
    local shifted=F.shiftDay(start,case[4])
    check(F.dayLabel(shifted)==case[5],'navigation calendar rollover')
    check(os.date('*t',shifted).hour==12,'navigation uses local noon')
end
local spring=os.time({year=2026,month=9,day=5,hour=12})
local fall=os.time({year=2026,month=4,day=4,hour=12})
check(F.shiftDay(spring,1)-spring==23*3600,'navigation across 23-hour DST day')
check(F.shiftDay(fall,1)-fall==25*3600,'navigation across 25-hour DST day')
check(F.shiftDay(F.shiftDay(spring,1),-1)==spring,'navigation DST round trip')
local e={id='1:2',quarter=2,time=1000000}
local settings={enabled=false,allPhases=false,advance=true,atEvent=true,hours=24,grace=6}
check(#N.due({e},e.time-86400,settings,{})==0,'disabled by default')
settings.enabled=true
check(#N.due({e},e.time-86401,settings,{})==0,'no early alert')
local due=N.due({e},e.time-86400,settings,{})
check(#due==1 and due[1].key=='1:2:24','advance threshold')
check(#N.due({e},e.time-86400,settings,{['1:2:24']=true})==0,'dedup persisted key')
check(#N.due({e},e.time-86400+3600,settings,{})==1,'catch up after sleep')
check(#N.due({e},e.time-86400+7*3600,settings,{})==0,'stale reminder expires')
check(#N.due({e},e.time,settings,{})==1,'event occurrence')
check(#N.due({e},e.time+6*3600+1,settings,{})==0,'stale occurrence expires')
settings.grace=48
check(#N.due({e},e.time+1,settings,{})==1,'expired advance suppressed after event')
for _,hours in ipairs({6,12,24,48}) do
    settings.hours=hours
    check(#N.due({e},e.time-hours*3600,settings,{})==1,'supported advance hours')
end
local new={id='1:0',quarter=0,time=e.time}
check(#N.due({new},e.time,settings,{})==0,'optional phases off')
settings.allPhases=true
check(#N.due({new},e.time,settings,{})==1,'optional phases on')
-- Filesystem persistence tests run in Rainmeter's native Lua, too. Fengari's
-- limited io implementation does not provide write, so policy tests above remain pure.
if io.open then
    local path='tests/notification-test.dat'
    local f=io.open(path,'w')
    if f and f.write then
        f:close()
        local seen={}
        check(N.commit(path,'1:2:24',seen),'journal commit')
        check(not N.commit(path,'1:2:24',seen),'same session duplicate')
        check(N.load(path)['1:2:24'],'restart deduplication')
        check(not N.commit('missing-directory/state.dat','1:2:0',{}),'unwritable fails closed')
        os.remove(path)
    elseif f then f:close() end
end
print(string.format('%d checks passed; maximum USNO event error %.1f seconds',count,maxError))
