-- Rainmeter adapter. Only bundled Lua files are loaded, using fixed paths.
local A,N,F,settings,events,seen,statePath,lang
local lastUpdate,lastPhase,eventAnchor,alertUntil=0,0,0,0
local selectedTime,selectedEvents
local function number(name,default,low,high)
    local n=tonumber(SKIN:GetVariable(name,'')) or default
    if n~=n or n==math.huge or n==-math.huge then n=default end
    return math.max(low,math.min(high,n))
end
local function flag(name) return SKIN:GetVariable(name,'0')=='1' end
local function set(meter,option,value)
    value=tostring(value)
    if option=='Text' or option=='ToolTipText' then value=F.rainmeter(value) end
    SKIN:Bang('!SetOption',meter,option,value)
end
local function text(meter,value) set(meter,'Text',value) end
local function displayDate(t) return F.date(t,settings.language,settings.dateFormat,settings.hour24) end
local function shortEvent(e)
    return lang.phases[e.quarter*2+1]..' · '..F.date(e.time,settings.language,'iso',settings.hour24)
end
local function resizeBackground(showAlert)
    local height=settings.compact and 365 or (settings.showEvents and 510 or 445)
    if showAlert then height=settings.compact and 445 or 590 end
    height=height+30
    local scale=settings.scale
    set('MeterBounds','H',height*scale)
    set('MeterBounds','Shape',string.format(
        'Rectangle 0,0,%.3f,%.3f,%.3f | Fill Color 18,20,28,%d | StrokeWidth 0',
        360*scale,height*scale,settings.cornerRadius*scale,settings.backgroundOpacity))
end
function Initialize()
    local root=SKIN:GetVariable('@')
    A=dofile(root..'Scripts\\Astronomy.lua')
    N=dofile(root..'Scripts\\Alerts.lua')
    F=dofile(root..'Scripts\\Format.lua')
    local language=SKIN:GetVariable('Language','en')
    if language~='es' then language='en' end
    local dateFormat=SKIN:GetVariable('DateFormat','long')
    if dateFormat~='iso' and dateFormat~='dmy' then dateFormat='long' end
    settings={language=language,dateFormat=dateFormat,hour24=flag('Hour24'),
        interval=number('UpdateSeconds',30,5,300),compact=flag('Compact'),
        showEvents=flag('ShowEvents'),latitude=number('Latitude',0,-90,90),
        enabled=flag('Notifications'),advance=flag('NotifyAdvance'),atEvent=flag('NotifyAtEvent'),
        allPhases=flag('NotifyAllPhases'),hours=number('AdvanceHours',24,6,48),
        grace=number('CatchUpHours',6,0,48)}
    if settings.hours~=6 and settings.hours~=12 and settings.hours~=24 and settings.hours~=48 then settings.hours=24 end
    lang=F[language]
    local scale=number('Scale',1,.5,2.5)
    settings.scale=scale
    settings.backgroundOpacity=math.floor(number('BackgroundOpacity',200,0,255))
    settings.cornerRadius=number('CornerRadius',20,0,90)
    SKIN:Bang('!SetVariable','Scale',tostring(scale))
    SKIN:Bang('!SetVariable','Opacity',tostring(math.floor(number('Opacity',240,0,255))))
    local positions=settings.compact and {196,233,272,298,328,0,0,370} or {264,301,347,373,404,450,475,510}
    local meters={'MeterPhase','MeterIllumination','MeterNextLabel','MeterNextDate','MeterCountdown','MeterPrevious','MeterUpcoming','MeterAlert'}
    for i,m in ipairs(meters) do set(m,'Y',(positions[i]+30)*scale) end
    set('MeterMoon','Y',84*scale)
    set('MeterDivider','Shape','Line '..110*scale..','..359*scale..','..250*scale..','..359*scale..' | StrokeWidth 1 | Stroke Color 115,131,160,55')
    if settings.compact then
        set('MeterMoon','X',116*scale); set('MeterMoon','W',128*scale); set('MeterMoon','H',128*scale)
        set('MeterDivider','Shape','Line '..110*scale..','..287*scale..','..250*scale..','..287*scale..' | StrokeWidth 1 | Stroke Color 115,131,160,55')
    end
    if settings.compact or not settings.showEvents then
        SKIN:Bang('!HideMeter','MeterPrevious'); SKIN:Bang('!HideMeter','MeterUpcoming')
    end
    set('MeterMoon','ImageRotate',settings.latitude<0 and 180 or 0)
    text('MeterTitle',lang.title); text('MeterNextLabel',lang.nextFull)
    text('MeterToday',lang.today)
    set('MeterBack','ToolTipText',lang.previousDay)
    set('MeterForward','ToolTipText',lang.nextDay)
    set('MeterToday','ToolTipText',lang.returnToday)
    statePath=root..'NotificationState.dat'
    seen=settings.enabled and N.load(statePath) or {}
    lastUpdate=0; lastPhase=0; eventAnchor=0; alertUntil=0
    selectedTime=nil; selectedEvents=nil
    resizeBackground(false)
end
local function browse(direction)
    local candidate=F.shiftDay(selectedTime or os.time(),direction)
    if not candidate or not A.supported(candidate) then return end
    selectedTime=candidate
    selectedEvents=A.events(candidate)
    lastUpdate=0; lastPhase=0
    Update()
end
function PreviousDay() browse(-1) end
function NextDay() browse(1) end
function Today()
    selectedTime=nil; selectedEvents=nil
    lastUpdate=0; lastPhase=0
    Update()
end
function Dismiss()
    alertUntil=0
    resizeBackground(false)
    SKIN:Bang('!HideMeter','MeterAlert'); SKIN:Bang('!UpdateMeter','*'); SKIN:Bang('!Redraw')
end
function Update()
    local now=os.time()
    if now>=lastUpdate and now-lastUpdate<settings.interval then return 0 end
    lastUpdate=now
    local viewTime=selectedTime or now
    text('MeterBrowseDate',F.dayLabel(viewTime))
    text('MeterTitle',lang.title..(selectedTime and ' · '..lang.preview or ''))
    text('MeterNextLabel',selectedTime and lang.previewFull or lang.nextFull)
    set('MeterBrowseDate','ToolTipText',selectedTime and lang.previewRemaining or lang.localTime)
    if not A.supported(viewTime) then
        text('MeterPhase','Supported dates: 2000–2050')
        for _,meter in ipairs({'MeterIllumination','MeterNextDate','MeterCountdown','MeterPrevious','MeterUpcoming'}) do text(meter,'') end
        SKIN:Bang('!HideMeter','MeterMoon'); SKIN:Bang('!HideMeter','MeterAlert')
        SKIN:Bang('!UpdateMeter','*'); SKIN:Bang('!Redraw'); return 0
    end
    SKIN:Bang('!ShowMeter','MeterMoon')
    if math.abs(now-eventAnchor)>86400 then events=A.events(now); eventAnchor=now end
    local viewEvents=selectedTime and selectedEvents or events
    local _,full=A.surrounding(viewEvents,viewTime,2)
    text('MeterNextDate',displayDate(full.time))
    local days,hours=A.countdown(full.time,viewTime)
    text('MeterCountdown',days..'d  '..hours..'h')
    set('MeterCountdown','ToolTipText',(selectedTime and lang.previewRemaining or lang.remaining)..' · '..displayDate(full.time))
    if now<lastPhase or now-lastPhase>=300 then
        local phase=A.phase(viewTime)
        text('MeterPhase',lang.phases[phase.index+1])
        text('MeterIllumination',lang.illumination..'  '..string.format('%.0f',phase.fraction*100)..'%')
        set('MeterMoon','ImageName',SKIN:GetVariable('@')..string.format('Images\\moon-%03d.png',phase.frame))
        lastPhase=now
    end
    if settings.showEvents and not settings.compact then
        local previous,upcoming=A.surrounding(viewEvents,viewTime)
        text('MeterPrevious',lang.previous..': '..shortEvent(previous))
        text('MeterUpcoming',lang.upcoming..': '..shortEvent(upcoming))
    end
    -- Preview dates must never trigger or consume a real notification.
    local due=A.supported(now) and N.due(events,now,settings,seen) or {}
    local messages={}
    for _,notice in ipairs(due) do
        -- Fail closed: no alert if persistence is unavailable. Never load code from state.
        if N.commit(statePath,notice.key,seen) then
            messages[#messages+1]=(notice.hours==0 and lang.occurred or lang.advance)..': '..shortEvent(notice.event)
        else
            SKIN:Bang('!Log','Lunar: cannot save notification state; alert suppressed.','Warning')
        end
    end
    if #messages>0 then
        text('MeterAlert',table.concat(messages,'\n'))
        set('MeterAlert','ToolTipText',table.concat(messages,'\n'))
        SKIN:Bang('!ShowMeter','MeterAlert'); alertUntil=now+600
    elseif alertUntil>0 and now>=alertUntil then Dismiss() end
    resizeBackground(alertUntil>now)
    SKIN:Bang('!UpdateMeter','*'); SKIN:Bang('!Redraw')
    return 1
end
