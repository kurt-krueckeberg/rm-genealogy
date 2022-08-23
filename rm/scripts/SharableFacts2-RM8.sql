-- SharableFacts2-RM8.sql
-- Counts events having citations
-- grouped by EventDate, "Cited by", "Description", "Event Place", "Event Site", "Source Name", "Cit Fields"
-- rev 2022-02-20 by Tom Holden for RM8
--  
-- SourceList.sql
-- by ve3meo 2011-11-03
-- A powerful query emulating the RM4 Source List Report that can be sorted and filtered in many ways.
-- Reports every citation, showing the Source Name, Citation Fields, Quality, Text and Comment, the citing fact and event date and the person 
-- with whom it is associated, the Source Template and key ID's for finding the corresponding records in the database tables.
--
-- Based on prior work:
--  Source Template List with Citation Texts
--  created  by romermb 14 Feb 2010
--  modified by romermb 15 Feb 2010 to override SQLite query optimization routine treatment of 
--             IsPrimary field in order to produce faster run time,
--             to add Template Type field
--  2010-06-01 rev by ve3meo to replace IF construct (not supported without a load extension) by CASE
--  2011-11-01 ve3meo - to concatenate names for easier viewing        SourceTemplateListWithCitationDetails2.sql
-- 2011-11-02 ve3meo - added Citation Details and Comments            SourceTemplateListWithCitationDetails3.sql
--            added Source Details Fields (Cit Fields), Citation Quality, Event Date, rearranged table order
--                                                                    SourceTemplateListWithCitationDetails4.sql
-- 2011-11-03 ve3meo corrected misreporting of RIN and Person having an Alternate Name fact source
--                                                         renamed    SourceList.sql
-- 2011-11-04 ve3meo further corrected reporting of false citations from non-existing Alternate Name facts
-- 2011-11-06 now reports Free Form and orphaned citations; count of media items linked to citation;
--            improved format of CitFields; CAST CitText and CitComments AS TEXT for wider compatability with SQLite managers
-- 2011-11-18 ve3meo added SourceTable FIELDS, Event Place and Site to output
 
-- This complex SELECT processes data from the UNION of 5 SELECTs that it queries, setting the order of display 
SELECT 
       "Source Name", --
-- SourceTable FIELDS parsed out from XML in a blob - this version works for both RM7 and RM8 per Pat Jones Feb 2021
    REPLACE(                                                                                                
		REPLACE(
			REPLACE(
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
									REPLACE(
										REPLACE(CAST(SrcFields AS TEXT),'</Name>', ':' || CAST(X'09' AS TEXT))
									,'<?xml version="1.0" encoding="UTF-8"?>','')
							,'<Root><Fields>','')
						,'</Fields></Root>','')
					,'<Field><Name>', '')
				,'</Value>','')
			,'<Value>','')
		,'<Value/>','')
	,'</Field>',CAST (X'0D' AS TEXT)) 
         AS [Src Fields],
 --
-- CitationTable FIELDS parsed out from XML in a blob - this version works for both RM7 and RM8
    REPLACE(                                                                                                
		REPLACE(
			REPLACE(
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
									REPLACE(
										REPLACE(CAST(CitFields AS TEXT),'</Name>', ':' || CAST(X'09' AS TEXT))
									,'<?xml version="1.0" encoding="UTF-8"?>','')
							,'<Root><Fields>','')
						,'</Fields></Root>','')
					,'<Field><Name>', '')
				,'</Value>','')
			,'<Value>','')
		,'<Value/>','')
	,'</Field>',CAST (X'0D' AS TEXT)) 
         AS [Cit Fields],
 --
       "Quality" AS 'Qual',
       CAST("Citation Text" AS TEXT) AS 'Cit Text',
       CAST("Citation Comment" AS TEXT) AS 'Cit Comment',
       Media,
       COUNT() -1 AS Sharables,
       "Fact Type" AS 'Cited by',
-- Convert Fact dates to readable form
        CASE Substr( rawDate , 1 , 1 )
      	WHEN 'Q' THEN rawDate 
      	WHEN 'T' THEN Substr( rawDate , 2 , 20 ) 
      	WHEN 'D' THEN 
      		CASE Substr( rawDate , 2 , 1 ) 
      			WHEN 'A' THEN 'aft ' 
      			WHEN 'B' THEN 'bef ' 
      			WHEN 'F' THEN 'from ' 
      			WHEN 'I' THEN 'since ' 
      			WHEN 'R' THEN 'bet ' 
      			WHEN 'S' THEN 'from ' 
      			WHEN 'T' THEN 'to ' 
      			WHEN 'U' THEN 'until ' 
      			WHEN 'Y' THEN 'by ' 
      		ELSE '' 
      		END 
      		|| 
      		CASE Substr( rawDate , 13 , 1 ) 
      			WHEN 'A' THEN 'abt ' 
      			WHEN 'C' THEN 'ca ' 
      			WHEN 'E' THEN 'est ' 
      			WHEN 'L' THEN 'calc ' 
      			WHEN 'S' THEN 'say ' 
      			WHEN '6' THEN 'cert ' 
      			WHEN '5' THEN 'prob ' 
      			WHEN '4' THEN 'poss ' 
      			WHEN '3' THEN 'lkly ' 
      			WHEN '2' THEN 'appar ' 
      			WHEN '1' THEN 'prhps ' 
      			WHEN '?' THEN 'maybe ' 
      		ELSE '' 
      		END 
      		|| 
      		CASE WHEN Substr( rawDate , 3 , 1 ) = '-' THEN 'BC' ELSE '' END  
      		|| 
      		CASE WHEN Substr( rawDate , 4 , 4 ) = '0000' THEN '' ELSE Substr( rawDate , 4 , 4 ) END 
      		|| 
      		CASE WHEN Substr( rawDate , 12 , 1 ) = '/' THEN '/' || ( 1 + Substr( rawDate , 3 , 5 ) ) ELSE '' END 
      		|| 
      		CASE 
      			WHEN Substr( rawDate , 8 , 2 ) = '00' AND ( Substr( rawDate , 4 , 4 ) <> '0000' AND Substr( rawDate , 10 , 2 ) <> '00' ) THEN '-??' 
      			WHEN Substr( rawDate , 8 , 2 ) = '00' AND ( Substr( rawDate , 4 , 4 ) <> '0000' AND Substr( rawDate , 10 , 2 ) == '00' ) THEN '' 
      			WHEN Substr( rawDate , 8 , 2 ) = '00' THEN '' 
      		ELSE '-' || Substr( rawDate , 8 , 2 ) 
      		END 
      		|| 
      		Coalesce( Nullif( '-' || Substr( rawDate , 10 , 2 ) , '-00' ) , '' ) 
      		|| 
      		CASE Substr( rawDate , 2 , 1 ) 
      			WHEN 'R' THEN ' and ' 
      			WHEN 'S' THEN ' to ' 
      			WHEN 'O' THEN ' or ' 
      			WHEN '-' THEN ' - ' 
      		ELSE '' 
      		END 
      		|| 
      		CASE Substr( rawDate , 24 , 1 ) 
      			WHEN 'A' THEN 'abt ' 
      			WHEN 'E' THEN 'est ' 
      			WHEN 'L' THEN 'calc ' 
      			WHEN 'C' THEN 'ca ' 
      			WHEN 'S' THEN 'say ' 
      			WHEN '6' THEN 'cert ' 
      			WHEN '5' THEN 'prob ' 
      			WHEN '4' THEN 'poss ' 
      			WHEN '3' THEN 'lkly ' 
      			WHEN '2' THEN 'appar ' 
      			WHEN '1' THEN 'prhps ' 
      			WHEN '?' THEN 'maybe ' 
    		  ELSE '' 
    	   	END 
      		|| 
      		CASE WHEN Substr( rawDate , 14 , 1 ) = '-' THEN 'BC' ELSE '' END 
      		|| 
      		CASE WHEN Substr( rawDate , 15 , 4 ) = '0000' THEN '' ELSE Substr( rawDate , 15 , 4 ) END 
      		|| 
      		CASE WHEN Substr( rawDate , 23 , 1 ) = '/' THEN '/' || ( 1 + Substr( rawDate , 14 , 5 ) ) ELSE '' END 
      		|| 
      		CASE 
      			WHEN Substr( rawDate , 19 , 2 ) = '00' AND ( Substr( rawDate , 15 , 4 ) <> '0000' AND Substr( rawDate , 21 , 2 ) <> '00' ) THEN '-??' 
      			WHEN Substr( rawDate , 19 , 2 ) = '00' AND ( Substr( rawDate , 15 , 4 ) <> '0000' AND Substr( rawDate , 21 , 2 ) == '00' ) THEN '' 
      			WHEN Substr( rawDate , 19 , 2 ) = '00' THEN '' 
      		ELSE '-' || Substr( rawDate , 19 , 2 ) 
      		END 
      		|| 
      		Coalesce( Nullif( '-' || Substr( rawDate , 21 , 2 ) , '-00' ) , '' ) 
      	ELSE '' 
        END AS 'EventDate' ,
--
        CAST("EventDetail" AS TEXT) AS Description,
        "Event Place",
        "Event Site",
       "RIN 1",
-- Concatenate Name fields
       UPPER("Surname 1") ||
          CASE "Suffix 1"
           WHEN '' THEN ''
           ELSE ' ' || "Suffix 1"
          END
          ||', '||  
          "Prefix 1" ||' '||  
          "Given 1" ||
          CASE
           WHEN "Nickname 1" NOT LIKE ''
            THEN ' "'|| "Nickname 1" ||'"'
           ELSE ''
          END 
       AS 'Person 1',
--
       "MRIN",
       "RIN 2", 
-- Concatenate Spouse Name fields
       UPPER("Surname 2") ||
          CASE "Suffix 2"
           WHEN '' THEN ''
           ELSE ' ' || "Suffix 2"
          END
          ||', '||  
          "Prefix 2" ||' '||  
          "Given 2" ||
          CASE
           WHEN "Nickname 2" NOT LIKE ''
            THEN ' "'|| "Nickname 2" ||'"'
           ELSE ''
          END 
       AS 'Person 2',
--       
--       "Records",
       "CitID",
       "SrcID",
       "Template",
       "TpltID",
       CASE WHEN "TpltID" < 10000 
           THEN 'OEM' 
           ELSE 'USR'
       END AS 'Tplt Type'

FROM 
(
 (  -- Start of UNION of X SELECT queries of the database
-- Person Fact Citations
SELECT   CASE
          WHEN SourceTable.TemplateID=0 THEN 'Free Form'
          WHEN SourceTemplateTable.TemplateID THEN SourceTemplateTable.Name COLLATE NOCASE
          ELSE 'ERROR: source template does not exist'
         END AS 'Template',
         SourceTable.TemplateID AS 'TpltID',
         SourceTable.SourceID AS 'SrcID',
         SourceTable.Name COLLATE NOCASE AS 'Source Name',
         SourceTable.Fields AS 'SrcFields',
         CitationTable.CitationID AS 'CitID',
         CitationTable.Fields AS 'CitFields',
         CitationLinkTable.Quality AS 'Quality',
         CitationTable.ActualText AS 'Citation Text',
         CitationTable.Comments AS 'Citation Comment',
         'Fact - Person' AS 'Citation Type',
         FactTypeTable.Name COLLATE NOCASE AS 'Fact Type',
         EventTable.Date AS 'rawDate',         
         EventTable.Details AS 'EventDetail',         
         PlaceTable.Name COLLATE NOCASE AS 'Event Place',         
         SiteTable.Name COLLATE NOCASE AS 'Event Site',
         NULL AS MRIN,
         NameTable.OwnerID AS 'RIN 1',
         NameTable.Surname COLLATE NOCASE AS 'Surname 1',
         NameTable.Suffix COLLATE NOCASE AS 'Suffix 1',
         NameTable.Prefix COLLATE NOCASE AS 'Prefix 1',
         NameTable.Given COLLATE NOCASE AS 'Given 1',
         NameTable.Nickname COLLATE NOCASE AS 'Nickname 1',
         NULL AS 'RIN 2',
         NULL AS 'Surname 2',
         NULL AS 'Suffix 2',
         NULL AS 'Prefix 2',
         NULL AS 'Given 2',
         NULL AS 'Nickname 2',
         COUNT(1) AS Records
FROM     CitationLinkTable
         INNER JOIN CitationTable USING (CitationID)
         LEFT JOIN SourceTable USING (SourceID)
         LEFT JOIN SourceTemplateTable USING (TemplateID)
         INNER JOIN EventTable ON
         CitationLinkTable.OwnerID = EventTable.EventID
         INNER JOIN FactTypeTable ON
         EventTable.EventType = FactTypeTable.FactTypeID
         INNER JOIN NameTable ON
         EventTable.OwnerID = NameTable.OwnerID         
         LEFT JOIN PlaceTable USING (PlaceID)         
         LEFT JOIN PlaceTable AS SiteTable ON         
         EventTable.SiteID=SiteTable.PlaceID
WHERE    CitationLinkTable.OwnerType = 2 AND +NameTable.IsPrimary = 1 AND
         EventTable.OwnerType = 0
GROUP BY "CitID"
 
UNION ALL
 
-- Family Fact Citations
SELECT   CASE
          WHEN SourceTable.TemplateID=0 THEN 'Free Form'
          WHEN SourceTemplateTable.TemplateID THEN SourceTemplateTable.Name COLLATE NOCASE
          ELSE 'ERROR: source template does not exist'
         END AS 'Template',
         SourceTable.TemplateID AS 'TpltID',
         SourceTable.SourceID AS 'SrcID',
         SourceTable.Name COLLATE NOCASE AS 'Source Name',
         SourceTable.Fields AS 'SrcFields',
         CitationTable.CitationID AS 'CitID',
         CitationTable.Fields AS 'CitFields',
         CitationLinkTable.Quality AS 'Quality',
         CitationTable.ActualText AS 'Citation Text',
         CitationTable.Comments AS 'Citation Comment',
         'Fact - Family' AS 'Citation Type',
         FactTypeTable.Name COLLATE NOCASE AS 'Fact Type',
         EventTable.Date AS 'rawDate',
         EventTable.Details AS 'EventDetail',         
         PlaceTable.Name AS 'Event Place',         
         SiteTable.Name AS 'Event Site',
         FamilyTable.FamilyID AS MRIN,
         NameTable1.OwnerID AS 'RIN 1',
         NameTable1.Surname COLLATE NOCASE AS 'Surname 1',
         NameTable1.Suffix COLLATE NOCASE AS 'Suffix 1',
         NameTable1.Prefix COLLATE NOCASE AS 'Prefix 1',
         NameTable1.Given COLLATE NOCASE AS 'Given 1',
         NameTable1.Nickname COLLATE NOCASE AS 'Nickname 1',
         NameTable2.OwnerID AS 'RIN 2',
         NameTable2.Surname COLLATE NOCASE AS 'Surname 2',
         NameTable2.Suffix COLLATE NOCASE AS 'Suffix 2',
         NameTable2.Prefix COLLATE NOCASE AS 'Prefix 2',
         NameTable2.Given COLLATE NOCASE AS 'Given 2',
         NameTable2.Nickname COLLATE NOCASE AS 'Nickname 2',
         COUNT(1) AS Records
FROM     CitationLinkTable
         INNER JOIN CitationTable USING (CitationID)
         LEFT JOIN SourceTable USING (SourceID)
         LEFT JOIN SourceTemplateTable USING (TemplateID)
         INNER JOIN EventTable ON
         CitationLinkTable.OwnerID = EventTable.EventID
         INNER JOIN FactTypeTable ON
         EventTable.EventType = FactTypeTable.FactTypeID
         INNER JOIN FamilyTable ON
         EventTable.OwnerID = FamilyTable.FamilyID
         INNER JOIN NameTable AS NameTable1 ON
         FamilyTable.FatherID = NameTable1.OwnerID
         INNER JOIN NameTable AS NameTable2 ON
         FamilyTable.MotherID = NameTable2.OwnerID
         LEFT JOIN PlaceTable USING (PlaceID)         
         LEFT JOIN PlaceTable AS SiteTable ON         
         EventTable.SiteID=SiteTable.PlaceID
WHERE    CitationLinkTable.OwnerType = 2 AND +NameTable1.IsPrimary = 1 AND
         +NameTable2.IsPrimary = 1 AND EventTable.OwnerType = 1
GROUP BY "CitID"
 )
LEFT JOIN
-- count media items linkd to citation
(SELECT MediaLinkTable.OwnerID AS CitID, COUNT() AS Media
FROM multimediatable
LEFT JOIN MediaLinkTable USING(MediaID)
WHERE MediaLinkTable.OwnerType=4
GROUP BY CitID)
USING (CitID)
)  
GROUP BY EventDate, "Cited by", "Description", "Event Place", "Event Site", "Source Name", "Cit Fields"
-- Sort order - this one clusters identical Source Details Text for a given Source
-- ORDER BY "Source Name", "Citation Text", "Citation Comment", "Person 1", "Fact Type", "EventDate", "Person 2"
-- Sort order - this one clusters a person's citations for a given Source
-- ORDER BY "Source Name", "Person 1", "Fact Type", "EventDate", "Person 2", "Citation Text", "Citation Comment"
; -- END OF FILE                                                                    

