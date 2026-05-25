<?xml version="1.0" encoding="UTF-8"?>
<!-- This XSLT converts a structured XML tours dataset into an interactive HTML presentation 
    with styled cards and date filtering, supporting both semantic metadata and user-friendly layout.
    It matches the XML root and generates a full HTML page with metadata, stylesheets, and scripted 
    filtering functionality that allows users to filter tours by start date dynamically in the browser
    and it ignores the XML elements "guides" and "packages" by applying empty templates to their contents.
    The transformation applies templates recursively using <xsl:apply-templates />, allowing modular 
    handling of different XML elements. 

    Example command to run the transformation (from project root):

    java -cp libs/saxon-he-12.4.jar:libs/xmlresolver-5.1.1.jar net.sf.saxon.Transform \
    -s:dataset/merged_datasets.xml \
    -xsl:xsl/01_tours_to_html.xsl \
    -o:outputs/html/01_tours.html
-->

<!-- Scenario 1: List of all tours to HTML -->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cto="http://city-tour-operator.org/cto"
    exclude-result-prefixes="xs cto"> <!-- Using a namespace cto:-->
    <xsl:strip-space elements="*" />
    <xsl:output method="html" indent="yes" />

    <!-- We start at the root -->
    <xsl:template match="/">
        <html>
            <!-- We implement metadata expected in HTML content -->
            <head>
                <meta charset="utf-8" />
                <title></title>
                <meta name="author"
                    content="Audrey Costes, Halima Lemmouchi, Lina Marcela Diaz Bejarano, Vincent Boettcher" />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <meta name="description" content="Display a grid or list of tours with cards for each tour." />
                <link rel="stylesheet" href="../css/styles.css" />
            </head>
            <body>
                <header class="page-header">
                    <h1>Cycle Around the World</h1>
                </header>

                <!-- We apply templates to the child nodes of the current XML root element (data) in a recursive and
                flexible way -->
                <xsl:apply-templates />

                <!-- This is a script in javascript to implement the two behaviors:
                    - a CLOSED overlay over the cards when the tours already happended in the past.
                    - a filtering function: 
                        Based on the data-startdate attribute added to every tour at the level of the card. 
                        If the const filterValue (date selected in the date picker) is after the data-startdate
                        on the card, the card is not displayed.
                        The two addEventListener apply the functions on every click
                -->
                <script>
                    // Mark closed tours on page load
                    const today = new Date();
                    today.setHours(0, 0, 0, 0); // Reset to start of day for accurate comparison
        document.querySelectorAll('.card').forEach(card => {
                    const endDateStr = card.getAttribute('data-enddate');
                    if (endDateStr) {
                    const endDate = new Date(endDateStr);
                    if (endDate &lt; today) {
                    card.classList.add('closed');
                    }
                    }
                    });

                    document.getElementById('filterBtn').addEventListener('click', () => {
                    const filterValue = document.getElementById('startDateFilter').value;
                    if (!filterValue) {
                    // If no date selected, show all
                    document.querySelectorAll('.card').forEach(card => card.style.display = '');
                    return;
                    }
                    const filterDate = new Date(filterValue);
                    document.querySelectorAll('.card').forEach(card => {
                    const cardDateStr = card.getAttribute('data-startdate');
                    if (!cardDateStr) return;
                    const cardDate = new Date(cardDateStr);
                    card.style.display = (cardDate >= filterDate) ? '' : 'none';
                    });
                    });
                    document.getElementById('resetBtn').addEventListener('click', () => {
        document.getElementById('startDateFilter').value = '';
                    document.querySelectorAll('.card').forEach(card => card.style.display = '');
                    });
                </script>
            </body>
        </html>
    </xsl:template>

    <!-- We create a template that matches the child element "tours". 
    It will be applied by the <xsl:apply-templates /> at the root "/" -->
    <xsl:template match="cto:tours">
        <!-- Creation of two buttons for filtering purposes -->
        <div class="filter-container">
            <label for="startDateFilter">Filter Tours by Date:</label>
            <input type="date" id="startDateFilter" />
            <!-- filterBtn references the function that filters cards based on dates -->
            <button id="filterBtn">Filter</button>
            <!-- resetBtn resets all filters -->
            <button id="resetBtn">Reset</button>
        </div>

        <div class="cards-container">
            <!-- We sort the tours by start_date, in ascending order so that the tours appear in
            chronological order -->
            <xsl:apply-templates>
                <xsl:sort select="cto:duration/cto:start_date" order="ascending" data-type="text" />
            </xsl:apply-templates>

        </div>
    </xsl:template>

    <!-- We create a template that matches the child elements "tour". 
    It will apply the instructions for all the "tour" occurencies. So here we generate a card for each "tour" -->
    <xsl:template match="cto:tour">
        <!-- We create the attribute data-startdate based on the content of data/tours/tour/duration/start_date
        Since we are currently in tour we don't need to specify the full path to the element. We can concentrate 
        and start on the direct child of "tour" -->
        <div class="card" data-startdate="{cto:duration/cto:start_date}"
            data-enddate="{cto:duration/cto:end_date}">
            <!-- We add a CLOSED overlay div for past tours -->
            <div class="closed-overlay" />
            <div class="card-image">
                <img>
                    <!-- We create the src attribute value. Could have used concat() but the string has many
                    components, this way seemed a little more readable 
                    The HTML output will be inside outputs/html and the images are inside outputs/images/countries/
                    so we need to move to the parent of the html/ folder and then we can move to the sibling images/
                    folder. 
                    The full path will be outputs/images/countries/{$country}/{$city}
                    $country is found in element data/tours/tour/company/address/country
                    $city is found in element data/tours/tour/company/address/city -->
                    <xsl:attribute name="src">
                        <xsl:text>../images/countries/</xsl:text>
                        <xsl:value-of select="lower-case(cto:company/cto:address/cto:country)" />
                        <xsl:text>/</xsl:text>
                        <xsl:value-of
                            select="lower-case(cto:company/cto:address/cto:city)" />
                        <xsl:text>.jpg</xsl:text>
                    </xsl:attribute>
                    <!-- We apply the same logic for the expected alt attribute -->
                    <xsl:attribute name="alt">
                        <xsl:text>Tour image of the </xsl:text>
                        <xsl:value-of select="cto:company/cto:address/cto:city" />
                        <xsl:text> city in </xsl:text>
                        <xsl:value-of
                            select="cto:company/cto:address/cto:country" />
                    </xsl:attribute>
                </img>
                <!-- <img src="../images/{company/address/country}/{company/address/city}.jpg" alt="Tour image of the
                {company/address/city} city in {company/address/country}" /> -->
            </div>
            <div class="card-content">
                <!-- Upper part: Tour name and description -->
                <div class="upper-text">
                    <h2>
                        <!-- direct child of tour -->
                        <xsl:value-of select="cto:tour_name" />
                    </h2>
                    <p>
                        <i>
                            <!-- direct child of tour -->
                            <xsl:value-of select="cto:short_description" />
                        </i>
                    </p>
                </div>

                <!-- Lower part with two columns -->
                <div class="lower-text">
                    <!-- Left column: company info and address -->
                    <div class="left-col">
                        <h3>Company Info</h3>
                        <p>
                            <strong>Name: </strong>
                            <xsl:value-of select="cto:company/cto:name" />
                        </p>
                        <p>
                            <strong>Email: </strong>
                            <xsl:value-of select="cto:company/cto:contact/cto:email" />
                        </p>
                        <p>
                            <strong>Phone: </strong>
                            <xsl:value-of select="cto:company/cto:contact/cto:phone_number" />
                        </p>
                        <h3>Address</h3>
                        <p>
                            <xsl:value-of select="cto:company/cto:address/cto:street" />,<br />
                            <xsl:value-of
                                select="cto:company/cto:address/cto:city" />
                            <!-- In the schema we have defined that an address can contain a zip code minOccurs=0 
                            maxOccurs=1 so here we need to manage the fact that sometimes there is no zip code. 
                            We use the <xsl:if> tag to add a conditional element the attribute test let's us implement
                            the condition => here we cant to test if the <code> tag is present in the tour element 
                            (inside company/address/). If it does we add it, if not we directly go to the next element.
                            
                            With this logic we get:
                            
                            - when the zip code is specified
                            45 Glacier Way,
                            Chamonix, 74400,
                            France

                            - when the zip code is not specified
                            8-1 Ginza,
                            Tokyo,
                            Japan
                            -->
                            <xsl:if
                                test="cto:company/cto:address/cto:code">
                                <!-- We add a complementary ",". Can't be added before the if condition otherwise it
                                will
                                always be displayed. An equivalent logic would be:
                                
                                <xsl:value-of select="cto:company/cto:address/cto:city" />
                                <xsl:text>, </xsl:text>
                                <xsl:if test="cto:company/cto:address/cto:code">
                                    <xsl:value-of select="cto:company/cto:address/cto:code" />
                                    <xsl:text>, </xsl:text>
                                </xsl:if>
                                <xsl:value-of select="cto:company/cto:address/cto:country" />
                                -->
                                <xsl:text>, </xsl:text>
                                <xsl:value-of
                                    select="cto:company/cto:address/cto:code" />
                            </xsl:if>                
                            <xsl:text>, </xsl:text><br />
                            <xsl:value-of
                                select="cto:company/cto:address/cto:country" />
                        </p>
                    </div>

                    <!-- Right column: difficulty and price -->
                    <div class="right-col">
                        <p>
                            <!-- Example of string concatenation using concat(). Here we concat the values of two
                            elements
                            the output will look like: 
                            <time datetime="2025-05-10 - 2025-05-10">2025-05-10 - 2025-05-10</time>
                            
                            The "datetime" attribute provides a machine-readable format (used by browsers, search engines, 
                            or other softwares => for accessibility purposes for example), while the content inside <time> 
                            is the human-readable version displayed to users. They serve complementary purposes—one for semantic 
                            metadata, the other for presentation.
                            -->
                            <time datetime="{concat(cto:duration/cto:start_date, '/', cto:duration/cto:end_date)}">
                                <xsl:value-of
                                    select="concat(cto:duration/cto:start_date, ' - ', cto:duration/cto:end_date)" />
                            </time>
                        </p>
                        <p>
                            <strong>Difficulty: </strong>
                            <xsl:value-of select="cto:category" />
                        </p>
                        <p>
                            <strong>Price: </strong>
                            <xsl:value-of select="cto:price/cto:amount" />
                            <xsl:value-of select="cto:price/cto:currency" />
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="cto:guides" />     <!-- template left empty so that the content is ignored -->
    <xsl:template match="cto:packages" />   <!-- template left empty so that the content is ignored -->

</xsl:stylesheet>