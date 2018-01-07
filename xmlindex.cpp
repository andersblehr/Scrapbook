/*****************************************************************************
 * xmlindex.cpp
 *
 * Generic XML indexer that uses a mapping file to map from XML tags
 * (elements) to contexts, summary fields, and rank fields.  The FAST Indexing
 * API (FIXAPI) is used to do the actual indexing.  FastSAX is used for XML
 * parsing, and the FAST tokenizer is used for tokenizing.  In addition, the
 * logging and error handling utilities in "ftutil", currently (February 2001)
 * part of the FAST tokenizer CVS module, is used to do logging and error
 * handling.
 *
 * Copyright (c): 1997-2001 Fast Search & Transfer ASA
 *                ALL RIGHTS RESERVED
 * 
 * Created by: Anders Blehr, Fast Search & Transfer ASA.
 * $Id: xmlindex.cpp,v 1.2 2001/02/15 14:10:54 ablehr Exp $
 * $Log: xmlindex.cpp,v $
 * Revision 1.2  2001/02/15 14:10:54  ablehr
 * - Bugfix
 *
 * Revision 1.1.1.1  2001/02/06 11:52:52  ablehr
 * - Initial import into CVS.  No documentation at this stage.
 *
 *****************************************************************************/

#include <fastlib/log/filelogger.h>
#include <ftutil/Fast_LogHandler.h>
#include <fastsax/FastSAX.h>

#include "FastS_XMLIndexer.h"


#define _C_PROGRAM_VERSION  "1.0"


/*****************************************************************************
 * displayUsage --
 *
 * Display usage information for the application.
 *****************************************************************************/
void displayUsage(const char * moduleName)
{
  printf("\n");
  printf("%s: Version %s.\n", moduleName, _C_PROGRAM_VERSION);
  printf("\n");
  printf("Copyright (c) 2001: Fast Search & Transfer ASA\n");
  printf("\n");
  printf("\n");
  printf("Usage: %s -c <file> -i <dir> -m <file> [options] <input files>\n",
         moduleName                                                   );
  printf("\n");
  printf("Options:\n");
  printf("  -h          Help (displays this information)\n");
  printf("  -c file     Index configuration file (XML) (required)\n");
  printf("  -e encoding Input encoding (default = UTF-8)\n");
  printf("  -i dir      Index directory (required)\n");
  printf("  -m file     Mapping file (required)\n");
  printf("  -p num      Data partition number (default = 0)\n");
  printf("  -s parser   SAX parser to use for XML parsing (default = libxml)\n");
  printf("  -v num      Verbosity level (0-5; default = 0)\n");
  printf("\n\n");

  exit(EXIT_FAILURE);
}


/*****************************************************************************
 * main --
 *
 * Main program.
 *****************************************************************************/
int main(int argc, char ** argv) try
{
  Fast_LogHandler *  logHandler;
  FastS_XMLIndexer * indexer;
  char               option;
  Fast_String        configFile;
  Fast_String        encoding;
  Fast_String        indexDir;
  Fast_String        mappingFile;
  Fast_String        SAXParser(_C_SAXTYPE_DEFAULT);
  int                partition = 0;
  int                i;

  /* Create a log manager instance and retrieve the top level log handler */
  logHandler = Fast_LogManager::CreateInstance(argv[0]);

  /* Register stderr as a log destination (for screen output) */
  logHandler->RegisterLogDestination(new Fast_FileLogger("stderr"));

  /* Retrieve command line options and set fatal errors if errors are found */
  while ((option = getopt(argc, argv, "c:e:hi:m:p:s:v:")) != -1)
  {
    switch (option)
    {
      case 'c': /* Configuration file; required */
        configFile = optarg;
        break;
      case 'e':
        encoding = optarg;
        break;
      case 'h': /* Help */
        displayUsage(argv[0]);
        break;
      case 'i': /* Index directory; required */
        indexDir = optarg;
        break;
      case 'm': /* Mapping file; required */
        mappingFile = optarg;
        break;
      case 'p': /* Data partition number, must be number (optional; default 0) */
        if (!isdigit(optarg[0]))
          logHandler->SetFatal("Expected number for option -p, got %s\n", optarg);
        partition = atoi(optarg);
        break;
      case 's': /* SAX parser (optional; default libxml) */
        SAXParser = optarg;
        break;
      case 'v': /* Verbosity, must be number (optional; default 0) */
        if (!isdigit(optarg[0]))
          logHandler->SetFatal("Expected number for option -v, got %s\n", optarg);
        logHandler->SetVerbosity(atoi(optarg));
        break;
      default:
        displayUsage(argv[0]);
        break;
    }
  }

  /* Display usage if we don't have all we need to proceed */
  if ((optind == argc) ||
      (configFile == "") || (indexDir == "") || (mappingFile == ""))
    displayUsage(argv[0]);

  /* Create the parser factory to be used throughout the application */
  FastSAX_ParserFactory::createFactory(SAXParser);

  /* Create and initialize the FastS_XMLIndexer instance */
  indexer = new FastS_XMLIndexer(configFile, indexDir, mappingFile, partition);
  indexer->initialize();

  /* Set the input encoding if supplied (UTF-8 will be expected otherwise) */
  if (encoding != "")
    indexer->setInputEncoding(encoding);

  /* Index all files given on the command line */
  for (i = optind; i < argc; i++)
    indexer->index(argv[i]);

  /* Finalize the index */
  indexer->finalize();

  /* Log information about how many files and documents were indexed */
  logHandler->LogInfo("XML files processed : %u", argc - optind);
  logHandler->LogInfo("Documents OK        : %u", indexer->getNumDocumentsOK());
  logHandler->LogInfo("Documents aborted   : %u",
                      indexer->getNumDocumentsAborted());

  /* Delete the FastS_XMLIndexer instance */
  delete indexer;

  /* Delete singleton instances */
  FastSAX_ParserFactory::destroyFactory();
  Fast_LogManager::DeleteInstance();

  return 0;
}
catch (Fast_Exception& exception)
{
  exception.DefaultAction();
}
