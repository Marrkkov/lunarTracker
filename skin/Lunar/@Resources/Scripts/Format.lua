local F={}
-- Rainmeter 4.5's Lua bang boundary uses the Windows ANSI code page. Preserve
-- UTF-8 source strings on every locale using Rainmeter's Unicode character vars.
function F.rainmeter(value)
    return (value:gsub('[\194-\244][\128-\191]+',function(sequence)
        local first=sequence:byte(1)
        local code=first % (2^(7-#sequence))
        for i=2,#sequence do code=code*64+(sequence:byte(i)%64) end
        return '[\\'..string.format('%d',code)..']'
    end))
end
F.en={title='MOON PHASE',illumination='Illumination',nextFull='NEXT FULL MOON',remaining='Until full moon',previous='Previous',upcoming='Next',advance='Upcoming lunar event',occurred='Lunar event',localTime='local time',
    phases={'New Moon','Waxing Crescent','First Quarter','Waxing Gibbous','Full Moon','Waning Gibbous','Last Quarter','Waning Crescent'},
    months={'January','February','March','April','May','June','July','August','September','October','November','December'}}
F.es={title='FASE LUNAR',illumination='Iluminación',nextFull='PRÓXIMA LUNA LLENA',remaining='Hasta la luna llena',previous='Anterior',upcoming='Siguiente',advance='Próximo evento lunar',occurred='Evento lunar',localTime='hora local',
    phases={'Luna nueva','Luna creciente','Cuarto creciente','Gibosa creciente','Luna llena','Gibosa menguante','Cuarto menguante','Luna menguante'},
    months={'enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'}}
F.en.today='Today'
F.en.preview='PREVIEW'
F.en.previousDay='Previous day'
F.en.nextDay='Next day'
F.en.returnToday='Return to today and live updates'
F.en.previewFull='FULL MOON AFTER SELECTED DATE'
F.en.previewRemaining='From selected date at 12:00 local time'
F.es.today='Hoy'
F.es.preview='VISTA PREVIA'
F.es.previousDay='Día anterior'
F.es.nextDay='Día siguiente'
F.es.returnToday='Volver a hoy y a la hora actual'
F.es.previewFull='LUNA LLENA TRAS LA FECHA ELEGIDA'
F.es.previewRemaining='Desde la fecha elegida a las 12:00 hora local'
function F.dayLabel(t)
    local d=os.date('*t',math.floor(t))
    return string.format('%04d-%02d-%02d',d.year,d.month,d.day)
end
-- Move by a LOCAL calendar day, never by an assumed 86400-second interval.
-- Noon avoids the repeated/skipped midnight hours in Santiago's DST changes.
function F.shiftDay(t,direction)
    local d=os.date('*t',math.floor(t))
    return os.time({year=d.year,month=d.month,day=d.day+direction,hour=12,min=0,sec=0})
end
-- dateProvider is injectable for tests; production is the Windows C localtime.
function F.date(t,language,dateFormat,hour24,dateProvider)
    local provider=dateProvider or os.date
    local d=provider('*t',math.floor(t+.5))
    local l=F[language] or F.en
    local date
    if dateFormat=='iso' then date=string.format('%04d-%02d-%02d',d.year,d.month,d.day)
    elseif dateFormat=='dmy' then date=string.format('%02d/%02d/%04d',d.day,d.month,d.year)
    elseif language=='es' then date=d.day..' de '..l.months[d.month]..' de '..d.year
    else date=l.months[d.month]..' '..d.day..', '..d.year end
    local clock
    if hour24 then clock=string.format('%02d:%02d',d.hour,d.min)
    else clock=string.format('%d:%02d %s',(d.hour+11)%12+1,d.min,d.hour<12 and 'AM' or 'PM') end
    -- No locale-dependent %z/%Z support required in Windows Lua 5.1.
    return date..'  ·  '..clock..' ('..l.localTime..')'
end
return F
