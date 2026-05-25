<?xml version="1.0" encoding="UTF-8"?>
<!-- This XSLT transforms XML data into JSON format for business intelligence purposes.
    It looks for key metrics such as total revenue, number of bookings, and average booking value,
    and aggregates them to provide insights. As multiple currencies were involved, it includes
    a currency conversion step to standardize all amounts to euros. This function is called for
    on multiple occasions throughout the transformation process.
    We also used multiple xsl functions such as count(), sum(), distinct-values(), and more to manipulate
    and analyze the data effectively. 

    Example command to run the transformation (from project root):

     java -cp libs/saxon-he-12.4.jar:libs/xmlresolver-5.1.1.jar \
     net.sf.saxon.Transform \
     -s:dataset/merged_datasets.xml \
     -xsl:xsl/07_business_analysis_to_json.xsl \
     -o:outputs/json/07_business_analysis.json
-->

<xsl:stylesheet version="2.0"
      xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
      xmlns:xs="http://www.w3.org/2001/XMLSchema"
      xmlns:cto="http://city-tour-operator.org/cto"
      xmlns:local="http://local-functions"
      exclude-result-prefixes="xs cto local"> <!-- Using a namespace cto:-->

      <xsl:output method="text" encoding="UTF-8" />
      <!-- We use strip-space to remove unnecessary whitespace from the XML input to simplify processing -->
      <xsl:strip-space elements="*" />

      <!-- Currency conversion rates to EUR (as of November 2025). This would generally be updated
      in real time through an API call, but for the purpose of this course we rendered it static -->
      <xsl:variable name="currency-rates">
            <rate currency="EUR" value="1.00" />
      <rate currency="USD" value="0.92" />
      <rate currency="GBP"
                  value="1.17" />
      <rate currency="JPY" value="0.0062" />
      <rate currency="CAD" value="0.66" />
      <rate
                  currency="AUD" value="0.60" />
      <rate currency="CHF" value="1.05" />
      <rate currency="NOK"
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
                        <!-- It converts the amount value with the pertinent rate. The variable $rate represents an XML
                        node or attribute value, which is a string, so we need to explicitly convert it into a numeric value -->
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
      Note: There is no direct indent/newline declaration to format JSON output automatically which is why
      we needed to explicitely add &#10; everywhere for readability purposes -->
      <xsl:template match="/">
            <xsl:text>{&#10;</xsl:text>
            <!-- Create a root key/value pair. The value will contain all the data we extract from the dataset -->
      <xsl:text>  "business_intelligence": {&#10;</xsl:text>
      <xsl:apply-templates select="cto:data" />
      <xsl:text>  }&#10;</xsl:text>
      <xsl:text>}</xsl:text>
      </xsl:template>


      <!-- Data template -->
      <xsl:template match="cto:data">
            <!-- We apply-templates in different modes to extract various business insights. Here we will
        loop over the same content multiple times to extract different perspectives -->
      <xsl:apply-templates select="cto:tours" mode="market-analysis" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:apply-templates
                  select="cto:tours" mode="revenue-analytics" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:apply-templates
                  select="cto:packages" mode="package-roi" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:apply-templates
                  select="cto:tours" mode="pricing-strategy" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:call-template
                  name="performance-summary" />
      </xsl:template>


      <!-- Market analysis: Tours by category and popularity -->
      <xsl:template match="cto:tours" mode="market-analysis">
            <!-- Declaring a variable that contains all the tours for later use -->
       <xsl:variable name="all-tours" select="cto:tour" />
      <xsl:text>    "market_analysis": {&#10;</xsl:text>
            <!-- First we extract tours by category -->
      <xsl:text>      "tours_by_category": [</xsl:text>
            <!-- The xsl:for-each let's us iterate over each distinct category found in the tours
            We use distinct-values() to get unique categories (specified in data/tours/tour/category-->
      <xsl:for-each
                  select="distinct-values(cto:tour/cto:category)">
                  <!-- We declare two variables:
                  - cat: holds the current category being processed in the loop
                  - tours: contains all tours that belong to the current category -->
          <xsl:variable name="cat" select="." />
          <xsl:variable
                        name="tours"
                        select="$all-tours[cto:category = $cat]" />
          <xsl:text>&#10;        {&#10;</xsl:text>
          <xsl:text>          "category": "</xsl:text>
          <xsl:value-of
                        select="$cat" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "count": </xsl:text>
                  <!-- We count the number of tours in the current category -->
          <xsl:value-of
                        select="count($tours)" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "avg_distance_km": </xsl:text>
                  <!-- We extract the average distance of tours in the current category, using the avg() function.
                  format-number() is used to format the number to 2 decimal places. We set a value by default (0.00)
                  if no tours are found for the category -->
          <xsl:value-of
                        select="format-number(avg($tours/cto:distance), '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "avg_price_eur": </xsl:text>
                  <!-- Here we convert each tour price to euros using the local:convertToEur function defined earlier,
                  then calculate the average price for the category. We specify the values of the two variables
                  expected by convertToEur and make sure they are correctly passed in the right format and order.
                  We set a value by default (0.00) if no tours are found for the category -->
          <xsl:value-of
                        select="format-number(avg(
              for $tour in $tours
              return local:convertToEur(
                  number($tour/cto:price/cto:amount),
                  string($tour/cto:price/cto:currency)
              )
          ), '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "avg_duration_days": </xsl:text>
          <xsl:value-of
                        select="format-number(avg($tours/cto:duration/cto:duration_days), '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "total_capacity": </xsl:text>
                  <!-- We use the sum() function to calculate the total capacity of all tours in the current category -->
          <xsl:value-of
                        select="sum($tours/cto:tour_availability/cto:capacity)" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "total_participants": </xsl:text>
                  <!-- We also calculate the total number of participants across all tours in the category -->
          <xsl:value-of
                        select="sum($tours/cto:tour_availability/cto:current_number_of_participants)" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "market_share_percent": </xsl:text>
                  <!-- Here we calculate the market share of the current category by dividing the number of tours
                  in the category by the total number of tours, then multiplying by 100 to get a percentage. We set a
                  value by default (0.00) if no tours are found for the category -->
          <xsl:value-of
                        select="format-number((count($tours) div count($all-tours)) * 100, '0.00')" />
          <xsl:text>&#10;</xsl:text>
          <xsl:text>        }</xsl:text>
          <xsl:if
                        test="position() != last()">,</xsl:if>
            </xsl:for-each>
      <xsl:text>&#10;      ],&#10;</xsl:text>
      <xsl:text>      "tours_popularity": [</xsl:text>
            <!-- In a new for-each, we iterate over all tours to determine their popularity based on booking counts. -->
             <xsl:for-each
                  select="cto:tour">
                  <!--  We sort:
                  - the data-type so that sorting is done numerically. This value looks at the count of bookings for each tour,
                  i.e. the number of bikes that have a booking child element.
                  - the order "descending" so that the tours with the highest number of bookings come first -->
           <xsl:sort select="count(cto:bikes/cto:bike/cto:booking)" data-type="number"
                        order="descending" />
                  <!-- We declare the variable "bookings" that counts the number of bookings for the current tour -->
           <xsl:variable
                        name="bookings" select="count(cto:bikes/cto:bike/cto:booking)" />
          <xsl:text>&#10;        {&#10;</xsl:text>
                  <!-- We gather simple elements available directly in the dataset such as tour_name, category,
                  tour_availability/capacity, etc., but also calculated metrics like occupancy rate and price in euros. -->
          <xsl:text>          "tour_name": "</xsl:text>
          <xsl:value-of
                        select="cto:tour_name" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "category": "</xsl:text>
          <xsl:value-of
                        select="cto:category" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "total_bookings": </xsl:text>
          <xsl:value-of
                        select="$bookings" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "capacity": </xsl:text>
          <xsl:value-of
                        select="cto:tour_availability/cto:capacity" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "occupancy_rate_percent": </xsl:text>
                  <!-- Calculates the occupancy rate as the ratio of current participants to capacity, as a percentage -->
          <xsl:value-of
                        select="format-number((cto:tour_availability/cto:current_number_of_participants div cto:tour_availability/cto:capacity) * 100, '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "price_eur": </xsl:text>
                  <!-- Calls the local:convertToEur function to convert the price to euros. -->
          <xsl:value-of
                        select="format-number(local:convertToEur(number(cto:price/cto:amount), string(cto:price/cto:currency)), '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "distance_km": </xsl:text>
          <xsl:value-of
                        select="cto:distance" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "start_date": "</xsl:text>
          <xsl:value-of
                        select="cto:duration/cto:start_date" />
          <xsl:text>"&#10;</xsl:text>
          <xsl:text>        }</xsl:text>
                  <!-- We need to add a conditional element to avoid a trailing comma after the last item in the list.
                  Here we check if the current position is not the last one of the for-each loop -->
          <xsl:if
                        test="position() != last()">,</xsl:if>
            </xsl:for-each>
      <xsl:text>&#10;      ]&#10;</xsl:text>
      <xsl:text>    }</xsl:text>
      </xsl:template>


      <!-- Revenue analytics -->
      <xsl:template match="cto:tours" mode="revenue-analytics">
            <!-- Declaring two variables
            - all-bookings: contains all bookings and all tours for later use
            - all-tours: contains all tours for later use -->
       <xsl:variable name="all-bookings"
                  select="cto:tour/cto:bikes/cto:bike/cto:booking" />
      <xsl:variable
                  name="all-tours" select="cto:tour" />
      <xsl:text>    "revenue_analytics": {&#10;</xsl:text>
      <xsl:text>      "total_revenue_eur": </xsl:text>
            <!-- Loops over all bookings to calculate the total revenue in euros
             by converting each booking amount using the local:convertToEur function -->
      <xsl:value-of
                  select="format-number(sum(
          for $booking in $all-bookings
          return local:convertToEur(
              number($booking/cto:payment/cto:amount_paid),
              string($booking/cto:payment/cto:currency)
          )
      ), '0.00')" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "average_booking_value_eur": </xsl:text>
            <!-- Loops over all bookings to calculate the average booking value in euros by converting
            each booking amount using the local:convertToEur function. -->
      <xsl:value-of
                  select="format-number(avg(
          for $booking in $all-bookings
          return local:convertToEur(
              number($booking/cto:payment/cto:amount_paid),
              string($booking/cto:payment/cto:currency)
          )
      ), '0.00')" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "revenue_by_tour": [</xsl:text>
            <!-- We use a for-each to iterate over all tours to calculate revenue metrics for each tour. -->
      <xsl:for-each
                  select="cto:tour">
                  <!-- We sort the tours by their total revenue in euros, calculated by summing the amounts paid in
                  all bookings for each tour after converting them to euros using the local:convertToEur function.
                  We specify the data-type as "number" to ensure correct numerical sorting and sort it
                  by descending order so that the tours with the highest revenue appear first. -->
           <xsl:sort
                        select="sum(
              for $booking in bikes/bike/booking
              return local:convertToEur(
                  number($booking/cto:payment/cto:amount_paid),
                  string($booking/cto:payment/cto:currency)
              )
          )"
                        data-type="number" order="descending" />
                  <!-- We need to declare two more variables
               - tour-bookings: contains all bookings for the current tour
               - revenue: calculates the total revenue for the current tour by summing the amounts paid in
               all its bookings after converting them to euros using the local:convertToEur function -->
          <xsl:variable name="tour-bookings"
                        select="cto:bikes/cto:bike/cto:booking" />
          <xsl:variable name="revenue"
                        select="sum(
              for $booking in $tour-bookings
              return local:convertToEur(
                  number($booking/cto:payment/cto:amount_paid),
                  string($booking/cto:payment/cto:currency)
              )
          )" />
          <xsl:text>&#10;        {&#10;</xsl:text>
          <xsl:text>          "tour_name": "</xsl:text>
          <xsl:value-of
                        select="cto:tour_name" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "category": "</xsl:text>
          <xsl:value-of
                        select="cto:category" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "revenue_eur": </xsl:text>
          <xsl:value-of
                        select="format-number($revenue, '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "bookings_count": </xsl:text>
          <xsl:value-of
                        select="count($tour-bookings)" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "avg_revenue_per_booking_eur": </xsl:text>
                  <!-- We apply a conditional logic to avoid division by zero. The test ensures that we only
                  perform the division if there is at least one booking for the tour. If there are no bookings,
                  we return 0 as the average revenue per booking -->
          <xsl:choose>
                        <xsl:when test="count($tour-bookings) > 0">
                              <xsl:value-of select="format-number($revenue div count($tour-bookings), '0.00')" />
                        </xsl:when>
                        <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
          <xsl:text>&#10;</xsl:text>
          <xsl:text>        }</xsl:text>
                  <!-- We add a conditional element to avoid a trailing comma after the last item in the list. -->
          <xsl:if
                        test="position() != last()">,</xsl:if>
            </xsl:for-each>
      <xsl:text>&#10;      ],&#10;</xsl:text>
      <xsl:text>      "revenue_by_category": [</xsl:text>
            <!-- New for-each loop that iterates over each distinct tour category to calculate revenue metrics
            aggregated by category. The distinct-values() function is used to get unique categories -->
      <xsl:for-each
                  select="distinct-values(cto:tour/cto:category)">
                  <!-- We declare three new values
                  - cat: holds the current category being processed in the loop
                  - cat-tours: contains all tours that belong to the current category
                  - cat-bookings: contains all bookings for the tours in the current category -->
           <xsl:variable name="cat" select="." />
          <xsl:variable
                        name="cat-tours"
                        select="$all-tours[cto:category = $cat]" />
          <xsl:variable name="cat-bookings"
                        select="$cat-tours/cto:bikes/cto:bike/cto:booking" />
          <xsl:text>&#10;        {&#10;</xsl:text>
          <xsl:text>          "category": "</xsl:text>
          <xsl:value-of
                        select="$cat" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "revenue_eur": </xsl:text>
                  <!-- We calculate the total revenue for the current category by summing the amounts paid in all
                  bookings for tours in that category after converting them to euros using the local:convertToEur function. -->
          <xsl:value-of
                        select="format-number(sum(
              for $booking in $cat-bookings
              return local:convertToEur(
                  number($booking/cto:payment/cto:amount_paid),
                  string($booking/cto:payment/cto:currency)
              )
          ), '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "bookings_count": </xsl:text>
                  <!-- Using count() we determine the total number of bookings for the current category. -->
          <xsl:value-of
                        select="count($cat-bookings)" />
          <xsl:text>&#10;</xsl:text>
          <xsl:text>        }</xsl:text>
                  <!-- We make sure to avoid a trailing comma after the last item in the list. -->
          <xsl:if
                        test="position() != last()">,</xsl:if>
            </xsl:for-each>
      <xsl:text>&#10;      ]&#10;</xsl:text>
      <xsl:text>    }</xsl:text>
      </xsl:template>


      <!-- Package ROI analysis -->
      <xsl:template match="cto:packages" mode="package-roi">
            <xsl:text>    "package_roi": [</xsl:text>
            <!-- We iterate over each package to analyze its ROI -->
      <xsl:for-each select="cto:package">
                  <!-- We declare three variables:
                  - package_id: holds the ID of the current package
                  - bookings_with_package: contains all bookings that include the current package
                  - discount_value: calculates the total discount value given for the current package across all its bookings -->
           <xsl:variable name="package_id" select="@id" />
          <xsl:variable
                        name="bookings_with_package" select="//cto:booking[cto:package/@idref = $package_id]" />
                  <!-- There is a small specificity here, as we multiply the amount paid
                   by the reduction percentage to get the discount value -->
          <xsl:variable
                        name="discount_value"
                        select="sum(
              for $booking in $bookings_with_package
              return local:convertToEur(
                  number($booking/cto:payment/cto:amount_paid),
                  string($booking/cto:payment/cto:currency)
              ) * (number(cto:reduction) div 100)
          )" />
          <xsl:text>&#10;      {&#10;</xsl:text>
          <xsl:text>        "package_name": "</xsl:text>
          <xsl:value-of
                        select="cto:name" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>        "code": "</xsl:text>
          <xsl:value-of
                        select="cto:code" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>        "discount_percent": </xsl:text>
          <xsl:value-of
                        select="cto:reduction" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>        "times_used": </xsl:text>
          <xsl:value-of
                        select="count($bookings_with_package)" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>        "total_discount_given_eur": </xsl:text>
          <xsl:value-of
                        select="format-number($discount_value, '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>        "revenue_with_package_eur": </xsl:text>
                  <!-- We loop over all bookings that used the current package to calculate
                   the total revenue generated from those bookings -->
          <xsl:value-of
                        select="format-number(sum(
              for $booking in $bookings_with_package
              return local:convertToEur(
                  number($booking/cto:payment/cto:amount_paid),
                  string($booking/cto:payment/cto:currency)
              )
          ), '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>        "adoption_rate_percent": </xsl:text>
          <xsl:value-of
                        select="format-number((count($bookings_with_package) div count(//cto:booking)) * 100, '0.00')" />
          <xsl:text>&#10;</xsl:text>
          <xsl:text>      }</xsl:text>
          <xsl:if
                        test="position() != last()">,</xsl:if>
            </xsl:for-each>
      <xsl:text>&#10;    ]</xsl:text>
      </xsl:template>


      <!-- Pricing strategy insights -->
      <xsl:template match="cto:tours" mode="pricing-strategy">
            <!-- We declare a variable that contains all bikes for later use -->
       <xsl:variable name="all-bikes"
                  select="cto:tour/cto:bikes/cto:bike" />
      <xsl:text>    "pricing_strategy": {&#10;</xsl:text>
      <xsl:text>      "price_per_km_analysis": [</xsl:text>
            <!-- We use a for-each to iterate over all tours to analyze their price per kilometer. -->
      <xsl:for-each
                  select="cto:tour">
                  <!-- We sort the tours by their price per kilometer in euros, calculated by converting
                  the tour price to euros, we specify the data type as number for accurate sorting and the
                  descending order so that the most expensive tours per kilometer appear first -->
           <xsl:sort
                        select="local:convertToEur(number(cto:price/cto:amount), string(cto:price/cto:currency)) div cto:distance"
                        data-type="number" order="descending" />
                  <!-- We declare two variables:
                  - price_eur: converts the tour price to euros using the local:convertToEur function
                  - price_per_km: calculates the price per kilometer by dividing the price in euros by the tour distance -->
          <xsl:variable name="price_eur"
                        select="local:convertToEur(number(cto:price/cto:amount), string(cto:price/cto:currency))" />
          <xsl:variable
                        name="price_per_km" select="$price_eur div cto:distance" />
          <xsl:text>&#10;        {&#10;</xsl:text>
          <xsl:text>          "tour_name": "</xsl:text>
          <xsl:value-of
                        select="cto:tour_name" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "category": "</xsl:text>
          <xsl:value-of
                        select="cto:category" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "price_eur": </xsl:text>
          <xsl:value-of
                        select="format-number($price_eur, '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "distance_km": </xsl:text>
          <xsl:value-of
                        select="cto:distance" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "price_per_km_eur": </xsl:text>
          <xsl:value-of
                        select="format-number($price_per_km, '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "occupancy_rate_percent": </xsl:text>
                  <!-- Here we calculate the occupancy rate as the ratio of current participants to capacity
                   expressed as a percentage. -->
          <xsl:value-of
                        select="format-number((cto:tour_availability/cto:current_number_of_participants div cto:tour_availability/cto:capacity) * 100, '0.00')" />
          <xsl:text>&#10;</xsl:text>
          <xsl:text>        }</xsl:text>
                  <!-- We add a conditional element to avoid a trailing comma after the last item in the list. -->
          <xsl:if
                        test="position() != last()">,</xsl:if>
            </xsl:for-each>
      <xsl:text>&#10;      ],&#10;</xsl:text>
      <xsl:text>      "bike_rental_profitability": [</xsl:text>
            <!-- We iterate over each distinct bike type to analyze rental profitability using distinct-values() -->
      <xsl:for-each
                  select="distinct-values(cto:tour/cto:bikes/cto:bike/cto:bike_type/cto:type)">
                  <xsl:variable name="type" select="." />
                  <!-- We declare two variables:
                  - bikes: contains all bikes of the current type
                  - rented_bikes: contains only the bikes of the current type that have been rented (i.e., have a booking) -->
          <xsl:variable name="bikes"
                        select="$all-bikes[cto:bike_type/cto:type = $type]" />
          <xsl:variable name="rented_bikes"
                        select="$bikes[cto:booking]" />
          <xsl:text>&#10;        {&#10;</xsl:text>
          <xsl:text>          "bike_type": "</xsl:text>
                  <!-- We extract the value of the current bike type being processed in the loop. -->
          <xsl:value-of
                        select="$type" />
          <xsl:text>",&#10;</xsl:text>
          <xsl:text>          "avg_rental_price_eur": </xsl:text>
                  <!-- We calculate the average rental price for bikes of the current type by converting each bike's
                  rental price to euros using the local:convertToEur function. -->
          <xsl:value-of
                        select="format-number(avg(
              for $bike in $bikes
              return local:convertToEur(
                  number($bike/cto:rental_price_per_day/cto:amount),
                  string($bike/cto:rental_price_per_day/cto:currency)
              )
          ), '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "rental_frequency_percent": </xsl:text>
          <xsl:value-of
                        select="format-number((count($rented_bikes) div count($bikes)) * 100, '0.00')" />
          <xsl:text>,&#10;</xsl:text>
          <xsl:text>          "estimated_revenue_eur": </xsl:text>
                  <!-- We calculate the estimated revenue generated from renting bikes of the current type by summing
                  the rental prices of all rented bikes after converting them to euros using the local:convertToEur function. -->
          <xsl:value-of
                        select="format-number(sum(
              for $bike in $rented_bikes
              return local:convertToEur(
                  number($bike/cto:rental_price_per_day/cto:amount),
                  string($bike/cto:rental_price_per_day/cto:currency)
              )
          ), '0.00')" />
          <xsl:text>&#10;</xsl:text>
          <xsl:text>        }</xsl:text>
                  <!-- We make sure to avoid a trailing comma after the last item in the list. -->
          <xsl:if
                        test="position() != last()">,</xsl:if>
            </xsl:for-each>
      <xsl:text>&#10;      ]&#10;</xsl:text>
      <xsl:text>    }</xsl:text>
      </xsl:template>


      <!-- Performance summary -->
      <xsl:template name="performance-summary">
            <!-- We declare three variables:
             - all-tours: contains all tours for later use
              - all-bookings: contains all bookings for later use
              - total-revenue: calculates the total revenue across all bookings by converting each booking amount to euros
               using the local:convertToEur function -->
       <xsl:variable name="all-tours" select="cto:tours/cto:tour" />
      <xsl:variable
                  name="all-bookings"
                  select="cto:tours/cto:tour/cto:bikes/cto:bike/cto:booking" />
      <xsl:variable name="total-revenue"
                  select="sum(
          for $booking in $all-bookings
          return local:convertToEur(
              number($booking/cto:payment/cto:amount_paid),
              string($booking/cto:payment/cto:currency)
          )
      )" />
      <xsl:text>    "performance_summary": {&#10;</xsl:text>
      <xsl:text>      "total_revenue_eur": </xsl:text>
      <xsl:value-of
                  select="format-number($total-revenue, '0.00')" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "total_bookings": </xsl:text>
      <xsl:value-of
                  select="count($all-bookings)" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "avg_revenue_per_booking_eur": </xsl:text>
      <xsl:value-of
                  select="format-number($total-revenue div count($all-bookings), '0.00')" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "overall_occupancy_rate_percent": </xsl:text>
            <!-- We calculate the overall occupancy rate across all tours by dividing the total number of participants
            by the total capacity, then multiplying by 100 to express it as a percentage. -->
      <xsl:value-of
                  select="format-number((sum($all-tours/cto:tour_availability/cto:current_number_of_participants) div sum($all-tours/cto:tour_availability/cto:capacity)) * 100, '0.00')" />
      <xsl:text>,&#10;</xsl:text>
      <xsl:text>      "best_performing_category": "</xsl:text>
            <!-- We iterate over each distinct tour category to determine which one has generated the highest revenue. -->
      <xsl:for-each
                  select="distinct-values(cto:tours/cto:tour/cto:category)">
                  <!-- We sort the categories by their total revenue in euros, calculated by summing the amounts paid in
                  all bookings for tours in that category after converting them to euros using the local:convertToEur function.
                  We specify the data-type as "number" to ensure correct numerical sorting and sort it by descending order
                  so that the category with the highest revenue appears first. -->   
           <xsl:sort
                        select="sum(
              for $booking in $all-tours[category = current()]/bikes/bike/booking
              return local:convertToEur(
                  number($booking/cto:payment/cto:amount_paid),
                  string($booking/cto:payment/cto:currency)
              )
          )"
                        data-type="number" order="descending" />
                  <!-- We make sure to only output the first category after sorting, which is the best performing one. -->
           <xsl:if test="position() = 1">
                        <xsl:value-of select="." />
                  </xsl:if>
            </xsl:for-each>
      <xsl:text>",&#10;</xsl:text>
      <xsl:text>      "package_adoption_rate_percent": </xsl:text>
      <xsl:value-of
                  select="format-number((count($all-bookings[cto:package]) div count($all-bookings)) * 100, '0.00')" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>    }</xsl:text>
      </xsl:template>
</xsl:stylesheet>