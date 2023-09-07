/* Master sources list 
Converted to work with both RM7 and RM8 format - PJ Feb2021
*/
SELECT   SourceTable.SourceID AS [SrcID],
         SourceTable.Name COLLATE NOCASE AS [Source Name],
         SourceTable.RefNumber,
-- SourceTable FIELDS parsed out from XML in a blob - this version works for both RM7 and RM8
    REPLACE(                                                                                                
		REPLACE(
			REPLACE(
				REPLACE(
					REPLACE(
						REPLACE(
							REPLACE(
									REPLACE(
										REPLACE(CAST(SourceTable.Fields AS TEXT),'</Name>', ':' || CAST(X'09' AS TEXT))
									,'<?xml version="1.0" encoding="UTF-8"?>','')
							,'<Root><Fields>','')
						,'</Fields></Root>','')
					,'<Field><Name>', '')
				,'</Value>','')
			,'<Value>','')
		,'<Value/>','')
	,'</Field>',CAST (X'0D' AS TEXT)) 
         AS [Src Fields],
         SourceTable.ActualText,
         SourceTable.Comments,
         MediaCtr,
         SourceTable.IsPrivate,
         COUNT(CitationID) AS Citations,
         CASE
          WHEN SourceTable.TemplateID=0 THEN 'Free Form'
          WHEN SourceTemplateTable.TemplateID THEN SourceTemplateTable.Name COLLATE NOCASE
          ELSE 'ERROR: source template does not exist'
         END AS [Template],
         SourceTable.TemplateID AS [TpltID]
FROM     SourceTable 
         LEFT JOIN CitationTable USING (SourceID)
         LEFT JOIN SourceTemplateTable USING (TemplateID)
         LEFT JOIN
-- count media items linked to master source
(SELECT MediaLinkTable.OwnerID AS SourceID, COUNT() AS MediaCtr
FROM multimediatable
LEFT JOIN MediaLinkTable USING(MediaID)
WHERE MediaLinkTable.OwnerType=3
GROUP BY SourceID 
)
USING (SourceID)
GROUP BY SourceTable.SourceID
ORDER BY [Source Name]
