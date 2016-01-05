#!/usr/bin/env julia

using Luxor, Colors, ColorSchemes

function textright(t, x=0, y=0)
    textwidth = textextents(t)[5]
    text(t, x - textwidth, y)
end

function draw_grid(w, h, m, n)
    gsave()
    setline(0.3)
    #start
    x = -(width/2) + m
    y = -(height/2) + m
    gap = (w - m - m)/n
    for (i, month) in enumerate(everymonth)
        # text labels: year and month
        if i % 12 == 1
            gsave()
            translate(x, y)
            rotate(-pi/2)
            # now we're sideways, up is the left edge
            fontsize(11)
            sethue("gray10")
            text(string(Dates.year(month)), 10, 3)
            textright(string(Dates.year(month)), -height + margin + margin , 3)
            grestore()
        end

        if i % 3 == 1
            gsave()
            translate(x, y)
            rotate(-pi/2)
            sethue("gray10")
            fontsize(6)
            text(string(Dates.monthabbr(month)), 0, 2)
            grestore()
        end

        # vertical gridlines
        i % 12 == 1 ? sethue("gray85") : sethue("gray95")
        move(x, y)
        rline(0, height - m - m)
        stroke()
        x += gap
    end
    grestore()
end

function draw_datarow(data, w, h, margin, gap, title, vscalefactor, col)
    # don't rescale, cos text sizing gets too difficult
    # origin is positioned correctly at left edge / middle of box w by h
    gsave()
    # thick white line at top
    setline(15)
    setopacity(0.8)
    sethue("ivory")
    move(-margin, -h/2 + 15)
    line(w - margin, -h/2 + 15)
    stroke()

    # text at top
    setopacity(1)
    fontsize(14)
    sethue("black")
    text(title, 5, -h/2 + 18)
    grestore()

    n = length(data)
    gap = (w - margin - margin)/n

    highestvalue = roundaway(maximum(data))
    lowestvalue =  roundaway(minimum(data))

    # horizontal grid lines and labels
    gsave()
    fontsize(5)
    move(0, 0)
    for ymarker in highestvalue:-1:lowestvalue
        sethue("gray90")
        setline(.3)
        move(0, -ymarker * vscalefactor)
        line(w - margin - margin, -ymarker * vscalefactor)
        stroke()
        sethue("black")
        textright(string(ymarker, " °C"), -5, (-ymarker * vscalefactor) + 2)
        textright(string(ymarker, " °C"),  w - margin - margin + 15, (-ymarker * vscalefactor) + 2)
    end
    grestore()

    # plot data points
    sethue(col)
    p = Point[]
    n = length(data)
    gap = (w - margin - margin)/n
    x = 0
    y = 0
    setline(1.5)
    setopacity(0.95)
    for (i, month) in enumerate(everymonth)
        push!(p, Point(x, data[i] * -vscalefactor))
        x += gap
    end
    poly(p, :stroke)

    # dots
    x = 0
    y = 0

    for (i, month) in enumerate(everymonth)
        circle(x, data[i] * -vscalefactor, 1, :fill)
        x += gap
    end

end

function roundaway(x)
    x < 0 ? floor(x) : ceil(x)
end

data = readcsv(expanduser("~/projects/programming/climate/rss_monthly_msu_amsu_channel_ttt_anomalies_land_and_ocean_v03_3-1.csv"))

titles = UTF8String[
    "Global (Latitude 82.5S to 82.5N)",
    "Tropics (Latitude 20.0S to 20.0N)",
    "Northern extratropical (Latitude 20.0N to 82.5N)",
    "Southern extratropical (Latitude 82.5S to 20.0S",
    "Northern Polar (Latitude 60.0N to 82.5N)",
    "Southern Polar (Latitude 82.5S to 60S)",
    "Continental USA",
    "Northern Hemisphere (Latitude 0.0N to 82.5N)",
    "Southern Hemisphere (Latitude 82.5S to 0S)"]

width, height = 1800, 1200
margin = 100

const everymonth = Dates.Date(1979,1,1):Dates.Month(1):Dates.Date(2015,11,30)

Drawing(width, height, "/tmp/rss.pdf")
origin()
background("ivory")
fontface("TriplexSerif-BoldOldstyle")
darkrainbow = loadcolorscheme("darkrainbow")

draw_grid(width, height, margin, length(everymonth))

numberofgraphs = last(size(data))
vgap = 5
graphheight = ((height - margin - margin) - (vgap * numberofgraphs * 2)) / numberofgraphs

# highest values needed to calculate overall size of every graph

highestvalue = roundaway(maximum(vec(data)))
lowestvalue =  roundaway(minimum(vec(data)))
vscalefactor = (graphheight/2)/(highestvalue - lowestvalue) * 1.2

for g in 1:numberofgraphs
    datarow = data[:, g]
    gsave()
        # move to next location
        translate(-(width/2) + margin, (-height/2) + (g * graphheight) + margin)
        draw_datarow(datarow, width, graphheight, margin, vgap, titles[g], vscalefactor, colorscheme(darkrainbow, g/numberofgraphs))
    grestore()
end

#header

sethue("black")
fontsize(30)
textcentred("RSS monthly (Advanced) Microwave Sounding Unit: Temperature Tropical Troposphere (multichannel) anomalies, land/ocean v03.3", 0, -(height/2) + margin/2)

# footer text
fontsize(8)
text("Source: http://data.remss.com/MSU/monthly_time_series/RSS_Monthly_MSU_AMSU_Channel_TTT_Anomalies_Land_and_Ocean_v03_3.txt", -width/2 + margin, height/2 - margin + 60)

text("°C anomaly relative to reference period 1978-1998", -width/2 + margin, height/2 - margin + 70)

# add events

fontsize(10)

events = [
    ("El Niño", Date(1982, 11)),
    ("El Niño", Date(1997, 11)),
    ("El Niño", Date(2009, 11)),
    ("El Chichón eruption", Date(1982, 3)),
    ("Mount Pinatubo eruption", Date(1991, 6))
    ]

xgap = (width - margin - margin)/length(everymonth)
sw = 0 # switch to toggle placement of text
for event in events
    sethue("purple")
    setline(1)
    eventpos = find(ev -> (ev == event[2]), everymonth)
    if length(eventpos) == 1
        xloc = (-(width/2) + margin) + (first(eventpos) * xgap)
        yloc = height/2 - margin - 40
        circle(xloc, yloc, 3, :fill)
        text(event[1], xloc - 3, yloc + (sw % 2 == 0 ? -10 : 15))
        sw += 1
    end
end

finish()
preview()
