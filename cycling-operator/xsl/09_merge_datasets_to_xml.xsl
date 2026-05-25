<?xml version="1.0" encoding="UTF-8"?>
<!-- This XSLT stylesheet merges multiple XML files that follow the same XSD schema, handling ID
conflicts by
   prefixing IDs with source file identifiers. It also deduplicates guides and packages based on their
content.
   This tranformation takes a parameter "source-files" which is a space-separated list of XML file
paths to merge.
         
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
    exclude-result-prefixes="xs cto"> <!-- Using a namespace cto:-->

    <xsl:output method="xml" indent="yes" encoding="UTF-8" />
    <xsl:strip-space elements="*" />
    <!-- First we declare the source-files parameter to accept input file paths. -->
    <xsl:param name="source-files" as="xs:string" required="yes" />
    <!-- Next we parse the source-files parameter to create a sequence of file paths (there can be
    one or multiple files) -->
    <xsl:variable name="file-list" select="tokenize($source-files, '\s+')" as="xs:string*" />

    <!-- Before applying any template we need to build deduplication maps for guides and packages -->
    <!-- Guide deduplication map -->
    <xsl:variable name="guide-map">
        <xsl:call-template name="build-guide-map" />
    </xsl:variable>
    <!-- Package deduplication map -->
    <xsl:variable name="package-map">
        <xsl:call-template name="build-package-map" />
    </xsl:variable>

    <!-- Initial template
   We will need to iterate over the different source files to merge their content, the first one
   constructs the root element -->
    <xsl:template name="main">
        <data
            xmlns="http://city-tour-operator.org/cto"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://city-tour-operator.org/cto ../../schema/schema.xsd">
            <!-- We process tours from all files at this stage -->
            <tours>
                <!-- We iterate over each source file to extract and merge tours  -->
                <xsl:for-each select="$file-list">
                    <!-- We declare three variables to help with ID prefixing and file paths:
                      - file-index: position of the current file in the list (1-based). Here select="position()" is used
                        to get this index.
                      - file-path: the actual path of the current file being processed -->
                  <xsl:variable name="file-index"
                        select="position()" />
                  <xsl:variable
                        name="file-path" select="." />
                  <xsl:variable name="source-prefix"
                        select="concat('src', $file-index, '_')" />
                    <!-- We apply the template on the tours of the current file, passing the source
                    prefix for ID adjustments -->
                  <xsl:apply-templates
                        select="document($file-path)/cto:data/cto:tours/cto:tour" mode="merge-tours">
                        <!-- Here we specify a param named "prefix" that carries the source prefix for ID adjustments,
                         the tunnel attribute is set to "yes" to allow the parameter to be passed through multiple template calls -->
                        <xsl:with-param name="prefix" select="$source-prefix" tunnel="yes" />
                    </xsl:apply-templates>
                </xsl:for-each>
            </tours>
            <!-- We process the guides from all files (with deduplication) -->
            <guides>
                <xsl:call-template name="merge-guides" />
            </guides>
            <!-- We process the packages from all files (with deduplication) -->
            <packages>
                <xsl:call-template name="merge-packages" />
            </packages>
        </data>
    </xsl:template>

    <!-- Merge tours -->
    <xsl:template match="cto:tour" mode="merge-tours">
        <!-- Same idea as for template main -->
      <xsl:param name="prefix" tunnel="yes" />
      <tour
            xmlns="http://city-tour-operator.org/cto">
            <xsl:apply-templates mode="merge-tours">
                <!-- We pass the prefix parameter down to child elements for ID adjustments -->
                <xsl:with-param name="prefix" select="$prefix" tunnel="yes" />
            </xsl:apply-templates>
        </tour>
    </xsl:template>

    <!-- We update the guide IDREF based on the deduplication mapping -->
    <xsl:template match="cto:guide[@idref]" mode="merge-tours">
        <xsl:param name="prefix" tunnel="yes" />
        <!-- This variable constructs the prefixed ID by concatenating the source prefix with the original IDREF. -->
      <xsl:variable name="prefixed-id"
            select="concat($prefix, @idref)" />
        <!-- This second var looks up the deduplication mapping to find if there is a mapped ID for the prefixed ID.
         The mapping works with the "from" attribute matching the prefixed ID and retrieves the corresponding "to" attribute -->
      <xsl:variable
            name="mapped-id" select="$guide-map/mapping[@from=$prefixed-id]/@to" />
        <!-- We generate the guide element reference in a conditional manner:
           If a mapped ID exists (meaning the guide is a duplicate), we use the mapped ID.
           Otherwise, we use the prefixed ID as is. -->
      <guide
            xmlns="http://city-tour-operator.org/cto"
            idref="{if ($mapped-id) then $mapped-id else $prefixed-id}" />
    </xsl:template>

    <!-- We update bike IDs with the same kind of logic -->
    <xsl:template match="cto:bike[@id]" mode="merge-tours">
        <xsl:param name="prefix" tunnel="yes" />
        <!-- We generate the bike element with its ID prefixed by the source file identifier.
           This ensures uniqueness across merged datasets. -->
      <bike xmlns="http://city-tour-operator.org/cto"
            id="{concat($prefix, @id)}">
            <xsl:apply-templates mode="merge-tours">
                <!-- We pass down the prefix parameter -->
                <xsl:with-param name="prefix" select="$prefix" tunnel="yes" />
            </xsl:apply-templates>
        </bike>
    </xsl:template>

    <!-- We update package IDREF in bookings like we did for guides -->
    <xsl:template match="cto:package[@idref]" mode="merge-tours">
        <xsl:param name="prefix" tunnel="yes" />
      <xsl:variable name="prefixed-id"
            select="concat($prefix, @idref)" />
      <xsl:variable
            name="mapped-id" select="$package-map/mapping[@from=$prefixed-id]/@to" />
      <package
            xmlns="http://city-tour-operator.org/cto"
            idref="{if ($mapped-id) then $mapped-id else $prefixed-id}" />
    </xsl:template>

    <!-- We copy all other elements as-they are
    Here match="node()|@*" allows us to match any node or attribute not specifically handled above and simply copy it over,
    while passing down the prefix parameter for consistency. -->
    <xsl:template match="node()|@*" mode="merge-tours">
        <xsl:param name="prefix" tunnel="yes" />
        <!-- We copy all other elements as they are -->
      <xsl:copy copy-namespaces="no">
            <!-- Here the apply-template matching @*|node() lets us work recursively on all
            attributes and child nodes of the current node, ensuring the entire subtree is processed correctly -->
          <xsl:apply-templates
                select="@*|node()"
                mode="merge-tours">
                <xsl:with-param name="prefix" select="$prefix" tunnel="yes" />
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="comment()" mode="merge_tours" priority="1" />

    <!-- We build the guide deduplication mapping -->
    <xsl:template name="build-guide-map">
        <!-- We declare a variable to hold all guides from all source files, along with their
       prefixed IDs and content hashes. This will help us identify duplicates based on content. -->
      <xsl:variable name="all-guides">
            <!-- Which is why we recursively go through each source file -->
          <xsl:for-each
                select="$file-list">
                <xsl:variable name="file-index" select="position()" />
              <xsl:variable name="file-path"
                    select="." />
              <xsl:variable
                    name="source-prefix" select="concat('src', $file-index, '_')" />
                <!-- And for each source-file it recursively goes through each guide -->
              <xsl:for-each
                    select="document($file-path)/cto:data/cto:guides/cto:guide">
                    <!-- We use the element guide-wrapper to temporarily hold each guide's new ID
                   and content hash for
                   deduplication processing -->
                  <guide-wrapper>
                        <new-id>
                            <xsl:value-of select="concat($source-prefix, @id)" />
                        </new-id>
                        <!-- normalize-space() is used to trim and normalize whitespace in the content and string-join()
                        concatenates all descendant text nodes with a space separator. The decendant nodes are specified
                        with the XPath expression descendant::text().
                        So here normalize-space(string-join(descendant::text(), ' ')) returns a normalized string representation
                        of all text content within the guide element, which is used for deduplication based on content -->
                        <content-hash>
                            <xsl:value-of
                                select="normalize-space(string-join(descendant::text(), ' '))" />
                        </content-hash>
                    </guide-wrapper>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <!-- For each content group, we map the duplicates to the first occurrence which is why we
        use a group-by on content-hash -->
      <xsl:for-each-group
            select="$all-guides/guide-wrapper" group-by="content-hash">
            <!-- The first guide in each group is considered the canonical one, we select it by its
            position in the group using [1] on the current-group using the XPath expression current-group()[1] -->
          <xsl:variable
                name="canonical-id"
                select="current-group()[1]/new-id" />
          <xsl:for-each select="current-group()">
                <!-- We map using the new ID as the source and the canonical ID as the target -->
              <mapping
                    from="{new-id}"
                    to="{$canonical-id}" />
            </xsl:for-each>
        </xsl:for-each-group>
    </xsl:template>

    <!-- We build the package deduplication mapping using the exactly the same kind of methodology -->
    <xsl:template name="build-package-map">
        <xsl:variable name="all-packages">
            <xsl:for-each select="$file-list">
                <xsl:variable name="file-index" select="position()" />
              <xsl:variable name="file-path"
                    select="." />
              <xsl:variable
                    name="source-prefix" select="concat('src', $file-index, '_')" />
              <xsl:for-each
                    select="document($file-path)/cto:data/cto:packages/cto:package">
                    <package-wrapper>
                        <new-id>
                            <xsl:value-of select="concat($source-prefix, @id)" />
                        </new-id>
                        <content-hash>
                            <xsl:value-of
                                select="normalize-space(string-join(descendant::text(), ' '))" />
                        </content-hash>
                    </package-wrapper>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>
        <!-- For each content group, we map the duplicates to the first occurrence
         which is why we use a group-by on content-hash -->
      <xsl:for-each-group
            select="$all-packages/package-wrapper" group-by="content-hash">
            <xsl:variable name="canonical-id" select="current-group()[1]/new-id" />
          <xsl:for-each
                select="current-group()">
                <mapping from="{new-id}" to="{$canonical-id}" />
            </xsl:for-each>
        </xsl:for-each-group>
    </xsl:template>

    <!-- Now we merge the guides with content-based deduplication -->
    <xsl:template name="merge-guides">
        <!-- First we declare a variable to hold all guides from all source files along with their
       prefixed IDs and content hashes. This will help us identify duplicates based on content.  -->
      <xsl:variable name="all-guides">
            <xsl:for-each select="$file-list">
                <xsl:variable name="file-index" select="position()" />
              <xsl:variable name="file-path"
                    select="." />
              <xsl:variable name="source-prefix"
                    select="concat('src', $file-index, '_')" />
              <xsl:for-each
                    select="document($file-path)/cto:data/cto:guides/cto:guide">
                    <!-- We use the element guide-wrapper to temporarily hold guide data along with
                    metadata for deduplication -->
                  <guide-wrapper>
                        <source-prefix>
                            <xsl:value-of select="$source-prefix" />
                        </source-prefix>
                        <original-id>
                            <xsl:value-of select="@id" />
                        </original-id>
                        <new-id>
                            <xsl:value-of select="concat($source-prefix, @id)" />
                        </new-id>
                        <content-hash>
                            <!-- Here the string-join() is directly on the nodes of the guide
                            element to create a content hash instead of a descendant text node -->
                            <xsl:value-of select="normalize-space(string-join(node(), ' '))" />
                        </content-hash>
                        <guide-content>
                            <!-- We can copy the full content of the guide element as is now that we
                           have managed the id -->
                            <xsl:copy-of copy-namespaces="no" select="." />
                        </guide-content>
                    </guide-wrapper>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>

        <!-- We deduplicate by content and assign IDs. We keep the first occurrence using group-by
       on content-hash -->
      <xsl:for-each-group
            select="$all-guides/guide-wrapper" group-by="content-hash">
            <xsl:variable name="new-id" select="current-group()[1]/new-id" />
       
          <guide
                xmlns="http://city-tour-operator.org/cto" id="{$new-id}">
                <xsl:apply-templates select="current-group()[1]/guide-content/cto:guide/*"
                    mode="copy-content" />
            </guide>
        </xsl:for-each-group>
    </xsl:template>

    <!-- We merge the packages with content-based deduplication exactly like we did for the guides -->
    <xsl:template name="merge-packages">
        <xsl:variable name="all-packages">
            <xsl:for-each select="$file-list">
                <xsl:variable name="file-index" select="position()" />
              <xsl:variable name="file-path"
                    select="." />
              <xsl:variable name="source-prefix"
                    select="concat('src', $file-index, '_')" />
              <xsl:for-each
                    select="document($file-path)/cto:data/cto:packages/cto:package">
                    <package-wrapper>
                        <source-prefix>
                            <xsl:value-of select="$source-prefix" />
                        </source-prefix>
                        <original-id>
                            <xsl:value-of select="@id" />
                        </original-id>
                        <new-id>
                            <xsl:value-of select="concat($source-prefix, @id)" />
                        </new-id>
                        <content-hash>
                            <xsl:value-of
                                select="normalize-space(string-join(descendant::text(), ' '))" />
                        </content-hash>
                        <package-content>
                            <xsl:copy-of copy-namespaces="no" select="." />
                        </package-content>
                    </package-wrapper>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:variable>

        <!-- We deduplicate by content and assign IDs. We keep the first occurrence using group-by
       on content-hash -->
      <xsl:for-each-group
            select="$all-packages/package-wrapper" group-by="content-hash">
            <xsl:variable name="new-id" select="current-group()[1]/new-id" />
       
          <package
                xmlns="http://city-tour-operator.org/cto" id="{$new-id}">
                <xsl:apply-templates select="current-group()[1]/package-content/cto:package/*"
                    mode="copy-content" />
            </package>
        </xsl:for-each-group>
    </xsl:template>

    <!-- We recursively copy all the content nodes and attributes that were not involved in
   deduplication -->
    <xsl:template match="node()|@*" mode="copy-content">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@*|node()" mode="copy-content" />
        </xsl:copy>
    </xsl:template>

    <!-- Ignore comments when copying content -->
    <xsl:template match="comment()" mode="copy-content" />

</xsl:stylesheet>