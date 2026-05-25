<?xml version="1.0" encoding="UTF-8"?>
<!-- This XSLT builds an Emergency Contact Dashboard in HTML. It scans the
     tours dataset and extracts emergency contact entries associated with
     bookings so that operators can quickly find contact information. The
     stylesheet renders a table containing tour, client and emergency contact
     details, and it provides simple counts in the table caption for quick metrics.

     Example command to run the transformation (from project root):

     java -cp libs/saxon-he-12.4.jar:libs/xmlresolver-5.1.1.jar net.sf.saxon.Transform \
       -s:dataset/merged_datasets.xml \
       -xsl:xsl/05_emergency_contacts_to_html.xsl \
       -o:outputs/html/05_emergency_contacts.html
-->

<!-- Scenario 5: Emergency Contact Dashboard -->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cto="http://city-tour-operator.org/cto"
    exclude-result-prefixes="xs cto"> <!-- Using a namespace cto:-->
    <xsl:output method="html" />
    <xsl:strip-space elements="*" />
    <xsl:template match="/cto:data">
        <!-- All emergency_contact nodes across all tours -->
        <xsl:variable name="allContacts"
            select="cto:tours/cto:tour/cto:bikes/cto:bike/cto:booking/cto:client/cto:emergency_contact" />
        <!-- Distinct client elements that have at least one emergency_contact -->
        <xsl:variable
            name="clientsWithContacts"
            select="cto:tours/cto:tour/cto:bikes/cto:bike/cto:booking/cto:client[cto:emergency_contact]" />
        <!-- Tours that include at least one emergency_contact under bookings -->
        <xsl:variable
            name="toursWithContacts"
            select="cto:tours/cto:tour[cto:bikes/cto:bike/cto:booking/cto:client/cto:emergency_contact]" />

        <html>
            <head>
                <meta charset="utf-8" />
                <title>Emergency Contact Dashboard</title>
                <meta name="author"
                    content="Audrey Costes, Halima Lemmouchi, Lina Marcela Diaz Bejarano, Vincent Boettcher" />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <link rel="stylesheet" href="../css/styles.css" />
            </head>
            <body class="emergency-dashboard">
                <header class="page-header">
                    <h1>Emergency Contact Dashboard</h1>
                </header>
                <main class="table-wrapper">
                    <table class="contact-table">
                        <caption>
                            <span>Emergency contacts on file</span>
                            <span class="caption-meta">
                                <!-- Show simple counts derived from the variables above -->
                                <xsl:text>Tours: </xsl:text>
                                <xsl:value-of select="count($toursWithContacts)" />
                                <xsl:text> · Clients: </xsl:text>
                                <xsl:value-of select="count($clientsWithContacts)" />
                                <xsl:text> · Contacts: </xsl:text>
                                <xsl:value-of select="count($allContacts)" />
                            </span>
                        </caption>
                        <thead>
                            <tr>
                                <th>Tour</th>
                                <th>Client</th>
                                <th>Client contact</th>
                                <th>Emergency contact</th>
                                <th>Emergency phone</th>
                                <th>Relation</th>
                                <th>Bike / booking</th>
                            </tr>
                        </thead>
                        <tbody>
                            <!--
                                Nested iteration strategy:
                                1) Iterate tours that include emergency contacts.
                                2) Inside each tour iterate bikes that have bookings with emergency contacts.
                                3) Inside each bike iterate booking elements that include a client with an emergency contact.
                                4) For each client/emergency_contact node output a table row.
                                We use <xsl:sort> at several levels to keep the output logical.
                            -->
                            <xsl:for-each
                                select="cto:tours/cto:tour[cto:bikes/cto:bike/cto:booking/cto:client/cto:emergency_contact]">
                                <xsl:sort select="cto:tour_name" />
                                <xsl:variable name="tourName" select="cto:tour_name" />
                                <xsl:for-each
                                    select="cto:bikes/cto:bike[cto:booking/cto:client/cto:emergency_contact]">
                                    <!-- Sort bikes by their id attribute when present -->
                                    <xsl:sort
                                        select="@id"
                                        data-type="text" />
                                    <xsl:variable name="bikeModel" select="cto:model" />
                                    <xsl:for-each
                                        select="cto:booking[cto:client/cto:emergency_contact]">
                                        <!-- Sort bookings by booking_date for stable output -->
                                        <xsl:sort
                                            select="cto:booking_date"
                                            data-type="text" />
                                        <xsl:variable name="client" select="cto:client" />
                                        <xsl:variable
                                            name="bookingDate" select="cto:booking_date" />
                                        <!-- Each client may declare multiple emergency_contact entries; iterate them -->
                                        <xsl:for-each
                                            select="$client/cto:emergency_contact">
                                            <tr>
                                                <td>
                                                    <strong>
                                                        <xsl:value-of select="$tourName" />
                                                    </strong>
                                                </td>
                                                <td>
                                                    <strong>
                                                        <!-- Reuse the full-name template to render the client's name -->
                                                        <xsl:call-template name="full-name">
                                                            <xsl:with-param name="identity"
                                                                select="$client/cto:identity" />
                                                        </xsl:call-template>
                                                    </strong>
                                                </td>
                                                <td>
                                                    <div>
                                                        <xsl:value-of select="$client/cto:contact/cto:phone_number" />
                                                    </div>
                                                    <div class="contact-meta">
                                                        <xsl:value-of select="$client/cto:contact/cto:email" />
                                                    </div>
                                                </td>
                                                <td>
                                                    <strong>
                                                        <!-- Emergency contact full name -->
                                                        <xsl:call-template name="full-name">
                                                            <xsl:with-param name="identity" select="cto:identity" />
                                                        </xsl:call-template>
                                                    </strong>
                                                </td>
                                                <td>
                                                    <xsl:value-of select="cto:phone_number" />
                                                </td>
                                                <td>
                                                    <!-- Relation tag is optional; render a placeholder when absent -->
                                                    <xsl:choose>
                                                        <xsl:when test="cto:relation">
                                                            <span class="tag">
                                                                <xsl:value-of select="cto:relation" />
                                                            </span>
                                                        </xsl:when>
                                                        <xsl:otherwise>—</xsl:otherwise>
                                                    </xsl:choose>
                                                </td>
                                                <td>
                                                    <div>
                                                        <xsl:text>Bike model: </xsl:text>
                                                        <strong>
                                                            <xsl:value-of select="$bikeModel" />
                                                        </strong>
                                                    </div>
                                                    <div class="contact-meta">
                                                        <xsl:value-of select="$bookingDate" />
                                                    </div>
                                                </td>
                                            </tr>
                                        </xsl:for-each>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </xsl:for-each>
                        </tbody>
                    </table>
                </main>
            </body>
        </html>
    </xsl:template>

    <!-- Renders a full name from an identity node: it iterates over any firstname nodes,
     normalizes whitespace and then appends the lastname value. This keeps name formatting consistent across the dashboard. -->
    <xsl:template name="full-name">
        <xsl:param name="identity" />
        <xsl:for-each select="$identity/cto:firstname">
            <xsl:value-of select="normalize-space(.)" />
            <xsl:if test="position() != last()"> </xsl:if>
        </xsl:for-each>
        <xsl:text> </xsl:text>
        <xsl:value-of
            select="$identity/cto:lastname" />
    </xsl:template>
</xsl:stylesheet>