# Overview

There are 1057 Ancestry.com jpg, png, docx, pdf, etc files that RootsMagic downloaded during
tree synchronization to `~/d/genealogy/roots-magic-09-06-2023_media/`.

Thus, some of these files occur with with more than one OnwerTypeDesc-OwnerName pair.
When the `OwnerTypeDesc = Person`, `OwnerName` is simply the name written in this order 
and manner: 

1. Surname all in caps
2. followed by a comma
3. followed by the given names
4. followed by a '-' and then `OwnerID` (which I assume is the `PersonID`)

When `OwnerTypeDesc` is `Event` or `Citation`, the `OwnerName` is followed by a suffix that begins with a `:` 
followed by more information. The other `OwnerTyepDesc` is `Alt Name`. This table summarizes all the
`OwnerTypeDesc` and their number of occurances:

Occurances | Type of owner
     16 OwnerTypeDesc = Alt. Name
   9714 OwnerTypeDesc = Citation
    330 OwnerTypeDesc = Event
    896 OwnerTypeDesc = Person

**Note:** There is no `EventType` given in the media.sql query.

## Plan

For the `OwnerName`:

1. Change the uppercase of surnames to lowercase - except first letter.
2. Remove the dash and what follows from the OwnerName

Some/many files change are references by other people and by more than one type of owner, as follows: 

* Create a folder for the right person person's name: `/Surnane-given-names`. Organize per the bookmarked article
by the librarian.

Then either keep the current file name, if descriptive enough, or use the OwnerName if it isn't. I couldn't
figure out the event(s) the image is for.

Is a person always referenced when an event or citation is?

Well, just save those whose EventOwner is Person, whether .jpg/.pdf/.docx files, and then see if among the
remaining list of filenames (for Citations, etc), there are any exceptions.

This approach is straight forward.
