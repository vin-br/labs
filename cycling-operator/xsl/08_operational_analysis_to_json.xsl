<?xml version="1.0" encoding="UTF-8"?>
<!-- This XSLT stylesheet transforms XML data related to bike tours into a structured JSON format
  focusing on operational analytics such as guide assignments, tour schedules, and resource utilization.
  It looks for various elements in the XML dataset and computes metrics to provide insights into the operations
  of the bike tour company.
  We implemented the same function as in the transformation 07_business_analysis_to_json.xsl to convert 
  currencies to euros.
  We also used multiple xsl functions such as sum(), count(), avg(), etc. to manipulate and analyze
  the data effectively.

  Example command to run the transformation (from project root):

   java -cp libs/saxon-he-12.4.jar:libs/xmlresolver-5.1.1.jar \
   net.sf.saxon.Transform \
   -s:dataset/merged_datasets.xml \
   -xsl:xsl/08_operational_analysis_to_json.xsl \
   -o:outputs/json/08_operational_analysis.json
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cto="http://city-tour-operator.org/cto"
    xmlns:local="http://local-functions"
    exclude-result-prefixes="xs cto local"> <!-- Using a namespace cto:-->

    <xsl:output method="text" encoding="UTF-8" />
    <!-- We use strip-space to remove unnecessary whitespace from the XML input to simplify
    processing -->
    <xsl:strip-space elements="*" />

    <!-- Currency conversion rates to EUR (as of November 2025). This would generaly be updated
  in real time through an API call, but for the purpose of this course we rendered it static -->
    <xsl:variable name="currency-rates">
         <rate currency="EUR" value="1.00" />
      <rate currency="USD" value="0.92" />
      <rate
              currency="GBP"
              value="1.17" />
      <rate currency="JPY" value="0.0062" />
      <rate currency="CAD"
              value="0.66" />
      <rate
              currency="AUD" value="0.60" />
      <rate currency="CHF" value="1.05" />
      <rate
              currency="NOK"
              value="0.085" />
      <rate currency="SEK" value="0.087" />
    </xsl:variable>

    <!-- This function "convertToEur" converts a numeric monetary amount from any given currency
  to euros based on provided conversion rates. If the currency rate isn't known,
  it assumes the amount is already in euros and returns it directly. -->
    <!-- "xs:double" covers all floating-point numbers and uses decimal notation -->
    <xsl:function name="local:convertToEur" as="xs:double">
         <!-- The function takes to parameters: amount and currency -->
      <xsl:param name="amount" as="xs:double" />
      <xsl:param
              name="currency" as="xs:string" />
         <!-- And a variable "rate" that is based on the variable "currency-rates" defined above
      It extract the rate value from currency-rates that matches the value of the currency element
      from the dataset. -->
      <xsl:variable
              name="rate" select="$currency-rates/cto:rate[@currency = $currency]/@value" />
         <!-- We implement a conditional logic -->
      <xsl:choose>
              <!-- If $rate has a value -->
              <xsl:when test="$rate">
                   <!-- It converts the amount value with the pertinent rate. The variable $rate
              represents
              an XML node or attribute value, which is a string, so we need to explicitly convert it
              into a numeric value -->
              <xsl:sequence select="$amount * number($rate)" />
              </xsl:when>
              <!-- If $rate doesn't have a value -->
              <xsl:otherwise>
                   <!-- It simply returns the amount value available without transforming it -->
              <xsl:sequence select="$amount" />
              </xsl:otherwise>
         </xsl:choose>
    </xsl:function>

    <!-- Root template
      Note: There is no direct indent/newline declaration to format JSON output automatically which is
      why we needed to explicitely add &#10; everywhere for readability purposes. -->
    <xsl:template match="/">
         <xsl:text>{&#10;</xsl:text>
      <xsl:text>  "operational_analytics": {&#10;</xsl:text>
         <!-- Create a root key/value paire. The value will contain all the data we extract from
         the dataset -->
      <xsl:apply-templates select="cto:data" />
      <xsl:text>  }&#10;</xsl:text>
      <xsl:text>}</xsl:text>
    </xsl:template>

    <!-- Data template -->
    <xsl:template match="cto:data">
         <!-- We apply multiple templates to extract different sections of operational analytics -->
      <xsl:call-template name="overview" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:apply-templates
              select="cto:tours" mode="bikes-operations" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:apply-templates
              select="cto:guides" mode="workload" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:apply-templates
              select="cto:tours" mode="payment-analytics" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:call-template
              name="operational-efficiency" />
    </xsl:template>

    <!-- Overview section -->
    <xsl:template name="overview">
         <xsl:text>    "overview": {&#10;</xsl:text>
      <xsl:text>      "total_tours": </xsl:text>
      <xsl:value-of select="count(cto:tours/cto:tour)" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "total_guides": </xsl:text>
      <xsl:value-of
              select="count(cto:guides/cto:guide)" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "total_bikes": </xsl:text>
      <xsl:value-of
              select="count(cto:tours/cto:tour/cto:bikes/cto:bike)" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "total_bookings": </xsl:text>
      <xsl:value-of
              select="count(cto:tours/cto:tour/cto:bikes/cto:bike/cto:booking)" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "active_tours": </xsl:text>
      <xsl:value-of
              select="count(cto:tours/cto:tour[cto:bikes/cto:bike/cto:booking])" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>    }</xsl:text>
    </xsl:template>

    <!-- Bikes operational statistics -->
    <xsl:template match="cto:tours" mode="bikes-operations">
         <!-- We declare a variable "all-bikes" that selects all bike elements within tours -->
      <xsl:variable name="all-bikes"
              select="cto:tour/cto:bikes/cto:bike" />
         <!-- We store a reference to the tours element to use inside for-each loops -->
      <xsl:variable name="tours" select="." />
      <xsl:text>    "bikes_operations": {&#10;</xsl:text>
      <xsl:text>      "fleet_by_type": [</xsl:text>
         <!-- We iterate over each distinct bike type found in the dataset using the
         distinct-values() function -->
      <xsl:for-each
              select="distinct-values(cto:tour/cto:bikes/cto:bike/cto:bike_type/cto:type)">
              <!-- We declare three variables:
          - "type": holds the current bike type in the iteration.
          - "bikes-of-type": selects all bikes that match the current type.
          - "rented-bikes": selects the subset of bikes of the current type that are currently rented -->
          <xsl:variable
                   name="type" select="." />
          <xsl:variable
                   name="bikes-of-type"
                   select="$all-bikes[cto:bike_type/cto:type = $type]" />
          <xsl:variable
                   name="rented-bikes"
                   select="$bikes-of-type[cto:booking]" />
          <xsl:text>&#10;        {&#10;</xsl:text>
          <xsl:text>          "bike_type": "</xsl:text>
          <xsl:value-of
                   select="$type" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "total_in_fleet": </xsl:text>
              <!-- Counts the total number of bikes of the current type -->
          <xsl:value-of
                   select="count($bikes-of-type)" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "currently_rented": </xsl:text>
              <!-- Counts the number of bikes of the current type that are rented -->
          <xsl:value-of
                   select="count($rented-bikes)" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "rental_frequency_percent": </xsl:text>
              <!-- Counts the rental frequency as a percentage of the total bikes of that type and
              formats it
          to two decimal places -->
          <xsl:value-of
                   select="format-number((count($rented-bikes) div count($bikes-of-type)) * 100, '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "avg_rental_price_eur": </xsl:text>
              <!-- We declare a variable "avg-price-eur" that calculates the average rental price
              in euros for the current
           bike type -->
          <xsl:variable
                   name="avg-price-eur">
                   <!-- We implement a conditional logic to handle cases where there are no bikes
                   of the current type -->
              <xsl:choose>
                        <!-- We test if there are bikes of the current type -->
                        <xsl:when test="count($bikes-of-type) > 0">
                             <!-- Then we calculate the average rental price in euros by:
                      - Iterating over each bike of the current type
                      - Converting its rental price to euros using the local:convertToEur function
                      - Finally, we compute the average of these converted prices using the avg() function  -->
                      <xsl:value-of
                                  select="avg(
                          for $bike in $bikes-of-type
                          return local:convertToEur(
                              number($bike/cto:rental_price_per_day/cto:amount),
                              string($bike/cto:rental_price_per_day/cto:currency)
                          )
                      )" />
                        </xsl:when>
                        <!-- If there are no bikes of the current type, we set the average rental
                        price to 0 -->
                        <xsl:otherwise>0</xsl:otherwise>
                   </xsl:choose>
              </xsl:variable>
          <xsl:value-of
                   select="format-number($avg-price-eur, '0.00')" />
          <xsl:text>&#10;</xsl:text>
          <xsl:text>        }</xsl:text>
              <!-- We add a comma after each bike type object except for the last one to maintain a
              valid JSON syntax -->
          <xsl:if
                   test="position() != last()">,</xsl:if>
         </xsl:for-each>
      <xsl:text>&#10;      ],&#10;</xsl:text>
      <xsl:text>      "bikes_by_tour_date": [</xsl:text>
         <!-- We iterate over each distinct tour start date found in the dataset using the
         distinct-values() function -->
      <xsl:for-each
              select="distinct-values(cto:tour/cto:duration/cto:start_date)">
              <!-- We sort the dates in ascending order to have a chronological output. Here,
              select="." means we sort by
           the current value in the for-each loop -->
          <xsl:sort select="."
                   order="ascending" />
              <!-- With the same logic we declare the variable date that holds the current date in
              the iteration
           (select=".")
           and two other variables:
              - tours-on-date: selects all tours that start on the current date.
              - bikes-on-date: selects all bikes associated with the tours on the current date -->
          <xsl:variable
                   name="date" select="." />
          <xsl:variable
                   name="tours-on-date"
                   select="$tours/cto:tour[cto:duration/cto:start_date = $date]" />
          <xsl:variable
                   name="bikes-on-date"
                   select="$tours-on-date/cto:bikes/cto:bike" />
          <xsl:text>&#10;        {&#10;</xsl:text>
          <xsl:text>          "date": "</xsl:text>
          <xsl:value-of
                   select="$date" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "tours_count": </xsl:text>
          <xsl:value-of
                   select="count($tours-on-date)" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "total_bikes": </xsl:text>
          <xsl:value-of
                   select="count($bikes-on-date)" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "bikes_available": </xsl:text>
          <xsl:value-of
                   select="count($bikes-on-date[cto:availability = 'available'])" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "bikes_reserved": </xsl:text>
          <xsl:value-of
                   select="count($bikes-on-date[cto:availability = 'reserved'])" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "bikes_in_maintenance": </xsl:text>
          <xsl:value-of
                   select="count($bikes-on-date[cto:availability = 'maintenance'])" />
          <xsl:text>&#10;</xsl:text>
          <xsl:text>        }</xsl:text>
              <!-- We make sure to add a comma after each date object except for the last one to
              maintain a valid JSON
           syntax -->
          <xsl:if
                   test="position() != last()">,</xsl:if>
         </xsl:for-each>
      <xsl:text>&#10;      ],&#10;</xsl:text>
      <xsl:text>      "maintenance_tracking": {&#10;</xsl:text>
      <xsl:text>        "bikes_in_maintenance": </xsl:text>
      <xsl:value-of
              select="count($all-bikes[cto:availability = 'maintenance'])" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>        "bikes_available": </xsl:text>
      <xsl:value-of
              select="count($all-bikes[cto:availability = 'available'])" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>        "bikes_reserved": </xsl:text>
      <xsl:value-of
              select="count($all-bikes[cto:availability = 'reserved'])" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>        "maintenance_rate_percent": </xsl:text>
         <!-- We calculate the maintenance rate as a percentage of the total bikes and format it to
         two decimal places -->
      <xsl:value-of
              select="format-number((count($all-bikes[cto:availability = 'maintenance']) div count($all-bikes)) * 100, '0.00')" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>      }&#10;</xsl:text>
      <xsl:text>    }</xsl:text>
    </xsl:template>

    <!-- Guides workload -->
    <!-- We match the guides element in "workload" mode to generate workload statistics for each
    guide. We will manage
   it's content
    through the application of templates in "workload-detail" mode -->
    <xsl:template match="cto:guides" mode="workload">
         <xsl:text>    "guides_workload": [</xsl:text>
      <xsl:apply-templates select="cto:guide" mode="workload-detail" />
      <xsl:text>&#10;    ]</xsl:text>
    </xsl:template>

    <!-- Individual guide workload -->
    <xsl:template match="cto:guide" mode="workload-detail">
         <!-- We declare two variables:
      - "guide_id": holds the ID of the current guide being processed.
      - "tours_led": selects all tours assigned to the current guide by matching the guide's ID with the
         guide reference in
       the tour elements.
    
      select="@" is used to get the value of an attribute, in our case the value of the @id attribute of
         the current guide
       element -->
      <xsl:variable name="guide_id"
              select="@id" />
         <!-- Here we use select="//" to search for tours anywhere in the document that reference
         the current guide ID
       and in the same way that
       we selected the guide id above, now we select the guide reference in the tour elements -->
      <xsl:variable
              name="tours_led"
              select="//cto:tour[cto:guide/@idref = $guide_id]" />
      <xsl:text>&#10;      {&#10;</xsl:text>
      <xsl:text>        "guide_name": "</xsl:text>
      <xsl:value-of
              select="cto:identity/cto:firstname" />
      <xsl:text> </xsl:text>
      <xsl:value-of
              select="cto:identity/cto:lastname" />
      <xsl:text>",&#10;</xsl:text>
      <xsl:text>        "guide_id": "</xsl:text>
      <xsl:value-of
              select="@id" />
      <xsl:text>",&#10;</xsl:text>
      <xsl:text>        "nationality": "</xsl:text>
      <xsl:value-of
              select="cto:nationality" />
      <xsl:text>",&#10;</xsl:text>
      <xsl:text>        "languages": [</xsl:text>
      <xsl:for-each
              select="cto:spoken_languages/cto:language">
              <xsl:text>"</xsl:text>
          <xsl:value-of select="." />
          <xsl:text>"</xsl:text>
              <!-- We make sure to add a comma after each language except for the last one to
              maintain a valid JSON syntax -->
          <xsl:if
                   test="position() != last()">,</xsl:if>
         </xsl:for-each>
      <xsl:text>],&#10;</xsl:text>
      <xsl:text>        "tours_assigned": </xsl:text>
      <xsl:value-of
              select="count($tours_led)" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>        "total_capacity": </xsl:text>
      <xsl:value-of
              select="sum($tours_led/cto:tour_availability/cto:capacity)" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>        "total_participants": </xsl:text>
      <xsl:value-of
              select="sum($tours_led/cto:tour_availability/cto:current_number_of_participants)" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>        "workload_efficiency_percent": </xsl:text>
         <!-- Here we calculate the workload efficiency as a percentage of participants to capacity
         for the tours led by
       the guide -->
      <xsl:value-of
              select="format-number((sum($tours_led/cto:tour_availability/cto:current_number_of_participants) div sum($tours_led/cto:tour_availability/cto:capacity)) * 100, '0.00')" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>      }</xsl:text>
         <!-- We make sure to add a comma after each language except for the last one to maintain a
         valid JSON syntax -->
      <xsl:if
              test="position() != last()">,</xsl:if>
    </xsl:template>

    <!-- Payment analytics -->
    <xsl:template match="cto:tours" mode="payment-analytics">
         <!-- We declare a variable "all-payments" that selects all payment elements within
         bookings of bikes in tours  -->
      <xsl:variable name="all-payments"
              select="cto:tour/cto:bikes/cto:bike/cto:booking/cto:payment" />
      <xsl:text>    "payment_analytics": {&#10;</xsl:text>
      <xsl:text>      "by_status": [</xsl:text>
         <!-- We iterate over each distinct payment status found in the dataset using the
         distinct-values() function  -->
      <xsl:for-each
              select="distinct-values(cto:tour/cto:bikes/cto:bike/cto:booking/cto:payment/cto:payment_status)">
              <xsl:variable name="status" select="." />
          <xsl:text>&#10;        {&#10;</xsl:text>
          <xsl:text>          "status": "</xsl:text>
          <xsl:value-of
                   select="$status" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "count": </xsl:text>
          <xsl:value-of
                   select="count($all-payments[cto:payment_status = $status])" />
          <xsl:text>&#10;</xsl:text>
          <xsl:text>        }</xsl:text>
              <!-- We make sure to add a comma after each language except for the last one to
              maintain a valid JSON syntax -->
          <xsl:if
                   test="position() != last()">,</xsl:if>
         </xsl:for-each>
      <xsl:text>&#10;      ],&#10;</xsl:text>
      <xsl:text>      "by_method": [</xsl:text>
         <!-- We iterate over each distinct payment method found in the dataset using the
         distinct-values() function -->
      <xsl:for-each
              select="distinct-values(cto:tour/cto:bikes/cto:bike/cto:booking/cto:payment/cto:method)">
              <xsl:variable name="method" select="." />
          <xsl:text>&#10;        {&#10;</xsl:text>
          <xsl:text>          "method": "</xsl:text>
          <xsl:value-of
                   select="$method" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "count": </xsl:text>
          <xsl:value-of
                   select="count($all-payments[cto:method = $method])" />
          <xsl:text>&#10;</xsl:text>
          <xsl:text>        }</xsl:text>
              <!-- We make sure to add a comma after each language except for the last one to
              maintain a valid JSON syntax -->
          <xsl:if
                   test="position() != last()">,</xsl:if>
         </xsl:for-each>
      <xsl:text>&#10;      ]&#10;</xsl:text>
      <xsl:text>    }</xsl:text>
    </xsl:template>

    <!-- Operational efficiency metrics -->
    <xsl:template name="operational-efficiency">
         <!-- We declare three variables:
      - "all-tours": selects all tour elements within tours.
      - "all-bikes": selects all bike elements within tours.
      - "all-payments": selects all payment elements within bookings of bikes in tours. -->
      <xsl:variable name="all-tours"
              select="cto:tours/cto:tour" />
      <xsl:variable
              name="all-bikes"
              select="cto:tours/cto:tour/cto:bikes/cto:bike" />
      <xsl:variable name="all-payments"
              select="cto:tours/cto:tour/cto:bikes/cto:bike/cto:booking/cto:payment" />
      <xsl:text>    "operational_efficiency": {&#10;</xsl:text>
      <xsl:text>      "overall_bike_utilization_percent": </xsl:text>
      <xsl:value-of
              select="format-number((count($all-bikes[cto:booking]) div count($all-bikes)) * 100, '0.00')" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "overall_tour_occupancy_percent": </xsl:text>
      <xsl:value-of
              select="format-number((sum($all-tours/cto:tour_availability/cto:current_number_of_participants) div sum($all-tours/cto:tour_availability/cto:capacity)) * 100, '0.00')" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "payment_completion_rate_percent": </xsl:text>
      <xsl:value-of
              select="format-number((count($all-payments[cto:payment_status = 'paid']) div count($all-payments)) * 100, '0.00')" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "guides_with_assignments": </xsl:text>
         <!-- Using //tours allows us to search for tour elements anywhere in the document to find
         guides assigned to
       tours -->
      <xsl:value-of
              select="count(cto:guides/cto:guide[@id = //cto:tour/cto:guide/@idref])" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "guides_without_assignments": </xsl:text>
         <!-- Here too, we calcultate the number of guides without assignments by subtracting the
         count of guides with
       assignments from the total count of guides.
       This ensures we capture all guides who are not currently assigned to any tours. -->
      <xsl:value-of
              select="count(cto:guides/cto:guide) - count(cto:guides/cto:guide[@id = //cto:tour/cto:guide/@idref])" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>    }</xsl:text>
    </xsl:template>

</xsl:stylesheet>