<?xml version="1.0" encoding="UTF-8"?>
<!-- This XSLT converts a structured XML guides dataset into an HTML presentation
     showing guide profiles with images, contact details, languages and qualifications.
     The transformation generates a responsive grid of guide cards and includes fallbacks
     for missing portrait images. It ignores the XML elements "tours" and "packages"
     for this view by applying empty templates to their contents.

     Example command to run the transformation (from project root):

     java -cp libs/saxon-he-12.4.jar:libs/xmlresolver-5.1.1.jar net.sf.saxon.Transform \
       -s:dataset/merged_datasets.xml \
       -xsl:xsl/02_guides_to_html.xsl \
       -o:outputs/html/02_guides.html
-->

<!-- Scenario 2: List of all guides to HTML -->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cto="http://city-tour-operator.org/cto"
    exclude-result-prefixes="xs cto"> <!-- Using a namespace cto:-->
    <xsl:strip-space elements="*" />
    <xsl:output method="html" />

    <xsl:template match="/">
        <html>
            <head>
                <meta charset="utf-8" />
                <title>Guide Profiles</title>
                <meta name="author"
                    content="Audrey Costes, Halima Lemmouchi, Lina Marcela Diaz Bejarano, Vincent Boettcher" />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <meta name="description" content="Display a grid of guide profiles with languages and qualifications." />
                <link rel="stylesheet" href="../css/styles.css" />
            </head>
            <body>
                <header class="page-header">
                    <h1>Guide Profiles</h1>
                </header>
                <xsl:apply-templates />
            </body>
        </html>
    </xsl:template>

    <!-- Ignore tours and packages for this view -->
    <xsl:template match="cto:tours" />
    <xsl:template match="cto:packages" />

    <!-- Guides container
         Renders the top-level container for guide cards. We select guide explicitly
         so they are processed in document order by the guide template below. -->
    <xsl:template match="cto:guides">
        <div class="cards-container guides-grid">
            <xsl:apply-templates select="cto:guide" />
        </div>
    </xsl:template>

    <!-- Single guide card
         For each guide element we render a .card containing the guide's
         portrait, name, nationality, contact details, location, languages and qualifications -->
    <xsl:template match="cto:guide">
        <div class="card guide-card">
            <div class="card-image">
                <!-- Derive image file name from first + last name if no explicit picture_name -->
                <xsl:variable name="fname" select="normalize-space(cto:identity/cto:firstname)" />
                <xsl:variable name="lname" select="normalize-space(cto:identity/cto:lastname)" />
                <xsl:variable name="derived" select="concat(lower-case($fname),'_',lower-case($lname),'.jpg')" />
                <xsl:choose>
                    <xsl:when test="cto:picture/cto:picture_name">
                        <!-- Use explicit picture name when provided; include onerror fallback -->
                        <img
                            onerror="this.src='../images/guides/default_guide.svg';this.onerror=null;">
                            <xsl:attribute name="src">../images/guides/<xsl:value-of
                                    select="cto:picture/cto:picture_name" /></xsl:attribute>
                            <xsl:attribute name="alt">Portrait of <xsl:value-of select="concat($fname,' ',$lname)" /></xsl:attribute>
                        </img>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Fallback derived filename when no explicit picture is supplied -->
                        <img onerror="this.src='../images/guides/default_guide.svg';this.onerror=null;">
                            <xsl:attribute name="src">../images/guides/<xsl:value-of select="$derived" /></xsl:attribute>
                            <xsl:attribute name="alt">Portrait of <xsl:value-of select="concat($fname,' ',$lname)" /></xsl:attribute>
                        </img>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
            <div class="card-content">
                <div class="upper-text">
                    <h2>
                        <!-- Full name built from identity fields -->
                        <xsl:value-of select="concat(cto:identity/cto:firstname,' ',cto:identity/cto:lastname)" />
                    </h2>
                    <p>
                        <i><xsl:value-of select="cto:nationality" /> Guide</i>
                    </p>
                </div>
                <div class="lower-text">
                    <div class="left-col">
                        <h3>Contact</h3>
                        <p>
                            <strong>Email: </strong>
                            <xsl:value-of select="cto:contact/cto:email" />
                        </p>
                        <p>
                            <strong>Phone: </strong>
                            <xsl:value-of select="cto:contact/cto:phone_number" />
                        </p>
                        <!-- Location block only rendered when there is at least a city or country -->
                        <xsl:if test="cto:address/cto:city or cto:address/cto:country">
                            <h3>Location</h3>
                            <p>
                                <xsl:if test="cto:address/cto:street"><xsl:value-of select="cto:address/cto:street" />,<br /></xsl:if>
                                <xsl:if test="cto:address/cto:city"><xsl:value-of select="cto:address/cto:city" />, </xsl:if>
                                <xsl:value-of select="cto:address/cto:country" />
                            </p>
                        </xsl:if>
                    </div>
                    <div class="right-col">
                        <div class="languages">
                            <strong>Languages:</strong>
                            <ul>
                                <!-- Iterate over spoken languages to produce list items -->
                                <xsl:for-each select="cto:spoken_languages/cto:language">
                                    <li>
                                        <xsl:value-of select="." />
                                    </li>
                                </xsl:for-each>
                            </ul>
                        </div>
                        <div class="qualifications">
                            <strong>Qualifications:</strong>
                            <ul>
                                <!-- Iterate over qualifications to produce list items -->
                                <xsl:for-each select="cto:qualifications/cto:qualification">
                                    <li>
                                        <xsl:value-of select="." />
                                    </li>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>

</xsl:stylesheet>