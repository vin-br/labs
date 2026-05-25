<?xml version="1.0" encoding="UTF-8"?>
<!-- This XSLT converts a structured XML guides dataset into an HTML presentation
     filtered by a spoken language. It generates a full HTML page with metadata,
     a language-aware title and a grid of guide cards. The stylesheet accepts a
     parameter lang (default: 'French') which is used to select only guides
     that have the requested language under spoken_languages.

     The transformation produces accessible markup and re-uses the shared
     ../css/styles.css for consistent presentation. It also includes image
     fallback logic so missing portraits are replaced with a placeholder.

     Example command to run the transformation (from project root):

    java -cp libs/saxon-he-12.4.jar:libs/xmlresolver-5.1.1.jar net.sf.saxon.Transform \
    -s:dataset/merged_datasets.xml \
    -xsl:xsl/03_guides_filtered_by_language_to_html.xsl \
    -o:outputs/html/03_guides_filtered_by_language.html \
    lang=Spanish
-->

<!-- Scenario 3: List of guides filtered by spoken language to HTML -->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cto="http://city-tour-operator.org/cto"
    exclude-result-prefixes="xs cto"> <!-- Using a namespace cto:-->
    <xsl:strip-space elements="*" />
    <xsl:output method="html" />

    <!-- Parameter controlling which language to filter by.
         The parameter is used below to select only guides that declare a
         matching language element under spoken_languages -->
    <xsl:param name="lang" select="'French'" /> <!-- setting a default value -->

    <xsl:template match="/">
        <html>
            <head>
                <meta charset="utf-8" />
                <title>
                    <xsl:value-of select="concat($lang, '-Speaking Guides Profiles')" />
                </title>
                <meta name="author"
                    content="Audrey Costes, Halima Lemmouchi, Lina Marcela Diaz Bejarano, Vincent Boettcher" />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <meta name="description" content="Filter to show only French-speaking guides." />
                <link rel="stylesheet" href="../css/styles.css" />
            </head>
            <body>
                <header class="page-header">
                    <h1>
                        <xsl:value-of select="concat($lang, ' Speaking Guides')" />
                    </h1>
                </header>
                <div class="cards-container guides-grid">
                    <!-- Select only guides with at least one language equal to the requested lang parameter.
                     We use an absolute path here to make sure we find guides regardless of the current context -->
                    <xsl:apply-templates select="//cto:guides/cto:guide[cto:spoken_languages/cto:language=$lang]" />
                </div>
            </body>
        </html>
    </xsl:template>

    <!-- Guide card template
         Renders a single .card for a guide element -->
    <xsl:template match="cto:guide">
        <div class="card guide-card">
            <div class="card-image">
                <!-- Build first/last name and a derived filename to
                     use as a fallback image when no explicit picture is provided -->
                <xsl:variable name="fname" select="normalize-space(cto:identity/cto:firstname)" />
                <xsl:variable name="lname" select="normalize-space(cto:identity/cto:lastname)" />
                <xsl:variable name="derived" select="concat(lower-case($fname),'_',lower-case($lname),'.jpg')" />
                <xsl:choose>
                    <xsl:when test="cto:picture/cto:picture_name">
                        <!-- Use explicit picture file when available. The onerror handler replaces missing images with
                        a shared placeholder -->
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
                        <!-- Show nationality followed by the label 'Guide' -->
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
                        <!-- Only render Location when at least one locality field exists -->
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
                                <!-- List all declared spoken languages for the guide -->
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
                                <!-- List each qualification declared for the guide -->
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