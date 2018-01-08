# Scrapbook

Over the decades that I have been writing code, some pieces have stuck with me more than others, and I have copied them onto floppies, FTP'ed them down, pulled them over from computer to computer, and kept them more or less at hand to reminisce over whenever nostalgia should hit. In reverse chronological order they are:

## [JSONCache](https://github.com/andersblehr/JSONCache) (2017)

My first and so far only open source project (not counting [Origon](https://github.com/andersblehr/Origon) and [SheetMusicPlayer](https://github.com/andersblehr/SheetMusicPlayer), which for the time being are here only for historic and reference reasons). I was on a project working on an iOS app that required local caching of backend data, and after having hit a brick wall with [3lvis](https://github.com/3lvis)'s eminent [Sync](https://github.com/3lvis/Sync) library (due to [this bug](https://github.com/3lvis/Sync/issues/373)), I decided to roll my own. I had already implemented a data caching and replication framework for [Origon](https://github.com/andersblehr/Origon), so I knew it wouldn't be too hard. I plugged it into the app (which is under NDA, so I can't give details), and it has been working flawlessly ever since.

**Language:** Swift<br/>
**Platforms:** macOS, iOS, watchOS, tvOS

## [Origon - shared contact lists](https://github.com/andersblehr/Origon) (2012)

From [Origon's web page](https://origon.co):

> _With Origon's shared contact lists, everybody keeps their own contact information up to date. Whenever one of your contacts updates their address, email or phone number, you will have their updated information at your fingertips the next time you open Origon. This way, the contact lists always stay up to date._

This was the idea that I 'bet my house on' when I quit my day job in 2012. It took too long, was marketed too haphazardly (marketing most definitely is _not_ my strong suite), and the income was not sufficient to make a living. Then [Spond](https://spond.com/) launched with basically the same idea, and I realised Origon offered too little, if not too late.

Still, it was an invaluable learning experience, both technologically and personally.

**Language:** Objective-C<br/>
**Platform:** iOS (iPhone + iPad)

## [Origon backend](https://github.com/andersblehr/OrigonBackend) (2012)

To enable users to mirror each other's contact information, I built a REST API that interfaces with a replication framework that seemlessly persists changes from indvidual users to the backend, and pushes those same changes back out to linked users. It is hosted on [Google App Engine](https://cloud.google.com/appengine/) (GAE) and utilises [RESTEasy](http://resteasy.jboss.org) for the API and [Objectify](https://github.com/objectify/objectify) for interfacing with the GAE datastore.

**Language:** Java<br/>
**Platform:** Google App Engine

## [Sheet music player](https://github.com/andersblehr/SheetMusicPlayer) (2011)

With kids, you may happen upon a song, notes and all, when you read them their good night story. Or they may come home from daycare or school with a song sheet and want you to help them learn the song. Even though I play the piano and know how to read music, I am not able to sing directly from notes on a sheet, and I found myself wanting an app with which I could snap a photo of the music sheet and have it play the melody back to me. No such app existed, and I took it upon myself to create one. I had never done any mobile development, but I had an iPhone and a Mac, so I installed Xcode, dug out the same Digital Image Processing book I referenced in my [thesis](https://github.com/andersblehr/Scrapbook/tree/1993/Uni/Thesis/EyeTracker) back in 1993, and got going.

I got to a certain point when I realised that the hurdle I was struggling with was an artifact of my entire approach, and that I would have to start (almost) over to get past it. I still haven't started over, but if it hadn't been for this project, I might be still be shuffling papers around for a living, rather than write code.

**Language:** Objective-C<br/>
**Platform:** iOS (iPhone)

## [FAST Maven plugin](https://github.com/andersblehr/Scrapbook/tree/2007/Work/FastMavenPlugin)[*](#abandonware) (2007)

I was heading up FAST's Solution Architecture Centre in Europe, aiming to streamline how we delivered projects to customers. Each _Enterprise Search Platform_ (ESP) installation was different, but the underpinnings were the same. Still, installation and configuration had to be done manually by on-site or remote FAST engineers. I had a hunch that [Apache Maven](https://maven.apache.org) might help to automate a lot of the manual work, and itching to code again, I took it upon myself to develop an ESP plugin prototype for Maven.

**Language:** Java<br/>
**Platform:** Linux, Windows

## FAST search components[*](#abandonware) (2000-2001)

Working as a developer in FAST's R&D department, I was tasked with developing a generic **[tokenizer](https://github.com/andersblehr/Scrapbook/tree/2001/Work/FastTokenizer)** that would decompose raw data into indexable words, independently of source language (including Chinese and other East Asian languages). Another component I developed, was a **[SAX wrapper](https://github.com/andersblehr/Scrapbook/tree/2001/Work/FastSAXWrapper)** that abstracted away the implementation details of [libxml](http://xmlsoft.org) and other third party [SAX](https://en.wikipedia.org/wiki/Simple_API_for_XML) interfaces, effectively letting us inject whichever SAX library suited us best. Lastly, based on my experience with having to [convert to FiXML](https://github.com/andersblehr/Scrapbook/tree/2000/Work/FastIndexingPreprocessor) any raw data other than HTML, I developed a generic **[XML indexer](https://github.com/andersblehr/Scrapbook/tree/2001/Work/FastXMLIndexer)** that could index any set of well-formed XML documents.

**Language:** C++<br/>
**Platform:** Linux

## [FAST indexing preprocessor](https://github.com/andersblehr/Scrapbook/tree/2000/Work/FastIndexingPreprocessor)[*](#abandonware) (2000)

At the time that FAST's [alltheweb.com](https://en.wikipedia.org/wiki/AlltheWeb) was competing head to head with Google to be the first search engine to index 1 billion web documents, I was working on-site with [LookSmart](http://www.looksmart.com) in San Francisco to have their curated internet directory be powered by FAST Search. To index the directory, it first had to be exported and converted to _FAST indexing XML_ (FiXML). The raw directory export was in a format referred to internally as [Mirkwood](https://en.wikipedia.org/wiki/Mirkwood), and I wrote this suite of Perl scripts to convert it to indexable FiXML.

**Language:** Perl<br/>
**Platform:** Solaris

## [Reactive rules engine](https://github.com/andersblehr/Scrapbook/tree/1999/Work/ReactiveRulesEngine)[*](#abandonware) (1999)

To be continued...

**Language:** PL/SQL<br/>
**Platform:** Oracle

## [Client architecture](https://github.com/andersblehr/Scrapbook/tree/1995/Work/ClientArchitecture)[*](#abandonware) (1995)

To be continued...

**Language:** C<br/>
**Platform:** OS/2, Windows

## [mbox reader](https://github.com/andersblehr/Scrapbook/tree/1994/Hobby/MboxReader) (1994)

To be continued...

**Language:** Turbo Pascal<br/>
**Platform:** DOS

## [Master's Thesis: A Software-Based Approach to Real-Time Eye-Tracking](https://github.com/andersblehr/Scrapbook/tree/1993/Uni/Thesis/EyeTracker) (1993)

To be continued...

**Language:** Turbo Pascal<br/>
**Platform:** DOS

## [Utilities collection](https://github.com/andersblehr/Scrapbook/tree/1992/Uni/UtilitiesCollection) (1992)

To be continued...

**Language:** Turbo Pascal<br/>
**Platform:** DOS

## [HyperHelp](https://github.com/andersblehr/Scrapbook/tree/1992/Internship/HyperHelp) (1992)

To be continued...

**Language:** Turbo Pascal<br/>
**Platform:** DOS

## [Visual cortex filter](https://github.com/andersblehr/Scrapbook/tree/1992/Internship/VisualCortexFilter)[*](#abandonware) (1992)

To be continued...

**Language:** Turbo Pascal<br/>
**Platform:** DOS

## [Candidate elimination](https://github.com/andersblehr/Scrapbook/tree/1992/Uni/CandidateElimination) (1992)

To be continued...

**Language:** Prolog<br/>
**Platform:** SunOS

## [Natural language shell](https://github.com/andersblehr/Scrapbook/tree/1992/Uni/NaturalLanguageShell) (1992)

To be continued...

**Language:** Prolog<br/>
**Platform:** SunOS

## [ATM interface](https://github.com/andersblehr/Scrapbook/tree/1992/Uni/Minibank) (1992)

To be continued...

**Language:** Smalltalk<br/>
**Platform:** SunOS

---<br/>
<small><a id="abandonware">*</a> [Abandonware](https://en.wikipedia.org/wiki/Abandonware) still under copyright. However, as the original author of this work, I claim [fair use](https://en.wikipedia.org/wiki/Fair_use)</small>.