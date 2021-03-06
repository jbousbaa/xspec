<?xml version="1.0" encoding="UTF-8"?>
<!-- ===================================================================== -->
<!--  File:       generate-tests-utils.xsl                                 -->
<!--  Author:     Jeni Tennison                                            -->
<!--  URL:        http://github.com/xspec/xspec                            -->
<!--  Tags:                                                                -->
<!--    Copyright (c) 2008, 2010 Jeni Tennison (see end of file.)          -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->


<xsl:stylesheet version="3.0"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:test="http://www.jenitennison.com/xslt/unit-test"
                xmlns:x="http://www.jenitennison.com/xslt/xspec"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="#all">

   <pkg:import-uri>http://www.jenitennison.com/xslt/xspec/generate-tests-utils.xsl</pkg:import-uri>

   <!-- Serialization parameters for the test result report XML
      TODO: Put @parameter-document="xml-report-serialization-parameters.xml" and remove the other
         parameters after the fixes for https://saxonica.plan.io/issues/4599 and
         https://saxonica.plan.io/issues/4602 are made available on all the supported versions of
         Saxon. -->
   <xsl:output name="x:xml-report-serialization-parameters" method="xml" indent="yes" />

   <!--
      TODO: Implement this debugging feature??
      TODO: @name must not pollute the other modules: xspec/xspec#985
   -->
   <!--<xsl:param name="debug" as="xs:boolean" select="true()" />-->

   <!-- $flags
      w : Ignores descendant whitespace-only text nodes except the ones in <test:ws>
      1 : Simulates XSLT version 1.0 -->
   <xsl:function name="test:deep-equal" as="xs:boolean">
      <xsl:param name="seq1" as="item()*" />
      <xsl:param name="seq2" as="item()*" />
      <xsl:param name="flags" as="xs:string" />

      <!-- Using a $param in @use-when does not work.  TODO: What to do? At run time? -->
      <!-- See also ../../misc/archive/ for x:node-path(). -->
      <!--
      <xsl:if test="$seq1 instance of node()" use-when="$debug">
         <xsl:message select="'DEEP-EQUAL: SEQ1:', x:node-path($seq1)" />
      </xsl:if>
      <xsl:if test="$seq2 instance of node()" use-when="$debug">
         <xsl:message select="'DEEP-EQUAL: SEQ2:', x:node-path($seq2)" />
      </xsl:if>
      -->

      <xsl:variable name="result" as="xs:boolean">
         <xsl:choose>
            <xsl:when test="contains($flags, '1')">
               <xsl:sequence select="test:deep-equal-v1($seq1, $seq2, $flags)" />
            </xsl:when>

            <xsl:when test="empty($seq1) or empty($seq2)">
               <xsl:sequence select="empty($seq1) and empty($seq2)" />
            </xsl:when>

            <xsl:when test="count($seq1) = count($seq2)">
               <xsl:sequence
                  select="
                     every $i in (1 to count($seq1)) 
                     satisfies test:item-deep-equal($seq1[$i], $seq2[$i], $flags)" />
            </xsl:when>

            <xsl:when test="$seq1 instance of text() and
                            $seq2 instance of text()+">
               <xsl:variable name="seq2" as="text()">
                  <xsl:value-of select="$seq2" separator="" />
               </xsl:variable>
               <xsl:sequence select="test:deep-equal($seq1, $seq2, $flags)" />
            </xsl:when>

            <xsl:when test="test:wrappable-sequence($seq1) and test:wrappable-sequence($seq2)">
               <xsl:variable name="seq1doc" as="document-node()" select="test:wrap-nodes($seq1)" />
               <xsl:variable name="seq2doc" as="document-node()" select="test:wrap-nodes($seq2)" />

               <xsl:choose>
                  <xsl:when
                     test="
                        count($seq1doc/node()) != count($seq1)
                        or count($seq2doc/node()) != count($seq2)">
                     <xsl:sequence
                        select="test:deep-equal($seq1doc/node(), $seq2doc/node(), $flags)" />
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="false()" />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:when>

            <xsl:otherwise>
               <xsl:sequence select="false()" />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <!-- Using a $param in @use-when does not work.  TODO: What to do? At run time? -->
      <!--
      <xsl:message select="'DEEP-EQUAL: RESULT:', $result" use-when="$debug" />
      -->

      <xsl:sequence select="$result" />
   </xsl:function>

   <xsl:function name="test:deep-equal-v1" as="xs:boolean">
      <xsl:param name="seq1" as="item()*" />
      <xsl:param name="seq2" as="item()*" />
      <xsl:param name="flags" as="xs:string" />

      <xsl:variable name="seq2-adapted" as="xs:anyAtomicType?">
         <xsl:if test="$seq2 instance of text()+">
            <xsl:variable name="seq2-string" as="xs:string" select="string-join($seq2)" />

            <xsl:choose>
               <xsl:when test="$seq1 instance of xs:string">
                  <xsl:sequence select="$seq2-string" />
               </xsl:when>
               <xsl:when test="$seq1 instance of xs:double">
                  <xsl:sequence select="$seq2-string[. castable as xs:double] => xs:double()" />
               </xsl:when>
               <xsl:when test="$seq1 instance of xs:decimal">
                  <xsl:sequence select="$seq2-string[. castable as xs:decimal] => xs:decimal()" />
               </xsl:when>
               <xsl:when test="$seq1 instance of xs:integer">
                  <xsl:sequence select="$seq2-string[. castable as xs:integer] => xs:integer()" />
               </xsl:when>
            </xsl:choose>
         </xsl:if>
      </xsl:variable>

      <xsl:sequence
         select="
            test:deep-equal(
               $seq1,
               ($seq2-adapted, $seq2)[1],
               translate($flags, '1', '')
            )" />
   </xsl:function>

   <xsl:function name="test:item-deep-equal" as="xs:boolean">
      <xsl:param name="item1" as="item()" />
      <xsl:param name="item2" as="item()" />
      <xsl:param name="flags" as="xs:string" />

      <xsl:choose>
         <xsl:when test="$item1 instance of node() and
                         $item2 instance of node()">
            <xsl:sequence select="test:node-deep-equal($item1, $item2, $flags)" />
         </xsl:when>

         <xsl:when test="not($item1 instance of node()) and
                         not($item2 instance of node())">
            <xsl:sequence select="deep-equal($item1, $item2)" />
         </xsl:when>

         <xsl:otherwise>
            <xsl:sequence select="false()" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="test:node-deep-equal" as="xs:boolean">
      <xsl:param name="node1" as="node()" />
      <xsl:param name="node2" as="node()" />
      <xsl:param name="flags" as="xs:string" />

      <xsl:choose>
         <xsl:when test="$node1 instance of document-node() and
                         $node2 instance of document-node()">
            <xsl:variable name="children1" as="node()*"
               select="test:sorted-children($node1, $flags)" />
            <xsl:variable name="children2" as="node()*" 
               select="test:sorted-children($node2, $flags)" />
            <xsl:sequence select="test:deep-equal($children1, $children2, $flags)" />
         </xsl:when>

         <xsl:when test="$node1 instance of element() and
                         $node2 instance of element()">
            <xsl:sequence select="test:element-deep-equal($node1, $node2, $flags)" />
         </xsl:when>

         <xsl:when test="$node1 instance of text() and
                         $node1 = '...'">
            <xsl:sequence select="true()" />
         </xsl:when>

         <xsl:when test="$node1 instance of text() and
                         $node2 instance of text()">
            <!--
            <xsl:choose>
               <xsl:when test="not(normalize-space($node1)) and 
                               not(normalize-space($node2))">
                  <xsl:sequence select="true()" />
               </xsl:when>
               <xsl:otherwise>
            -->
            <xsl:sequence select="string($node1) eq string($node2)" />
            <!--
               </xsl:otherwise>
            </xsl:choose>
            -->
         </xsl:when>

         <xsl:when test="($node1 instance of attribute() and
                          $node2 instance of attribute()) or
                         ($node1 instance of processing-instruction() and
                          $node2 instance of processing-instruction()) or
                         ($node1 instance of namespace-node() and
                          $node2 instance of namespace-node())">
            <xsl:sequence
               select="
                  deep-equal(node-name($node1), node-name($node2))
                  and
                  (
                     string($node1) eq string($node2)
                     or
                     string($node1) = '...'
                  )" />
         </xsl:when>

         <xsl:when test="$node1 instance of comment() and
                         $node2 instance of comment()">
            <xsl:sequence select="string($node1) eq string($node2) or string($node1) = '...'" />
         </xsl:when>

         <xsl:otherwise>
            <xsl:sequence select="false()" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="test:element-deep-equal" as="xs:boolean">
      <xsl:param name="elem1" as="element()" />
      <xsl:param name="elem2" as="element()" />
      <xsl:param name="flags" as="xs:string" />

      <xsl:variable name="node-name-equal" as="xs:boolean"
         select="node-name($elem1) eq node-name($elem2)" />

      <xsl:variable name="attrs-equal" as="xs:boolean"
         select="
            test:deep-equal(
               test:sort-named-nodes($elem1/attribute()),
               test:sort-named-nodes($elem2/attribute()),
               $flags
            )" />

      <xsl:variable name="children-equal" as="xs:boolean"
         select="
            $elem1[count(node()) eq 1][text() = '...']
            or
            test:deep-equal(
               test:sorted-children($elem1, $flags),
               test:sorted-children($elem2, $flags),
               $flags
            )" />

      <xsl:sequence select="$node-name-equal and $attrs-equal and $children-equal" />
   </xsl:function>

   <xsl:function name="test:sorted-children" as="node()*">
      <xsl:param name="node" as="node()" />
      <xsl:param name="flags" as="xs:string" />

      <xsl:sequence 
         select="
            $node/child::node()
            except ($node/text()[not(normalize-space())][contains($flags, 'w')][not($node/self::test:ws)],
                    $node/test:message)" />
   </xsl:function>

   <xsl:function name="test:sort-named-nodes" as="node()*">
      <xsl:param name="nodes" as="node()*" />

      <xsl:perform-sort select="$nodes">
         <xsl:sort select="namespace-uri()" />
         <xsl:sort select="local-name()" />
      </xsl:perform-sort>
   </xsl:function>

   <xsl:template name="test:report-sequence" as="element()">
      <xsl:context-item use="absent" />

      <xsl:param name="sequence" as="item()*" required="yes" />
      <xsl:param name="report-name" as="xs:string" required="yes" />
      <xsl:param name="report-namespace" as="xs:string" select="$x:xspec-namespace" />

      <xsl:variable name="attribute-nodes" as="attribute()*"      select="$sequence[. instance of attribute()]" />
      <xsl:variable name="document-nodes"  as="document-node()*"  select="$sequence[. instance of document-node()]" />
      <xsl:variable name="namespace-nodes" as="namespace-node()*" select="$sequence[. instance of namespace-node()]" />
      <xsl:variable name="text-nodes"      as="text()*"           select="$sequence[. instance of text()]" />

      <xsl:variable name="report-element" as="element()">
         <xsl:element name="{$report-name}" namespace="{$report-namespace}">
            <xsl:choose>
               <!-- Empty -->
               <xsl:when test="empty($sequence)">
                  <xsl:attribute name="select" select="'()'" />
               </xsl:when>

               <!-- One or more atomic values -->
               <xsl:when test="$sequence instance of xs:anyAtomicType+">
                  <xsl:variable as="xs:string+" name="atomic-value-reports"
                     select="for $value in $sequence return test:report-atomic-value($value)" />
                  <xsl:attribute name="select" select="string-join($atomic-value-reports, ',&#x0A;')" />
               </xsl:when>

               <!-- One or more nodes of the same type which can be a child of document node -->
               <xsl:when
                  test="
                     ($sequence instance of comment()+)
                     or ($sequence instance of element()+)
                     or ($sequence instance of processing-instruction()+)
                     or ($sequence instance of text()+)">
                  <xsl:attribute name="select"
                     select="concat('/', x:node-type($sequence[1]), '()')" />
                  <xsl:apply-templates select="$sequence" mode="test:report-node" />
               </xsl:when>

               <!-- Single document node -->
               <xsl:when test="$sequence instance of document-node()">
                  <!-- People do not always notice '/' in the report HTML. So express it more verbosely.
                     Also the expression must match the one in ../reporter/format-xspec-report.xsl. -->
                  <xsl:attribute name="select" select="'/self::document-node()'" />
                  <xsl:apply-templates select="$sequence" mode="test:report-node" />
               </xsl:when>

               <!-- One or more nodes which can be stored in an element safely and without losing each position.
                  Those nodes include document nodes and text nodes. By storing them in an element, they will
                  be unwrapped and/or merged with adjacent nodes. When it happens, the report does not
                  represent the sequence precisely. That's ok, because
                  * Otherwise the report will be cluttered with pseudo elements.
                  * XSpec in general including its test:deep-equal() inclines to merge them. -->
               <xsl:when
                  test="
                     ($sequence instance of node()+)
                     and not($attribute-nodes or $namespace-nodes)">
                  <xsl:attribute name="select" select="'/node()'" />
                  <xsl:apply-templates select="$sequence" mode="test:report-node" />
               </xsl:when>

               <!-- Otherwise each item needs to be represented as a pseudo element -->
               <xsl:otherwise>
                  <xsl:attribute name="select">
                     <!-- Select the pseudo elements -->
                     <xsl:text>/*</xsl:text>

                     <xsl:choose>
                        <!-- If all items are instance of node, they can be expressed in @select.
                           (Document nodes are unwrapped, though.) -->
                        <xsl:when test="$sequence instance of node()+">
                           <xsl:variable name="expressions" as="xs:string+"
                              select="
                                 '@*'[$attribute-nodes],
                                 'namespace::*'[$namespace-nodes],
                                 'node()'[$sequence except ($attribute-nodes | $namespace-nodes)]" />
                           <xsl:variable name="multi-expr" as="xs:boolean"
                              select="count($expressions) ge 2" />

                           <xsl:text>/</xsl:text>
                           <xsl:if test="$multi-expr">
                              <xsl:text>(</xsl:text>
                           </xsl:if>
                           <xsl:value-of select="$expressions" separator=" | " />
                           <xsl:if test="$multi-expr">
                              <xsl:text>)</xsl:text>
                           </xsl:if>
                        </xsl:when>

                        <xsl:otherwise>
                           <!-- Not all items can be expressed in @select. Just leave the pseudo elements selected. -->
                        </xsl:otherwise>
                     </xsl:choose>
                  </xsl:attribute>

                  <xsl:sequence
                     select="
                        for $item in $sequence
                        return test:report-pseudo-item($item, $report-namespace)" />
               </xsl:otherwise>
            </xsl:choose>
         </xsl:element>
      </xsl:variable>

      <!-- Output the report element -->
      <xsl:choose>
         <!-- If too many nodes, save the report element as an external doc -->
         <xsl:when test="count($report-element/descendant-or-self::node()) ge 1000">
            <!-- URI of the external file.
               Ensure that each report outputs to a unique URI (expath/xspec#67). -->
            <xsl:variable name="href" as="xs:string"
               select="'result-' || generate-id($report-element) || '.xml'" />

            <!-- Save the report element as the external file.
               You can't unwrap the report element, because not all nodes can be located in the document root. -->
            <!-- Use @format to avoid clashes with <xsl:output> in another stylesheet which would
               otherwise govern the output of the external file. -->
            <xsl:result-document href="{$href}" format="x:xml-report-serialization-parameters">
               <xsl:sequence select="$report-element" />
            </xsl:result-document>

            <!-- Alter the report element, discarding its stale @select -->
            <xsl:copy select="$report-element">
               <xsl:sequence select="attribute() except @select" />
               <xsl:attribute name="href" select="$href" />
            </xsl:copy>
         </xsl:when>

         <!-- Not too many nodes. Just output the report element as is. -->
         <xsl:otherwise>
            <xsl:sequence select="$report-element" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:function name="test:report-pseudo-item" as="element()">
      <xsl:param name="item" as="item()" />
      <xsl:param name="report-namespace" as="xs:string" />

      <xsl:variable name="local-name-prefix" as="xs:string" select="'pseudo-'" />

      <xsl:choose>
         <xsl:when test="$item instance of xs:anyAtomicType">
            <xsl:element name="{$local-name-prefix}atomic-value" namespace="{$report-namespace}">
               <xsl:value-of select="test:report-atomic-value($item)" />
            </xsl:element>
         </xsl:when>

         <xsl:when test="$item instance of node()">
            <xsl:element name="{$local-name-prefix}{x:node-type($item)}" namespace="{$report-namespace}">
               <xsl:choose>
                  <!-- Can't apply templates to namespace nodes -->
                  <xsl:when test="$item instance of namespace-node()">
                     <xsl:sequence select="$item" />
                  </xsl:when>

                  <xsl:otherwise>
                     <xsl:apply-templates select="$item" mode="test:report-node" />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:element>
         </xsl:when>

         <xsl:when test="x:instance-of-function($item)">
            <xsl:element name="{$local-name-prefix}{x:function-type($item)}"
               namespace="{$report-namespace}">
               <xsl:value-of select="test:serialize-adaptive($item)" />
            </xsl:element>
         </xsl:when>

         <xsl:otherwise>
            <xsl:element name="{$local-name-prefix}other" namespace="{$report-namespace}" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!--
      mode="test:report-node"
      Copies the nodes while wrapping whitespace-only text nodes in <test:ws>.
      You can't use @on-no-match="shallow-copy", because SUT may have xsl:template[@mode="#all"].
   -->
   <xsl:mode name="test:report-node" on-multiple-match="fail" on-no-match="fail" />

   <xsl:template match="document-node() | attribute() | node()" as="node()"
      mode="test:report-node">
      <xsl:call-template name="x:identity" />
   </xsl:template>

   <xsl:template match="text()[not(normalize-space())]" as="element(test:ws)"
      mode="test:report-node">
      <!-- This element name is not 'test:ws' but 'ws'. This prefix-less name is a workaround for
         https://sourceforge.net/p/saxon/mailman/message/37066342/ -->
      <xsl:element name="ws" namespace="{$x:legacy-namespace}">
         <xsl:sequence select="." />
      </xsl:element>
   </xsl:template>

   <xsl:function name="test:report-atomic-value" as="xs:string">
      <xsl:param name="value" as="xs:anyAtomicType" />

      <xsl:choose>
         <!-- Derived types must be handled before their base types -->

         <!-- String types -->
         <xsl:when test="$value instance of xs:normalizedString"
            use-when="type-available('xs:normalizedString')">
            <xsl:sequence select="test:report-atomic-value-as-constructor($value)" />
         </xsl:when>
         <xsl:when test="$value instance of xs:string">
            <xsl:sequence select="x:quote-with-apos($value)" />
         </xsl:when>

         <!-- Derived numeric types -->
         <xsl:when test="$value instance of xs:nonPositiveInteger"
            use-when="type-available('xs:nonPositiveInteger')">
            <xsl:sequence select="test:report-atomic-value-as-constructor($value)" />
         </xsl:when>
         <xsl:when test="$value instance of xs:long" use-when="type-available('xs:long')">
            <xsl:sequence select="test:report-atomic-value-as-constructor($value)" />
         </xsl:when>
         <xsl:when test="$value instance of xs:nonNegativeInteger"
            use-when="type-available('xs:nonNegativeInteger')">
            <xsl:sequence select="test:report-atomic-value-as-constructor($value)" />
         </xsl:when>

         <!-- Numeric types which can be expressed as numeric literals:
            http://www.w3.org/TR/xpath20/#id-literals -->
         <xsl:when test="$value instance of xs:integer">
            <xsl:sequence select="string($value)" />
         </xsl:when>
         <xsl:when test="$value instance of xs:decimal">
            <xsl:sequence select="x:decimal-string($value)" />
         </xsl:when>
         <xsl:when test="$value instance of xs:double">
            <xsl:sequence
               select="
                  if (string($value) = ('NaN', 'INF', '-INF')) then
                     test:report-atomic-value-as-constructor($value)
                  else
                     test:serialize-adaptive($value)" />
         </xsl:when>

         <xsl:when test="$value instance of xs:QName">
            <xsl:sequence select="x:QName-expression($value)" />
         </xsl:when>

         <xsl:otherwise>
            <xsl:sequence select="test:report-atomic-value-as-constructor($value)" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="test:report-atomic-value-as-constructor" as="xs:string">
      <xsl:param name="value" as="xs:anyAtomicType" />

      <!-- Constructor usually has the same name as type -->
      <xsl:variable name="constructor-name" as="xs:string" select="test:atom-type($value)" />

      <!-- Cast as either xs:integer or xs:string -->
      <xsl:variable name="casted-value" as="xs:anyAtomicType">
         <xsl:choose>
            <xsl:when test="$value instance of xs:integer">
               <!-- Force casting down to integer, by first converting to string -->
               <xsl:sequence select="string($value) cast as xs:integer" />
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="string($value)" />
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <!-- Constructor parameter:
         Either numeric literal of integer or string literal -->
      <xsl:variable name="costructor-param" as="xs:string"
         select="test:report-atomic-value($casted-value)" />

      <xsl:sequence select="concat($constructor-name, '(', $costructor-param, ')')" />
   </xsl:function>

   <xsl:function name="test:atom-type" as="xs:string">
      <xsl:param name="value" as="xs:anyAtomicType" />

      <xsl:variable name="local-name" as="xs:string">
         <xsl:choose>
            <!-- Grouped as the spec does: http://www.w3.org/TR/xslt20/#built-in-types
               Groups are in the reversed order so that the derived types are before the primitive types,
               otherwise xs:integer is recognised as xs:decimal, xs:yearMonthDuration as xs:duration, and so on. -->

            <!-- A schema-aware XSLT processor additionally supports: -->

            <!--    * All other built-in types defined in [XML Schema Part 2] -->
            <!-- xs:IDREFS: list -->
            <!-- xs:ENTITIES: list -->
            <xsl:when test="$value instance of xs:ID" use-when="type-available('xs:ID')">ID</xsl:when>
            <xsl:when test="$value instance of xs:IDREF" use-when="type-available('xs:IDREF')">IDREF</xsl:when>
            <xsl:when test="$value instance of xs:ENTITY" use-when="type-available('xs:ENTITY')">ENTITY</xsl:when>
            <xsl:when test="$value instance of xs:NCName" use-when="type-available('xs:NCName')">NCName</xsl:when>
            <!-- xs:NMTOKENS: list -->
            <xsl:when test="$value instance of xs:language" use-when="type-available('xs:language')">language</xsl:when>
            <xsl:when test="$value instance of xs:Name" use-when="type-available('xs:Name')">Name</xsl:when>
            <xsl:when test="$value instance of xs:NMTOKEN" use-when="type-available('xs:NMTOKEN')">NMTOKEN</xsl:when>
            <xsl:when test="$value instance of xs:token" use-when="type-available('xs:token')">token</xsl:when>
            <xsl:when test="$value instance of xs:normalizedString" use-when="type-available('xs:normalizedString')">normalizedString</xsl:when>
            <xsl:when test="$value instance of xs:negativeInteger" use-when="type-available('xs:negativeInteger')">negativeInteger</xsl:when>
            <xsl:when test="$value instance of xs:nonPositiveInteger" use-when="type-available('xs:nonPositiveInteger')">nonPositiveInteger</xsl:when>
            <xsl:when test="$value instance of xs:byte" use-when="type-available('xs:byte')">byte</xsl:when>
            <xsl:when test="$value instance of xs:short" use-when="type-available('xs:short')">short</xsl:when>
            <xsl:when test="$value instance of xs:int" use-when="type-available('xs:int')">int</xsl:when>
            <xsl:when test="$value instance of xs:long" use-when="type-available('xs:long')">long</xsl:when>
            <xsl:when test="$value instance of xs:unsignedByte" use-when="type-available('xs:unsignedByte')">unsignedByte</xsl:when>
            <xsl:when test="$value instance of xs:unsignedShort" use-when="type-available('xs:unsignedShort')">unsignedShort</xsl:when>
            <xsl:when test="$value instance of xs:unsignedInt" use-when="type-available('xs:unsignedInt')">unsignedInt</xsl:when>
            <xsl:when test="$value instance of xs:unsignedLong" use-when="type-available('xs:unsignedLong')">unsignedLong</xsl:when>
            <xsl:when test="$value instance of xs:positiveInteger" use-when="type-available('xs:positiveInteger')">positiveInteger</xsl:when>
            <xsl:when test="$value instance of xs:nonNegativeInteger" use-when="type-available('xs:nonNegativeInteger')">nonNegativeInteger</xsl:when>
            <!-- xs:NOTATION: Abstract -->

            <!-- Every XSLT 2.0 processor includes the following named type definitions in the in-scope schema components: -->

            <!--    * The following types defined in [XPath 2.0] -->
            <xsl:when test="$value instance of xs:yearMonthDuration">yearMonthDuration</xsl:when>
            <xsl:when test="$value instance of xs:dayTimeDuration">dayTimeDuration</xsl:when>
            <!-- xs:anyAtomicType: Abstract -->
            <!-- xs:untyped: Not atomic -->
            <xsl:when test="$value instance of xs:untypedAtomic">untypedAtomic</xsl:when>

            <!--    * The types xs:anyType and xs:anySimpleType. -->
            <!-- Not atomic -->

            <!--    * The derived atomic type xs:integer defined in [XML Schema Part 2]. -->
            <xsl:when test="$value instance of xs:integer">integer</xsl:when>

            <!--    * All the primitive atomic types defined in [XML Schema Part 2], with the exception of xs:NOTATION. -->
            <xsl:when test="$value instance of xs:string">string</xsl:when>
            <xsl:when test="$value instance of xs:boolean">boolean</xsl:when>
            <xsl:when test="$value instance of xs:decimal">decimal</xsl:when>
            <xsl:when test="$value instance of xs:double">double</xsl:when>
            <xsl:when test="$value instance of xs:float">float</xsl:when>
            <xsl:when test="$value instance of xs:date">date</xsl:when>
            <xsl:when test="$value instance of xs:time">time</xsl:when>
            <xsl:when test="$value instance of xs:dateTime">dateTime</xsl:when>
            <xsl:when test="$value instance of xs:duration">duration</xsl:when>
            <xsl:when test="$value instance of xs:QName">QName</xsl:when>
            <xsl:when test="$value instance of xs:anyURI">anyURI</xsl:when>
            <xsl:when test="$value instance of xs:gDay">gDay</xsl:when>
            <xsl:when test="$value instance of xs:gMonthDay">gMonthDay</xsl:when>
            <xsl:when test="$value instance of xs:gMonth">gMonth</xsl:when>
            <xsl:when test="$value instance of xs:gYearMonth">gYearMonth</xsl:when>
            <xsl:when test="$value instance of xs:gYear">gYear</xsl:when>
            <xsl:when test="$value instance of xs:base64Binary">base64Binary</xsl:when>
            <xsl:when test="$value instance of xs:hexBinary">hexBinary</xsl:when>

            <xsl:otherwise>anyAtomicType</xsl:otherwise>
         </xsl:choose>
      </xsl:variable>

      <xsl:sequence select="x:known-UQName('xs:' || $local-name)" />
   </xsl:function>

   <xsl:function name="test:serialize-adaptive" as="xs:string">
      <xsl:param name="item" as="item()" />

      <xsl:sequence
         select="
            serialize(
               $item,
               map {
                  'indent': true(),
                  'method': 'adaptive'
               }
            )" />
   </xsl:function>

   <!-- Returns true if every item in sequence can be wrapped in document node.
      Empty sequence is considered to be able to be wrapped. -->
   <xsl:function name="test:wrappable-sequence" as="xs:boolean">
      <xsl:param name="sequence" as="item()*" />

      <xsl:sequence select="every $item in $sequence satisfies test:wrappable-node($item)" />
   </xsl:function>

   <!-- Returns true if item is node and can be wrapped in document node -->
   <xsl:function name="test:wrappable-node" as="xs:boolean">
      <xsl:param name="item" as="item()" />

      <!-- Document node cannot wrap attribute node or namespace node:
         http://www.w3.org/TR/xslt20/#err-XTDE0420 -->
      <xsl:sequence
         select="
            $item instance of node()
            and not($item instance of attribute()
                    or $item instance of namespace-node())" />
   </xsl:function>

   <!-- Wraps nodes in document node with their type annotations kept -->
   <xsl:function name="test:wrap-nodes" as="document-node()">
      <xsl:param name="nodes" as="node()*" />

      <!-- $wrap aims to create an implicit document node as described
         in http://www.w3.org/TR/xslt20/#temporary-trees
         So its xsl:variable must not have @as or @select.
         Do not use xsl:document or xsl:copy-of: xspec/xspec#47 -->
      <xsl:variable name="wrap">
         <xsl:sequence select="$nodes" />
      </xsl:variable> 
      <xsl:sequence select="$wrap" />
   </xsl:function>

   <!-- This mode resolves URI in Saxon configuration to work around https://saxonica.plan.io/issues/4471
      TODO: Cover more attributes/elements (only as needed basis).
      TODO: Retire this mode when no longer needed (probably when Oxygen picks up Saxon 9.9.1.7). -->
   <xsl:mode name="test:fixup-saxon-config" on-multiple-match="fail" on-no-match="shallow-copy" />
   <xsl:template match="configuration:package/@sourceLocation" as="attribute(sourceLocation)"
      mode="test:fixup-saxon-config" xmlns:configuration="http://saxon.sf.net/ns/configuration">
      <xsl:attribute name="{local-name()}" namespace="{namespace-uri()}" select="resolve-uri(., base-uri())" />
   </xsl:template>

   <!-- Checks that the sequence appears to be a Saxon configuration -->
   <xsl:function name="test:is-saxon-config" as="xs:boolean">
      <xsl:param name="sequence" as="item()*" />

      <xsl:sequence xmlns:config="http://saxon.sf.net/ns/configuration"
         select="
            ($sequence instance of element(config:configuration))
            or
            ($sequence instance of document-node(element(config:configuration)))" />
   </xsl:function>

</xsl:stylesheet>


<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
<!-- DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS COMMENT.             -->
<!--                                                                       -->
<!-- Copyright (c) 2008, 2010 Jeni Tennison                                -->
<!--                                                                       -->
<!-- The contents of this file are subject to the MIT License (see the URI -->
<!-- http://www.opensource.org/licenses/mit-license.php for details).      -->
<!--                                                                       -->
<!-- Permission is hereby granted, free of charge, to any person obtaining -->
<!-- a copy of this software and associated documentation files (the       -->
<!-- "Software"), to deal in the Software without restriction, including   -->
<!-- without limitation the rights to use, copy, modify, merge, publish,   -->
<!-- distribute, sublicense, and/or sell copies of the Software, and to    -->
<!-- permit persons to whom the Software is furnished to do so, subject to -->
<!-- the following conditions:                                             -->
<!--                                                                       -->
<!-- The above copyright notice and this permission notice shall be        -->
<!-- included in all copies or substantial portions of the Software.       -->
<!--                                                                       -->
<!-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       -->
<!-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    -->
<!-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.-->
<!-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  -->
<!-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  -->
<!-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     -->
<!-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                -->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
