<?xml version="1.0" encoding="UTF-8"?>
<!-- This XSLT converts a structured XML tours dataset into an interactive HTML
        map visualization showing tour start and end locations. It creates a full
        HTML page that includes the Leaflet map library, builds a client-side
        JavaScript array of tour objects (via XSLT iteration), and places markers
        and lines on the map to represent each tour.

        The template expects the dataset to provide coordinates under
        `starting_point/coordinates` and `final_destination/coordinates` for each
        `tour`. Missing or invalid coordinates are skipped by client-side logic.

        Example command to run the transformation (from project root):

        java -cp libs/saxon-he-12.4.jar:libs/xmlresolver-5.1.1.jar net.sf.saxon.Transform \
        -s:dataset/merged_datasets.xml \
        -xsl:xsl/04_tours_map_to_html.xsl \
        -o:outputs/html/04_tours_map.html
-->

<!-- Scenario 4: Map of tour locations (start/end) -->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cto="http://city-tour-operator.org/cto"
    exclude-result-prefixes="xs cto"> <!-- Using a namespace cto:-->
    <xsl:output method="html" />
    <xsl:strip-space elements="*" />

    <xsl:template match="/cto:data">
        <html>
            <head>
                <meta charset="utf-8" />
                <title>Tours Map</title>
                <meta name="author"
                    content="Audrey Costes, Halima Lemmouchi, Lina Marcela Diaz Bejarano, Vincent Boettcher" />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <!-- Leaflet CSS for map -->
                <link rel="stylesheet" href="../css/styles.css" />
                <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
                    integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="" />
                <style>
                    /* Map container styling */
                    #map { height: 80vh; margin: 1.5rem; border-radius: 0.4rem; box-shadow: 0 0.4rem 1rem
        rgba(0,0,0,0.18);}
                </style>
            </head>
            <body>
                <header class="page-header">
                    <h1>Tours Map</h1>
                </header>
                <!-- Map container -->
                <div id="map"></div>
                <!-- Leaflet JS for map functionality -->
                <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
                    integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
                <!-- Main map logic: JS code builds map and markers from tour data -->
                <script>
<![CDATA[
                    // Create the map and set up OpenStreetMap tiles
                    const map = L.map('map');
                    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { attribution: '&copy; OpenStreetMap contributors' }).addTo(map);

                    const markers = [];

                    // Build JS array of tours from XML data
                    const tours = [
]]>
                    <!-- For each tour, output a JS object with its info and coordinates -->
                    <xsl:for-each select="cto:tours/cto:tour">
                        <xsl:variable name="name" select="normalize-space(cto:tour_name)" />
                                                <xsl:variable name="lat1"
                            select="cto:starting_point/cto:coordinates/cto:latitude" />
                                                <xsl:variable name="lon1"
                            select="cto:starting_point/cto:coordinates/cto:longitude" />
                                                <xsl:variable name="lat2"
                            select="cto:final_destination/cto:coordinates/cto:latitude" />
                                                <xsl:variable name="lon2"
                            select="cto:final_destination/cto:coordinates/cto:longitude" /> {"name":"<xsl:value-of
                            select="$name" />", "category":"<xsl:value-of select="normalize-space(cto:category)" />",
        "distance":"<xsl:value-of
                            select="normalize-space(cto:distance)" />", "start": [<xsl:value-of select="$lat1" />, <xsl:value-of
                            select="$lon1" />], "end": [<xsl:value-of select="$lat2" />, <xsl:value-of select="$lon2" />],
        "price": "<xsl:value-of
                            select="concat(normalize-space(cto:price/cto:amount),' ',normalize-space(cto:price/cto:currency))" />",
        "dates": "<xsl:value-of
                            select="concat(normalize-space(cto:duration/cto:start_date),' - ',normalize-space(cto:duration/cto:end_date))" />",
        "availability": "<xsl:value-of select="normalize-space(cto:tour_availability/cto:availability)" />" }<xsl:if
                            test="position() != last()">,</xsl:if>
                    </xsl:for-each>
<![CDATA[
                    ];

                    // Fit map to all markers and draw lines between start/end
                    const bounds = L.latLngBounds([]);
                    tours.forEach(t => {
                        // Helper: check if coordinates are valid
                        function valid(coord) { return Array.isArray(coord) && coord.length===2 && !isNaN(coord[0]) && !isNaN(coord[1]); }
                        // Popup HTML for each tour
                        const popupHtml = `<b>${t.name}</b><br/>${t.category} • ${t.distance} km<br/>${t.dates}<br/>${t.price}<br/>${t.availability}`;
                        // Add start marker
                        if (valid(t.start)) {
                            const m = L.marker(t.start).addTo(map).bindPopup(popupHtml + '<br/><i>Start</i>');
                            markers.push(m); bounds.extend(t.start);
                        }
                        // Add end marker
                        if (valid(t.end)) {
                            const m2 = L.marker(t.end, {opacity:0.9}).addTo(map).bindPopup(popupHtml + '<br/><i>End</i>');
                            markers.push(m2); bounds.extend(t.end);
                        }
                        // Draw line from start to end
                        if (valid(t.start) && valid(t.end)) {
                            L.polyline([t.start, t.end], {color:'#11A0F2', weight:4, opacity:0.7}).addTo(map);
                        }
                    });
                    // Fit map to all markers, or show world if none
                    if (bounds.isValid()) { map.fitBounds(bounds.pad(0.15)); } else { map.setView([0,0], 2); }
]]>
                </script>
            </body>
        </html>
    </xsl:template>

</xsl:stylesheet>