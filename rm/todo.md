# Overview

Roots MAgic sychronization with Ancestry.com downloaded 1057 files--jpg, png, docx, pdf, etc--to `~/d/genealogy/roots-magic-09-06-2023_media/`.

`media.sql`, from <https://sqlitetoolsforrootsmagic.com/>, lists where media items are used and their key properties. 

In the query results, some of file names, `MediaFile`, occur more than once. This is because there are four possible `OwnerTypeDesc` values:

1. Alt. Name
2. Citation
3. Event
4. Person

They occur with this frequency:

```
Occurances | Type of owner
     16 OwnerTypeDesc = Alt. Name
   9714 OwnerTypeDesc = Citation
    330 OwnerTypeDesc = Event
    896 OwnerTypeDesc = Person
```

## Analysis of OwnerTypeDesc and OwnerName

The `OwnerName` differs depending on the `OwnerTypeDesc`. The format of `OwnerName`, of the person's name, when `OwnerTypeDesc = Person`
or `OwerTypeDesc = Alt. Name` is:

```
OwnerName = RIEHL, Anna E-3132
```

The format is:

1. First, the surname all in caps
2. followed by a comma
3. followed by the given names
4. followed by a '-' and then the `OwnerID` (which I assume is the `PersonID`)

When `OwnerTypeDesc` is `Event` or `Citation`, the `OwnerName` has an additional suffix information introduced with `:`.
The `OwnerName` suffix for `OwnerTypeDesc = Event` is a subset of at least one of the `OwerTypeDesc = Citation` as shown below:

`Event` suffix information examples:

```
OwnerTypeDesc = Event
OwnerName = WEBER, Emilie F-3176:  AUGUST W. BUSSE

OwnerTypeDesc = Event
OwnerName = WEBER, Emilie F-3176:  AUGUST W. BUSSE
```

Question: For every `OwnerTypeDesc = Event` is there also a `OwerTypeDesc = Citation` entry?

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
