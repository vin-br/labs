<?xml version="1.0" encoding="UTF-8"?>
<!--
  This XSLT builds a Bike Inventory Management Dashboard in HTML. It
  consolidates bike records nested under tours into a single, filterable table,
  computes fleet metrics and distinct type/availability lists for dropdowns,
  and renders per-bike details (model, reference, weight, type/autonomy, size),
  tour assignment, booking contact windows and daily rates. Rows are grouped and
  sorted (tour → bike id) and include data-* attributes to support client-side filtering.
  The stylesheet uses the cto: namespace and provides fallbacks for missing fields.

  Example command to run the transformation (from project root):

    java -cp libs/saxon-he-12.4.jar:libs/xmlresolver-5.1.1.jar net.sf.saxon.Transform \
      -s:dataset/merged_datasets.xml \
      -xsl:xsl/06_bikes_inventory_to_html.xsl \
      -o:outputs/html/06_bikes_inventory.html
-->

<!-- Scenario 6: Bike Inventory Management Dashboard -->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cto="http://city-tour-operator.org/cto"
    exclude-result-prefixes="xs cto">
    <xsl:output method="html" />
    <xsl:strip-space elements="*" />

    <xsl:template match="/cto:data">
        <!-- Collect every bike once so we can reuse the sequence across counts, filters and the table -->
          <xsl:variable name="allBikes" select="cto:tours/cto:tour/cto:bikes/cto:bike" />
        <!-- Pre-compute distinct bike types and availability values for the dropdown filters -->
    		<xsl:variable
            name="bikeTypes"
            select="distinct-values($allBikes/cto:bike_type/cto:type ! normalize-space(.))" />
    		<xsl:variable
            name="availabilityStates"
            select="distinct-values($allBikes/cto:availability ! normalize-space(.))" />

		<html>
            <head>
                <meta charset="utf-8" />
                <title>Bike Inventory Dashboard</title>
                <meta name="author"
                    content="Audrey Costes, Halima Lemmouchi, Lina Marcela Diaz Bejarano, Vincent Boettcher" />
                <meta name="viewport" content="width=device-width, initial-scale=1" />
                <link rel="stylesheet" href="../css/styles.css" />
            </head>
            <body class="bike-inventory-dashboard">
                <header class="page-header">
                    <h1>Bike Inventory Management</h1>
                </header>
                <main class="inventory-content">
                    <div class="table-wrapper">
                        <!-- Summary table with filter controls, fleet counts and the detailed rows -->
                        <table class="bike-table">
                            <caption>
                                <div class="caption-content">
                                    <span class="caption-title">Fleet overview</span>
                                    <div class="filter-controls">
                                        <!-- Filter dropdowns mirror the bike type / availability sequences computed
                                        above -->
                                        <form>
                                            <label for="filter-type">Filter by type</label>
                                            <select id="filter-type" name="filter-type">
                                                <option value="all">All</option>
                                                <xsl:for-each select="$bikeTypes[. != '']">
                                                    <xsl:sort select="." />
								<option>
                                                        <xsl:attribute name="value">
                                                            <xsl:value-of select="lower-case(.)" />
                                                        </xsl:attribute>
                                                        <xsl:value-of select="." />
                                                    </option>
                                                </xsl:for-each>
                                            </select>
                                            <label for="filter-availability">Filter by availability</label>
                                            <select id="filter-availability" name="filter-availability">
                                                <option value="all">All</option>
                                                <xsl:for-each select="$availabilityStates[. != '']">
                                                    <xsl:sort select="." />
								<option>
                                                        <xsl:attribute name="value">
                                                            <xsl:value-of select="lower-case(.)" />
                                                        </xsl:attribute>
                                                        <xsl:value-of select="." />
                                                    </option>
                                                </xsl:for-each>
                                            </select>
                                        </form>
                                    </div>
                                </div>
                                <span class="caption-meta">
                                    <!-- Quick stats on the global fleet, broken down by availability -->
                                    <xsl:text>Bikes: </xsl:text>
                                    <xsl:value-of select="count($allBikes)" />
                                    <xsl:text> · Available: </xsl:text>
                                    <xsl:value-of
                                        select="count($allBikes[lower-case(normalize-space(cto:availability)) = 'available'])" />
                                    <xsl:text> · Reserved: </xsl:text>
                                    <xsl:value-of
                                        select="count($allBikes[lower-case(normalize-space(cto:availability)) = 'reserved'])" />
                                    <xsl:text> · Maintenance: </xsl:text>
                                    <xsl:value-of
                                        select="count($allBikes[lower-case(normalize-space(cto:availability)) = 'maintenance'])" />
                                </span>
                            </caption>
                            <thead>
                                <tr>
                                    <th>Bike</th>
                                    <th>Type &amp; size</th>
                                    <th>Availability</th>
                                    <th>Tour assignment</th>
                                    <th>Booking</th>
                                    <th>Rate</th>
                                </tr>
                            </thead>
                            <tbody>
                                <!-- Iterate over tours first to keep bikes grouped by their parent tour -->
                                <xsl:for-each select="cto:tours/cto:tour[cto:bikes/cto:bike]">
                                    <xsl:sort select="cto:tour_name" />
								<xsl:variable name="tour" select="." />
								<xsl:variable
                                        name="tourName" select="cto:tour_name" />
								<xsl:for-each
                                        select="$tour/cto:bikes/cto:bike">
                                        <xsl:sort select="@id" />
									<xsl:variable name="bikeId" select="@id" />
									<xsl:variable
                                            name="bikeModel" select="cto:model" />
                					<xsl:variable name="bikeType"
                                            select="normalize-space(cto:bike_type/cto:type)" />
                					<xsl:variable
                                            name="bikeTypeDisplay"
                                            select="if ($bikeType) then concat(upper-case(substring($bikeType, 1, 1)), substring($bikeType, 2)) else ''" />
									<xsl:variable
                                            name="bikeAvailability"
                                            select="normalize-space(cto:availability)" />
									<xsl:variable name="bikeWeight"
                                            select="normalize-space(cto:weight)" />
									<xsl:variable name="rentalAmount"
                                            select="normalize-space(cto:rental_price_per_day/cto:amount)" />
									<xsl:variable
                                            name="rentalCurrency"
                                            select="normalize-space(cto:rental_price_per_day/cto:currency)" />
									<tr>
                                            <xsl:attribute name="data-type">
                                                <xsl:value-of
                                                    select="if ($bikeType) then lower-case($bikeType) else 'unknown'" />
                                            </xsl:attribute>
                                            <xsl:attribute name="data-availability">
                                                <xsl:value-of
                                                    select="if ($bikeAvailability) then lower-case($bikeAvailability) else 'unknown'" />
                                            </xsl:attribute>
                                            <td>
                                                <strong>
                                                    <!-- Prefer the explicit model name, fall back to ID when missing -->
                                                    <xsl:choose>
                                                        <xsl:when test="normalize-space($bikeModel)">
                                                            <xsl:value-of select="$bikeModel" />
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:value-of select="$bikeId" />
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </strong>
                                                <div class="bike-ref">
                                                    <xsl:text>Ref: </xsl:text>
                                                    <xsl:value-of select="$bikeId" />
                                                </div>
                                                <xsl:if test="$bikeWeight">
                                                    <div class="contact-meta">
                                                        <xsl:text>Weight: </xsl:text>
                                                        <xsl:value-of select="$bikeWeight" />
                                                        <xsl:text> kg</xsl:text>
                                                    </div>
                                                </xsl:if>
                                            </td>
                                            <td>
                                                <div>
                                                    <xsl:value-of select="$bikeTypeDisplay" />
                                                </div>
                                                <xsl:if test="cto:bike_type/cto:electric_autonomy">
                                                    <!-- Electric bikes expose their autonomy in km -->
                                                    <div
                                                        class="bike-autonomy">
                                                        <xsl:value-of select="cto:bike_type/cto:electric_autonomy" />
                                                        <xsl:text> km autonomy</xsl:text>
                                                    </div>
                                                </xsl:if>
                                                <div class="contact-meta">
                                                    <xsl:text>Size: </xsl:text>
                                                    <xsl:value-of select="cto:size" />
                                                </div>
                                            </td>
                                            <td>
                                                <span class="tag">
                                                    <xsl:value-of select="$bikeAvailability" />
                                                </span>
                                            </td>
                                            <td>
                                                <strong>
                                                    <xsl:value-of select="$tourName" />
                                                </strong>
                                                <div class="contact-meta">
                                                    <xsl:text>Category: </xsl:text>
                                                    <xsl:value-of select="$tour/cto:category" />
                                                </div>
                                                <div class="contact-meta">
                                                    <xsl:text>Distance: </xsl:text>
                                                    <xsl:value-of select="$tour/cto:distance" />
                                                    <xsl:text> km</xsl:text>
                                                </div>
                                            </td>
                                            <td>
                                                <xsl:choose>
                                                    <xsl:when test="cto:booking">
                                                        <!-- Show each booking for the bike with inline contact info -->
                                                        <xsl:for-each select="cto:booking">
                                                            <div class="booking-entry">
                                                                <div class="booking-client">
                                                                    <strong>
                                                                        <xsl:call-template name="full-name">
                                                                            <xsl:with-param name="identity"
                                                                                select="cto:client/cto:identity" />
                                                                        </xsl:call-template>
                                                                    </strong>
                                                                </div>
                                                                <div class="contact-meta">
                                                                    <xsl:text>Booking date: </xsl:text>
                                                                    <xsl:value-of select="cto:booking_date" />
                                                                </div>
                                                                <xsl:if test="$tour/cto:duration/cto:start_date">
                                                                    <div class="contact-meta">
                                                                        <xsl:text>Tour dates: </xsl:text>
                                                                        <xsl:value-of
                                                                            select="$tour/cto:duration/cto:start_date" />
                                                                        <xsl:text> → </xsl:text>
                                                                        <xsl:value-of
                                                                            select="$tour/cto:duration/cto:end_date" />
                                                                    </div>
                                                                </xsl:if>
                                                            </div>
                                                            <xsl:if
                                                                test="position() != last()">
                                                                <hr />
                                                            </xsl:if>
                                                        </xsl:for-each>
                                                    </xsl:when>
                                                    <xsl:otherwise>—</xsl:otherwise>
                                                </xsl:choose>
                                            </td>
                                            <td class="rate-cell">
                                                <xsl:choose>
                                                    <xsl:when test="$rentalAmount">
                                                        <!-- Rental rate shown as "amount currency / day" when available -->
                                                        <span class="rate-value">
                                                            <xsl:value-of select="$rentalAmount" />
                                                            <xsl:if test="$rentalCurrency">
                                                                <xsl:text> </xsl:text>
                                                                <xsl:value-of
                                                                    select="$rentalCurrency" />
                                                            </xsl:if>
                                                        </span>
                                                        <span
                                                            class="rate-unit">/day</span>
                                                    </xsl:when>
                                                    <xsl:otherwise>—</xsl:otherwise>
                                                </xsl:choose>
                                            </td>
                                        </tr>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </tbody>
                        </table>
                    </div>
                </main>
                <!-- Client-side filtering (type + availability) -->
                <script><![CDATA[
(function () {
  var typeSelect = document.getElementById('filter-type');
  var availabilitySelect = document.getElementById('filter-availability');
  if (!typeSelect || !availabilitySelect) {
	return;
  }
  var rows = Array.prototype.slice.call(document.querySelectorAll('.bike-table tbody tr'));
  function applyFilters() {
	var typeValue = typeSelect.value;
	var availabilityValue = availabilitySelect.value;
	rows.forEach(function (row) {
	  var matchesType = typeValue === 'all' || row.getAttribute('data-type') === typeValue;
	  var matchesAvailability = availabilityValue === 'all' || row.getAttribute('data-availability') === availabilityValue;
	  row.style.display = (matchesType && matchesAvailability) ? '' : 'none';
	});
  }
  typeSelect.addEventListener('change', applyFilters);
  availabilitySelect.addEventListener('change', applyFilters);
})();
				]]></script>
            </body>
        </html>
    </xsl:template>

    <!-- Helper template shared by bookings: builds "Firstname Lastname" -->
    <xsl:template name="full-name">
        <xsl:param name="identity" />
		<xsl:for-each select="$identity/cto:firstname">
            <xsl:value-of select="normalize-space(.)" />
			<xsl:if test="position() != last()">
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:for-each>
		<xsl:if test="$identity/cto:lastname">
            <xsl:text> </xsl:text>
			<xsl:value-of select="$identity/cto:lastname" />
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>