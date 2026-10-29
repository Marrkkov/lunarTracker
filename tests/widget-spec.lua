-- Exercise actual navigation callbacks and verify preview cannot advance alerts.
-- The mock replaces only Rainmeter's host API and notification IO, not the widget.
local original={SKIN=SKIN,time=os.time,dofile=dofile,Initialize=Initialize,Update=Update,
    Dismiss=Dismiss,PreviousDay=PreviousDay,NextDay=NextDay,Today=Today}
local A=dofile('skin/Lunar/@Resources/Scripts/Astronomy.lua')
local F=dofile('skin/Lunar/@Resources/Scripts/Format.lua')
local fixedNow=A.utc(2026,10,29,16)
local dueTime,dueEvents
local vars={['@']='skin/Lunar/@Resources/',Hour24='1',ShowEvents='1',Notifications='1'}
local options={}
SKIN={}
function SKIN:GetVariable(name,default) return vars[name] or default end
function SKIN:Bang(command,meter,option,value)
    if command=='!SetOption' then
        options[meter]=options[meter] or {}
        options[meter][option]=value
    end
end
os.time=function(date) if date then return original.time(date) end return fixedNow end
dofile=function(path)
    if path:match('Alerts%.lua$') then
        return {load=function() return {} end,commit=function() error('preview wrote a reminder') end,
            due=function(events,now) dueTime=now; dueEvents=events; return {} end}
    end
    return original.dofile(path)
end
original.dofile('skin/Lunar/@Resources/Scripts/Widget.lua')
Initialize(); Update()
local liveImage=options.MeterMoon.ImageName
assert(options.MeterBrowseDate.Text=='2026-10-29','live local date')
NextDay()
assert(options.MeterBrowseDate.Text=='2026-10-30','forward arrow advances one date')
assert(options.MeterTitle.Text:find('PREVIEW'),'preview visibly marked')
assert(options.MeterNextLabel.Text==F.en.previewFull,'preview event label')
local preview=F.shiftDay(fixedNow,1)
assert(options.MeterMoon.ImageName:find(string.format('moon-%03d.png',A.phase(preview).frame),1,true),'preview phase image')
local _,previewFull=A.surrounding(A.events(preview),preview,2)
local previewDays,previewHours=A.countdown(previewFull.time,preview)
assert(options.MeterCountdown.Text==previewDays..'d  '..previewHours..'h','preview countdown uses selected noon')
assert(dueTime==fixedNow,'notification clock remains real')
local _,realFull=A.surrounding(dueEvents,fixedNow,2)
local _,expectedFull=A.surrounding(A.events(fixedNow),fixedNow,2)
assert(realFull.id==expectedFull.id,'notification events remain current')
for _=1,14 do NextDay() end
assert(options.MeterMoon.ImageName~=liveImage,'phase image changes while browsing')
PreviousDay()
assert(options.MeterBrowseDate.Text=='2026-11-12','back arrow moves one date')
Today()
assert(options.MeterBrowseDate.Text=='2026-10-29','Today restores real date')
assert(options.MeterMoon.ImageName==liveImage,'Today restores real phase immediately')
assert(options.MeterTitle.Text==F.en.title,'Today removes preview label')
-- Resume across local midnight: real view follows the live clock again.
fixedNow=A.utc(2026,10,30,16)
Update()
assert(options.MeterBrowseDate.Text=='2026-10-30','live date follows the clock')
SKIN=original.SKIN; os.time=original.time; dofile=original.dofile
Initialize=original.Initialize; Update=original.Update; Dismiss=original.Dismiss
PreviousDay=original.PreviousDay; NextDay=original.NextDay; Today=original.Today
print('14 widget navigation checks passed; reminder clock remains real during preview.')
