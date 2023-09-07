-- CitationSort-RM8.sql
/* 2022-07-06 Tom Holden ve3meo
Re-sorts the CitationLinkTable in order of Source Name, subsorted
by Citation Name which results in alphabetically sorted list of citations
for each fact. Also affects order of footnotes and endnotes at the fact level
and probably other areas where multiple sources are reported for a fact.
*/

REINDEX
;

DROP TABLE IF EXISTS zCitationLinkTable
;
CREATE TEMP TABLE zCitationLinkTable
AS 
  SELECT CL.* FROM CitationLinkTable CL
  LEFT JOIN CitationTable C USING (CitationID)
  LEFT JOIN SourceTable S USING (SourceID)
  ORDER BY S.Name, C.CitationName
;
UPDATE zCitationLinkTable
SET LinkID = Null
;

DELETE FROM CitationLinkTable
;

INSERT INTO CitationLinkTable
SELECT * FROM zCitationLinkTable
;

SELECT 'Completed. In RM8, run Files > Tools > Rebuild Indexes' AS Status
;
-- End of script --