-- Offline lunar events: Meeus, Astronomical Algorithms, 2nd ed., ch. 49.
-- Formula organization adapted from Sonia Keys' MIT meeus/moonphase; see NOTICE.
-- All public timestamps are Unix seconds, approximately UTC (not local time).
local A = {}
local pi, sin, cos, floor = math.pi, math.sin, math.cos, math.floor
local function s(d) return sin(d*pi/180) end
local function c(d) return cos(d*pi/180) end
local function jd(t) return t/86400 + 2440587.5 end
A.julian = jd
function A.unix(j) return (j-2440587.5)*86400 end

-- Gregorian civil date to UTC; never routes UTC through os.time's local rules.
function A.utc(y,m,d,h,n,sec)
    if m <= 2 then y=y-1; m=m+12 end
    local b=2-floor(y/100)+floor(y/400)
    return A.unix(floor(365.25*(y+4716))+floor(30.6001*(m+1))+d+b-1524.5)
        +(h or 0)*3600+(n or 0)*60+(sec or 0)
end

-- Espenak/Meeus Delta T polynomial. UT1 is treated as UTC at widget precision.
-- Future Delta T is a forecast, not a measurement. Supported calendar: 2000-2050.
function A.deltaT(y)
    local t=y-2000
    if y < 2005 then
        return 63.86+.3345*t-.060374*t^2+.0017275*t^3+.000651814*t^4+.00002373599*t^5
    end
    return 62.92+.32217*t+.005589*t^2
end
function A.supported(t) return t>=A.utc(2000,1,1) and t<A.utc(2051,1,1) end

local nc={-.40720,.17241,.01608,.01039,.00739,-.00514,.00208,-.00111,-.00057,.00056,-.00042,.00042,.00038,-.00024,-.00017,-.00007,.00004,.00004,.00003,.00003,-.00003,.00003,-.00002,-.00002,.00002}
local fc={-.40614,.17302,.01614,.01043,.00734,-.00515,.00209,-.00111,-.00057,.00056,-.00042,.00042,.00038,-.00024,-.00017,-.00007,.00004,.00004,.00003,.00003,-.00003,.00003,-.00002,-.00002,.00002}
local planets={
    {.000325,299.77,.107408}, {.000165,251.88,.016321},
    {.000164,251.83,26.651886}, {.000126,349.42,36.412478},
    {.000110,84.66,18.206239}, {.000062,141.74,53.303771},
    {.000060,207.14,2.453732}, {.000056,154.84,7.306860},
    {.000047,34.52,27.261239}, {.000042,207.19,.121824},
    {.000040,291.34,1.844379}, {.000037,161.72,24.198154},
    {.000035,239.56,25.513099}, {.000023,331.55,3.592518}
}
-- Integer lunation 0 begins January 2000. q=0,1,2,3 for the four phases.
function A.event(lunation,q)
    assert(q==0 or q==1 or q==2 or q==3, 'invalid quarter')
    local k=lunation+q/4
    local T=k/1236.85
    local E=1-.002516*T-.0000074*T*T
    local M=2.5534+29.10535670*k-.0000014*T^2-.00000011*T^3
    local P=201.5643+385.81693528*k+.0107582*T^2+.00001238*T^3-.000000058*T^4
    local F=160.7108+390.67050284*k-.0016118*T^2-.00000227*T^3+.000000011*T^4
    local O=124.7746-1.56375588*k+.0020672*T^2+.00000215*T^3
    local J=2451550.09766+29.530588861*k+.00015437*T^2-.000000150*T^3+.00000000073*T^4
    local correction=0
    if q==0 or q==2 then
        local terms={s(P),E*s(M),s(2*P),s(2*F),E*s(P-M),E*s(P+M),E*E*s(2*M),s(P-2*F),s(P+2*F),E*s(2*P+M),s(3*P),E*s(M+2*F),E*s(M-2*F),E*s(2*P-M),s(O),s(P+2*M),s(2*P-2*F),s(3*M),s(P+M-2*F),s(2*P+2*F),s(P+M+2*F),s(P-M+2*F),s(P-M-2*F),s(3*P+M),s(4*P)}
        local coeff=q==0 and nc or fc
        for i=1,#terms do correction=correction+coeff[i]*terms[i] end
    else
        correction=-.62801*s(P)+.17172*E*s(M)-.01183*E*s(P+M)+.00862*s(2*P)+.00804*s(2*F)+.00454*E*s(P-M)+.00204*E^2*s(2*M)-.00180*s(P-2*F)-.00070*s(P+2*F)-.00040*s(3*P)-.00034*E*s(2*P-M)+.00032*E*s(M+2*F)+.00032*E*s(M-2*F)-.00028*E^2*s(P+2*M)+.00027*E*s(2*P+M)-.00017*s(O)-.00005*s(P-M-2*F)+.00004*s(2*P+2*F)-.00004*s(P+M+2*F)+.00004*s(P-2*M)+.00003*s(P+M-2*F)+.00003*s(3*M)+.00002*s(2*P-2*F)+.00002*s(P-M+2*F)-.00002*s(3*P+M)
        local w=.00306-.00038*E*c(M)+.00026*c(P)-.00002*c(P-M)+.00002*c(P+M)+.00002*c(2*F)
        correction=correction+(q==1 and w or -w)
    end
    for i,p in ipairs(planets) do
        local angle=p[2]+p[3]*k
        if i==1 then angle=angle-.009173*T*T end
        correction=correction+p[1]*s(angle)
    end
    local year=2000+(J-2451545)/365.2425
    return A.unix(J+correction)-A.deltaT(year)
end

function A.events(t)
    local base=floor((jd(t)-2451550.09766)/29.530588861)
    local out={}
    -- Includes prior events for sleep/restart notification catch-up and next month.
    for k=base-2,base+2 do
        for q=0,3 do out[#out+1]={time=A.event(k,q),quarter=q,id=k..':'..q} end
    end
    table.sort(out,function(a,b) return a.time<b.time end)
    return out
end
function A.surrounding(events,t,quarter)
    local previous,nextEvent
    for _,e in ipairs(events) do
        if quarter==nil or e.quarter==quarter then
            if e.time<=t then previous=e elseif not nextEvent then nextEvent=e end
        end
    end
    return previous,nextEvent
end

-- Meeus ch.48 (48.4), truncated geocentric phase angle, degrees.
-- Display approximation; event times above are calculated independently.
function A.phase(t)
    local T=(jd(t)-2451545)/36525
    local D=297.8501921+445267.1114034*T-.0018819*T^2+T^3/545868-T^4/113065000
    local M=357.5291092+35999.0502909*T-.0001536*T^2+T^3/24490000
    local P=134.9633964+477198.8675055*T+.0087414*T^2+T^3/69699-T^4/14712000
    local angle=180-D-6.289*s(P)+2.100*s(M)-1.274*s(2*D-P)-.658*s(2*D)-.214*s(2*P)-.110*s(D)
    local phase=((180-angle)%360)/360
    return {fraction=(1+c(angle))/2,cycle=phase,index=floor(phase*8+.5)%8,
        frame=floor(phase*120+.5)%120}
end
function A.countdown(eventTime,now)
    local hours=floor(math.max(0,eventTime-now)/3600)
    return floor(hours/24),hours%24
end
return A
