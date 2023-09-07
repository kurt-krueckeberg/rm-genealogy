-- DeleteDuplicateCitationLinks-RM8.sql
/* 2021-07-18 Tom Holden ve3meo
RM8 Preview 7.9.310 can merge duplicate citations but such citations
linked or tagged to the same fact will produce duplicate links or 'uses'
for the merged citation. Moreover there appears to be no method of deleting
the duplicate links between fact and citation; deleting the citation from 
the fact deletes all the links to the fact.

This script deletes the duplicate links, leaving only one use of the 
merged citation per fact. 
It ignores differences in SortOrder, Quality, IsPrivate and Flags.
*/
DELETE
FROM CitationLinkTable
WHERE LinkID NOT IN (
		SELECT LinkID
		FROM CitationLinkTable
		GROUP BY CitationID
			,OwnerType
			,OwnerID
			-- only the first LinkID from the duplicates is listed
		);