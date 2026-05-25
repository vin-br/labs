<?xml version="1.0" encoding="UTF-8"?>
<!-- This XSLT stylesheet is designed to anonymize personally identifiable information (PII)
   from an XML dataset containing tour, guide, package, client, and booking information.
   We keep the business-relevant data while removing or masking sensitive details to ensure GDPR
compliance.
   The stylesheet defines functions to generate anonymous IDs and hash strings for consistent
anonymization.
 
   Example command to run the transformation (from project root):

   java -cp libs/saxon-he-12.4.jar:libs/xmlresolver-5.1.1.jar \
     net.sf.saxon.Transform \
     -xsl:xsl/09_merge_datasets_to_xml.xsl \
     -o:outputs/xml/09_merged_datasets_to_xml.xml \
     -it:main \
     'source-files=../dataset/sub_datasets/dataset_1.xml ../dataset/sub_datasets/dataset_2.xml
../dataset/sub_datasets/dataset_3.xml ../dataset/sub_datasets/dataset_4.xml'
-->

<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:cto="http://city-tour-operator.org/cto"
  xmlns:local="http://local-functions"
  xmlns="http://city-tour-operator.org/cto"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  exclude-result-prefixes="xs cto local"> <!-- Using a namespace cto:-->

  <xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="no" />

  <!-- We define a function generateAnonymousId that generates an anonymous ID based on a given
  prefix and position. This helps in creating unique but non-identifiable IDs for entities like clients and guides. -->
  <xsl:function name="local:generateAnonymousId" as="xs:string">
    <!-- The function takes two parameters: 
      - prefix: a string to prefix the anonymous ID
      - position: an integer to ensure uniqueness -->
  <xsl:param name="prefix"
      as="xs:string" />
  <xsl:param
      name="position" as="xs:integer" />
    <!-- The function concatenates the prefix with '_anon_' and a zero-padded position number to
   create the anonymous ID. -->
  <xsl:sequence
      select="concat($prefix, '_anon_', format-number($position, '0000'))" />
  </xsl:function>

  <!-- We define a second function hashString for consistent anonymization through hashing strings. -->
  <xsl:function name="local:hashString" as="xs:string">
    <!-- The function takes one parameter, input which is the string to be hashed -->
  <xsl:param name="input" as="xs:string" />
    <!-- It returns a complex hashed representation of the input string to prevent collisions.
   We use multiple characteristics: length, first char, last char, middle char, and character count modulo -->
  <xsl:variable
      name="len"
      select="string-length($input)" />
  <xsl:variable name="mid" select="ceiling($len div 2)" />
    <!-- - substring($input, 1, 1) returns the first character of the input string because we
   specified
         1 as the starting position and 1 as the length
       - substring($input, $len, 1) returns the last character of the input string because we specified
         $len as the starting position (which is the length of the string) and 1 as the length
       - substring($input, $mid, 1) returns the middle character of the input string because we specified
         $mid as the starting position (which is the ceiling of half the length of the string) and 1 as the length
       - ($len mod 97) gives us the remainder when the length of the string is divided by 97 -->
  <xsl:sequence
      select="concat(
      'HASH_',
      $len,
      '_',
      substring($input, 1, 1),
      substring($input, $len, 1),
      '_',
      substring($input, $mid, 1),
      '_',
      ($len mod 97)
    )" />
  </xsl:function>

  <!-- Root template -->
  <xsl:template match="/">
    <!-- We us xsl:comment to insert comments in the output XML file, for example this lets us now when the data was
    anonymized through the select="current-dateTime()" which is an xsl function that returns the current date and time -->
<xsl:comment> ANONYMIZED DATA - PII REMOVED FOR PRIVACY COMPLIANCE </xsl:comment>
<xsl:comment> Generated on: <xsl:value-of select="current-dateTime()"/> </xsl:comment>
  <xsl:apply-templates />
  </xsl:template>

  <!-- We copy the data structure
 
 We MUST set a higher priority (1) for this template compared to the generic templates (0.5)
 defined later, otherwise those generic templates would match first and we would not be able to
 process the data element correctly. The schema path is transformed from ../../schema/schema.xsd
 to ../schema/schema.xsd in the output XML if we don't set the priority explicitly.
 -->
  <xsl:template match="cto:data" priority="1">
    <data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <xsl:attribute name="xsi:schemaLocation">http://city-tour-operator.org/cto ../../schema/schema.xsd</xsl:attribute>
      <xsl:apply-templates select="cto:tours" />
      <xsl:apply-templates select="cto:guides" />
      <xsl:apply-templates select="cto:packages" />
    </data>
  </xsl:template>

  <!-- Template for tours -->
  <xsl:template match="cto:tours">
    <tours>
      <xsl:apply-templates select="cto:tour" />
    </tours>
  </xsl:template>

  <xsl:template match="cto:tour">
    <tour>
      <xsl:apply-templates select="cto:tour_name" />
      <xsl:apply-templates select="cto:company" />
      <xsl:apply-templates select="cto:short_description" />
      <xsl:apply-templates select="cto:long_description" />
      <xsl:apply-templates select="cto:category" />
      <xsl:apply-templates select="cto:distance" />
      <xsl:apply-templates select="cto:duration" />
      <xsl:apply-templates select="cto:price" />
      <xsl:apply-templates select="cto:guide" />
      <xsl:apply-templates select="cto:tour_availability" />
      <xsl:apply-templates select="cto:starting_point" />
      <xsl:apply-templates select="cto:final_destination" />
      <xsl:apply-templates select="cto:tour_steps" />
      <xsl:apply-templates select="cto:bikes" />
    </tour>
  </xsl:template>

  <!-- Anonymize company contact information: we duplicate the content of the company element from
  the original XML but replace sensitive contact details with anonymized placeholders -->
  <xsl:template match="cto:company">
    <company>
      <!-- We use the xsl function copy-of to duplicate the name element from the original XML -->
      <xsl:copy-of select="cto:name" copy-namespaces="no" />
      <contact>
        <!-- Use hash to create consistent but anonymized email based on company name and original
       contact -->
        <email>
          <xsl:value-of
            select="concat(
          'company.',
          local:hashString(concat(cto:name, '_', cto:contact/cto:email)),
          '@privacy.example'
        )" />
        </email>
        <phone_number>+00-000-000-0000</phone_number>
      </contact>
      <!-- Keep address at city/country level only.
      We apply a condition: if the address element exists, we create a new address element with street replaced by [REDACTED]
      If the address element does not exist, we skip it altogether. -->
      <xsl:if test="cto:address">
        <address>
          <street>[REDACTED]</street>
          <xsl:copy-of select="cto:address/cto:city" copy-namespaces="no" />
          <!-- With the same logic we handle the code element -->
          <xsl:if test="cto:address/cto:code">
            <code>[REDACTED]</code>
          </xsl:if>
          <xsl:copy-of select="cto:address/cto:country" copy-namespaces="no" />
        </address>
      </xsl:if>
    </company>
  </xsl:template>

  <!-- Copy most tour elements as-is
  Using | we can match multiple elements in one template -->
  <!-- Copy most tour elements as-is -->
  <xsl:template
    match="cto:tour_name | cto:short_description | cto:long_description | cto:category | cto:distance | cto:price | cto:tour_availability">
    <xsl:element name="{local-name()}">
      <xsl:copy-of select="@*" />
     <xsl:apply-templates select="node()" />
    </xsl:element>
  </xsl:template>

  <!-- Guide reference in tour -> recreate without namespace -->
  <xsl:template match="cto:tour/cto:guide">
    <guide>
      <xsl:copy-of select="@*" />
    </guide>
  </xsl:template>

  <!-- Duration -> recreate structure -->
  <xsl:template match="cto:duration">
    <duration>
      <xsl:apply-templates select="*" />
    </duration>
  </xsl:template>

  <!-- Tour locations -> recreate structure -->
  <xsl:template match="cto:starting_point | cto:final_destination">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates select="*" />
    </xsl:element>
  </xsl:template>

  <!-- Tour steps -> recreate structure -->
  <xsl:template match="cto:tour_steps">
    <tour_steps>
      <xsl:apply-templates select="*" />
    </tour_steps>
  </xsl:template>

  <!-- Generic template for simple elements (text content only) - LOW PRIORITY -->
  <xsl:template match="cto:*[not(*) and not(parent::cto:tour)]" priority="0.5">
    <xsl:element name="{local-name()}">
      <xsl:copy-of select="@*" />
    <xsl:value-of select="." />
    </xsl:element>
  </xsl:template>

  <!-- Generic template for complex elements (with children) - LOW PRIORITY -->
  <xsl:template
    match="cto:*[* and not(self::cto:company or self::cto:guide or self::cto:booking or self::cto:bike)]"
    priority="0.5">
    <xsl:element name="{local-name()}">
      <xsl:copy-of select="@*" />
    <xsl:apply-templates select="*" />
    </xsl:element>
  </xsl:template>

  <!-- Template for bikes -->
  <xsl:template match="cto:bikes">
    <bikes>
      <xsl:apply-templates select="cto:bike" />
    </bikes>
  </xsl:template>

  <xsl:template match="cto:bike">
    <bike>
      <xsl:attribute name="id" select="@id" />
      <!-- We keep the bike details -->
      <xsl:copy-of select="cto:model" copy-namespaces="no" />
      <xsl:copy-of select="cto:bike_type" copy-namespaces="no" />
      <xsl:copy-of select="cto:gear_count" copy-namespaces="no" />
      <xsl:copy-of select="cto:size" copy-namespaces="no" />
      <xsl:copy-of select="cto:weight" copy-namespaces="no" />
      <xsl:copy-of select="cto:rental_price_per_day" copy-namespaces="no" />
      <xsl:copy-of select="cto:availability" copy-namespaces="no" />
      <!-- Anonymize booking information -->
      <xsl:apply-templates select="cto:booking" />
    </bike>
  </xsl:template>

  <!-- Template for booking, we need to remove all PII, keep only the aggregated data -->
  <xsl:template match="cto:booking">
    <booking>
      <xsl:copy-of select="cto:booking_date" copy-namespaces="no" />
      <xsl:copy-of select="cto:package" copy-namespaces="no" />
      <!-- We replace the client with anonymized version using hash for consistency -->
      <client>
        <identity>
          <firstname>Client</firstname>
          <lastname>
            <!-- Hash based on full client identity to ensure same client always gets same hash -->
            <xsl:value-of
              select="local:hashString(concat(
              cto:client/cto:identity/cto:firstname,
              '_',
              cto:client/cto:identity/cto:lastname,
              '_',
              cto:client/cto:contact/cto:email,
              '_',
              client/nationality
            ))" />
          </lastname>
        </identity>
        <contact>
          <email>client.anonymized@privacy.example</email>
          <phone_number>+00-000-000-0000</phone_number>
        </contact>
        <!-- We keep city and country for geographic analysis but we redact street and code so that privacy is
        maintained -->
        <address>
          <street>[REDACTED]</street>
          <xsl:copy-of select="cto:client/cto:address/cto:city" copy-namespaces="no" />
          <xsl:if test="cto:client/cto:address/cto:code">
            <code>[REDACTED]</code>
          </xsl:if>
          <xsl:copy-of select="cto:client/cto:address/cto:country" copy-namespaces="no" />
        </address>
        <!-- We keep the nationality for statistical purposes -->
        <xsl:copy-of select="cto:client/cto:nationality" copy-namespaces="no" />
        <!-- We remove the emergency contact content completely -->
        <emergency_contact>
          <identity>
            <firstname>Emergency</firstname>
            <lastname>Contact</lastname>
          </identity>
          <phone_number>+00-000-000-0000</phone_number>
          <relation>[REDACTED]</relation>
        </emergency_contact>
      </client>
      <!-- We keep the payment information -->
      <payment>
        <xsl:copy-of select="cto:payment/cto:amount_paid" copy-namespaces="no" />
        <xsl:copy-of select="cto:payment/cto:left_to_be_paid" copy-namespaces="no" />
        <xsl:copy-of select="cto:payment/cto:currency" copy-namespaces="no" />
        <xsl:copy-of select="cto:payment/cto:method" copy-namespaces="no" />
        <xsl:copy-of select="cto:payment/cto:payment_status" copy-namespaces="no" />
      </payment>
    </booking>
  </xsl:template>

  <!-- Template for guides -->
  <xsl:template match="cto:guides">
    <guides>
      <xsl:apply-templates select="cto:guide" />
    </guides>
  </xsl:template>

  <!-- Template for guide
  We cannot just match guide directly because they appear in multiple contexts tour/guide or
  guides/guide. We need to anonymize data regarding the guides -->
  <xsl:template match="cto:guides/cto:guide">
    <guide>
      <!-- The guide element contains an attribute id that we need to preserve using xsl:attribute -->
      <xsl:attribute name="id" select="@id" />
      <!-- We anonymize both first and last name using hash for consistency.
      We hash based on original identity and contact info to ensure same guide always gets same hash -->
      <identity>
        <firstname>Guide</firstname>
        <lastname>
          <!-- Hash based on guide's original identity and contact to ensure uniqueness and
         consistency -->
          <xsl:value-of
            select="local:hashString(concat(
          cto:identity/cto:firstname,
          '_',
          cto:identity/cto:lastname,
          '_',
          cto:contact/cto:email,
          '_',
          cto:nationality,
          '_',
          @id
        ))" />
        </lastname>
      </identity>
      <!-- We keep the picture if it exists, but anonymize the filename using the same hash as
     lastname -->
      <xsl:if test="cto:picture">
        <!-- Store the hash value to reuse for both lastname and picture_name -->
       <xsl:variable name="guideHash"
          select="local:hashString(concat(
          cto:identity/cto:firstname,
          '_',
          cto:identity/cto:lastname,
          '_',
          cto:contact/cto:email,
          '_',
          cto:nationality,
          '_',
          @id
        ))" />
       <picture>
          <xsl:choose>
            <!-- If picture has child elements (proper structure), copy them -->
            <xsl:when test="cto:picture/cto:picture_name">
              <picture_name>
                <xsl:value-of select="concat('guide_', $guideHash, '.jpg')" />
              </picture_name>
             <xsl:copy-of
                select="cto:picture/cto:picture_description" copy-namespaces="no" />
            </xsl:when>
            <!-- If picture is just text content, parse it and reconstruct the structure -->
            <xsl:otherwise>
              <xsl:variable name="pictureText" select="normalize-space(cto:picture)" />
             <xsl:variable
                name="lines" select="tokenize($pictureText, '\n')" />
             <picture_name>
                <xsl:value-of select="concat('guide_', $guideHash, '.jpg')" />
              </picture_name>
             <picture_description>
                <xsl:value-of select="normalize-space($lines[2])" />
              </picture_description>
            </xsl:otherwise>
          </xsl:choose>
        </picture>
      </xsl:if>
      <!-- We anonymize contact -->
      <contact>
        <email>
          <xsl:value-of select="concat('guide.', @id, '@privacy.example')" />
        </email>
        <phone_number>+00-000-000-0000</phone_number>
      </contact>
      <!-- But we keep city and country in the address element for geographic analysis -->
      <xsl:if test="cto:address">
        <address>
          <street>[REDACTED]</street>
          <xsl:copy-of select="cto:address/cto:city" copy-namespaces="no" />
          <xsl:if test="cto:address/cto:code">
            <code>[REDACTED]</code>
          </xsl:if>
          <xsl:copy-of select="cto:address/cto:country" copy-namespaces="no" />
        </address>
      </xsl:if>
      <!-- We keep the nationality and spoken languages for business purposes -->
      <xsl:copy-of select="cto:nationality" copy-namespaces="no" />
      <xsl:copy-of select="cto:spoken_languages" copy-namespaces="no" />
      <xsl:copy-of select="cto:qualifications" copy-namespaces="no" />
    </guide>
  </xsl:template>

  <!-- Template for packages -->
  <xsl:template match="cto:packages">
    <packages>
      <xsl:apply-templates select="cto:package" />
    </packages>
  </xsl:template>

  <!-- Template for package
  There is no data to anonymize here so we copy it as is  -->
  <xsl:template match="cto:package">
    <xsl:copy-of select="." copy-namespaces="no" />
  </xsl:template>
</xsl:stylesheet>