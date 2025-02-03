<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <!-- Identity template to copy all elements by default -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- Template to skip elements with shareable="no" and to remove METS fileGrp PRESENTATION -->
    <xsl:template match="*[@shareable='no']|*[@USE='PRESENTATION']|*[contains(@FILEID, 'PRESENTATION')]"/>    
</xsl:stylesheet>
