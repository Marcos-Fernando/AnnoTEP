#!/home/amvarani/miniconda3/envs/EDTA/bin/perl
#
##---------------------------------------------------------------------------##
##  File:
##      @(#) ProcessRepeats
##  Authors:
##      Arian Smit <asmit@systemsbiology.org>
##      Robert Hubley <rhubley@systemsbiology.org>
##  Description:
##      Takes RepeatMasker output and produces an annotation table.
##
##
#******************************************************************************
#*
#* Copyright (C) Institute for Systems Biology 2002-2012 Developed by
#* Arian Smit and Robert Hubley.
#*
#* Copyright (C) Arian Smit 2000-2001
#*
#* Copyright (C) University of Washington 1996-1999 Developed by Arian Smit,
#* Philip Green and Colin Wilson of the University of Washington Department of
#* Genomics.
#*
#* This work is licensed under the Open Source License v2.1.  To view a copy
#* of this license, visit http://www.opensource.org/licenses/osl-2.1.php or
#* see the license.txt file contained in this distribution.
#*
###############################################################################
# ChangeLog
#
#   $Log: ProcessRepeats,v $
#   Revision 1.279  2017/02/01 21:01:54  rhubley
#   Cleanup before a distribution
#
#
###############################################################################
#
#

=head1 NAME

ProcessRepeats - Post process results from RepeatMasker and produce an annotation file.

=head1 SYNOPSIS

  ProcessRepeats [-options] <RepeatMasker *.cat file>

=head1 DESCRIPTION

The options are:

=over 4

=item -h(elp)

Detailed help

=item -species <query species> 

Post process RepeatMasker results run on sequence from
this species.  Default is human.

=item -lib <libfile>

Skips most processing, does not produce a .tbl file unless
the custome library is in the ">name#class" format.

=item -nolow 

Does not display simple repeats or low_complexity DNA in the annotation.

=item -noint 

Skips steps specific to interspersed repeats, saving lots of time.

=item -lcambig

Outputs ambiguous DNA transposon fragments using a lower case
name.  All other repeats are listed in upper case.  Ambiguous 
fragments match multiple repeat elements and can only be
called based on flanking repeat information.

=item -u     

Creates an untouched annotation file besides the manipulated file.

=item -xm    

Creates an additional output file in cross_match format (for parsing).

=item -ace

Creates an additional output file in ACeDB format.

=item -gff   

Creates an additional Gene Feature Finding format.

=item -poly  

Creates an output file listing only potentially polymorphic simple repeats.

=item -no_id 

Leaves out final column with unique number for each element (was default).

=item -excln 

Calculates repeat densities excluding long stretches of Ns in the query.

=item -orf2   

Results in sometimes negative coordinates for L1 elements; all L1 subfamilies
are aligned over the ORF2 region, sometimes improving interpretation of data.

=item -a     

Shows the alignments in a .align output file.

=item -maskSource <originalSeqenceFile> 

Instructs ProcessRepeats to mask the sequence file using the annotation.

=item -x        

Mask repeats with a lower case 'x'.

=item -xsmall   

Mask repeats by making the sequence lowercase.

=back

=head1 SEE ALSO

=over 4

RepeatMasker, Crossmatch, Blast

=back

=head1 COPYRIGHT

Copyright 2002-2012 Arian Smit, Robert Hubley,  Institute for Systems Biology

=head1 AUTHORS

Arian Smit <asmit@systemsbiology.org>

Robert Hubley <rhubley@systemsbiology.org>

=cut

# 
# Module Dependence
# 
use strict;
use FindBin;
use lib $FindBin::RealBin;
use SeqDBI;
use FileHandle;
use FastaDB;
use SearchResult;
use SearchEngineI;
use SearchResultCollection;
use ArrayList;
use CrossmatchSearchEngine;
use Getopt::Long;
use Taxonomy;
use Data::Dumper;
use PRSearchResult;
use Matrix;

# New home for RepeatAnnotationData
use lib "$FindBin::RealBin/Libraries";
use RepeatAnnotationData;

# Global variables
my $DEBUG     = 0;
my $DIRECTORY = "$FindBin::Bin";

#
#  Refinement Hash:
#     Contains re-alignments for *.cat alignments which were refined.
#     structure is as follows:
#         $refinementHash{ "b#s#i#" }->{ ConsensusID } = ( annot1ref, annot2ref, ...)
#
my %refinementHash = ();    # Contains refined annotations ordered by catID
my %chainSeq1Length;

# A bug in 5.8 produces way too many warnings
if ( $] && $] >= 5.008003 ) {
  use warnings;
}

#
# Option processing
#  e.g.
#   -t: Single letter binary option
#   -t=s: String parameters
#   -t=i: Number paramters
#
my @opts =
    qw (a ace debug excln gff lib=s noint nolow orf2 orifile=s no_id poly species=s u xm mammal mus rat rod|rodent cow pig artiodactyl cat dog carnivore chicken fugu danio drosophila elegans arabidopsis rice wheat maize primate maskSource=s xsmall x lcambig source html );

#
# Get the supplied command line options, and set flags
#
my %options = ();
unless ( &GetOptions( \%options, @opts ) ) {
  exec "pod2text $0";
  exit( 0 );
}

## Print the internal POD documentation if something is missing
if ( $#ARGV == -1 && !$options{'help'} ) {
  print "No cat file indicated\n\n";

  # This is a nifty trick so we don't have to have
  # a duplicate "USAGE()" subroutine.  Instead we
  # just recycle our POD docs.  See PERL POD for more
  # details.
  exec "pod2text $0";
  die;
}

##
## option -source is now a deprecated option.  We only save
## the source alignments if -a is used
##
if ( $options{'a'} ) {
  $options{'source'} = 1;
}
else {
  $options{'source'} = 0;
}

##
## Species Options and Taxonomy Processing
##
## NOTE: Tax needs to be global for the moment
#my $tax;
#if ( $options{'species'} ) {

  # Need to set opt_species, opt_mammal, opt_mus
#  $tax =
#      Taxonomy->new( taxonomyDataFile => "$DIRECTORY/Libraries/taxonomy.dat" );
#      Taxonomy->new( famdbfile => "$DIRECTORY/Libraries/RepeatMaskerLib.h5" );

#  if ( $tax->isA( $options{'species'}, "primates" ) ) {
#    $options{'primate'} = 1;
#  }
#  elsif ( $tax->isA( $options{'species'}, "rodentia" ) ) {
#    $options{'mus'} = 1;
#  }
#  elsif ( $tax->isA( $options{'species'}, "mammalia" ) ) {
#    $options{'mammal'} = 1;
#  }
#}
#else {
#  $options{'species'} = "homo";
#  $options{'primate'} = 1;
#}

# warning for debug mode
print "Note that in debug mode the IDs are not adjusted to go up stepwise\n\n"
    if $options{'debug'};

#
# Check library type used
#
# TODO: We need different levels of meta data compliance.  Ie.
#       Pound formatting isn't enough anymore. Also we can glean
#       compliance like pound formatting from the cat file.  No
#       need to open up the lib ( yet ).
my $poundformat = "";
if ( $options{'lib'} ) {
  open( IN, $options{'lib'} );
  while ( <IN> ) {
    if ( /^>\S+\#\S+/ ) {
      $poundformat = 1;

      # Assuming that this represents my classification formatting; no sure
      # thing could make it more restrictive by also requiring a backslash
      last;
    }
  }
}
else {
  $poundformat = 1;
}

#
# Loop over input files
#
foreach my $file ( @ARGV ) {
  if ( $file =~ /.*\.gz$/ ) {
    open( INCAT, "gunzip -c $file |" ) || die "Can\'t open file $file\n";
  }
  else {
    open( INCAT, $file ) || die "Can\'t open file $file\n";
  }

  # INITIALIZE CAT FILE DATA
  #   Read the cat file and calculate:
  #     - The length of the original sequence ( minus 1/2 of the overlap )
  #     - The number of N bases
  #     - The number of sequences
  #     - The length of each sequence
  #     - The fraction GC the version the masked length and the dbversion.
  #   Also...grab batch overlap boundaries if information is present.
  my %batchOverlapBoundaries         = ();
  my $numSearchedSeqs                = 0;
  my $lenSearchedSeqs                = 0;
  my $lenSearchedSeqsExcludingXNRuns = 0;
  my $lenSearchedSeqsExcludingAmbig  = 0;
  my $versionmode                    = "";
  my $engine                         = "";
  my $dbversion                      = "";

  while ( <INCAT> ) {
    if ( /^##\s*(\S+)\s+([\d\s,]+)/ ) {
      $batchOverlapBoundaries{$1} = [ sort( split( /,/, $2 ) ) ];
    }
    elsif ( /^##\s*Total\s+Sequences:\s*(\d+)/i ) {
      $numSearchedSeqs = $1;
    }
    elsif ( /^##\s*Total\s+Length:\s*(\d+)/i ) {
      $lenSearchedSeqs = $1;
    }
    elsif ( /^##\s*Total\s+NonMask.*:\s*(\d+)/i ) {
      $lenSearchedSeqsExcludingXNRuns = $1;
    }
    elsif ( /^##\s*Total\s+NonSub.*:\s*(\d+)/i ) {
      $lenSearchedSeqsExcludingAmbig = $1;
    }
    elsif ( /^RepeatMasker|run|RepBase/ ) {
      my @bit = split;
      $versionmode = $_ if $bit[ 0 ] eq 'RepeatMasker';
      $engine = $1 if /^(run with.*)/;
      if ( /^(RepBase.*)/ ) {
        $dbversion = $1;
        last;
      }
    }
  }
  close INCAT;

  #
  #  Parse the cat file into an object
  #
  my $sortedAnnotationsList = undef;

  # Always read in alignment data
  $sortedAnnotationsList = &parseCATFile( file => $file );

  #
  # Separate out refined annotations
  #
  my $annotIter = $sortedAnnotationsList->getIterator();
  while ( $annotIter->hasNext() ) {
    my $currentAnnot = $annotIter->next();

    if ( $currentAnnot->getClassName() eq "" ) {
      $currentAnnot->setClassName( "Unspecified" );
    }
    if ( $currentAnnot->getLineageId() =~ /\[/ ) {
      $annotIter->remove();
      $currentAnnot->setOrientation( "+" )
          if ( $currentAnnot->getOrientation() ne "C" );

      my $catID = $currentAnnot->getLineageId();
      die "Missing cat file ID for refined element!"
          . Dumper( $currentAnnot ) . "\n"
          if ( $catID eq "" );
      $catID =~ s/[\[\]]//g;
      push @{ $refinementHash{$catID}->{ $currentAnnot->getHitName() } },
          ( $currentAnnot );
    }
  }

  # Create some filename constants
  my $catfile = $file;
  $file =~ s/\.(temp)?cat(.gz)?$//;
  my $filename = $file;
  $filename =~ s/(.*\/)//;

  unless ( $sortedAnnotationsList->size() > 0 ) {
    my $filenaam = $file;
    $filenaam = $options{'orifile'} if $options{'orifile'};
    open( OUT, ">$file.out" );
    print "\n\n\nNo repetitive sequences were detected in $filenaam\n";
    print OUT "There were no repetitive sequences detected in $filenaam\n";
    close( OUT );
    next;
  }

  print "processing output: ";

  open( OUTRAW, ">$file.ori.out" ) if ( $options{'u'} || !$poundformat );

  #
  # Initialize data structures and ID each annotation
  #
  # Makes global %seq1Lengths
  #   NOTE: Only needed because we are not updating LeftOver
  #         when we modify Seq1Beg/End
  #
  $sortedAnnotationsList->sort( \&byNameBeginEndrevSWrev );
  my $cycleAnnotIter = $sortedAnnotationsList->getIterator();
  my %seq1Lengths    = ();
  my $i              = -1;
  while ( $cycleAnnotIter->hasNext() ) {
    $i++;
    my $currentAnnot = $cycleAnnotIter->next();

    $currentAnnot->setPRID( $i );
    $currentAnnot->setOrientation( "+" )
        if ( $currentAnnot->getOrientation() ne "C" );

    # Do this early so we capture all information before it is changed.
    # NOTE: I may make derived elements links to the cat file for
    #       memory brevity.
    if ( $options{'source'} ) {
      $currentAnnot->addDerivedFromAnnot( $currentAnnot );
      $currentAnnot->setAlignData( undef );
    }

    my $HitName = $currentAnnot->getHitName();
    $HitName =~ s/_short_$//;

    # RMH 11/21/12: Added for Dfam
    $HitName =~ s/_offset$//;
    $currentAnnot->setHitName( $HitName );
    if ( !defined $seq1Lengths{ $currentAnnot->getQueryName() }
         || $seq1Lengths{ $currentAnnot->getQueryName() } <
         ( $currentAnnot->getQueryEnd() + $currentAnnot->getQueryRemaining() ) )
    {
      $seq1Lengths{ $currentAnnot->getQueryName() } =
          $currentAnnot->getQueryEnd() + $currentAnnot->getQueryRemaining();
    }
  }

  print "\ncycle 1 ";

  #printHitArrayList( $sortedAnnotationsList );
  my ( $chainBegRef, $chainEndRef ) = &cycleReJoin( $sortedAnnotationsList );

  my %chainBeg = %{$chainBegRef};
  my %chainEnd = %{$chainEndRef};

  ##########################  C Y C L E   2  ###############################
  # Purpose: Remove Edge Effect Annotations
  #          Remove Masklevel violations
  #          Rename Satellite Shifted Copies
  #          build DNA transposon equivalency datastructure
  ##########################################################################
  print "\ncycle 2 ";

  # Sort by name, begin position, and end position descending
  $sortedAnnotationsList->sort( \&byNameBeginEndrevSWrev );

  # Create an ArrayListIterator for this cycle
  $cycleAnnotIter = $sortedAnnotationsList->getIterator();

  my %colWidths = &getMaxColWidths( $sortedAnnotationsList );
  my $DEBUG     = 0;
  $i = -1;
CYCLE2:
  while ( $cycleAnnotIter->hasNext() ) {
    $i++;
    print "." if ( $i + 1 ) % 1000 == 0;

    # NOTE: An iterator's index is considered
    #       to be in between elements of a datastructure.
    #       To obtain the correct index for the
    #       current element in this pass we should
    #       get the index *before* we move the iterator.
    my $currentIndex = $cycleAnnotIter->getIndex();
    my $currentAnnot = $cycleAnnotIter->next();

    if ( $DEBUG ) {
      print "CYCLE2: Considering\n";
      $currentAnnot->print();
    }

    # TODO: This recursion violation code might not be necessary
    # once the cycleReJoin code is changed to use the new *.cat ID field
    # or not:  What if RM fragmented two overlapping alignments:
    #   maskelevel 90:
    #                            ------^-------->
    #                        ----------^----->
    #          You would have
    #                            ++++++++++
    #                      -----/          \--------->
    #                            ++++++++++
    #  and      ----------------/          \----->
    #
    #   HMMM...have to think about this.  This is a fine dance with the
    #          search engine maskelevel parameter.
    #
    if ( $currentAnnot->getRightLinkedHit() ) {
      my $proxIter = $cycleAnnotIter->getIterator();
      while ( $proxIter->hasNext() ) {
        my $nextAnnot = $proxIter->next();

        # Quit once we reach our partner
        last if ( $nextAnnot == $currentAnnot->getRightLinkedHit() );

        # Break Recursion Violations
        if ( $currentAnnot->containsElement( $nextAnnot )
          && $nextAnnot->containsElement( $currentAnnot->getRightLinkedHit() ) )
        {
          if ( $DEBUG ) {
            print "This violates recursion:\nFirst:\n";
            $currentAnnot->printLeftRightLinks();
            print "Second:\n";
            $nextAnnot->printLeftRightLinks();
          }

          # Break lower scoring link
          my $oldRight = $nextAnnot->getRightLinkedHit();
          $nextAnnot->setRightLinkedHit( undef );
          $oldRight->setLeftLinkedHit( undef );
        }
      }
    }

    ##
    ##  Edge Effect Removal
    ##
    ##  The current method of processing overlaps, while better
    ##  than before still produces some edge effects.  This
    ##  section attempts to remove these before we start any
    ##  serious analysis.
    ##
    ##  Overlaps are handled in RepeatMasker thus:
    ##
    ##                     Middle
    ##          <------      |
    ##                    ----->
    ##    Batch#1            |  ----x---->
    ##    ...-----------------------------|
    ##                       |
    ##                       |
    ##             |-----------------------------...
    ##                       |               BATCH#2
    ##              <-x-     |
    ##                     ---->
    ##                       |  ---------------->
    ##
    ##
    ## RepeatMasker deletes all annotations which are
    ## contained in the region left/right ( closest to
    ## the edge ) of the overlap midpoint. Shown here
    ## with an "x" in the diagram annotations.
    ## If an annotation spans the midpoint it is kept
    ## in the cat file.  This leaves several types of
    ## edge effects in annoation:
    ##
    ## Perfect or Near Perfect duplicates.  Perfect if
    ## the same matrix was used and the annotation is
    ## completely contained in the overlap.  Near perfect
    ## otherwise.
    ##
    ##                     Middle
    ##                       |
    ##                     ----->
    ##                       |
    ##                     ----->
    ##
    ##
    ## Cut Level Ambiguities.  A full length young repeat
    ## partially contained in the overlap will be excised
    ## at a lower cutlevel in one batch and masked at
    ## a higher cutlevel in the other batch. See below
    ## for some examples.
    ##
    ##
    # Remove exact duplicates.  Near duplicates get resolved elsewhere
    # ( FuseOverlappingSeqs etc ). We do this now especially to handle
    # duplicated poly-a tails that we are about to join.
    my $prevAnnot = $sortedAnnotationsList->get( $currentIndex - 1 )
        if ( $currentIndex > 0 );
    if (    $prevAnnot
         && $currentAnnot->getScore() == $prevAnnot->getScore()
         && $currentAnnot->getPctDiverge() == $prevAnnot->getPctDiverge()
         && $currentAnnot->getQueryName() eq $prevAnnot->getQueryName()
         && $currentAnnot->getQueryStart() == $prevAnnot->getQueryStart()
         && $currentAnnot->getQueryEnd() == $prevAnnot->getQueryEnd() )
    {

      #  Lower Scoring Overlap > %90 Covered by Higher Scoring
      #  Get rid of lower scoring one
      #  same cutlevel
      if ( $DEBUG ) {
        print "REMOVING EXACT DUPLICATE:\n";
        $currentAnnot->print();
        print "  because of:\n";
        $prevAnnot->print();
      }

      #$prevAnnot->addDerivedFromAnnot( $currentAnnot )
      #    if ( $options{'source'} );

      # Fix any previous joins to this element
      $currentAnnot->removeFromJoins();
      $cycleAnnotIter->remove();
      next CYCLE2;
    }

    #
    #    If a large >1000bp ( 1/2 current overlap distance )
    #    young repeat starts outside the overlap and spans
    #    the middle of the overlap you will get edge effect
    #    duplications.  I.e.
    #
    #  Case #1              Middle
    #      batch1             |
    #      ---------------------------|
    #           ----------------->   ( excised cutlevels 0-4 )
    #                   ----X---->   ( masked cutlevel 5 )
    #                  |------------------------------
    #                         |                  batch2
    #                         |
    # or                      |
    #      batch1             ----X-->  ( masked cutlevel 5 )
    #      ----------------------------|
    #                  |------------------------------- batch2
    #                         -----------------> ( excised cutlevel 0-4 )
    #                         |
    #
    #    Because excision is only performed on full length
    #    elements (lines can be 5' truncated) this can be
    #    detected by checking for elements which are contained by
    #    a masked annotation *and* are cut out.
    #
    #  Case #2              Middle
    #                         |
    #                         <---X---  (masked..just outside the other )
    #      ----------------------------|
    #                  |-------------------------------
    #                         | <---------- (cut)
    #                         |
    #                         |
    #  Case #3                |
    #          (masked)  -->  |
    #                       -------> (cut)
    #     -----------------------------|
    #                  |----------------------------
    #                    X>   |
    #                      -------->
    #
    #  In this case you have a cut out element spaning a middle
    #  which is one bp longer in one batch.  This creates
    #  a 1bp overlap with a something which has been masked.
    #
    #  So our general rule ends up: Remove all masked elements
    #  which overlap ( by > 10bp ) or are contained by another
    #  cut out element.
    #  These cases should never occur outside the overlap
    #  region anyway.
    #
    if ( $currentAnnot->isMasked() ) {
      my $proxIter = $cycleAnnotIter->getIterator();
      $proxIter->previous();
      while ( $proxIter->hasPrevious() ) {
        my $prevAnnot = $proxIter->previous();
        last
            unless ( $currentAnnot->getQueryName eq $prevAnnot->getQueryName()
               && $prevAnnot->getQueryEnd() >= $currentAnnot->getQueryStart() );
        if (  $prevAnnot->isCut()
           && $prevAnnot->getQueryEnd() - $currentAnnot->getQueryStart() >= 10 )
        {
          if ( $DEBUG ) {
            print "DELETING MASKED INSIDE CUT:\n";
            $currentAnnot->print();
            print "  because of previous:\n";
            $prevAnnot->print();
          }

          # Fix any previous joins to this element
          $currentAnnot->removeFromJoins();
          $cycleAnnotIter->remove();
          next CYCLE2;
        }
      }

      $proxIter = $cycleAnnotIter->getIterator();
      while ( $proxIter->hasNext() ) {
        my $nextAnnot = $proxIter->next();
        last
            unless ( $currentAnnot->getQueryName eq $nextAnnot->getQueryName()
               && $nextAnnot->getQueryStart() <= $currentAnnot->getQueryEnd() );
        if (  $nextAnnot->isCut()
           && $currentAnnot->getQueryEnd() - $nextAnnot->getQueryStart() >= 10 )
        {
          if ( $DEBUG ) {
            print "DELETING MASKED INSIDE CUT:\n";
            $currentAnnot->print();
            print "  because of next:\n";
            $nextAnnot->print();
          }

          #$nextAnnot->addDerivedFromAnnot( $currentAnnot )
          #    if ( $options{'source'} );

          # Fix any previous joins to this element
          $currentAnnot->removeFromJoins();
          $cycleAnnotIter->remove();
          next CYCLE2;
        }
      }
    }

    #
    # Masklevel Violations From Clipping Boundaries
    #
    #   RepeatMasker fragments alignments which span
    # cut out elements.  This fragmentation process may
    # convert a pair of alignments like:
    #
    #       --------------^------------->     SW=1000
    #          -----------^----------------->  SW=1500
    #
    # ( where "^" marks the site of a clipped out element )
    # into something like:
    #
    #         SW = 1000          SW = 1000
    #       -------------->     ------------->
    #          ----------->     ----------------->
    #            SW = 1500       SW = 1500
    #
    # This little block of code resolves this masklevel
    # rule-breaker ( lower scoring alignment contained by
    # higher scoring one ) by elminating the lower scoring
    # subfragments.
    #
    # i.e Delete element if flanking elements include
    # it and has a better or equal score.
    #
    #         SW = 1000
    #       -------------->
    #          ----------->     ----------------->
    #            SW = 1500       SW = 1500
    #
    # This is still a bit artificial.
    #
    $prevAnnot = $sortedAnnotationsList->get( $currentIndex - 1 )
        if ( $currentIndex > 0 );
    my $proxIter = $cycleAnnotIter->getIterator();
    my ( $prevHitName, $prevClassName ) =
        split( /\#/, $prevAnnot->getSubjName() )
        if ( $prevAnnot );

    #
    # Delete iff:
    #       ----current-----^   SW <= past
    #       -----past-------^
    #  -..----past----------^
    #
    #   or
    #       ^---current-----   SW <= past
    #       ^----past-------
    #       ^------past----------...--
    #
    if (
         $prevAnnot
         && (
              (
                   $currentAnnot->getQueryEnd() == $prevAnnot->getQueryEnd()
                && $currentAnnot->getScore() <= $prevAnnot->getScore()
                && $currentAnnot->getQueryName() eq $prevAnnot->getQueryName()
                && $currentAnnot->getClassName() eq $prevClassName
              )
              || ( $currentAnnot->getQueryStart() == $prevAnnot->getQueryStart()
                  && $currentAnnot->getQueryEnd() <= $prevAnnot->getQueryEnd()
                  && $currentAnnot->getScore() <= $prevAnnot->getScore()
                  && $currentAnnot->getQueryName() eq $prevAnnot->getQueryName()
                  && $currentAnnot->getClassName() eq $prevClassName )
         )
        )
    {
      if ( $DEBUG ) {
        print "Deleting clipping boundary fragment "
            . "( masklevel violation ):\n";
        $prevAnnot->print();
        $currentAnnot->print();
      }

      #$prevAnnot->addDerivedFromAnnot( $currentAnnot )
      #    if ( $options{'source'} );

      # Fix any previous joins to this element
      $currentAnnot->removeFromJoins();
      $cycleAnnotIter->remove();
      next CYCLE2;
    }

    my $Seq2BeginPrint     = $currentAnnot->getSubjStart();
    my $LeftUnalignedPrint = "(" . $currentAnnot->getSubjRemaining() . ")";
    my $LeftOverPrint      = "(" . $currentAnnot->getQueryRemaining() . ")";
    if ( $currentAnnot->getOrientation() eq "C" ) {
      $Seq2BeginPrint     = "(" . $currentAnnot->getSubjRemaining() . ")";
      $LeftUnalignedPrint = $currentAnnot->getSubjStart();
    }

    #
    # Supposedly creates an untouched annotation file.
    # What it really does is create an annotation file
    # which has been modified to remove exact duplicates
    # and batch overlap artifacts only.
    #
    if ( $options{'u'} || !$poundformat ) {

      my $prevAnnot = $sortedAnnotationsList->get( $currentIndex - 1 )
          if ( $currentIndex > 0 );

      my $nextAnnot = $sortedAnnotationsList->get( $currentIndex + 1 )
          if ( $currentIndex < $sortedAnnotationsList->size() - 1 );

      my $Overlapped = "";
      if (    $prevAnnot
           && $currentAnnot->getQueryStart() <= $prevAnnot->getQueryEnd()
           && $currentAnnot->getScore() < $prevAnnot->getScore()
           || $nextAnnot
           && $currentAnnot->getQueryEnd() >= $nextAnnot->getQueryStart()
           && $currentAnnot->getScore() < $nextAnnot->getScore() )
      {
        $Overlapped = "*";
      }
      $currentAnnot->setClassName( "" )
          unless ( $currentAnnot->getClassName() );

      #
      # sequence names get truncated to 20 letters. Too
      # cumbersome to change.  However, names like
      # /mnt/user/users/FlipvanTiel/mystuff/sequence1 better be
      # clipped from the end. Thus:
      $currentAnnot->setQueryName(
                                  substr( $currentAnnot->getQueryName(), -20 ) )
          if ( length $currentAnnot->getQueryName() > 20
               && $currentAnnot->getQueryName() =~ /^\// );

      printf OUTRAW "%6d %4s %4s %4s %20s %9s %9s %8s %1s "
          . "%20s %15s %7s %7s %7s %3s\n", $currentAnnot->getScore(),
          $currentAnnot->getPctDiverge, $currentAnnot->getPctDelete,
          $currentAnnot->getPctInsert,  $currentAnnot->getQueryName(),
          $currentAnnot->getQueryStart(), $currentAnnot->getQueryEnd(),
          "(" . $currentAnnot->getQueryRemaining() . ")",
          $currentAnnot->getOrientation(), $currentAnnot->getHitName(),
          $currentAnnot->getClassName(),   $Seq2BeginPrint,
          $currentAnnot->getSubjEnd(),     $LeftUnalignedPrint;
      $Overlapped;
    }    # if ( $options{'u'}  || !$poundformat )

    #
    # If a user supplied non-classified library was used
    #
    if ( !$poundformat ) {
      if ( $options{'ace'} ) {
        if ( $currentAnnot->getOrientation() eq "C" ) {
          print OUTACE "Motif_homol \""
              . $currentAnnot->getHitName()
              . "\" \"RepeatMasker\" "
              . $currentAnnot->getPctDiverge() . " "
              . $currentAnnot->getQueryStart() . " "
              . $currentAnnot->getQueryEnd() . " - "
              . $currentAnnot->getSubjEnd() . " "
              . $currentAnnot->getSubjStart() . "\n";
        }
        else {
          print OUTACE "Motif_homol \""
              . $currentAnnot->getHitName()
              . "\" \"RepeatMasker\" "
              . $currentAnnot->getPctDiverge() . " "
              . $currentAnnot->getQueryStart() . " "
              . $currentAnnot->getQueryEnd() . " + "
              . $currentAnnot->getSubjStart() . " "
              . $currentAnnot->getSubjEnd() . "\n";
        }
      }
      if ( $options{'xm'} ) {
        my $tempclassname = "";
        $tempclassname = "\#" . $currentAnnot->getClassName()
            if ( $currentAnnot->getClassName() );
        print OUTXM $currentAnnot->getScore() . " "
            . $currentAnnot->getPctDiverge() . " "
            . $currentAnnot->getPctDelete() . " "
            . $currentAnnot->getPctInsert() . " "
            . $currentAnnot->getQueryName() . " "
            . $currentAnnot->getQueryStart() . " "
            . $currentAnnot->getQueryEnd() . " "
            . $LeftOverPrint . " "
            . $currentAnnot->getOrientation() . " "
            . $currentAnnot->getHitName()
            . $tempclassname . " "
            . $Seq2BeginPrint . " "
            . $currentAnnot->getSubjEnd() . " "
            . $LeftUnalignedPrint . "\n";
      }
      if ( $options{'gff'} ) {
        my $source;
        if ( $currentAnnot->getHitName() =~ /Alu/ ) {
          $source = 'RepeatMasker_SINE';
        }
        else {    #
          $source = 'RepeatMasker';
        }
        print OUTGFF ""
            . $currentAnnot->getQueryName()
            . "\t$source\tsimilarity\t"
            . $currentAnnot->getQueryStart() . "\t"
            . $currentAnnot->getQueryEnd() . "\t"
            . $currentAnnot->getPctDiverge() . "\t"
            . ( $currentAnnot->getOrientation() eq 'C' ? '-' : '+' ) . "\t.\t"
            . "Target \"Motif:"
            . $currentAnnot->getHitName() . "\" "
            . $currentAnnot->getClassName() . "\" "
            . $currentAnnot->getSubjStart() . " "
            . $currentAnnot->getSubjEnd() . "\n";
      }
    }    # if ( !$poundformat )
    else {

      #
      # Satellite Consensi
      #    Searching for satellites with consensi is a hack.
      #    Search engines such as crossmatch will often return
      #    hits to a single repeating pattern as:
      #           |       |       |       |       |
      #           abcdefghabcdefghabcdefghabcdefghabcdefgh
      #          --------->
      #                           -------->
      #                                           -------->
      #    By creating a consensus for the repeat pattern and
      #    another for the same pattern shifted by 1/2 of the
      #    cycle. You can nicely overlapping hits.
      #    These shifted consensi are denoted by the use of a
      #    trailing "_" in the name.
      #
      #    Here is the regular expression for the syntax:
      #
      #    [A-Z_]+[a-z]?_?#Satellite
      #
      #    So here are some examples:
      #
      #     ALR_#Satellite
      #     ALRa#Satellite
      #     ALRa_#Satellite
      #     CENSAT_MC#Satellite
      #
      #    Since these trailing "_" variants and the "[a-z]"
      #    variants are equivalent we only need to restore
      #    the original name by stripping these characters
      #    HitName.
      #
      #    NOTE: The lowercase varieties are not in repbase.
      #
      if ( $currentAnnot->getClassName =~ /Satellite/ ) {
        my $HitName = $currentAnnot->getHitName();
        $HitName =~ s/_(offset)?$//;

        # This was truncating newer statellite names which use the
        #  _??? to indicate species names.
        if ( $HitName =~ /ALR|BSR/ && $HitName !~ /_/ ) {
          $HitName =~ s/[a-z]$//;
        }
        $currentAnnot->setHitName( $HitName );
      }

      if ( $currentAnnot->getClassName =~ /DNA/ ) {

        # Find all ambiguous dna transposon fragments and generate
        # equivalency lists
        &preProcessDNATransp( \%chainBeg, \%chainEnd, $currentAnnot,
                              \%RepeatAnnotationData::repeatDB );
      }

    }
  }    # END CYCLE 2

  close( OUTRAW ) if ( $options{'u'} || !$poundformat );

  #
  #  If we do not have a pound formatted database we are done!
  #
  if ( !$poundformat ) {
    &generateOutput(
                     \%options,              \%seq1Lengths,
                     $file,                  $filename,
                     $dbversion,             $numSearchedSeqs,
                     $lenSearchedSeqs,       $lenSearchedSeqsExcludingXNRuns,
                     $versionmode,           $engine,
                     $sortedAnnotationsList, $poundformat
    );
  }
  else {

    # Continue with the rest of the cycles!

    ########################## C Y C L E 3 ################################
    #
    #  - DNA Transposon de-fragmentation
    #  - PreProcessLTRs - Setup adjustment structures for MLT2s
    #  - PreProcessLINEs - Adjust LINE subject positions to the
    #    reference scaffold so that we may compare them later.
    #  - Join Simple/Satellite Repeats
    #     o Merge Simple/Satellite repeats which are spanned by
    #       another Simple/Satellite repeat with the same name.
    #     o Ambiguate diverged simple repeat matches
    #     o Convert Simple/Low complexity repeats to the + strand
    #       and consensus start point of 1.
    #
    #  TODO: Can we short circuit consideration of SINES here?
    #
    #  Creates global %conPosCorrection
    ########################################################################

    #printHitArrayList( $sortedAnnotationsList );

    # Sort by name, begin position, and end position descending
    print "\ncycle 3 ";
    $sortedAnnotationsList->sort( \&byNameBeginEndrevSWrev );
    $i              = -1;
    $cycleAnnotIter = $sortedAnnotationsList->getIterator();
    $DEBUG          = 0;
    my %conPosCorrection = ();

CYCLE3:
    while ( $cycleAnnotIter->hasNext() ) {
      $i++;
      print "." if ( $i + 1 ) % 1000 == 0;

      # NOTE: An iterator's index is considered
      #       to be in between elements of a datastructure.
      #       To obtain the correct index for the
      #       current element in this pass we should
      #       get the index *before* we move the iterator.
      print "getting next element\n" if ( $DEBUG );
      my $currentIndex = $cycleAnnotIter->getIndex();
      my $currentAnnot = $cycleAnnotIter->next();

      if ( $currentAnnot->getStatus() eq "DELETED" ) {

        # NOTE: Annotation already added to derived list.

        # Fix any previous joins to this element
        print "removing DELETE element\n" if ( $DEBUG );
        $currentAnnot->removeFromJoins();
        $cycleAnnotIter->remove();
        next CYCLE3;
      }

      if ( $DEBUG ) {
        print "Considering:\n";
        $currentAnnot->print();
      }

      if (    $currentAnnot->getClassName() =~ /DNA/
           && $currentAnnot->getStatus() ne "JOINED" )
      {

        #if ( $DEBUG ) {
        #print  "DNA Transposon Equivalent:\n";
        #print  Dumper( $EquivHash ) . "\n";
        #}
        # Look into our future
        my $proxIter             = $cycleAnnotIter->getIterator();
        my @dnaTransposonCluster = ();
        my $elementDistance      = 0;
        my $ignoreUntil          = undef;
        while ( $proxIter->hasNext() ) {
          my $nextAnnot = $proxIter->next();
          my ( $nextHitName, $nextClassName ) =
              split( /\#/, $nextAnnot->getSubjName() );

          if ( $DEBUG ) {
            print "   -vs-: ";
            $nextAnnot->print();
          }

          $elementDistance++ if ( $nextClassName =~ /DNA/ );

          #
          # Reasons we wouldn't consider this element in our cluster and
          # trigger the end to the search
          #
          # TODO: Do not join fragments outside of a parent fragment.
          #
          last
              if (
               $currentAnnot->getQueryName() ne $nextAnnot->getQueryName()
            || $elementDistance > 20
            || $nextAnnot->getQueryEnd() - $currentAnnot->getQueryEnd() >
            15000    # max retrovirus insert
            || $nextAnnot->containsElement( $currentAnnot )
              );

          if ( $ignoreUntil ) {
            if ( $ignoreUntil == $nextAnnot ) {
              $ignoreUntil = undef;
            }
            next;
          }

          if (    $nextClassName =~ /DNA/
               && $nextAnnot->getStatus() ne "JOINED"
               && $nextAnnot->getStatus() ne "DELETED" )
          {
            push @dnaTransposonCluster, $nextAnnot;
          }

          if ( $nextAnnot->getRightLinkedHit() ) {
            $ignoreUntil = $nextAnnot->getRightLinkedHit();
          }

        }
        if ( @dnaTransposonCluster ) {

          # Consider recruiting putative related elements to our cause
          print "calling joinDNATransposonFragments\n" if ( $DEBUG );
          &joinDNATransposonFragments(
                                       \%chainBeg,
                                       \%chainEnd,
                                       \%RepeatAnnotationData::repeatDB,
                                       $currentAnnot,
                                       \@dnaTransposonCluster
          );
        }

        #printHitArrayList( $sortedAnnotationsList );
      }

      if ( $currentAnnot->getHitName =~ /^MLT2/ )
      {    #  middle region of MLT2 variable in length in subfamilies
            # NOTE: Initializes conPosCorrection{ID} for LTRs
        print "calling preProcessLTR\n" if ( $DEBUG );
        &preProcessLTR( \%chainBeg,         \%chainEnd,
                        \%conPosCorrection, $currentAnnot );
      }
      elsif ( $currentAnnot->getClassName =~ /LINE/ ) {

        # I placed this here because I could.
        # Adjust start position of LINE termini and
        # give generic names to too precisely categorized LINEs
        # NOTE: Initializes conPosCorrection{ID} for LINEs
        print "calling preProcessLINE\n" if ( $DEBUG );
        &preProcessLINE( \%chainBeg,         \%chainEnd,
                         \%conPosCorrection, $currentAnnot );
        print "done preProcessLINE\n" if ( $DEBUG );
      }

      # merge long simple repeats which were initially partly spliced out
      # Note that not all satellite entries represent (multiple)
      # units. Some are complex sequences that can contain
      # minisatellites in it; overlapping matches to such
      # subsequences cause 'funny' annotation (in particular,
      # the location of the match in the consensus sequence is off)
      if ( $currentAnnot->getClassName() =~ /Simple|Satellite/ ) {
        if ( $cycleAnnotIter->hasNext() ) {

          #
          # current   ..-----------
          # next          ..-----
          #
          my $proxIter  = $cycleAnnotIter->getIterator();
          my $nextAnnot = $proxIter->next();

          if (   $currentAnnot->getQueryName() eq $nextAnnot->getQueryName()
              && $currentAnnot->getOrientation() eq $nextAnnot->getOrientation()
              && $currentAnnot->getQueryEnd() > $nextAnnot->getQueryEnd() )
          {
            my $tempname = quotemeta $currentAnnot->getHitName();
            if ( $nextAnnot->getSubjName() =~ /$tempname/ ) {
              my $thislength =
                  $currentAnnot->getSubjEnd() - $currentAnnot->getSubjStart() +
                  1;
              my $nextlength =
                  $nextAnnot->getSubjEnd() - $nextAnnot->getSubjStart() + 1;
              my $Seq2Length = $thislength + $nextlength;
              my $SW         = $nextAnnot->getScore()
                  if ( $nextAnnot->getScore() > $currentAnnot->getScore() );
              $currentAnnot->setScore( $SW );
              $currentAnnot->setPctDiverge(
                                (
                                  $currentAnnot->getPctDiverge() * $thislength +
                                      $nextAnnot->getPctDiverge() * $nextlength
                                ) / $Seq2Length
              );
              $currentAnnot->setPctDelete(
                                 (
                                   $currentAnnot->getPctDelete() * $thislength +
                                       $nextAnnot->getPctDelete() * $nextlength
                                 ) / $Seq2Length
              );
              $currentAnnot->setPctInsert(
                                 (
                                   $currentAnnot->getPctInsert() * $thislength +
                                       $nextAnnot->getPctInsert() * $nextlength
                                 ) / $Seq2Length
              );
              $nextAnnot->removeFromJoins();
              $currentAnnot->addDerivedFromAnnot( $nextAnnot )
                  if ( $options{'source'} );
              $proxIter->remove();
            }
          }
        }    # if ( $cycleAnnotIter->hasNext()...
             #
        if ( $currentAnnot->getClassName() =~ /Simple/ ) {

          # Requirement added in January 2005; Satellites should not
          # be considered This loop will convert all to forward
          # orientation. The annotation shows then the inverse
          # complement unit of simple repeats, but such is not
          # available for satellites.
          if (
              (
                $currentAnnot->getPctDiverge() + $currentAnnot->getPctDelete() +
                $currentAnnot->getPctInsert()
              ) > 15
              )
          {
            if ( $currentAnnot->getHitName() =~ /AAA|\(A\)/ ) {
              if ( $currentAnnot->getOrientation() eq '+' ) {
                $currentAnnot->setHitName( "A-rich" );
              }
              else {
                $currentAnnot->setHitName( "T-rich" );
              }
            }
            elsif ( $currentAnnot->getHitName() =~ /GGG|\(G\)/ ) {
              if ( $currentAnnot->getOrientation() eq '+' ) {
                $currentAnnot->setHitName( "G-rich" );
              }
              else {
                $currentAnnot->setHitName( "C-rich" );
              }
            }
            if ( $currentAnnot->getHitName() =~ /\([GA]+\)/ ) {
              if (
                 $currentAnnot->getScore() < (
                   $currentAnnot->getSubjEnd() - $currentAnnot->getSubjStart() +
                       1
                 ) * (
                       9 - $currentAnnot->getPctDiverge() * 16 / 100 - (
                                               $currentAnnot->getPctDelete() +
                                                   $currentAnnot->getPctInsert()
                           ) * 23 / 100
                 )
                  )
              {
                if ( $currentAnnot->getOrientation() eq '+' ) {
                  $currentAnnot->setHitName( "GA-rich" );
                }
                else {
                  $currentAnnot->setHitName( "CT-rich" );
                }
              }
              else {
                if ( $currentAnnot->getOrientation() eq '+' ) {
                  $currentAnnot->setHitName( "polypurine" );
                }
                else {
                  $currentAnnot->setHitName( "polypyrimidine" );
                }
              }
            }
          }
          if ( $currentAnnot->getHitName() =~ /^\(/ ) {
            my $unit = $currentAnnot->getHitName();
            $unit =~ s/\((\w+)\)n/$1/;
            my $merness = length $unit;
            if ( $currentAnnot->getOrientation() eq "C" ) {
              unless ( $currentAnnot->getHitName() =~
                       /\(TA\)|\(TTAA\)|\(CG\)|\(CCGG\)/ )
              {
                $unit = reverse $unit;
                $unit =~ tr/ACGT/TGCA/;
                $currentAnnot->setHitName( "($unit)n" );
              }
            }
            while ( $currentAnnot->getSubjStart() > $merness ) {
              $currentAnnot->setSubjStart(
                                     $currentAnnot->getSubjStart() - $merness );
              $currentAnnot->setSubjEnd(
                                       $currentAnnot->getSubjEnd() - $merness );
            }
          }
          $currentAnnot->setOrientation( "+" );
          $currentAnnot->setSubjRemaining( 0 );
        }
      }

      if ( $currentAnnot->getClassName() eq "Low_complexity" ) {

        # AT-rich and GC rich not strand specific
        $currentAnnot->setOrientation( '+' );
        $currentAnnot->setSubjEnd(
              $currentAnnot->getSubjEnd() - $currentAnnot->getSubjStart() + 1 );
        $currentAnnot->setSubjStart( 1 );
        $currentAnnot->setSubjRemaining( 0 );
      }

    }

    ########################## C Y C L E 4 ################################
    #
    #  Use overlapping annotation information to create alias
    #  list for fragments.
    #
    ########################################################################

    #printHitArrayList( $sortedAnnotationsList );
    # Sort by name, begin position, and end position descending
    print "\ncycle 4 ";
    $sortedAnnotationsList->sort( \&byNameBeginEndrevSWrev );

    $i = -1;
    ##
    ## This "joins" overlapping fragments for all types of
    ## annotations.  This in effect replaces the FuseOverlappingSeqs sub.
    ##
    ##
    $DEBUG          = 0;
    $cycleAnnotIter = $sortedAnnotationsList->getIterator();
    my $prevAnnot;
    while ( $cycleAnnotIter->hasNext() ) {
      $i++;
      print "." if ( $i + 1 ) % 1000 == 0;
      my $currentAnnot = $cycleAnnotIter->next();

      if ( $DEBUG ) {
        print "Overlapping Fragments Considering:\n";
        $currentAnnot->printBrief();
      }
      next if ( $currentAnnot->getClassName() =~ /Simple|Low/ );

      my $nextAnnot;
      my $proxIter   = $cycleAnnotIter->getIterator();
      my @joinList   = ();
      my $currentEnd = $currentAnnot->getQueryEnd();
      my $skipUntil  = undef;
      while ( $proxIter->hasNext() ) {
        $nextAnnot = $proxIter->next();
        if ( $DEBUG ) {
          print "  -vs-> (qo = "
              . $currentAnnot->getQueryOverlap( $nextAnnot ) . "): ";
          $nextAnnot->printBrief();
        }

        # Quit once we reach our partner
        last
            if (
                 (
                      $currentAnnot->getRightLinkedHit()
                   && $nextAnnot == $currentAnnot->getRightLinkedHit()
                 )
                 || ( !$currentAnnot->getRightLinkedHit()
                      && $currentEnd < $nextAnnot->getQueryStart() )
                 || $currentAnnot->getQueryName() ne $nextAnnot->getQueryName()
            );

        # ASSERT: No more recursion violations
        if ( $DEBUG
          && $currentAnnot->getRightLinkedHit()
          && $currentAnnot->containsElement( $nextAnnot )
          && $nextAnnot->containsElement( $currentAnnot->getRightLinkedHit() ) )
        {
          ## TODO: Currently DNA Transposons can violate recursion rules.
          ##       consider this further.
          print "\n\n\nThis violates recursion:\nFirst:\n";
          $currentAnnot->printLeftRightLinks();
          print "Second:\n";
          $nextAnnot->printLeftRightLinks();
          print "\n\n\n";
          die;
        }

        if ( $skipUntil ) {
          if ( $skipUntil == $nextAnnot ) {
            $skipUntil = undef;
          }
          else {
            print "  -- Can't consider...inside existing join\n"
                if ( $DEBUG );
            next;
          }
        }

     #
     # Join Overlapping Elements
     #
     # TODO: We join things that perhaps we shouldn't.  This is a proposed
     # change to the joining mechanism.  Need to consider the change
     # from 33 to 50 architectually before we continue with this.
     #
     # Query Overlap > 50
     # ConsensusOverlap - QueryOverlap < 200
     # if (
     #  (
     #    $currentEnd - $nextAnnot->getQueryStart() > 50
     #    || ( $currentAnnot->getQueryOverlap( $nextAnnot ) ==
     #         ( $nextAnnot->getQueryEnd() - $nextAnnot->getQueryStart() + 1 ) )
     #  )
     #  && $currentAnnot->getRightLinkedHit() != $nextAnnot
     #  && $currentAnnot->getRightLinkedHit() != $currentAnnot
     #  && $currentAnnot->getClassName() eq $nextAnnot->getClassName()
     #  && $currentAnnot->getOrientation()   eq $nextAnnot->getOrientation()
     #  && ( $currentAnnot->getConsensusOverlap( $nextAnnot ) -
     #       $currentAnnot->getQueryOverlap( $nextAnnot ) ) < 200
     #    )
        if (
           (
             $currentEnd - $nextAnnot->getQueryStart() > 33
             || ( $currentAnnot->getQueryOverlap( $nextAnnot ) ==
               ( $nextAnnot->getQueryEnd() - $nextAnnot->getQueryStart() + 1 ) )
           )
           && $currentAnnot->getRightLinkedHit() != $nextAnnot
           && $currentAnnot->getRightLinkedHit() != $currentAnnot
           && $currentAnnot->getClassName()   eq $nextAnnot->getClassName()
           && $currentAnnot->getOrientation() eq $nextAnnot->getOrientation()
            )
        {
          if ( $DEBUG ) {
            print "  Adding to overlap element cluster (co="
                . $currentAnnot->getConsensusOverlap( $nextAnnot ) . ")\n";
          }
          push @joinList, $nextAnnot;
          $currentEnd = $nextAnnot->getQueryEnd()
              if ( $currentEnd < $nextAnnot->getQueryEnd() );
        }
        elsif ( $nextAnnot->getRightLinkedHit() ) {
          $skipUntil = $nextAnnot->getRightLinkedHit();
        }
      }    # while has next

      if ( @joinList ) {
        my $leftSide  = $currentAnnot;
        my $equivHash = {};
        if ( $DEBUG ) {
          print "  Joining overlap cluster ---- :\n";
          print "    ";
          $leftSide->printBrief();
        }
        foreach my $partner ( @joinList ) {
          if ( $DEBUG ) {
            print "printing partner\n" if ( $DEBUG );
            print "    ";
            $partner->printBrief();
            print "done\n" if ( $DEBUG );
          }

          print "Going to join" if ( $DEBUG );
          $leftSide->join( $partner );
          print "joined" if ( $DEBUG );

          # Don't ambiguate the name unless the overlap is excessive
          # or the element is subsummed completely by the other.
          if (    $leftSide->getQueryOverlap( $partner ) > 50
               || $leftSide->getQueryEnd() >= $partner->getQueryEnd() )
          {
            print " ls = "
                . $leftSide->getSubjName()
                . " par = "
                . $partner->getSubjName() . "\n"
                if ( $DEBUG );
            $equivHash->{ $leftSide->getSubjName() } = 1;
            $equivHash->{ $partner->getSubjName() }  = 1;
          }
          $leftSide = $partner;
        }

        if ( keys( %{$equivHash} ) ) {
          foreach my $element ( @joinList, $currentAnnot ) {
            my $newEquivHash = { %{$equivHash} };
            if ( defined $equivHash->{ $element->getSubjName() } ) {
              delete $newEquivHash->{ $element->getSubjName() };
            }
            $element->setEquivHash( $newEquivHash );
          }
        }
      }
    }

    #printHitArrayList( $sortedAnnotationsList );

    ########################## C Y C L E 5 ################################
    #
    #  This cycle is currently handling the de-fragmentation
    #  of SINES using a new method.
    #
    ########################################################################

    #printHitArrayList( $sortedAnnotationsList );

    # Sort by name, begin position, and end position descending
    print "\ncycle 5 ";

    if ( keys( %refinementHash ) ) {

      $sortedAnnotationsList->sort( \&byNameBeginEndrevSWrev );
      $i              = -1;
      $cycleAnnotIter = $sortedAnnotationsList->getIterator();
      $DEBUG          = 0;
      my %conPosCorrection = ();

      ## Create a cycle data structure to hold last 21 join scores.
      ##  ie.   prevScoreHash{ ID }->{ HitName } = chainScore ( sum of score function )
      my %prevScoreHash = ();

  CYCLE5:
      while ( $cycleAnnotIter->hasNext() ) {
        $i++;
        print "." if ( $i + 1 ) % 1000 == 0;

        # NOTE: An iterator's index is considered
        #       to be in between elements of a datastructure.
        #       To obtain the correct index for the
        #       current element in this pass we should
        #       get the index *before* we move the iterator.
        my $currentIndex = $cycleAnnotIter->getIndex();
        my $currentAnnot = $cycleAnnotIter->next();

        my ( $currentHitName, $currentClassName ) =
            split( /\#/, $currentAnnot->getSubjName() );

        if ( $DEBUG ) {
          print "Considering:\n";
          $currentAnnot->print();
          if ( $currentAnnot->getRightLinkedHit() ) {
            print "Bummer this already is linked forward to:\n   ";
            $currentAnnot->getRightLinkedHit()->print();
          }
        }

        #
        # Refined elements ( currently Alus ):
        #
        # Find first fragment which is capable of joining to the right:
        #
        #
        #         ----seed---->    ------>
        #  or
        #    <----+
        #         |
        #         ----seed---->    ------>
        #
        #   NOTE: Currently I am using a non-empty $refinementHash as a
        #         proxy for $currentAnnot->isRefineable()
        #
        if (    defined $refinementHash{ $currentAnnot->getLineageId() }
             && keys %{ $refinementHash{ $currentAnnot->getLineageId() } }
             && !$currentAnnot->getRightLinkedHit() )
        {
          if ( $DEBUG ) {
            print "First Candidate Seed:\n  ";
            $currentAnnot->print();
          }

          #
          # Gather a collection of candidates
          #
          my @candidateJoins  = ();
          my $proxIter        = $cycleAnnotIter->getIterator();
          my $elementDistance = 0;
          my $ignoreUntil     = undef;
          my $lastAnnot       = $currentAnnot;
          my $lastDivAnnot    = undef;

          my $classElementDistance  = 0;
          my $totElementDistance    = 0;
          my $highestInterveningDiv = 0;
          my $unAnnotatedBP         = 0;
          my $unAnnotatedGaps       = 0;

          while ( $proxIter->hasNext() ) {
            my $nextAnnot = $proxIter->next();
            $elementDistance++;
            my ( $nextHitName, $nextClassName ) =
                split( /\#/, $nextAnnot->getSubjName() );

            if ( $DEBUG ) {
              print "   -vs-: ";
              $nextAnnot->print();
            }

            my $queryGap = $lastAnnot->getQueryGap( $nextAnnot );
            if ( $queryGap >= 100 ) {
              $unAnnotatedBP += $queryGap;

              # Only count a series of low/simple repeats as one gap
              if ( $currentAnnot->getClassName !~ /^simple|low/i ) {
                $unAnnotatedGaps++;
              }
            }
            $lastAnnot = $nextAnnot;

            # We don't care to record the divergence of simple/low complexity
            if (    $lastDivAnnot
                 && $lastDivAnnot->getClassName() !~ /^simple|low/i )
            {
              $highestInterveningDiv = $lastDivAnnot->getPctDiverge()
                  if (
                      $highestInterveningDiv < $lastDivAnnot->getPctDiverge() );
            }
            $lastDivAnnot = $nextAnnot;

            # Number of intervening elements of the same class
            $classElementDistance++ if ( $nextClassName eq $currentClassName );

            #
            # Reasons we wouldn't consider this element in our cluster and
            # trigger the end to the search
            #
            #   A parent join ends at this element
            #   A much older element is reached ( higher cutlevel )
            #   A much older intervening ( any class ) element.
            #   A set of unannotated gaps exceeds our threshold
            #   When the 21st annotation is reached
            #
            if (
                 $nextAnnot->containsElement( $currentAnnot )
              || $currentAnnot->getQueryName() ne $nextAnnot->getQueryName()
              || $elementDistance > 21
              || ( $unAnnotatedBP * $unAnnotatedGaps ) > 10000
              || (

                # Think about these impacts a bit:
                # Don't give up on high intervening
                # divergence if ( LTR-int or a SINE )
                # TODO: This appears to be broken!
                !&isInternal( $nextAnnot ) && $currentClassName !~ /SINE/
                && (
                   (
                     $currentAnnot->getSubjEnd() - $currentAnnot->getSubjStart()
                   ) > 50
                   && &isTooDiverged(
                                      $currentAnnot->getPctDiverge(),
                                      $highestInterveningDiv
                   )
                )
              )
                )
            {
              last;
            }

            #
            if ( $ignoreUntil ) {
              if ( $ignoreUntil == $nextAnnot ) {
                $ignoreUntil = undef;
              }
              print "ignoring...\n" if ( $DEBUG );
              next;
            }

            if (    defined $refinementHash{ $nextAnnot->getLineageId() }
                 && keys %{ $refinementHash{ $nextAnnot->getLineageId() } }
                 && !$nextAnnot->getLeftLinkedHit() )
            {

              #print  "Pushing...\n";
              push @candidateJoins, $nextAnnot;
            }

            if ( $nextAnnot->getRightLinkedHit() ) {
              print "This has a right linked hit\n" if ( $DEBUG );
              $ignoreUntil = $nextAnnot->getRightLinkedHit();
            }
          }    # While ( proxIter->hasNext() ) .... searching for candidates

          # Do we have some candidate joins for this entry?
          if ( @candidateJoins ) {

            if ( $DEBUG ) {
              print "Candidates found:\n";
              foreach my $tmp ( @candidateJoins ) {
                print "   + ";
                $tmp->print();
                print "\n";
              }
            }

            # Lookup seed refinement twin: The consensus/model used
            #   to seed the refinement step is also returned in
            #   the refinement set.  The score/div for the refined
            #   version of the seed will differ due to the nature of
            #   the realignment.
            my $currentMatch = getMatchingRefinedEntry( $currentAnnot );

            # NOTE: This is to get around strange batch overlap
            #       behaviour where the twin doesn't exist
            #       in the refinement set.  Found in:
            #          hg18:chr9:131500000-132000000
            $currentMatch = $currentAnnot if ( !defined $currentMatch );
            if ( $DEBUG ) {
              print "Current match = \n  ";
              $currentMatch->print();
            }

            my $currentLenThresh = (
                 $currentMatch->getQueryEnd() - $currentMatch->getQueryStart() +
                     1 ) * .70;

            # Filter out hits that are less than 80% of the score of
            # the highest scoring realignment or 200 less than the
            # the score of the highest scoring realignment whichever
            # threshold is more permissive.
            my $chs                = getRefinedHighScore( $currentAnnot );
            my $currentScoreThresh = $chs * 0.80;
            $currentScoreThresh = $chs - 100
                if ( $chs - $currentScoreThresh < 100 );

            my $prevLinkedAnnot       = $currentAnnot->getRightLinkedHit();
            my $continuationScoreHash = undef;
            if ( $prevLinkedAnnot
                 && defined $prevScoreHash{ $currentAnnot->getLineateId() } )
            {
              $continuationScoreHash =
                  $prevScoreHash{ $currentAnnot->getLineageId() };
            }

        #
        # Iterate through currentAnnot's refinement alignments and score each
        # one against each candidate's refinement alignments keeping the highest
        # score as we go.
        #
            my $forwardHighScore                 = 0;
            my $forwardHighScoringCandidateEquiv = undef;
            my $forwardHighScoringCurrentEquiv   = undef;
            my $forwardHighScoringCandidate      = undef;
            my %currentScores                    = ();
            my @equivArray = getEquivArray( $currentAnnot );
            foreach my $currentEquiv ( @equivArray ) {

              if ( $DEBUG ) {
                print "  - Current Seed Equiv: ";
                $currentEquiv->print;
              }

              # Don't bother with tiny sub-alignments produced by realignment
              next
                  if (
                 $currentEquiv->getQueryEnd() - $currentEquiv->getQueryStart() +
                 1 < $currentLenThresh );
              print "       - not tiny\n" if ( $DEBUG );

              next if ( $currentEquiv->getScore() < $currentScoreThresh );
              print "       - high enough score\n" if ( $DEBUG );

              # Don't bother if consensus remaining is lower
              next
                  if (
                       (
                            $currentEquiv->getOrientation() ne "C"
                         && $currentEquiv->getSubjRemaining() < 20
                       )
                       || (    $currentEquiv->getOrientation() eq "C"
                            && $currentEquiv->getQueryStart() < 20 )
                  );
              print "       - enough consensus remaining\n"
                  if ( $DEBUG );

              # TODO: If currentAnnot is joined previously then use the
              #       list of possible names to constrain this search.
              if ( $continuationScoreHash
                 && !
                 defined $continuationScoreHash->{ $currentEquiv->getHitName() }
                  )
              {
                print "       - previous joins make this name possible\n"
                    if ( $DEBUG );
                next;
              }

              my $sourceScore        = 0;
              my $score              = 0;
              my @finalJoins         = ();
              my @finalEquivs        = ();
              my $compatibleDistance = 1;
              my @prevCandidates     = ();
              foreach my $candidate ( @candidateJoins ) {
                my $candidateMatch = getMatchingRefinedEntry( $candidate );
                next if ( !defined $candidateMatch );
                my $candidateLenThresh =
                    ( $candidateMatch->getQueryEnd() -
                      $candidateMatch->getQueryStart() + 1 ) * .70;

                # Filter out hits that are less than 80% of the score of
                # the highest scoring realignment or 200 less than the
                # the score of the highest scoring realignment whichever
                # threshold is more permissive.
                my $chs                  = getRefinedHighScore( $candidate );
                my $candidateScoreThresh = $chs * 0.80;
                $candidateScoreThresh = $chs - 100
                    if ( $chs - $candidateScoreThresh < 100 );
                my $candidateEquivHighScore = 0;
                my $cEquiv                  = undef;
                foreach my $candidateEquiv (
                        getMatchingRefinedEntries( $candidate, $currentEquiv ) )
                {
                  next
                      if ( $candidateEquiv->getQueryEnd() -
                           $candidateEquiv->getQueryStart() + 1 <
                           $candidateLenThresh );

                  next
                      if (
                          $candidateEquiv->getScore() < $candidateScoreThresh );

                  my $tmpScore =
                      scoreRefinedSINEPair( $currentEquiv, $candidateEquiv,
                                            $compatibleDistance );

                  if ( $tmpScore > $candidateEquivHighScore ) {
                    $candidateEquivHighScore = $tmpScore;
                    $cEquiv                  = $candidateEquiv;
                  }
                }    # foreach candidateEquiv

                if (    $continuationScoreHash
                     && $candidateEquivHighScore
                     && defined
                     $continuationScoreHash->{ $currentEquiv->getHitName() } )
                {
                  print "Adjusting candidate score due to prevScoreHash entry\n"
                      if ( $DEBUG );
                  $candidateEquivHighScore +=
                      $continuationScoreHash->{ $currentEquiv->getHitName() };
                }

                if ( $candidateEquivHighScore ) {
                  ## Check backwards in ( @candidates ) to make sure that the
                  ## isn't an intervening higher scoring join.
                  my $backwardHighScore = 0;

                  my $cEquivLengthThresh =
                      ( $cEquiv->getQueryEnd() - $cEquiv->getQueryStart() + 1 )
                      * .70;

                  my $cDistance = 1;
                  foreach my $highScoreCandidateEquiv (
                                                   getEquivArray( $candidate ) )
                  {

                 # Don't bother with tiny sub-alignments produced by realignment
                    next
                        if ( $highScoreCandidateEquiv->getQueryEnd() -
                             $highScoreCandidateEquiv->getQueryStart() + 1 <
                             $cEquivLengthThresh );

                    my $prevCandidateEquivHighScore = 0;
                    foreach my $prevCandidate ( @prevCandidates ) {
                      my $prevCandidateMatch =
                          getMatchingRefinedEntry( $prevCandidate );
                      next if ( !defined $prevCandidateMatch );
                      my $prevCandidateLenThresh =
                          ( $prevCandidateMatch->getQueryEnd() -
                            $prevCandidateMatch->getQueryStart() + 1 ) * .70;

                      foreach my $prevCandidateEquiv (
                                   getMatchingRefinedEntries( $prevCandidate ) )
                      {
                        next
                            if ( $prevCandidateEquiv->getQueryEnd() -
                                 $prevCandidateEquiv->getQueryStart() + 1 <
                                 $prevCandidateLenThresh );
                        my $tmpScore =
                            scoreRefinedSINEPair( $prevCandidateEquiv,
                                         $highScoreCandidateEquiv, $cDistance );

                        if ( $tmpScore > $prevCandidateEquivHighScore ) {
                          $prevCandidateEquivHighScore = $tmpScore;
                        }
                      }
                    }
                    if ( $prevCandidateEquivHighScore > $backwardHighScore ) {
                      $cDistance++;
                      $backwardHighScore = $prevCandidateEquivHighScore;
                    }
                  }

                  if ( $backwardHighScore < $candidateEquivHighScore ) {
                    print "We have a new forward high score of "
                        . "$candidateEquivHighScore\n"
                        if ( $DEBUG );
                    $compatibleDistance++;
                    $currentScores{ $currentEquiv->getHitName() } =
                        $candidateEquivHighScore;
                    if ( $candidateEquivHighScore > $forwardHighScore ) {
                      $forwardHighScore = $candidateEquivHighScore;
                      $forwardHighScoringCandidateEquiv = $cEquiv;
                      $forwardHighScoringCurrentEquiv   = $currentEquiv;
                      $forwardHighScoringCandidate      = $candidate;
                    }
                  }
                  else {
                    print
                        "Backward high score of $backwardHighScore invalidates"
                        . " the current forward high score of "
                        . "$candidateEquivHighScore\n"
                        if ( $DEBUG );
                  }
                }    # if ( $candidateEquivHighScore...
                push @prevCandidates, $candidate;
              }    # for each candidate
            }    # foreach currentEquiv

            if ( $DEBUG ) {
              print "forwardHighScore = $forwardHighScore\n";
              if ( keys( %currentScores ) > 1 ) {
                print "Other high scores:\n";
                foreach my $key ( keys( %currentScores ) ) {
                  print "    $key = " . $currentScores{$key} . "\n";
                }
              }
            }

            # Join code
            if ( $forwardHighScore ) {
              if ( $DEBUG ) {
                print "Joining: \n    ";
                $forwardHighScoringCurrentEquiv->print();
                print " with \n    ";
                $forwardHighScoringCandidateEquiv->print();
              }

              if ( defined $continuationScoreHash ) {
                print "Updating prevScoreHash!\n" if ( $DEBUG );
                foreach my $key ( keys( %{$continuationScoreHash} ) ) {
                  if ( defined $currentScores{$key} ) {
                    $prevScoreHash{ $forwardHighScoringCandidate->getLineageId()
                        }->{$key} =
                        $prevScoreHash{ $currentAnnot->getLineageId() }
                        ->{$key} + $currentScores{$key};
                  }
                }
              }
              else {
                print "Creating new prevScoreHash\n" if ( $DEBUG );
                $prevScoreHash{ $forwardHighScoringCandidate->getLineageId() } =
                    {%currentScores};

             #print "Dumper prevScoreHash: " . Dumper( \%prevScoreHash ) . "\n";
              }

              # TODO: Trim prevScoreHash so it doesn't just keep growing!
              my $leftAnnot = $currentAnnot;
              my $leftEquiv = $forwardHighScoringCurrentEquiv;

              if ( $leftAnnot->getHitName() ne $leftEquiv->getHitName() ) {
                ## Special case:  If leftAnnot was fragmented by RM then we
                ##                need to treat the equivalent differently.
                ##
                if (    $leftAnnot->getLeftLinkedHit()
                     && $leftAnnot->getLineageId() eq
                     $leftAnnot->getLeftLinkedHit()->getLineageId() )
                {
                  print "Replacing chain with Refinement\n" if ( $DEBUG );
                  &replaceRMFragmentChainWithRefinement( $leftAnnot,
                                                         $leftEquiv );
                }
                else {
                  print "Replacing single annot with Refinement\n"
                      if ( $DEBUG );
                  $leftAnnot->setHitName( $leftEquiv->getHitName() );
                  $leftAnnot->setScore( $leftEquiv->getScore() );
                  $leftAnnot->setPctDiverge( $leftEquiv->getPctDiverge() );
                  $leftAnnot->setPctKimuraDiverge(
                                            $leftEquiv->getPctKimuraDiverge() );
                  $leftAnnot->setPctDelete( $leftEquiv->getPctDelete() );
                  $leftAnnot->setPctInsert( $leftEquiv->getPctInsert() );
                  $leftAnnot->setQueryStart( $leftAnnot->getQueryStart() +
                                          ( $leftEquiv->getQueryStart() - 1 ) );
                  $leftAnnot->setQueryEnd(
                     $leftAnnot->getQueryEnd() - $leftEquiv->getQueryRemaining()
                  );
                  $leftAnnot->setQueryRemaining(
                                          $leftAnnot->getQueryRemaining() +
                                              $leftEquiv->getQueryRemaining() );
                  $leftAnnot->setOrientation( $leftEquiv->getOrientation() );
                  $leftAnnot->setHitName( $leftEquiv->getHitName() );
                  $leftAnnot->setClassName( $leftEquiv->getClassName() );
                  $leftAnnot->setSubjStart( $leftEquiv->getSubjStart() );
                  $leftAnnot->setSubjEnd( $leftEquiv->getSubjEnd() );
                  $leftAnnot->setSubjRemaining(
                                               $leftEquiv->getSubjRemaining() );
                }

                $leftEquiv->setQueryName( $leftAnnot->getQueryName() );
                $leftEquiv->setQueryStart( $leftAnnot->getQueryStart() );
                $leftEquiv->setQueryEnd( $leftAnnot->getQueryEnd() );
                $leftEquiv->setQueryRemaining(
                                              $leftAnnot->getQueryRemaining() );

                $leftAnnot->setDerivedFromAnnot( $leftEquiv );
              }

              my $rightAnnot = $forwardHighScoringCandidate;
              $leftAnnot->setRightLinkedHit( $rightAnnot );
              $rightAnnot->setLeftLinkedHit( $leftAnnot );
              my $rightEquiv = $forwardHighScoringCandidateEquiv;
              if ( $rightAnnot->getHitName() ne $rightEquiv->getHitName()
                   || ( $rightAnnot->getScore() < $rightEquiv->getScore() ) )
              {

                # Special case: Given that b1s4i3 joins to the previously joined
                #               RM fragmented repeat b1s6i8
                #
                #                                     +-----------+
                #         ---b1s4i3--->               |           |
                #                          ---b1s6i8--->        -----b1s6i8--->
                #
                #  and given the relalignment:
                #
                #                          --------[b1s6i8]---------->
                #
                #  we must fragment [b1s6i8] into something approximating the
                #  original fragments and then replace the original ones.
                #

                if (    $rightAnnot->getRightLinkedHit()
                     && $rightAnnot->getLineageId() eq
                     $rightAnnot->getRightLinkedHit()->getLineageId() )
                {
                  &replaceRMFragmentChainWithRefinement( $rightAnnot,
                                                         $rightEquiv );
                }
                else {
                  $rightAnnot->setHitName( $rightEquiv->getHitName() );
                  $rightAnnot->setScore( $rightEquiv->getScore() );
                  $rightAnnot->setPctDiverge( $rightEquiv->getPctDiverge() );
                  $rightAnnot->setPctKimuraDiverge(
                                           $rightEquiv->getPctKimuraDiverge() );
                  $rightAnnot->setPctDelete( $rightEquiv->getPctDelete() );
                  $rightAnnot->setPctInsert( $rightEquiv->getPctInsert() );
                  $rightAnnot->setQueryStart( $rightAnnot->getQueryStart() +
                                         ( $rightEquiv->getQueryStart() - 1 ) );
                  $rightAnnot->setQueryEnd( $rightAnnot->getQueryEnd() -
                                            $rightEquiv->getQueryRemaining() );
                  $rightAnnot->setQueryRemaining(
                                         $rightAnnot->getQueryRemaining() +
                                             $rightEquiv->getQueryRemaining() );
                  $rightAnnot->setOrientation( $rightEquiv->getOrientation() );
                  $rightAnnot->setHitName( $rightEquiv->getHitName() );
                  $rightAnnot->setClassName( $rightEquiv->getClassName() );
                  $rightAnnot->setSubjStart( $rightEquiv->getSubjStart() );
                  $rightAnnot->setSubjEnd( $rightEquiv->getSubjEnd() );
                  $rightAnnot->setSubjRemaining(
                                              $rightEquiv->getSubjRemaining() );
                }
                $rightEquiv->setQueryName( $rightAnnot->getQueryName() );
                $rightEquiv->setQueryStart( $rightAnnot->getQueryStart() );
                $rightEquiv->setQueryEnd( $rightAnnot->getQueryEnd() );
                $rightEquiv->setQueryRemaining(
                                             $rightAnnot->getQueryRemaining() );
                $rightAnnot->setDerivedFromAnnot( $rightEquiv );
              }
              $leftAnnot = $rightAnnot;
            }    # if ( $forwardHighScore
          }    # if ( @candidateJoins )
        }    # if seed
      }    # cycle5a

    }    # if refcat.....
         #printHitArrayList( $sortedAnnotationsList );

    ########################## C Y C L E 6 ################################
    #
    #  LINE/LTR/SINE Joining Algorithm
    #
    ########################################################################

    print "\ncycle 6 ";
    $cycleAnnotIter = $sortedAnnotationsList->getIterator();
    $i              = -1;
    $DEBUG          = 0;
    while ( $cycleAnnotIter->hasNext() ) {
      $i++;
      print "." if ( $i + 1 ) % 1000 == 0;
      my $currentAnnot     = $cycleAnnotIter->next();
      my $currentHitName   = $currentAnnot->getHitName();
      my $currentClassName = $currentAnnot->getClassName();

      #
      # This is not a simple/low complexity joining loop.
      # Skip these and do not include them in the intervening
      # divergence calculations. Also skip DNA Transposons
      # which were joined in a previous cycle.
      #
      next if ( $currentClassName =~ /^simple|low|dna/i );

      my $maxScore        = 0;
      my $maxScoringAnnot = undef;

      #
      # Do not attempt to link fragments which are already
      # pre-linked.
      #  -- Except in the narrow case of linkage to an insignificant
      #     extension < 10bp
      #
      if (
           !$currentAnnot->getRightLinkedHit()
           || ( $currentAnnot->getRightLinkedHit()->getQueryEnd() -
                $currentAnnot->getRightLinkedHit()->getQueryStart() < 10 )
          )
      {
        if ( $DEBUG ) {
          print "\nCYCLE6: Considering:\n";
          $currentAnnot->print();
        }

        # Look into our future
        my $proxIter = $cycleAnnotIter->getIterator();
        my $ignoreUntil;
        my $classElementDistance  = 0;
        my $totElementDistance    = 0;
        my $highestInterveningDiv = 0;
        my $unAnnotatedBP         = 0;
        my $unAnnotatedGaps       = 0;
        my $lastDivAnnot          = undef;
        my $lastAnnot             = $currentAnnot;
        my $score                 = 0;
        while ( $proxIter->hasNext() ) {
          my $nextAnnot     = $proxIter->next();
          my $nextHitName   = $nextAnnot->getHitName();
          my $nextClassName = $nextAnnot->getClassName();

          $totElementDistance++;

          #
          # A new statistic for giving up on joins
          #    - Count all un-annoted gaps > threshold ( currently 100 )
          #    - Sum all bp in the above gaps
          #
          my $queryGap = $lastAnnot->getQueryGap( $nextAnnot );
          if ( $queryGap >= 100 ) {
            $unAnnotatedBP += $queryGap;

            # Only count a series of low/simple repeats as one gap
            if ( $currentAnnot->getClassName !~ /^simple|low/i ) {
              $unAnnotatedGaps++;
            }
          }
          $lastAnnot = $nextAnnot;

          # We don't care to record the divergence of simple/low complexity
          if (    $lastDivAnnot
               && $lastDivAnnot->getClassName() !~ /^simple|low/i )
          {
            $highestInterveningDiv = $lastDivAnnot->getPctDiverge()
                if ( $highestInterveningDiv < $lastDivAnnot->getPctDiverge() );
          }
          $lastDivAnnot = $nextAnnot;

          # Number of intervening elements of the same class
          $classElementDistance++ if ( $nextClassName eq $currentClassName );

          if ( $DEBUG ) {
            print " $totElementDistance -vs-> ";
            $nextAnnot->print();
            print
"     unAnnotatedBP = $unAnnotatedBP * unAnnoatedGaps = $unAnnotatedGaps < 10000\n";
          }

          #
          # Reasons we wouldn't consider this element in our cluster and
          # trigger the end to the search
          #
          #   A parent join ends at this element
          #   A much older element is reached ( higher cutlevel )
          #   A much older intervening ( any class ) element.
          #   A set of unannotated gaps exceeds our threshold
          #   When the 21st annotation is reached
          #
          if (
               $nextAnnot->containsElement( $currentAnnot )
            || $currentAnnot->getQueryName() ne $nextAnnot->getQueryName()
            || $totElementDistance > 21
            || ( $unAnnotatedBP * $unAnnotatedGaps ) > 10000
            || (

              # Think about these impacts a bit:
              # Don't give up on high intervening
              # divergence if ( LTR-int or a SINE )
              # LTR-int consensi are not ideal...so therefore the
              #  divergence calculation for these elements is inflated.
              # TODO: Why SINE..this doesn't make sense.  Remove
              !&isInternal( $nextAnnot ) && $currentClassName !~ /SINE/
              && (
                 ( $currentAnnot->getSubjEnd() - $currentAnnot->getSubjStart() )
                 > 50
                 && &isTooDiverged(
                                    $currentAnnot->getPctDiverge(),
                                    $highestInterveningDiv
                 )
              )
            )
              )
          {
            if ( $DEBUG ) {
              print "    ---> This element is beyond our "
                  . "consideration boundary:\n";
              print "         totElementDistance = " . "$totElementDistance\n";
              print "         highestInterveningDiv = "
                  . "$highestInterveningDiv\n";
              print "         unAnnotatedBP = $unAnnotatedBP\n";
              print "         unAnnotatedGaps = $unAnnotatedGaps\n";
              print "         isTooDiverged() = "
                  . &isTooDiverged( $currentAnnot->getPctDiverge(),
                                    $highestInterveningDiv )
                  . "\n";
              print "         containsElement ==> "
                  . $nextAnnot->containsElement( $currentAnnot ) . "\n";
            }
            last;
          }

          #
          # Move along if we are moving over a joined set of
          # fragments ( and their children ) which cannot be joined
          # to us.  This flag is set below.
          #
          #                     +--------joined------------+
          #                     |                          |
          #   --current--  -----+----   ---   ------    ---+---  -----
          #                  *skip*    *skip*  *skip*
          #
          if (    $ignoreUntil
               && $ignoreUntil != $nextAnnot )
          {
            print "   --> Ignoring joined fragments\n" if ( $DEBUG );
            next;
          }
          else {
            $ignoreUntil = undef;
          }

          #
          # Do not consider this one if it has a much lower divergence than
          # something in between.  This is the symmetric opposite of the
          # catch above.
          #
          # TODO: Document
          if (
                  !&isInternal( $nextAnnot )
               && $nextAnnot->getSubjEnd() - $nextAnnot->getSubjStart() > 50
               && &isTooDiverged(
                                  $nextAnnot->getPctDiverge(),
                                  $highestInterveningDiv
               )
              )
          {
            if ( $DEBUG ) {
              print "   --> This has a much lower div than something "
                  . "in between: interveningHitDiv = $highestInterveningDiv\n";
            }
            next;
          }

          #
          # Need to ignore all element until we reach the right-hand element.
          #
          if ( $nextAnnot->getRightLinkedHit() ) {
            if ( $DEBUG ) {
              print "   ---> Has right linked hit...ignoring until: ";
              $nextAnnot->getRightLinkedHit()->print();
            }
            $ignoreUntil = $nextAnnot->getRightLinkedHit();
          }

          #
          # Don't join fragments of different classes.
          #
          if ( $nextClassName ne $currentClassName ) {
            print "   --> Not same class...moving on\n" if ( $DEBUG );
            next;
          }

          #
          # Only elements not already linked to something before the
          # current element:
          #
          #                     +--------joined------------+
          #                     |                          |
          #   --current--  -----+----   ---   ------    ---+---  -----
          #                                              *skip*
          #
          if ( !$nextAnnot->getLeftLinkedHit() ) {

            # LINE Equivalences ( SINE/LTR are not handled this way )
            my @currentNames = ( $currentAnnot->getSubjName() );
            if ( defined $currentAnnot->getEquivHash() ) {
              push @currentNames, keys( %{ $currentAnnot->getEquivHash() } );
            }

            #print  "Dumper: " . Dumper(\@currentNames) . "\n";
            my @nextNames = ( $nextAnnot->getSubjName() );
            if ( defined $nextAnnot->getEquivHash() ) {
              push @nextNames, keys( %{ $nextAnnot->getEquivHash() } );
            }
            my $savedCName = $currentAnnot->getSubjName();
            my $savedNName = $nextAnnot->getSubjName();
            foreach my $cName ( @currentNames ) {
              print "    -->trying current name: $cName\n"
                  if ( $DEBUG );
              $currentAnnot->setSubjName( $cName );
              foreach my $nName ( @nextNames ) {
                print "    -->trying next name: $nName\n"
                    if ( $DEBUG );
                $nextAnnot->setSubjName( $nName );
                if ( $currentClassName =~ /LINE/ ) {
                  $score = &scoreLINEPair( $currentAnnot,         $nextAnnot,
                                           $classElementDistance, \%options );
                }
                elsif ( $currentClassName =~ /LTR/ ) {
                  $score =
                      &scoreLTRPair( $currentAnnot, $nextAnnot,
                                     $totElementDistance,
                                     $classElementDistance );
                }
                elsif (    $currentClassName =~ /SINE/
                        && $currentClassName !~ /Alu/ )
                {
                  $score =
                      &scoreSINEPair( $currentAnnot, $nextAnnot,
                                      $totElementDistance,
                                      $classElementDistance );
                }
                else {
                  $score =
                      &scoreGenericPair( $currentAnnot, $nextAnnot,
                                   $totElementDistance, $classElementDistance );
                }

                if ( $score > 0 ) {
                  print "    --> Ambiguous names matched:" . " $cName, $nName\n"
                      if ( $DEBUG );
                  last;
                }
              }
              last if ( $score > 0 );
            }    # foreach my $cName...

            # Why are we setting the names here when we may
            # not link these two?  There may be a better
            # intervening score which will void the linkage.
            $currentAnnot->setSubjName( $savedCName );
            $nextAnnot->setSubjName( $savedNName );
            print "    ---Wow saved one!\n"
                if ( $score > 0 && $DEBUG );

            #
            # If we found a compatible match we now look backwards
            # to see if there was a better intervening match to
            # the candidate.  I.e preserve the "best-closest-match"
            # concept.
            #
            #         +------------good-----------------+
            #         |                   +-better-+    |
            #         |                   |        |    |
            #  ----current---  -----   ---+---  ---+----+---
            #
            #  Ignore this match if there is a better intervening
            #  match.
            #
            if ( $score > 0 ) {
              print " \\----> score = $score\n" if ( $DEBUG );
              my $revIter = $proxIter->getIterator();
              $revIter->previous();
              my $inBetweenDistance    = 0;
              my $classBetweenDistance = 0;
              my $inBetweenScore       = 0;
              my $prevAnnot;
              print "   Looking backwards to see if there was a "
                  . "better match\n"
                  if ( $DEBUG );

              while ( $revIter->hasPrevious() ) {
                $prevAnnot = $revIter->previous();

                if ( $DEBUG ) {
                  print "     -vs-> ";
                  $prevAnnot->printBrief();
                }

                $inBetweenDistance++;
                $classBetweenDistance++;

                # Look backwards up to $currentAnnot
                last if ( $prevAnnot == $currentAnnot );
                next
                    if (
                  $prevAnnot->getClassName() ne $currentAnnot->getClassName() );
                if ( $currentClassName =~ /LINE/ ) {
                  $inBetweenScore = &scoreLINEPair(
                                                 $prevAnnot,         $nextAnnot,
                                                 $inBetweenDistance, \%options
                  );
                }
                elsif ( $currentClassName =~ /LTR/ ) {
                  $inBetweenScore =
                      &scoreLTRPair( $prevAnnot, $nextAnnot, $inBetweenDistance,
                                     $classBetweenDistance );
                }
                elsif ( $currentClassName =~ /SINE/ ) {
                  $inBetweenScore =
                      &scoreSINEPair( $prevAnnot, $nextAnnot,
                                      $inBetweenDistance );
                }
                else {
                  $inBetweenScore =
                      &scoreGenericPair( $prevAnnot, $nextAnnot,
                                    $inBetweenDistance, $classElementDistance );
                }

                last if ( $inBetweenScore >= $score );
              }

              if ( $inBetweenScore >= $score ) {

                # Abandon match, there is an intervening better match
                print "     \\--> Better intervening score "
                    . "$inBetweenScore\n"
                    if ( $DEBUG );
              }
              else {
                print "   ---> Sticking with first match: score=$score\n"
                    if ( $DEBUG );
                if ( $maxScore < $score ) {
                  $maxScore        = $score;
                  $maxScoringAnnot = $nextAnnot;
                }
              }
            }
          }
          else {
            if ( $DEBUG ) {
              print "   ---> Already linked to something on left"
                  . "\n        ";
              $nextAnnot->getLeftLinkedHit()->printBrief();
            }
          }
        }    # while ( $proxIter->hasNext()...

        if ( $maxScore > 0 ) {
          if ( $DEBUG ) {
            print " *** And the winner is: score = $maxScore\n     ";
            $maxScoringAnnot->print();
          }
          if ( $currentAnnot->getRightLinkedHit() ) {

            # Remove insignificant extension early
            $currentAnnot->getRightLinkedHit()->setLeftLinkedHit( undef );
          }
          $currentAnnot->setRightLinkedHit( $maxScoringAnnot );
          $maxScoringAnnot->setLeftLinkedHit( $currentAnnot );
        }

      }
    }
    $DEBUG = 0;

    #printHitArrayList( $sortedAnnotationsList );

    ########################## C Y C L E 7 ################################
    #
    #  Name joined LINE/LTR clusters
    #
    ########################################################################

    print "\ncycle 7 ";

    ##
    ## Name joined fragments & pick consensus adjustment
    ##
    ##   The name of a chain is determined by the highest scoring
    ##   fragment in the highest priority model group.  The model
    ##   groups are ( in order of priority ) 3-Prime End Models,
    ##   5-Prime End Models, ORF Models, and Undesignated Models.
    ##
    ##   Also the consensus adjustment is calculated by finding
    ##   the highest consensus adjustment from conPosCorrection
    ##   for the given fragment chain.
    ##
    $DEBUG          = 0;
    $cycleAnnotIter = $sortedAnnotationsList->getIterator();
    $i              = -1;
    while ( $cycleAnnotIter->hasNext() ) {
      $i++;
      print "." if ( $i + 1 ) % 1000 == 0;
      my $currentAnnot = $cycleAnnotIter->next();

      # RMH: 12/12
      # Small singleton fragments are no longer useful
      if (
         ( $currentAnnot->getQueryEnd() - $currentAnnot->getQueryStart() + 1 ) <
         10
         && !$currentAnnot->getLeftLinkedHit()
         && !$currentAnnot->getRightLinkedHit() )

      {
        $cycleAnnotIter->remove();
        next;
      }

      if (    keys( %refinementHash )
           && defined $refinementHash{ $currentAnnot->getLineageId() }
           && $currentAnnot->getSubjName =~ /Alu/
           && !$currentAnnot->getLeftLinkedHit() )
      {

        # Check that right linked hits are all the same ID
        my $nextLinked = $currentAnnot;
        my $isRMJoined = 1;
        while ( $nextLinked = $nextLinked->getRightLinkedHit() ) {
          if ( $nextLinked->getLineageId() ne $currentAnnot->getLineageId() ) {
            $isRMJoined = 0;
            last;
          }
        }
        next if ( !$isRMJoined );

        if ( $DEBUG ) {
          print "\nSEED: ";
          $currentAnnot->print();
        }

        my $currentAnnotRefinedMatch = getMatchingRefinedEntry( $currentAnnot );

        # See above problem with batch overlaps
        $currentAnnotRefinedMatch = $currentAnnot
            if ( !defined $currentAnnotRefinedMatch );

        if ( $DEBUG ) {
          print "   REFINED ( seed equiv): ";
          $currentAnnotRefinedMatch->print();
        }

        my $maxScore          = 0;
        my $maxScoringElement = undef;
        ##
        ##  Ambiguate refinement calls if small non-specific fragment
        ##  equally matches many consensi.  Here it is good to use a
        ##  scoring function which doesn't consider CpG sites --
        ##  which may weakly weigh the call towards one subfamily
        ##  vs another.
        ##
        ##  NOTE: The use of a fixed matrix here is only used to
        ##        evaluate the scores of the refined hits.  It
        ##        is not saved to the result object and thus doesn't
        ##        impact the final score printed to the *.out file.
        ##
        ## TODO: Consider changing this to a less extreme matrix.
        ##       I.e 18p41g or 18p43g
        my $matrix =
            Matrix->new(
            fileName => "$FindBin::RealBin/Matrices/crossmatch/18p35g.matrix" );
        my $numEquiv  = 0;
        my $totalEles = 0;

        # TODO : Optimisation potential.  Cache rescore.
        foreach my $ele ( getEquivArray( $currentAnnot ) ) {
          my ( $score, $div ) = $ele->rescoreAlignment(
                                                   scoreMatrix    => $matrix,
                                                   gapOpenPenalty => -30,
                                                   insGapExtensionPenalty => -6,
                                                   delGapExtensionPenalty => -5,
                                                   scoreCpGMod            => 1,
                                                   complexityAdjust       => 1
          );

          if ( $DEBUG ) {
            print "  Refined score = $score / $div: ";
            $ele->print();
          }
          if ( $score > $maxScore ) {
            $maxScore          = $score;
            $maxScoringElement = $ele;
            $numEquiv          = 0;
          }
          elsif ( $score >= $maxScore - 10 ) {
            $numEquiv++;
          }
          $totalEles++;
        }

        if ( $numEquiv > 10 ) {
          $maxScoringElement = undef;
          $currentAnnot->setHitName( "Alu" );
        }

        #print "lengthThreshold = $lengthThreshold\n" if ( $DEBUG );
        if ( $maxScoringElement ) {
          if ( $DEBUG ) {
            print "   REFINED winner (nonCpG Score $maxScore ): ";
            $maxScoringElement->print();
          }

          if ( $currentAnnot->getRightLinkedHit() ) {
            print "Replacing chain with refinement\n" if ( $DEBUG );
            &replaceRMFragmentChainWithRefinement( $currentAnnot,
                                                   $maxScoringElement );
          }
          else {
            print "Replacing single annot with refinement\n" if ( $DEBUG );
            $currentAnnot->setHitName( $maxScoringElement->getHitName() );
            $currentAnnot->setScore( $maxScoringElement->getScore() );
            $currentAnnot->setPctDiverge( $maxScoringElement->getPctDiverge() );
            $currentAnnot->setPctKimuraDiverge(
                                    $maxScoringElement->getPctKimuraDiverge() );
            $currentAnnot->setPctDelete( $maxScoringElement->getPctDelete() );
            $currentAnnot->setPctInsert( $maxScoringElement->getPctInsert() );
            $currentAnnot->setQueryStart( $currentAnnot->getQueryStart() +
                                  ( $maxScoringElement->getQueryStart() - 1 ) );
            $currentAnnot->setQueryEnd( $currentAnnot->getQueryEnd() -
                                      $maxScoringElement->getQueryRemaining() );
            $currentAnnot->setQueryRemaining(
                                  $currentAnnot->getQueryRemaining() +
                                      $maxScoringElement->getQueryRemaining() );
            $currentAnnot->setOrientation(
                                         $maxScoringElement->getOrientation() );
            $currentAnnot->setHitName( $maxScoringElement->getHitName() );
            $currentAnnot->setClassName( $maxScoringElement->getClassName() );
            $currentAnnot->setSubjStart( $maxScoringElement->getSubjStart() );
            $currentAnnot->setSubjEnd( $maxScoringElement->getSubjEnd() );
            $currentAnnot->setSubjRemaining(
                                       $maxScoringElement->getSubjRemaining() );

            my $newDerived = $maxScoringElement->clone();
            $newDerived->setQueryName( $currentAnnot->getQueryName() );
            $newDerived->setQueryStart( $currentAnnot->getQueryStart() );
            $newDerived->setQueryEnd( $currentAnnot->getQueryEnd() );
            $newDerived->setQueryRemaining(
                                           $currentAnnot->getQueryRemaining() );
            $currentAnnot->setDerivedFromAnnot( $newDerived );

          }
          if ( $DEBUG ) {
            print "I did this with it: ";
            $currentAnnot->print();
          }
        }
      }

      # We only care about LINES/LTR for the rest
      next if ( $currentAnnot->getSubjName !~ /LINE|LTR/ );

      # Consider only left ( from our direction of iteration )
      # fragment ends
      if ( $currentAnnot->getRightLinkedHit()
           && !$currentAnnot->getLeftLinkedHit()
           || !$currentAnnot->getLeftLinkedHit()
           && !$currentAnnot->getRightLinkedHit() )
      {
        my @elements = ();
        push @elements, $currentAnnot;

        # Follow links until end
        my $nextInChain    = $currentAnnot;
        my $highestConCorr = $conPosCorrection{ $nextInChain->getPRID() };
        if ( $DEBUG ) {
          print "Naming Current:\n";
          $currentAnnot->print();
        }
        while ( $nextInChain ) {
          if ( $DEBUG ) {
            print " -- ";
            $nextInChain->print();
            print "   \\--- ID="
                . $nextInChain->getPRID()
                . " con{ID} = "
                . $conPosCorrection{ $nextInChain->getPRID() }
                . " highest = "
                . $highestConCorr . "\n";
          }
          push @elements, $nextInChain;
          $highestConCorr = $conPosCorrection{ $nextInChain->getPRID() }
              if (
               $conPosCorrection{ $nextInChain->getPRID() } > $highestConCorr );
          $nextInChain = $nextInChain->getRightLinkedHit();
        }
        $nextInChain = $elements[ $#elements ];

        # LTR or LINE
        my $newLINEName   = "";
        my $newLTRName    = "";
        my $newLTRIntName = "";
        if ( $currentAnnot->getClassName =~ /LTR/ ) {
          @elements =
              sort {
            isLTR( $b ) <=> isLTR( $a )
                || $b->getScore() <=> $a->getScore();
              } @elements;
          my $winner = $elements[ 0 ];
          $newLTRName = $winner->getHitName() if ( isLTR( $winner ) );

          @elements =
              sort {
            isInternal( $b ) <=> isInternal( $a )
                || $b->getScore() <=> $a->getScore();
              } @elements;
          $winner        = shift @elements;
          $newLTRIntName = $winner->getHitName() if ( isInternal( $winner ) );

          #$newLTRIntName =~ s/-int//g;
        }
        else {
          @elements =
              sort {
            my $nameA = $a->getSubjName();
            my $nameB = $b->getSubjName();
            ( $nameA ) = ( $nameA =~ /(_5end|_3end|_orf2)/ );
            ( $nameB ) = ( $nameB =~ /(_5end|_3end|_orf2)/ );
            $nameA = "_zzz" if ( $nameA eq "" );
            $nameB = "_zzz" if ( $nameB eq "" );
            $nameA cmp $nameB || $b->getScore() <=> $a->getScore();
              } @elements;
          my $winner = shift @elements;
          $newLINEName = $winner->getSubjName();
        }

        # Now change the names
        while ( $nextInChain ) {
          if ( $currentAnnot->getClassName() =~ /LTR/ ) {
            if ( isInternal( $nextInChain ) ) {
              if (    $newLTRName
                   && $nextInChain->getClassName() =~ /ERVL-MaLR/ )
              {

                # Name after LTR
                if ( $newLTRName !~ /-I|-int/ ) {
                  $nextInChain->setHitName( $newLTRName . "-int" );
                }
                else {
                  $nextInChain->setHitName( $newLTRName );
                }
              }
              elsif ( $newLTRIntName ) {

                # Name after highest scoring internal
                if ( $newLTRIntName !~ /-I|-int/ ) {
                  $nextInChain->setHitName( $newLTRIntName . "-int" );
                }
                else {
                  $nextInChain->setHitName( $newLTRIntName );
                }

              }
            }
            else {
              $nextInChain->setHitName( $newLTRName );
            }
          }
          else {
            $nextInChain->setSubjName( $newLINEName );
          }
          if ( $DEBUG ) {
            print "Fixing conPosCorrection(*$highestConCorr): ";
            $nextInChain->print();
          }

# NOTE: Design improvement potential.  LINEs like Hal1B can
#       be renamed as other LINES ( ie. L1M7 ).  When this
#       happens a different adjustment should be used to
#       define it's consensus coordinates.
#       Here is a good example:
#287 28.17 8.72 4.70 big 5079 5227 (39675) C HAL1b#LINE/L1 (457) 1552 1398 5
#281 25.51 16.59 4.39 big 5136 5298 (39748) C L1M7_5end#LINE/L1 (417) 1820 1637 5
#705 15.03 0.00 8.28 big 5299 5443 (41394) C FLAM_C_short_#SINE/Alu (0) 133 1 3
#281 25.51 16.59 4.39 big 5444 5484 (39562) C L1M7_5end#LINE/L1 (601) 1636 1591 5
#345 27.33 5.26 1.32 big 5506 5657 (39389) C L1M7_5end#LINE/L1 (873) 1364 1207 5
# Consider a design change to handle this.
#
          $conPosCorrection{ $nextInChain->getPRID() } = $highestConCorr;

          # Can be linked to itself.
          if ( $nextInChain == $nextInChain->getLeftLinkedHit() ) {
            last;
          }
          $nextInChain = $nextInChain->getLeftLinkedHit();
        }    # while ( $nextInChain...
      }
    }
    $DEBUG = 0;

    #printHitArrayList( $sortedAnnotationsList );

    ########################## C Y C L E 8 ################################
    #
    #  Merge overlapping fragments
    #
    ########################################################################

    print "\ncycle 8 ";

    ##
    ## Merge joined overlapping fragments into one fragment
    ##
    ##   This is basically the old FuseOverlappingSeqs routine.
    ##   The process is basically a cosmetic one -- simplifying
    ##   the output.
    ##
    ##  Sort by class?
    ##
    $cycleAnnotIter = $sortedAnnotationsList->getIterator();
    my $prevAnnot;
    $DEBUG = 0;
    $i     = -1;
    while ( $cycleAnnotIter->hasNext() ) {

      # Pick one element
      $i++;
      print "." if ( $i + 1 ) % 1000 == 0;
      my $currentAnnot = $cycleAnnotIter->next();

      if ( $DEBUG ) {
        print "Considering:\n";
        $currentAnnot->print();
      }

      my $proxIter  = $cycleAnnotIter->getIterator();
      my $lookAhead = 0;
      while ( $proxIter->hasNext() ) {
        my $next1Annot = $proxIter->next();

        if ( $DEBUG ) {
          print "  --vs-->";
          $next1Annot->print();
          print "      query Gap = "
              . $currentAnnot->getQueryGap( $next1Annot ) . "\n";
        }

        # TODO: Now this is specific for SVA...need to generalize this for
        #       anything which contains a tandem repeat unit.
        last
            if (
                 $next1Annot->getQueryName() ne $currentAnnot->getQueryName()
                 || (    $currentAnnot->getHitName !~ /^SVA.*/
                      && $currentAnnot->getQueryGap( $next1Annot ) > 10 )
                 || (    $currentAnnot->getHitName() =~ /^SVA.*/
                      && $lookAhead++ > 2 )
            );

        next
            if ( $next1Annot->getClassName() ne $currentAnnot->getClassName() );

        my $next2Annot = undef;
        if ( $proxIter->hasNext() ) {
          $next2Annot = $proxIter->next();
          $proxIter->previous();

          # So as to emit the one we will delete
          $proxIter->previous();
          $proxIter->next();
        }

        my $QO = $currentAnnot->getQueryOverlap( $next1Annot );

        #
        # SVAs and LAVAs
        #
        #   - Special because they contain a vntr region.  This region
        #     behaves in a similar way to satellites or simple repeats.
        #     As a consequence we should lower the required overlap before
        #     merging/joining copies.
        #   - Lastly these are not joined yet.
        #   - Query Gap < 10bp
        #
        #   SVA Architecture:
        #         TSD---Hexamer---AluLike--VNTR---SINE-R--An--TSD
        #                                 ~436-793
        #   LAVA Architecture:
        #         TSD---AluLike---VNTR---AluSz----L1M5---An---TSD
        #     LAVA_A2            438 1383
        #     LAVA_A1/B.         413 1358
        #     LAVA_C2            364 1470
        #     LAVA_C4/D./E./F0   395 1500
        #     LAVA_F1/F2         236 1358
        #
        if (    $currentAnnot->getClassName() =~ /SVA/
             && $next1Annot->getClassName() =~ /SVA/ )
        {
          my $currentVNTRRange = getVNTRRange( $currentAnnot->getHitName() );
          my $next1VNTRRange   = getVNTRRange( $next1Annot->getHitName() );
          if (
                  defined $currentVNTRRange
               && defined $next1VNTRRange
               && (    $currentAnnot->getOrientation() eq "C"
                    && $currentAnnot->getSubjEnd() > $currentVNTRRange->[ 0 ]
                    && $next1Annot->getSubjEnd() < $next1VNTRRange->[ 1 ]
                    || $currentAnnot->getOrientation() eq "+"
                    && $currentAnnot->getSubjStart() < $currentVNTRRange->[ 1 ]
                    && $next1Annot->getSubjStart() > $next1VNTRRange->[ 0 ] )
              )
          {

            # rest taken care of elsewhere
            if ( $QO >= -10 ) {
              if ( $DEBUG ) {
                print "SVA/LAVA merging:\n";
                $currentAnnot->print();
                $next1Annot->print();
              }
              $currentAnnot->merge( $next1Annot );
              $currentAnnot->addDerivedFromAnnot( $next1Annot )
                  if ( $options{'source'} );
              $proxIter->remove();
              $lookAhead--;
            }
            else {
              if ( $DEBUG ) {
                print "SVA/LAVA joining\n";
                $currentAnnot->print();
                $next1Annot->print();
              }
              $currentAnnot->join( $next1Annot );
              last;
            }
          }
        }
        elsif (    $currentAnnot->getClassName() =~ /Simple|Satellite/
                && $QO >= -10 )
        {

          # Simple Repeats and Satellites
          my $thislength =
              $currentAnnot->getSubjEnd() - $currentAnnot->getSubjStart() + 1;
          my $lastlength =
              $next1Annot->getSubjEnd() - $next1Annot->getSubjStart() + 1;
          if ( $DEBUG ) {
            print "    Simple/Satellite";
          }

          #
          # ie. -------------->          or  --------------->
          #               ----------->             --------->
          #                              or  --------->
          #                                                ------------->
          # NOT:
          #          ----------------->
          #               ----->
          #     Why not?
          #
          if ( $next1Annot->getQueryEnd() >= $currentAnnot->getQueryEnd() ) {
            if ( $currentAnnot->getHitName() ne $next1Annot->getHitName() ) {
              my $nextoverlap = 0;
              if ( $next2Annot ) {
                if ( $DEBUG ) {
                  print "  --next->:";
                  $next2Annot->printBrief();
                }

                # don't fuse (CA)n(TG)n(CA)n etc
                # TODO: Wouldn't this fuse: (CA)n(TG)n(TG)n?
                # TODO: Run this by Arian
                my $tempname = quotemeta $next1Annot->getHitName();
                if ( $next2Annot->getSubjName() =~ /$tempname/
                  && $next1Annot->getQueryName() eq $next2Annot->getQueryName()
                  && $next2Annot->getQueryStart() < $next1Annot->getQueryEnd() )
                {
                  $nextoverlap = $currentAnnot->getQueryOverlap( $next2Annot );
                }
              }

              #print  " QO=$QO, thislength = $thislength, " .
              #             "nextoverlap = $nextoverlap\n" if ( $DEBUG );
              if (
                $QO + $nextoverlap > 10
                &&

                # just to be sure it's not 0 in the following division
                # Significant overlap between the three
                $thislength / ( $QO + $nextoverlap ) < 2
                  )
              {
                print "  --> merging!\n" if ( $DEBUG );
                $currentAnnot->mergeSimpleLow( $next1Annot );
                $currentAnnot->addDerivedFromAnnot( $next1Annot )
                    if ( $options{'source'} );
                $proxIter->remove();
              }
            }
            else {
              print "  --> merging!\n" if ( $DEBUG );
              $currentAnnot->mergeSimpleLow( $next1Annot );
              $currentAnnot->addDerivedFromAnnot( $next1Annot )
                  if ( $options{'source'} );
              $proxIter->remove();
            }
          }
        }

        # See if they overlap by some obvious amount
        if (
          $currentAnnot->getQueryEnd() - $next1Annot->getQueryStart() + 1 > 33 )
        {
          print "     -- a big overlap...is it already linked?\n"
              if ( $DEBUG );
          if ( $currentAnnot->getRightLinkedHit() == $next1Annot ) {
            if ( $DEBUG ) {
              print "Merging a joined pair:\n";
              $currentAnnot->print();
              $next1Annot->print();
            }
            $currentAnnot->merge( $next1Annot );

            $currentAnnot->addDerivedFromAnnot( $next1Annot )
                if ( $options{'source'} );
            $proxIter->remove();
            if ( $DEBUG ) {
              print "  Outcome:\n";
              $currentAnnot->print();
            }
            if (   $conPosCorrection{ $currentAnnot->getPRID() }
                && $currentAnnot->getSubjStart() < $next1Annot->getSubjStart() )
            {
              $conPosCorrection{ $next1Annot->getPRID() } =
                  $conPosCorrection{ $currentAnnot->getPRID() };
            }
          }
          elsif ( $DEBUG ) {
            print "      No!\n";

            #$currentAnnot->printLinks();
          }

          # If they don't....then try again with a not so obvious
          # check
        }
        elsif (
                $currentAnnot->getRightLinkedHit() == $next1Annot
             && $currentAnnot->getOrientation() eq $next1Annot->getOrientation()
             && $currentAnnot->getStage() == $next1Annot->getStage()
             && $currentAnnot->getQueryGap( $next1Annot ) <= 10
             && $currentAnnot->getConsensusGap( $next1Annot ) <= 100
             && (    $currentAnnot->getConsensusOverlap( $next1Annot ) <= 20
                  || $currentAnnot->getQueryGap( $next1Annot ) < 0
                  && $currentAnnot->getConsensusOverlap( $next1Annot ) -
                  $currentAnnot->getQueryOverlap( $next1Annot ) <= 20 )
            )
        {

          # Fuse all remaining neighboring closely related elements that
          # overlap or nearly join in the query and have small gaps or tiny
          # overlaps in the consensus. This simplifies the output, though
          # there is a further disconnect with the alignments. Since this is
          # largely a cosmetic action, selectivity trumps sensitivity.
          #
          # Arian suggested that we only join these if the pctDel
          # does not exceed some threshold.  This limit would keep
          # fragments from merging if they contain more info as
          # independent annotations.
          #
          my ( $subBases, $subPct, $delBases, $delPct, $insBases, $insPct ) =
              $currentAnnot->getAdjustedSubstLevel( $next1Annot );

          #
          print "Merged pair would have: subPct = $subPct, "
              . "delBases = $delBases, delPct = $delPct, insPct = $insPct\n"
              if ( $DEBUG );

          unless ( $delPct > 50 ) {
            if ( $DEBUG ) {
              print "SHOULD MERGE THESE TWO:\n";
              $currentAnnot->printBrief();
              $next1Annot->printBrief();
            }

            $currentAnnot->merge( $next1Annot );
            $currentAnnot->addDerivedFromAnnot( $next1Annot )
                if ( $options{'source'} );
            $proxIter->remove();
            if ( $DEBUG ) {
              print "  Outcome:\n";
              $currentAnnot->print();
            }
            if (   $conPosCorrection{ $currentAnnot->getPRID() }
                && $currentAnnot->getSubjStart() < $next1Annot->getSubjStart() )
            {
              $conPosCorrection{ $next1Annot->getPRID() } =
                  $conPosCorrection{ $currentAnnot->getPRID() };
            }
          }    # if $delPct < 50
        }    # Merge close fragments
        elsif ( $DEBUG ) {
          print "     Don't merge: qo = "
              . $currentAnnot->getQueryOverlap( $next1Annot )
              . " co = "
              . $currentAnnot->getConsensusOverlap( $next1Annot )
              . " stages = "
              . $currentAnnot->getStage() . "/"
              . $next1Annot->getStage()
              . " linked = ";
          if ( $currentAnnot->getRightLinkedHit() == $next1Annot ) {
            print "yes";
          }
          else {
            print "no";
          }
          print "\n";
        }
      }    # while proxIter->hasNext()...

    }

    #printHitArrayList( $sortedAnnotationsList );

    ########################## C Y C L E 9 ################################
    #
    #  Remove things included in other things???
    #  LINE Recombinants
    #  Unhide elements inserted inside other hits
    #
    ########################################################################

    print "\ncycle 9 ";

    $sortedAnnotationsList->sort( \&byNameBeginEndrevSWrev );

    $i              = -1;
    $cycleAnnotIter = $sortedAnnotationsList->getIterator();

    $DEBUG = 0;

CYCLE9:
    while ( $cycleAnnotIter->hasNext() ) {
      $i++;
      print "." if ( $i + 1 ) % 1000 == 0;
      my $currentAnnot = $cycleAnnotIter->next();

      if ( $DEBUG ) {
        print "Cycle9: Considering: ";
        $currentAnnot->print();
      }

      # Do not consider elements previously tagged for deletion!
      next if ( $currentAnnot->getHitName() eq "DELETE_ME" );

      #
      # Remove fragments contained by a previous annotation
      #
      #
      #      -Same stage
      #   and   ------>  or  ------>
      #           ---->        --->
      #      -Same ID or LTR8 and Harlequin
      #
      #  or
      #
      #      - Same stage
      #      - Same class
      #      - ----------->  or -------->
      #           -------->     ------>
      #
      #
      my $pastIter = $cycleAnnotIter->getIterator();
      $pastIter->previous();
      my $k = 1;
      while ( $k++ < 10 && $pastIter->hasPrevious() ) {
        my $pastAnnot = $pastIter->previous();
        if ( $currentAnnot->getQueryName() eq $pastAnnot->getQueryName() ) {
          my $currentClassName = $currentAnnot->getClassName();
          if (
               $currentAnnot->getStage() == $pastAnnot->getStage()
               && (
                  $currentAnnot->getQueryEnd() <= $pastAnnot->getQueryEnd()
                  && ( $currentAnnot->getSubjName() eq $pastAnnot->getSubjName()
                       || $currentAnnot->getSubjName() =~ /LTR8$/
                       && $pastAnnot->getSubjName()    =~ /Harlequin/ )
                  || (
                     (
                       $currentAnnot->getQueryEnd() == $pastAnnot->getQueryEnd()
                       || $currentAnnot->getQueryStart() ==
                       $pastAnnot->getQueryStart()
                     )
                     && $pastAnnot->getClassName() =~ /$currentClassName/
                  )
               )
              )
          {
            if ( $DEBUG ) {
              print "1Removing because it's included in the previous!\n";
              $pastAnnot->print();
              $currentAnnot->print();
            }
            if ( $pastAnnot->getRightLinkedHit() == $currentAnnot ) {
              print "Relinking the past\n" if ( $DEBUG );
              $pastAnnot->setRightLinkedHit(
                                           $currentAnnot->getRightLinkedHit() );
              if ( $currentAnnot->getRightLinkedHit() ) {
                $currentAnnot->getRightLinkedHit()
                    ->setLeftLinkedHit( $pastAnnot );
              }
            }
            else {    ###  What should be done with these?  They may have linked
              ###  partners.
            }
            $currentAnnot->removeFromJoins();
            $pastAnnot->addDerivedFromAnnot( $currentAnnot )
                if ( $options{'source'} );
            $cycleAnnotIter->remove();
            next CYCLE9;
          }
          ### TODO: WHAT IS THIS CATCHING REALLY?
          ###   - Same ID
          ###    ---masked--->  or   ---masked-->
          ###      ---cut---->       ---cut-->
          ###  How can this even happen???
          ###     I have not been able to find an example of this being
          ###     invoked.
          elsif (
               $currentAnnot->isCut()
            && $pastAnnot->isMasked()
            && $currentAnnot->getSubjName() eq $pastAnnot->getSubjName()
            && ( $currentAnnot->getQueryEnd() == $pastAnnot->getQueryEnd()
              || $currentAnnot->getQueryStart() == $pastAnnot->getQueryStart() )
              )
          {
            if ( $DEBUG ) {
              print "2Removing because it's included in the previous!\n";
              $pastAnnot->print();
              $currentAnnot->print();
            }
            if ( $pastAnnot->getRightLinkedHit() == $currentAnnot ) {
              print "Relinking the past\n" if ( $DEBUG );
              $pastAnnot->setRightLinkedHit(
                                           $currentAnnot->getRightLinkedHit() );
              if ( $currentAnnot->getRightLinkedHit() ) {
                $currentAnnot->getRightLinkedHit()
                    ->setLeftLinkedHit( $pastAnnot );
              }
            }    # See above
            $currentAnnot->removeFromJoins();
            $pastAnnot->addDerivedFromAnnot( $currentAnnot )
                if ( $options{'source'} );
            $cycleAnnotIter->remove();
            next CYCLE9;
          }
        }
        else {
          last;
        }
      }

      # March 2004; moved this block to so that recombined elements
      # with inserts can be joined properly.
      # I have seen insertions in human vs chimp (and chimp vs human) in
      # which the gap in the consensus was up to 175 bp
      # With new ORF2 consensus seqs less chance of false joining and more
      # consistent divergence of fragments, I've reset the allowed gap in the
      # consensus from 33 to a calculated distance based on difference in
      # divergence level, gap between fragments in query sequence. The gap
      # allowed is doubled when the fragments have the same subfamily
      # designation.
      if ( $currentAnnot->getClassName =~ /^LINE\/L1/ ) {

        # special case of (the quite common case of) LINEs integrated
        # after recombination this appears as an inversion of part of
        # the element giving a <- -> structure. matchL1frags() matches
        # up IDs of fragments and improves subfamily name if possible.
        # This is not seen in L2,L3 (Perhaps in L4; don't know yet)
        my $pastIter = $cycleAnnotIter->getIterator();
        $pastIter->previous();
        my $forwIter = $cycleAnnotIter->getIterator();
        my $n        = 1;
        my $matched  = 0;
        while ( $n++ < 6 ) {
          my $pastAnnot = undef;
          my $pastAnnot = $pastIter->previous() if ( $pastIter->hasPrevious() );
          my $nextAnnot = undef;
          my $nextAnnot = $forwIter->next() if ( $forwIter->hasNext() );

          #       past           current
          #    <----L1-- <=20bp ----L1--->
          if (  $pastAnnot
             && $currentAnnot->getQueryName() eq $pastAnnot->getQueryName()
             && $pastAnnot->getClassName()    eq "LINE/L1"
             && $currentAnnot->getQueryStart() - $pastAnnot->getQueryEnd() <= 20
             && $currentAnnot->getOrientation() eq '+'
             && $pastAnnot->getOrientation()    eq "C" )
          {
            my $gap =
                $currentAnnot->getQueryStart() - $pastAnnot->getQueryEnd();

            # Overlaps always indicate false extension; neither bad nor good
            $gap = 0 if ( $gap < 0 );

            # The more different the divergence and the further apart
            # the fragments, the stricter the requirements
            my $gapallowed = 175 - 20 *
                abs(
                $currentAnnot->getPctDiverge() - $pastAnnot->getPctDiverge() ) -
                5 * $gap;

            # Same subfamily name is a big bonus
            $gapallowed += 50
                if ( $currentAnnot->getHitName() eq $pastAnnot->getHitName() );

            if (
              $currentAnnot->getSubjEnd() - $pastAnnot->getSubjStart() <
              $gapallowed / 2
              &&    # overlap should be smaller, but ones seen up to 46 bp
              $pastAnnot->getSubjStart() - $currentAnnot->getSubjEnd() <
              $gapallowed
                )
            {
              if ( &areLINENamesCompat( $currentAnnot, $pastAnnot )
                || $currentAnnot->getHitName() =~ /^L1.*_3end$/
                && $currentAnnot->getSubjEnd() < 6015
                && $pastAnnot->getSubjEnd() - $pastAnnot->getSubjStart() > 100 )
              {
                $matched = $pastAnnot;
                last;
              }
            }
          }

          #      current          next
          #    <----L1-- <=20bp ----L1--->
          elsif ( $nextAnnot
             && $nextAnnot->getSubjName() =~ /LINE\/L1/
             && $currentAnnot->getQueryName() eq $nextAnnot->getQueryName()
             && $nextAnnot->getQueryStart() - $currentAnnot->getQueryEnd() <= 20
             && $currentAnnot->getOrientation() eq "C"
             && $nextAnnot->getOrientation()    eq '+' )
          {
            my $gap =
                $nextAnnot->getQueryStart() - $currentAnnot->getQueryEnd();
            $gap = 0 if ( $gap < 0 );

            my $gapallowed = 175 - 20 *
                abs(
                $currentAnnot->getPctDiverge() - $nextAnnot->getPctDiverge() ) -
                5 * $gap;

            $gapallowed += 50
                if ( $nextAnnot->getHitName() eq $currentAnnot->getHitName() );

            if ( $currentAnnot->getSubjEnd() - $nextAnnot->getSubjStart() <
                    $gapallowed / 2
                 && $nextAnnot->getSubjStart() - $currentAnnot->getSubjEnd <
                 $gapallowed )
            {
              if ( &areLINENamesCompat( $currentAnnot, $nextAnnot )
                || $currentAnnot->getHitName() =~ /^L1.*_3end$/
                && $currentAnnot->getSubjEnd() < 6015
                && $nextAnnot->getSubjEnd() - $nextAnnot->getSubjStart() > 100 )
              {
                $matched = $nextAnnot;
                last;
              }
            }
          }
        }
        if ( $matched ) {
          ## TODO: This code should be moved before line clusters
          ##       are named and corrections are determined.  This
          ##       would reduce having to do this twice.
          if ( $DEBUG ) {
            print "Joining recombinant L1's:\n";
            $matched->print();
            $currentAnnot->print();
          }
          my $highestConsCorrection = $conPosCorrection{ $matched->getPRID() };
          $highestConsCorrection = $conPosCorrection{ $currentAnnot->getPRID() }
              if ( $conPosCorrection{ $currentAnnot->getPRID() } >
                   $highestConsCorrection );
          $currentAnnot->join( $matched );

          # Fix left
          my $chainNext  = $currentAnnot;
          my $detectLoop = 0;
          while (    $chainNext->getLeftLinkedHit() != undef
                  && $chainNext->getLeftLinkedHit() != $chainNext
                  && $detectLoop < 50 )
          {
            $chainNext = $chainNext->getLeftLinkedHit();
            $conPosCorrection{ $chainNext->getPRID() } = $highestConsCorrection;
            $detectLoop++;
          }

          # Fix right
          $chainNext  = $currentAnnot;
          $detectLoop = 0;
          while (    $chainNext->getRightLinkedHit() != undef
                  && $chainNext->getRightLinkedHit() != $chainNext
                  && $detectLoop < 50 )
          {
            $chainNext = $chainNext->getRightLinkedHit();
            $conPosCorrection{ $chainNext->getPRID() } = $highestConsCorrection;
            $detectLoop++;
          }

          # Fix current
          $conPosCorrection{ $currentAnnot->getPRID() } =
              $highestConsCorrection;

          $currentAnnot->setHitName( $matched->getSubjName() );
          if ( $DEBUG ) {
            print "Result:";
            $currentAnnot->print();
          }
        }
      }    # if ( $ClassName =~ /^LINE\/L1/...

      unless ( $options{'noint'} ) {

        my $flankingIter = $cycleAnnotIter->getIterator();
        $flankingIter->previous();
        my $prevAnnot = undef;
        if ( $flankingIter->hasPrevious ) {
          $prevAnnot = $flankingIter->previous();
          $flankingIter->next();
        }
        $flankingIter->next();
        my $nextAnnot = undef;
        if ( $flankingIter->hasNext() ) {
          $nextAnnot = $flankingIter->next();
          $flankingIter->previous();
        }

        #
        # unhide elements inserted in older elements by breaking up the
        # older elements.
        #
        #  ie.      ---------LINE--------------------
        #                  ------LTR-----------
        #
        # These would not get fused in the previous code because
        # they are of different classes. Now we need to decide
        # if the LINE above should be broken up?
        #
        my $newSeq2Begin = $currentAnnot->getSubjStart();
        my $newSeq2End   = $currentAnnot->getSubjEnd();
        my @inserts      = ();

        # Look for all elements inserted in this entry
        # we're estimating the position(s) in Seq2 where the
        # insertion(s) took place from the position(s) in Seq1
        # Look into the future until
        #    - The future element isn't contained inside the current one.
        #    - We have moved into a new query sequence.
        my $j             = 0;
        my $prevNextAnnot = undef;
        if ( $DEBUG ) {
          print "Unhide Inserts:\n";
        }
        while ( $flankingIter->hasNext() ) {
          $j++;
          $nextAnnot = $flankingIter->next();
          if ( $DEBUG ) {
            print " --vs-->";
            $nextAnnot->print();
          }
          last
              if ($nextAnnot->getQueryEnd() > $currentAnnot->getQueryEnd()
               || $nextAnnot->getQueryName() ne $currentAnnot->getQueryName() );

          if (
               $nextAnnot->getSubjName() =~ $currentAnnot->getSubjName()
            && $currentAnnot->getStage() == $nextAnnot->getStage()

            ||    # i.e. ignore not yet eliminated overlapping matches to the
                  # same element
            $nextAnnot->getQueryStart() < $currentAnnot->getQueryStart()
            ## TODO ASSERT:  IF $sortedHits[ $j ]->getQueryStart()
            ##                  < $BeginAlign
              )
          {
            next;
          }

          # Too close to the beginning -- just shift it along
          elsif (    $j == 1
                  && $nextAnnot->getQueryStart() <=
                  $currentAnnot->getQueryStart() + 5 )
          {

            # Only 5 bp or less before insertion; move BeginAlign after
            # this element
            if ( $DEBUG ) {
              print "Only 5bp or less...begin extension...clipping it\n";
            }
            my $diff =
                $nextAnnot->getQueryStart() - $currentAnnot->getQueryStart();
            if ( $currentAnnot->getOrientation() eq '+' ) {
              $currentAnnot->setSubjStart(
                                        $currentAnnot->getSubjStart() + $diff );
            }
            else {
              $currentAnnot->setSubjEnd( $currentAnnot->getSubjEnd() - $diff );
            }
            $currentAnnot->setQueryStart( $nextAnnot->getQueryEnd() + 1 );
            if ( $DEBUG ) {
              print "Now:\n";
              $currentAnnot->print();
            }

            # There are cases where exposing an insert by cutting back the
            # begin position will change the sort order of a previously joined
            # set of fragments.  Obvioulsy you don't want a left join
            # pointing to something on the right.
            $currentAnnot->resortJoins();
            next;
          }

          # Too close to the end -- just shift it along
          elsif (
                 $nextAnnot->getQueryEnd() >= $currentAnnot->getQueryEnd() - 5 )
          {

            # Only 5 bp or less after insertion; change EndAlign to
            # just before this element

            # First remove invalidated inserts
            while ( @inserts
                && ( $nextAnnot->getQueryStart() - 1 ) < $inserts[ $#inserts ] )
            {

              # Remove insert
              pop @inserts;
              pop @inserts;
            }

            if ( $DEBUG ) {
              print "Only 5bp or less...end extension...clipping it\n";
            }
            my $diff = $currentAnnot->getQueryEnd() - $nextAnnot->getQueryEnd();

            # could do + 1, but penalty for gap == match to X
            if ( $currentAnnot->getOrientation() eq 'C' ) {
              $currentAnnot->setSubjStart(
                                        $currentAnnot->getSubjStart() + $diff );
            }
            else {
              $currentAnnot->setSubjEnd( $currentAnnot->getSubjEnd() - $diff );
            }
            $currentAnnot->setQueryEnd( $nextAnnot->getQueryStart() - 1 );
            $currentAnnot->resortJoins();
          }
          else {

            # Do not consider inserts within previous inserts
            #  ie.   ------------------------
            #             -----------------
            #                 -----------
            if (    $prevNextAnnot
                 && $nextAnnot->getQueryEnd() < $prevNextAnnot->getQueryEnd() )
            {
              next;
            }

            # Immediate (i.e. within 5 bp) flanking inserts are merged
            if (    $prevNextAnnot
                 && $nextAnnot->getQueryStart() <
                 $prevNextAnnot->getQueryEnd() + 5 )
            {

              # replace last insert end with current one; use last insert start
              pop @inserts;
            }
            else {
              push( @inserts, $nextAnnot->getQueryStart() );
            }
            print "Pushing into inserts\n" if ( $DEBUG );
            push( @inserts, $nextAnnot->getQueryEnd() );
          }
          $prevNextAnnot = $nextAnnot;
        }    # while loop

        if ( @inserts ) {
          my $lengthQmatch =
              $currentAnnot->getQueryEnd() - $currentAnnot->getQueryStart() + 1;
          for ( my $m = 0 ; $m < $#inserts ; $m += 2 ) {

            #print  " inserts[ m, m+1 ] = " . $inserts[$m] . ", " .
            #             $inserts[ $m + 1 ] . "\n";
            my $endInsert = $currentAnnot->getQueryEnd();
            $endInsert = $inserts[ $m ] if ( $inserts[ $m ] < $endInsert );
            $lengthQmatch -= ( $inserts[ $m + 1 ] - $endInsert );
            --$inserts[ $m ];    # now last position of
            ++$inserts[ $m + 1 ];
          }
          my $bpHitperbpQuery = (
             $currentAnnot->getSubjEnd() - $currentAnnot->getSubjStart() + 1 ) /
              $lengthQmatch;

          if ( $DEBUG ) {
            print "Total inserts = " . scalar( @inserts ) . "\n"
                if ( $DEBUG );
            print "lengthQMatch = $lengthQmatch  bpHitperbpQuery = "
                . $bpHitperbpQuery . "\n";
          }

          my @edges = @inserts;
          unshift( @edges, $currentAnnot->getQueryStart() );
          push( @edges, $currentAnnot->getQueryEnd() );

          my $outline = "";

          if ( $DEBUG ) {
            print "   Fragmenting:\n";
          }
          $cycleAnnotIter->remove();
          my $newHit     = undef;
          my $lastNewHit = $currentAnnot->getLeftLinkedHit();
          $lastNewHit = undef
              if ( $currentAnnot->getLeftLinkedHit() == $currentAnnot );
          for ( my $m = 0 ; $m < $#edges ; $m += 2 ) {
            my $newBeginAlign = $edges[ $m ];
            my $newEndAlign   = $edges[ $m + 1 ];
            my $fragsize      = sprintf( "%d",
                                    ( $newEndAlign - $newBeginAlign ) *
                                        $bpHitperbpQuery );
            print "     frag size = $fragsize\n" if ( $DEBUG );
            if ( $currentAnnot->getOrientation() eq '+' ) {

              # NOTE: Clone does not inherit links
              $newHit = $currentAnnot->clone();

              # We don't want to alter the final end position of the
              # original match
              if ( $m < $#edges - 2 ) {
                $newSeq2End = $newSeq2Begin + $fragsize;
                my $remainder = $currentAnnot->getSeq2Len() - $newSeq2End;
                $newHit->setSubjRemaining( $remainder );
                $newHit->setSubjEnd( $newSeq2End );
              }
              $newHit->setQueryEnd( $newEndAlign );
              $newHit->setQueryStart( $newBeginAlign );
              $newHit->setSubjStart( $newSeq2Begin );
              $newSeq2Begin = $newSeq2End + 1;
            }
            else {
              $newHit = $currentAnnot->clone();
              if ( $m < $#edges - 2 ) {
                my $remainder = $currentAnnot->getSeq2Len() - $newSeq2End;
                $newSeq2Begin = $newSeq2End - $fragsize;    # estimate
                $newHit->setSubjStart( $newSeq2Begin );
                $newHit->setSubjRemaining( $remainder );
              }
              $newHit->setQueryStart( $newBeginAlign );
              $newHit->setQueryEnd( $newEndAlign );
              $newHit->setSubjEnd( $newSeq2End );
              $newSeq2End = $newSeq2Begin - 1;
            }
            if ( $lastNewHit ) {
              $newHit->setLeftLinkedHit( $lastNewHit );
              $lastNewHit->setRightLinkedHit( $newHit );
            }
            else {
              $newHit->setLeftLinkedHit( $currentAnnot->getLeftLinkedHit() );
            }
            $newHit->setRightLinkedHit( $currentAnnot->getRightLinkedHit() );
            if ( $DEBUG ) {
              print "Inserting\n";
              $newHit->print();
              print "    Linked to left:";
              $newHit->getLeftLinkedHit()->printBrief()
                  if ( $newHit->getLeftLinkedHit() );
              print "    Linked to right:";
              $newHit->getRightLinkedHit()->printBrief()
                  if ( $newHit->getRightLinkedHit() );
              print "\n";

            }
            $cycleAnnotIter->insert( $newHit );
            $lastNewHit = $newHit;
          }  # for loop
             # Note since we are adding multiple copies of these source
             # annotations, we need to make sure this routine makes a deep copy.

          #$newHit->addDerivedFromAnnot( $currentAnnot )
          #    if ( $options{'source'} );

          if ( $newHit->getRightLinkedHit() ) {
            if ( $newHit->getRightLinkedHit()->getQueryStart() >=
                 $newHit->getQueryStart() )
            {
              print "Setting correct backpointer\n" if ( $DEBUG );
              $newHit->getRightLinkedHit()->setLeftLinkedHit( $newHit );
            }
            else {
              print "Correcting order\n" if ( $DEBUG );
              my $oldRight = $newHit->getRightLinkedHit();
              my $oldLeft  = $newHit->getLeftLinkedHit();
              my $newRight = $oldRight->getRightLinkedHit();
              $newHit->setRightLinkedHit( $oldRight->getRightLinkedHit() );
              $newHit->setLeftLinkedHit( $oldRight );
              $oldRight->setRightLinkedHit( $newHit );
              $oldRight->setLeftLinkedHit( $oldLeft );
              $oldLeft->setRightLinkedHit( $oldRight );
            }
          }
        }    # if @inserts
      }
    }

    #printHitArrayList( $sortedAnnotationsList );
    ########################## C Y C L E 10 ################################
    # Poly-A Joining Code now lives here
    # Fix LINE ranges ( negative ranges )
    #
    ########################################################################

    print "\ncycle 10 ";
    $sortedAnnotationsList->sort( \&byNameBeginEndrevSWrev );

    $i              = -1;
    $cycleAnnotIter = $sortedAnnotationsList->getIterator();

    $DEBUG = 0;

    # Local to cycle
    my $pastAnnot = undef;

CYCLE10:
    while ( $cycleAnnotIter->hasNext() ) {
      $i++;
      print "." if ( $i + 1 ) % 1000 == 0;
      my $currentAnnot = $cycleAnnotIter->next();

      if ( $DEBUG ) {
        print "Cycle10: Considering: ";
        $currentAnnot->print();
      }

      #
      # Join Poly-A tails to SINE or LINE1 annotations:
      #
      # A Poly A tail defined as:
      #
      #    - A hit to a '(A)n', '(CA)n', '(CAA)n', '(AAA)n' etc
      #    - a previous hit (within 5) to a Alu,Flam, Fr?am, L1.*_3end,
      #      L1_.*extended or SVA.  Why would you go five back?? Is it
      #      because you could have overlapping annotations for the previous
      #      segment of DNA?  Why not go back to the limit of the gap that you
      #      accept?
      #    - And for each group of element there is a tolerance for
      #      the amount of consensus that remains unaligned at the end.
      #    - The annotations are not > 3 bases apart
      #    - The simple repeat isn't subsumed by more than 30 bases on
      #      the end. I.e the IR doesn't extend past the simple repeat
      #      by more than 30 bases.
      #    - They are in the same orientation, same sequence etc.
      #    - NOTE: This 30 base limit is due to a search related
      #            constant.  The maximum match to a simple repeat
      #            is around ~20bp.
      #
      #  TODO: Consider doing the same for repeat tails of other SINEs
      #        and LINEs.  Also could consider limiting this to diverged
      #        simple repeats. Consider what is the best way to deal
      #        with the consensus length/masked when the tail exceeds the
      #        length of the original consensus.
      #
      #  NOTE: This routine makes the assumption that simple repeats
      #        and low-complexity regions which where fragmented by
      #        repeatmasker are *not* rejoined above.  Rejoining
      #        is not always appropriate and would cause the code
      #        below to connect up distant fragments to the ends of
      #        SINEs and LINEs.
      #
      my $backIter = $cycleAnnotIter->getIterator();
      $backIter->previous();
      my $forwIter = $cycleAnnotIter->getIterator();
      if (
           (
                $currentAnnot->getHitName eq '(A)n'
             || $currentAnnot->getHitName =~ /^\(.A{3,6}\)/
             || $currentAnnot->getHitName =~ /^A-rich/
             || $currentAnnot->getHitName eq '(T)n'
             || $currentAnnot->getHitName =~ /^\(T{3,6}.\)/
             || $currentAnnot->getHitName =~ /^T-rich/
           )
           && !$options{'noint'}
          )
      {
        my $k = 1;
        my $prevAnnot;
        my $nextAnnot;
        while ( $k < 5 ) {
          my ( $prevHitName, $prevClassName );
          my ( $nextHitName, $nextClassName );
          if ( $backIter->hasPrevious() ) {
            $prevAnnot = $backIter->previous();
            ( $prevHitName, $prevClassName ) =
                split( /\#/, $prevAnnot->getSubjName() );
          }
          if ( $forwIter->hasNext() ) {
            $nextAnnot = $forwIter->next();
            ( $nextHitName, $nextClassName ) =
                split( /\#/, $nextAnnot->getSubjName() );
          }

# TODO: Meta data - Should we have a field in the DB called polyAJoiningMinUnaligned?
#       If set then join Poly A to element but only if unaligned is < polyAJoiningMinUnaligned
# Basic scenarios
#
#          previous                                             current
#  --SINE/LINE----..(max 31 or 25 bp )..> (max gap 3bp ) -------A Rich Repeat--->
#
# or
#
#  ---SINE/LINE---------.....>
#                --(max 31)----------A Rich Repeat----->
          if ( $DEBUG ) {
            print "Poly-A Joining Considering:\n";
            if ( $prevAnnot ) {
              print "  Prev: ";
              $prevAnnot->print();
            }
            print "  Current: ";
            $currentAnnot->print();
            if ( $nextAnnot ) {
              print "  Next: ";
              $nextAnnot->print();
            }
          }
          if (
            $prevAnnot

            # prevAnnot is an Alu or L1 at it's 3' end
            && (    $prevHitName =~ /^Alu|^FLAM/
                 && $prevAnnot->getSubjRemaining() <= 32
                 || $prevHitName =~ /^FR?AM$|^L1.*|^SVA$/
                 && $prevAnnot->getSubjRemaining() < 26 )

            # The Alu/L1 and simple repeat are no more than 4bp apart
            && $currentAnnot->getQueryStart() - $prevAnnot->getQueryEnd() < 4

            # Same input sequence
            && $currentAnnot->getQueryName eq $prevAnnot->getQueryName()

          # Alu/L1 is in the forward strand and simple repeat is a Poly-A repeat
            && (
                 $prevAnnot->getOrientation() ne "C"
                 && (    $currentAnnot->getHitName eq '(A)n'
                      || $currentAnnot->getHitName =~ /^\(.A{3,6}\)/
                      || $currentAnnot->getHitName =~ /^.?A-rich/ )
            )

   # Don't allow the Poly-A tail to extend beyond 30bp past the consensus length
            && (
               ( $currentAnnot->getQueryEnd() - $currentAnnot->getQueryStart() )
               < ( $prevAnnot->getSubjRemaining() + 30 ) )
              )
          {
            my $newend = $currentAnnot->getQueryEnd();

            # should not be counted as insert anymore
            if ( $DEBUG ) {
              print "Fusing ALU and Poly A: Current element:\n";
              $currentAnnot->print();
              print "will be renamed for prev element:\n";
              $prevAnnot->print();
            }

            # TODO: Remove $k loop
            #print  "STRANGE>>>>>>>>WHY IS K > 1???\n"
            #  if ( $k > 1 );

            #
            # Special Case: Incompletely excised Poly-A tails
            #
            # Typical Case:
            #   ---Foo1------> AAAAAAAA -Foo1->
            #
            # Should be resolved as:
            #   ------------Foo1-------------->
            #
            if ( $prevAnnot->getRightLinkedHit() ) {
              my $nextInChain = $prevAnnot->getRightLinkedHit();
              if (  $nextInChain->getScore() eq $prevAnnot->getScore()
                 && $nextInChain->getQueryStart() - $currentAnnot->getQueryEnd()
                 < 5
                 && $nextInChain->getSubjEnd() - $nextInChain->getSubjStart() +
                 1 <= 40
                 && $nextInChain == $nextAnnot )
              {

            # To resolve this we will remove the $prevAnnot and $nextAnnot while
            # converting the $currentAnnot to the final annotation.

                # Save original 'derived from' annotations
                if ( $options{'source'} ) {
                  $currentAnnot->addDerivedFromAnnot( $prevAnnot );
                  $currentAnnot->addDerivedFromAnnot( $nextAnnot );
                }

                # Copy all data fields from $prevAnnot over
                $currentAnnot->setFrom( $prevAnnot );

                # Copy over new Seq1End from $nextAnnot
                $currentAnnot->setQueryEnd( $nextAnnot->getQueryEnd() );
                $currentAnnot->setQueryRemaining(
                                              $nextAnnot->getQueryRemaining() );

                # Set the new seq2End to max
                $currentAnnot->setSubjEnd( $currentAnnot->getSubjEnd() +
                                           $currentAnnot->getSubjRemaining() );

                # Clear out unaligned field
                $currentAnnot->setSubjRemaining( 0 );

                # Remove $past, and $next
                my $removedAnnot = $backIter->remove();
                $pastAnnot = undef;
                if ( $DEBUG ) {
                  print "Removing: ";
                  $removedAnnot->print();
                }

                # Fix joins
                if ( $removedAnnot->getLeftLinkedHit() ) {
                  my $leftLinkedHit = $removedAnnot->getLeftLinkedHit();
                  $leftLinkedHit->setRightLinkedHit( $currentAnnot );
                  $currentAnnot->setLeftLinkedHit( $leftLinkedHit );
                }
                $removedAnnot = $forwIter->remove();
                if ( $DEBUG ) {
                  print "Removing: ";
                  $removedAnnot->print();
                }
                if ( $removedAnnot->getRightLinkedHit() ) {
                  my $rightLinkedHit = $removedAnnot->getRightLinkedHit();
                  $rightLinkedHit->setLeftLinkedHit( $currentAnnot );
                  $currentAnnot->setRightLinkedHit( $rightLinkedHit );
                }

                if ( $DEBUG ) {
                  print "Final call:\n";
                  $currentAnnot->print();
                }

              }
            }
            else {

              # Save original elements
              $currentAnnot->addDerivedFromAnnot( $prevAnnot )
                  if ( $options{'source'} );

              # Copy most data fields from $prevAnnot
              $currentAnnot->setFrom( $prevAnnot );

              if ( $prevAnnot->getLeftLinkedHit() ) {
                my $prevInChain = $prevAnnot->getLeftLinkedHit();
                $currentAnnot->setLeftLinkedHit( $prevInChain );
                $prevInChain->setRightLinkedHit( $currentAnnot );
              }

              $currentAnnot->setQueryEnd( $newend )
                  if ( $currentAnnot->getQueryEnd() < $newend );

              # This is now always the case; used to be that
              # interrupted IRs were "broken up" after this routine
              $currentAnnot->setSubjEnd(
                 $currentAnnot->getSubjEnd() + $currentAnnot->getSubjRemaining()
              );

              $currentAnnot->setSubjRemaining( 0 );

              #$prevAnnot->removeFromJoins();
              if ( $DEBUG ) {
                print "Removing: ";
                $prevAnnot->print();
              }
              $backIter->remove();
              $pastAnnot = undef;

              if ( $DEBUG ) {
                print "Final call:\n";
                $currentAnnot->print();
                print "and its links:\n";
                $currentAnnot->printLinks();
                if ( $currentAnnot->getLeftLinkedHit() ) {
                  print "foo:\n";
                  $currentAnnot->getLeftLinkedHit()->printLinks();
                }
              }
            }
            last;

            # Reverse strand equivalent
          }
          elsif (
               $nextAnnot
            && $currentAnnot->getQueryName  eq $nextAnnot->getQueryName()
            && $nextAnnot->getOrientation() eq 'C'
            && $nextAnnot->getQueryStart() - $currentAnnot->getQueryEnd() < 4
            && (    $nextAnnot->getSubjName() =~ /^Alu|^FLAM/
                 && $nextAnnot->getSubjRemaining() <= 32
                 || $nextAnnot->getSubjName() =~ /^FR?AM$|^L1.*/
                 && $nextAnnot->getSubjRemaining() < 26 )
            && (    $currentAnnot->getHitName eq '(T)n'
                 || $currentAnnot->getHitName =~ /^\(T{3,6}.\)/
                 || $currentAnnot->getHitName =~ /^.?T-rich/ )

   # Don't allow the Poly-A tail to extend beyond 30bp past the consensus length
            && (
               ( $currentAnnot->getQueryEnd() - $currentAnnot->getQueryStart() )
               < ( $nextAnnot->getSubjRemaining() + 30 ) )
              )
          {
            my $newbegin = $currentAnnot->getQueryStart();

            if ( $DEBUG ) {
              print "Fusing ALU and Poly A: Current element:\n";
              $currentAnnot->print();
              print "will be renamed for next element:\n";
              $nextAnnot->print();
            }

            #
            # Special Case: Incompletely excised Poly-A tails
            #
            # Typical Case:
            #   <-Foo1- AAAAAAAA <-------Foo1--------
            #
            # Should be resolved as:
            #   <------------Foo1--------------------
            #
            if ( $nextAnnot->getLeftLinkedHit() ) {
              my $nextInChain = $nextAnnot->getLeftLinkedHit();
              if (  $nextInChain->getScore() eq $nextAnnot->getScore()
                 && $nextInChain->getQueryEnd() - $currentAnnot->getQueryStart()
                 < 5
                 && $nextInChain->getSubjEnd() - $nextInChain->getSubjStart() +
                 1 <= 40
                 && $nextInChain == $prevAnnot )
              {

            # To resolve this we will remove the $prevAnnot and $nextAnnot while
            # converting the $currentAnnot to the final annotation.

                # Save original 'derived from' annotations
                if ( $options{'source'} ) {
                  $currentAnnot->addDerivedFromAnnot( $prevAnnot );
                  $currentAnnot->addDerivedFromAnnot( $nextAnnot );
                }

                # Copy all data fields from $nextAnnot over
                $currentAnnot->setFrom( $nextAnnot );

                # Copy over new Seq1Beg from $nextAnnot
                $currentAnnot->setQueryStart( $nextInChain->getQueryStart() );
                $currentAnnot->setQueryRemaining(
                                              $nextAnnot->getQueryRemaining() );

                # Set the new seq2End to max
                $currentAnnot->setSubjEnd( $currentAnnot->getSubjEnd() +
                                           $currentAnnot->getSubjRemaining() );

                # Clear out unaligned field
                $currentAnnot->setSubjRemaining( 0 );

                # Remove $past, and $next
                my $removedAnnot = $backIter->remove();
                $pastAnnot = undef;
                if ( $DEBUG ) {
                  print "Removing: ";
                  $removedAnnot->print();
                }
                $removedAnnot = $forwIter->remove();
                if ( $DEBUG ) {
                  print "Removing: ";
                  $removedAnnot->print();
                }

                $currentAnnot->setRightLinkedHit( $nextInChain );
                $nextInChain->setLeftLinkedHit( $currentAnnot );
                if ( $DEBUG ) {
                  print "Final call:\n";
                  $currentAnnot->print();
                }

              }
            }
            else {

              # Save original elements
              $currentAnnot->addDerivedFromAnnot( $nextAnnot )
                  if ( $options{'source'} );

              # Copy most data fields from $nextAnnot
              $currentAnnot->setFrom( $nextAnnot );
              if ( $nextAnnot->getRightLinkedHit() ) {
                my $nextInChain = $nextAnnot->getRightLinkedHit();
                $currentAnnot->setRightLinkedHit( $nextInChain );
                $nextInChain->setLeftLinkedHit( $currentAnnot );
              }
              if ( $nextAnnot->getLeftLinkedHit() ) {
                my $prevInChain = $nextAnnot->getLeftLinkedHit();
                $currentAnnot->setLeftLinkedHit( $prevInChain );
                $prevInChain->setRightLinkedHit( $currentAnnot );
              }

              # Clear original alignment data ( now under derived )
              #$currentAnnot->setAlignData( undef );

              # It seems better to adjust Seq2End to the end of
              # the consensus instead. This must (almost) always be
              # reached (maximally 25 bp unaligned to start; minimum
              # length of deleted simple repeat is 21 bp) and it is
              # confusing that IR consensus sequences appear to have
              # different lengths in the output (which you get with
              # the commented-out line).
              $currentAnnot->setSubjEnd(
                 $currentAnnot->getSubjEnd() + $currentAnnot->getSubjRemaining()
              );
              $currentAnnot->setQueryStart( $newbegin );
              $currentAnnot->setSubjRemaining( 0 );
              my $LeftOver = $currentAnnot->getQueryRemaining();
              $LeftOver =~ tr/[\(\)]//d;
              $currentAnnot->setQueryRemaining( $LeftOver );
              my $removedAnnot = $forwIter->remove();

              if ( $DEBUG ) {
                print " REMOVED: ";
                $removedAnnot->print();
              }
              last;
            }
          }

          # What does this do?
          my $ClassName = $currentAnnot->getClassName();
          $ClassName =~ s/_[no][el][dw](\d{1,2})?$//;
          $currentAnnot->setClassName( $ClassName );
          ++$k;
        }    # While ( $k < 5 ) loop
      }    # Join poly-A tails to SINE or LINE1 annotations
           #
           # Join Alu and L1 fragments broken by clipped-out A-rich simple
           # repeats, subsequently (in the previous annotation line)
           # attached to the poly A tail by above code
           #
      elsif ( $backIter->hasPrevious() ) {
        my $prevAnnot = $backIter->previous();
        my ( $prevHitName, $prevClassName ) =
            split( /\#/, $prevAnnot->getSubjName() );
        if (   $currentAnnot->getHitName eq $prevHitName
            && $currentAnnot->getQueryStart() - $prevAnnot->getQueryEnd() == 1
            && $currentAnnot->getOrientation() eq $prevAnnot->getOrientation() )
        {
          if (   $currentAnnot->getOrientation() eq 'C'
              && $prevAnnot->getSubjStart() - $currentAnnot->getSubjEnd() == 1 )
          {
            if ( $DEBUG ) {
              print "Fusing SINE/LINE and Poly A: Current element:\n";
              $currentAnnot->print();
              print "will be renamed for prev element:\n";
              $prevAnnot->print();
            }

            $currentAnnot->addDerivedFromAnnot( $prevAnnot )
                if ( $options{'source'} );

            $currentAnnot->setQueryStart( $prevAnnot->getQueryStart() );
            $currentAnnot->setSubjEnd( $prevAnnot->getSubjEnd() );
            $currentAnnot->setSubjRemaining( $prevAnnot->getSubjRemaining() );

            # Fix any previous joins to this element
            $prevAnnot->removeFromJoins();
            $backIter->remove();
          }
        }
      }

      #
      # LINE Renaming
      #
      if ( $currentAnnot->getClassName() =~ /^LINE/ ) {
        my $HitName = $currentAnnot->getHitName();

        # Rename unresolved LINEs
        $HitName =~ s/_orf2$//;

        # TODO: This is a special case of an element which needs
        #       a portion of it's sequence masked out in a seperate stage.
        #       The sequence is a simple repeats which is scored too high
        #       otherwise. I am refering to the endX designation.
        $HitName =~ s/(.*)_[35]endX?$/$1/;

        # TODO: Remove this.  No longer used.
        $HitName =~ s/_strong$//;

        # could use latter as a general tool to indicate a diagnostic fragment
        # rename carnivore LINEs who's name have been adjusted
        # temporarily to allow neighboring fragment recognition
        if ( $HitName =~ /^L1_Ca/ ) {
          $HitName =~ s/^L1_Canis0/L1_Cf/;
          $HitName =~ s/^L1_Canis4/L1_Canid/;
          $HitName =~ s/^L1_Canis5/L1_Canid2/;
        }
        $currentAnnot->setHitName( $HitName );
      }

      #
      # Count tandemly repeated fragments of a repeat as one insert
      # only recognizes constant monomers; croaks on diverged dimers
      #
      if (
           $pastAnnot
        && $pastAnnot->getClassName() !~ /^SINE/

        # SINEs are too common and often miss > 10 bp of tail
        # probably safe with LINEs because of variable 5' ends
        && $currentAnnot->getQueryStart() - $pastAnnot->getQueryEnd() < 30
        && $currentAnnot->getHitName()   eq $pastAnnot->getHitName()
        && $currentAnnot->getQueryName() eq $pastAnnot->getQueryName()
        && (    $currentAnnot->getSubjStart() > 10
             || $currentAnnot->getSubjRemaining() > 10 )
        && $currentAnnot->getSubjStart() - $pastAnnot->getSubjStart() < 15
        && $pastAnnot->getSubjStart() - $currentAnnot->getSubjStart() < 15
        && $currentAnnot->getSubjEnd() - $pastAnnot->getSubjEnd() < 15
        && $pastAnnot->getSubjEnd() - $currentAnnot->getSubjEnd() < 15
          )
      {
        $currentAnnot->setLeftLinkedHit( $pastAnnot );
      }

      # Get the next annot
      my $nextAnnot = undef;
      if ( $cycleAnnotIter->hasNext ) {
        $nextAnnot = $cycleAnnotIter->next();
        $cycleAnnotIter->previous();

        # NOTE: If you are going to remove anything in this
        #       cycle you should move back and forward so
        #       the last thing returned is the previous one.
        $cycleAnnotIter->previous();
        $cycleAnnotIter->next();
      }

      #
      # Skip the following processing blocks if we are simple/low
      #
      unless ( $currentAnnot->getClassName() =~
               /Low_complexity|Simple_repeat|Satellite/ )
      {

        #
        # Adjust overlapping sequences when begin or end of one of repeats
        # is probably known
        #    -----------
        #            ---------
        # Does the current fragment have 4-5 bp of unaligned space
        # at the end or begining?  Or...is the current fragment a LINE
        # a Unknown or a Composite?
        if (
             $currentAnnot->getOrientation eq '+'
             && ( $currentAnnot->getSubjRemaining >= 4 )
             || (    $currentAnnot->getOrientation eq "C"
                  && $currentAnnot->getSubjStart >= 5 )
             || ( $currentAnnot->getClassName =~ /^L1|^Unknown|Composite/ )
            )
        {

          # Does the current fragment and the next fragment:
          #       - reside on the same genomic sequence
          #  and  - Overlap by 1 or more bp in the query?
          #  and  - Is the next fragment a LTR or SINE or DNA?
          if (    $nextAnnot
               && $currentAnnot->getQueryName eq $nextAnnot->getQueryName()
               && $currentAnnot->getQueryEnd >= $nextAnnot->getQueryStart()
               && $currentAnnot->getQueryEnd < $nextAnnot->getQueryEnd()
               && ( $nextAnnot->getSubjName() =~ /LTR|SINE|DNA/ ) )
          {

            # Does the next fragment run to the end of consensus ( or close )
            # at the end opposite the overlap?  SINES are a special case?
            if (
                 (
                      $nextAnnot->getOrientation() eq '+'
                   && $nextAnnot->getSubjStart() < 5
                 )
                 || (    $nextAnnot->getOrientation() eq "C"
                      && $nextAnnot->getSubjRemaining() < 4
                      && $nextAnnot->getSubjName() !~ /SINE/ )
                )
            {
              my $overlap =
                  $currentAnnot->getQueryEnd - $nextAnnot->getQueryStart() + 1;

              # Added the following checks so that we do not end up
              # creating consensus positions that end before they
              # begin. - RMH 2005/12/2
              if (    $currentAnnot->getOrientation eq '+'
                   && $currentAnnot->getSubjEnd - $overlap >
                   $currentAnnot->getSubjStart )
              {
                $currentAnnot->setSubjEnd(
                                       $currentAnnot->getSubjEnd() - $overlap );
                $currentAnnot->setSubjRemaining(
                                   $currentAnnot->getSubjRemaining + $overlap );
                $currentAnnot->setQueryEnd(
                                        $currentAnnot->getQueryEnd - $overlap );
              }
              elsif ( $currentAnnot->getSubjStart + $overlap <
                      $currentAnnot->getSubjEnd )
              {
                $currentAnnot->setSubjStart(
                                     $currentAnnot->getSubjStart() + $overlap );
                $currentAnnot->setQueryEnd(
                                        $currentAnnot->getQueryEnd - $overlap );
              }
            }
          }
        }    # End Adjust overlapping sequences when begin...

        # Same as above but in reverse????
        if (
             $currentAnnot->getOrientation eq '+'
             && ( $currentAnnot->getSubjStart >= 5 )
             || (    $currentAnnot->getOrientation eq "C"
                  && $currentAnnot->getSubjRemaining >= 4 )
             || ( $currentAnnot->getClassName =~ /^L1|^Unknown|Composite/ )
            )
        {
          if (    $pastAnnot
               && $currentAnnot->getQueryName eq $pastAnnot->getQueryName
               && $currentAnnot->getQueryStart <= $pastAnnot->getQueryEnd
               && $currentAnnot->getQueryEnd > $pastAnnot->getQueryEnd + 25 )
          {
            if ( $pastAnnot->getClassName() =~ /^LTR|^SINE|^DNA/ ) {
              if (
                   (
                        $pastAnnot->getOrientation eq '+'
                     && $pastAnnot->getSubjRemaining < 4
                     && $pastAnnot->getClassName =~ /^[^S]/
                   )
                   || (    $pastAnnot->getOrientation eq "C"
                        && $pastAnnot->getSubjStart < 5 )
                  )
              {
                my $overlap =
                    $pastAnnot->getQueryEnd - $currentAnnot->getQueryStart + 1;

                # Added the following checks so that we do not end up
                # creating consensus positions that end before they
                # begin. - RMH 2005/12/2
                if (    $currentAnnot->getOrientation eq '+'
                     && $currentAnnot->getSubjStart + $overlap <
                     $currentAnnot->getSubjEnd )
                {
                  $currentAnnot->setSubjStart(
                                     $currentAnnot->getSubjStart() + $overlap );
                  $currentAnnot->setQueryStart( $pastAnnot->getQueryEnd + 1 );
                }
                elsif ( $currentAnnot->getSubjEnd - $overlap >
                        $currentAnnot->getSubjStart )
                {
                  $currentAnnot->setSubjEnd(
                                         $currentAnnot->getSubjEnd - $overlap );
                  $currentAnnot->setSubjRemaining(
                                 $currentAnnot->getSubjRemaining() + $overlap );
                  $currentAnnot->setQueryStart( $pastAnnot->getQueryEnd + 1 );
                }
              }
            }
          }
        }

        if ( $currentAnnot->getClassName =~ /^SINE/ ) {
          $currentAnnot->setClassName( "srpRNA" )
              if ( $currentAnnot->getHitName eq "7SLRNA" );
          $currentAnnot->setClassName( "scRNA" )
              if (    $currentAnnot->getHitName eq "BC200"
                   || $currentAnnot->getHitName =~ /^BC1_/ );

          # $ClassName = "scRNA" if $HitName eq "BC200" && $Seq2End > 100;
          if (    $currentAnnot->getHitName eq "ID_B1"
               && $currentAnnot->getSubjEnd < 90 )
          {
            $currentAnnot->setClassName( "SINE/ID" );
            $currentAnnot->setHitName( "ID" );
          }
        }

      }    # Unless ( $ClassName =~ /Low_complexity...

      # get rid of negative LINE1 positions; also readjust MLT2 fragments
      if ( $conPosCorrection{ $currentAnnot->getPRID() } ) {

        # probably don't need to be so restrictive, as only those
        # repeats in the following if ever obtain a $conPosCorrection vallue
        if (    $currentAnnot->getClassName() =~ /^LINE/ && !$options{'orf2'}
             || $currentAnnot->getHitName() =~ /^MLT2\w\d?/
             && $currentAnnot->getHitName() =~ /^MLT2B[34]$/ )
        {    # the adjusted pos are right for B3 & 4

          #$currentAnnot->sanityCheckConsPos( \%conPosCorrection );
          $currentAnnot->setSubjStart( $currentAnnot->getSubjStart() +
                                $conPosCorrection{ $currentAnnot->getPRID() } );
          ## TODO: Consider why this needs to be protected from
          ##       producing negative/0 numbers.  Considered: If the
          ##       renaming of a fragment changes the length of the consensus
          ##       ( making it shorter ) the adjustment will be off.
          ##       Now consider how to fix this.
          $currentAnnot->setSubjStart( 1 )
              if ( $currentAnnot->getSubjStart() < 1 );
          $currentAnnot->setSubjEnd( $currentAnnot->getSubjEnd() +
                                $conPosCorrection{ $currentAnnot->getPRID() } );
        }
      }
      elsif (    $currentAnnot->getHitName() =~ /MER33|Charlie5/
              && $currentAnnot->getSubjStart < 1 )
      {
        $currentAnnot->setSubjStart( 1 );
      }

      if ( $currentAnnot->getClassName =~ /Simple_repeat|Satellite/ ) {
        $currentAnnot->setClassName( "Low_complexity" )
            if ( $currentAnnot->getHitName =~ /rich|purine|pyrimidin/ );

        if ( $currentAnnot->getHitName =~ /\(CATTC\)n|\(GAATG\)n/ ) {
          my $hitname = quotemeta $currentAnnot->getHitName;
          if (
             $currentAnnot->getSubjEnd > 200
             || (   $pastAnnot
                 && $pastAnnot->getHitName =~ /$hitname|HSATII/
                 && $currentAnnot->getQueryStart - $pastAnnot->getQueryEnd < 100
                 && $currentAnnot->getSubjEnd + $pastAnnot->getSubjEnd > 200 )
             || (
                  $nextAnnot
               && $nextAnnot->getSubjName() =~ /$hitname|HSATII/
               && $nextAnnot->getQueryStart() - $currentAnnot->getQueryEnd < 100
               && (
                  ( $currentAnnot->getSubjEnd + $nextAnnot->getSubjEnd() > 200 )
                  || (    $pastAnnot
                       && $pastAnnot->getHitName eq $currentAnnot->getHitName
                       && $currentAnnot->getSubjEnd + $pastAnnot->getSubjEnd +
                       $nextAnnot->getSubjEnd() > 200 )
               )
             )
              )
          {
            $currentAnnot->setClassName( "Satellite" );
          }
        }
        $currentAnnot->setHitName( $currentAnnot->getHitName() . '/Alpha' )
            if ( $currentAnnot->getHitName eq 'ALR' );
        $currentAnnot->setHitName( $currentAnnot->getHitName() . '/Beta' )
            if ( $currentAnnot->getHitName eq 'BSR' );
        if (    $pastAnnot
             && $currentAnnot->getQueryName eq $pastAnnot->getQueryName )
        {
          if (    $pastAnnot->getHitName eq $currentAnnot->getHitName
               && $pastAnnot->getOrientation eq $currentAnnot->getOrientation
               && $currentAnnot->getQueryStart - $pastAnnot->getQueryEnd < 65 )
          {
            $currentAnnot->join( $pastAnnot );
          }

          # This doesn't appear to be doing anything
          #if (    $currentAnnot->getQueryStart <= $pastAnnot->getQueryEnd
          #     && $currentAnnot->getQueryEnd > $pastAnnot->getQueryEnd )
          #{
          #  $length -=
          #      ( $pastAnnot->getQueryEnd - $currentAnnot->getQueryStart + 1 );
          #}
        }
        if ( $currentAnnot->getClassName =~ /Satellite/ ) {
          my $tmpClassName = $currentAnnot->getClassName();
          $tmpClassName =~ s/[Cc]entromeric$/centr/;
          $tmpClassName =~ s/telomeric$/telo/;
          $tmpClassName =~ s/acromeric$/acro/;
          $currentAnnot->setClassName( $tmpClassName );
        }
      }    # if Simple/Sattellite

      # Do not print (near) duplicates created by fusing overlapping matches
      # Remove small fragments created by RM fragmentation of alignments.
      if (
        (
             $pastAnnot
          && $currentAnnot->getQueryName eq $pastAnnot->getQueryName()
          && $currentAnnot->getQueryEnd <= $pastAnnot->getQueryEnd()
          && $currentAnnot->getScore <= $pastAnnot->getScore()
          && $currentAnnot->getClassName eq $pastAnnot->getClassName()
          && $currentAnnot->getLineageId eq $pastAnnot->getLineageId()
        )
        || (
          $currentAnnot->getClassName !~ /Simple/

          # Removed this constraint per Arian's recommendations
          #&& ! $currentAnnot->getRightLinkedHit()
          #&& ! $currentAnnot->getLeftLinkedHit()
          && $currentAnnot->getQueryEnd() - $currentAnnot->getQueryStart() < 10
          || $currentAnnot->getQueryEnd() - $currentAnnot->getQueryStart() < 5
        )

        ||

        # nor low complexity DNA or simple repeats when people don't
        # want to see it
        (
             $options{'nolow'}
          && $currentAnnot->getClassName =~ /Low_complexity|Simple_repeat/
        )
          )
      {

        if ( $DEBUG ) {
          print
"Near duplicate (created by fusing), or short < 10bp fragment: Removing Current element:\n";
          $currentAnnot->print();
          if ( $pastAnnot ) {
            print "because of past element:\n";
            $pastAnnot->print();
          }
        }

        $currentAnnot->removeFromJoins();
        $cycleAnnotIter->remove();

        #$pastAnnot->addDerivedFromAnnot( $currentAnnot )
        #    if ( $pastAnnot && $options{'source'} );
        next CYCLE10;
      }

      $pastAnnot = $currentAnnot;

    }    # CYCLE 10
         #printHitArrayList( $sortedAnnotationsList );
    &generateOutput(
                     \%options,              \%seq1Lengths,
                     $file,                  $filename,
                     $dbversion,             $numSearchedSeqs,
                     $lenSearchedSeqs,       $lenSearchedSeqsExcludingXNRuns,
                     $versionmode,           $engine,
                     $sortedAnnotationsList, $poundformat
    );
  }    # else....if ( ! $poundformat
  print "\ndone\n";
}    # For each file

##
##
##  End of main loops
##
##

#########################################################################
##subroutines
#########################################################################

sub getVNTRRange {
  my $elementName = shift;

  my %vntrConsRanges = (
                         "SVA_A"     => [ 425, 880 ],
                         "SVA_B"     => [ 425, 880 ],
                         "SVA_C"     => [ 425, 880 ],
                         "SVA_D"     => [ 425, 880 ],
                         "SVA_E"     => [ 425, 880 ],
                         "SVA_F"     => [ 425, 880 ],
                         "LAVA_A2"   => [ 438, 1383 ],
                         "LAVA_A1"   => [ 413, 1358 ],
                         "LAVA_B1B"  => [ 413, 1358 ],
                         "LAVA_B1D"  => [ 413, 1358 ],
                         "LAVA_B1F1" => [ 413, 1358 ],
                         "LAVA_B1F2" => [ 413, 1358 ],
                         "LAVA_B1G"  => [ 413, 1358 ],
                         "LAVA_B1R1" => [ 413, 1358 ],
                         "LAVA_B1R2" => [ 413, 1358 ],
                         "LAVA_C2"   => [ 364, 1470 ],
                         "LAVA_C4A"  => [ 395, 1500 ],
                         "LAVA_C4B"  => [ 395, 1500 ],
                         "LAVA_D1"   => [ 395, 1500 ],
                         "LAVA_D2"   => [ 395, 1500 ],
                         "LAVA_E"    => [ 395, 1500 ],
                         "LAVA_F0"   => [ 395, 1500 ],
                         "LAVA_F1"   => [ 236, 1358 ],
                         "LAVA_F2"   => [ 236, 1358 ]
  );
  return ( $vntrConsRanges{$elementName} );
}

#
# replaceRMFragmentChainWithRefinement:
#   RepeatMasker fragments alignment's that span a ( previously )
#   clipped out repeat.  The RM refinement process is run prior
#   to RM fragmentation and therefore creates contiguous re-alignments.
#   RM does not fragment these re-alignments.  If we choose to replace
#   a RM fragmented alignment with a contiguous re-alignment then
#   we need to fragment the re-alignment ourselves.
#
#  Given that b1s4i3 joins to the previously joined
#  RM fragmented repeat b1s6i8:
#
#                                     +-----------+
#         ---b1s4i3--->               |           |
#                          ---b1s6i8--->        -----b1s6i8--->
#
#  and given the relalignment:
#
#                          --------[b1s6i8]---------->
#
#  we must fragment [b1s6i8] into something approximating the
#  original fragments and then replace the original ones.
#
#
# Scenario #1:                    +-----------+
#                                 |           |
# RM Frags ----------------------->           ---->
# Refined  ......................../         /....>
#
# Replace original fragments with new ones:
#                                 +-----------+
#                                 |           |
#          .......................>           ....>
#
#
# Scenario #2:                    +-----------+
#                                 |           |
#          ----------------------->           ---->
#          ......................../         /.>
#
# If fragment coverage is less than 10 than remove fragment:
#          .......................>
# else:
#                                 +-----------+
#                                 |           |
#          .......................>           ..>
#
#
#
# Scenario #2:                    +-----------+
#                                 |           |
#          ----------------------->           ---->
#          .....................>
#
# Remove uncovered fragment
#          .....................>
#
sub replaceRMFragmentChainWithRefinement {
  my $seed       = shift;
  my $refinement = shift;

  my $DEBUG   = 0;
  my $chainId = $seed->getLineageId();

  if ( $DEBUG ) {
    print "replaceRMFragmentChainWithRefinement: Entered...\n"
        if ( $DEBUG );
    print "  Seed:\n";
    $seed->printLinks();
    print "  Refinement:\n";
    $refinement->print();
  }

  # TODO:
  #warn "replaceRMFragmentChainWithRefinement: Refined query length is\n"
  #   . "larger than the seed!\n"

  # Make sure we are at the begining of the chain before we attempt to
  # replace with the refinement annotation.
  while ( $seed->getLeftLinkedHit() ) {
    if ( $seed->getLeftLinkedHit()->getLineageId() eq $chainId ) {
      $seed = $seed->getLeftLinkedHit();
    }
    else {
      last;
    }
  }

  # Get Refined Alignment
  my $refQuerySeq = $refinement->getQueryString();
  my $refSubjSeq  = $refinement->getSubjString();

  # Setup Indexes For Tabulating Over Alignment
  my $refSubjPos  = $refinement->getSubjStart();
  my $refConsSize = $refinement->getSubjEnd() + $refinement->getSubjRemaining();
  my $refDir      = 1;
  if ( $seed->getOrientation() eq "C" ) {
    $refSubjPos = $refinement->getSubjEnd();
    $refDir     = -1;
  }
  my $refAlignLen = length( $refQuerySeq );

  ## Assumption here is that until we see a query base we
  ## consider our current position to be 1 + the last base seen.
  my $refQueryPos  = $refinement->getQueryStart() + $seed->getQueryStart() - 1;
  my $seqIdx       = 0;
  my $prevSeedQEnd = 0;
  while ( $seed && $seed->getLineageId() eq $chainId ) {

    #print "While next....$refQueryPos\n";
    my $seedQueryStart = $seed->getQueryStart();
    my $seedQueryEnd   = $seed->getQueryEnd();

    # seqIdx = current pointer into alignment string
    # refQueryPos = genome position of seqIdx ( or last base if gap )
    # refSubjPos = consensus position of seqIdx ( or last base if gap )
    if ( $seqIdx < $refAlignLen && $prevSeedQEnd > 0 ) {
      $refQueryPos += $seedQueryStart - $prevSeedQEnd - 1;
    }

# Move seqIdx up to the seed query start [ if needed ]
#print "Starting at: seqIdx=$seqIdx, refQPos=$refQueryPos, refSPos=$refSubjPos\n";
    while ( $refQueryPos < $seedQueryStart && $seqIdx < ( $refAlignLen - 1 ) ) {
      $seqIdx++;
      my $qBase = substr( $refQuerySeq, $seqIdx, 1 );
      $refQueryPos++ if ( $qBase !~ /[-xX]/ );
      my $sBase = substr( $refSubjSeq, $seqIdx, 1 );
      if ( $sBase !~ /[-xX]/ ) {
        if ( $refDir > 0 ) {
          $refSubjPos++;
        }
        else {
          $refSubjPos--;
        }
      }
    }

   #print "Now at: seqIdx=$seqIdx, refQPos=$refQueryPos, refSPos=$refSubjPos\n";
   #print "Seedqueryrange: $seedQueryStart-$seedQueryEnd\n";
   # Is this fragment of the seed overlapping a bit of the refinement?
    if ( $refQueryPos >= $seedQueryStart && $refQueryPos <= $seedQueryEnd ) {

      # Save the start coordinates
      my $startSeqIdx   = $seqIdx;
      my $startQueryPos = $refQueryPos;
      my $startSubjPos  = $refSubjPos;
      if ( substr( $refSubjSeq, $seqIdx, 1 ) =~ /[-xX]/ ) {
        if ( $refDir > 0 ) {
          $startSubjPos++;
        }
        else {
          $startSubjPos--;
        }
      }

      # Find the seed end within the refinement
      while ( $refQueryPos < $seedQueryEnd && $seqIdx < ( $refAlignLen - 1 ) ) {
        $seqIdx++;
        my $qBase = substr( $refQuerySeq, $seqIdx, 1 );
        $refQueryPos++ if ( $qBase !~ /[-xX]/ );
        my $sBase = substr( $refSubjSeq, $seqIdx, 1 );
        if ( $sBase !~ /[-xX]/ ) {
          if ( $refDir > 0 ) {
            $refSubjPos++;
          }
          else {
            $refSubjPos--;
          }
        }

        #print "$qBase/$sBase - $refQueryPos : $refSubjPos\n";
      }

#print "Now end at: seqIdx=$seqIdx, refQPos=$refQueryPos, refSPos=$refSubjPos\n";
# Save the start coordinates
      my $endSeqIdx   = $seqIdx;
      my $endQueryPos = $refQueryPos;
      my $endSubjPos  = $refSubjPos;

      my $newSeedQuery =
          substr( $refQuerySeq, $startSeqIdx,
                  ( $endSeqIdx - $startSeqIdx + 1 ) );
      my $newSeedSubj =
          substr( $refSubjSeq, $startSeqIdx,
                  ( $endSeqIdx - $startSeqIdx + 1 ) );

  #print "New: $startQueryPos - $endQueryPos ( $startSubjPos - $endSubjPos )\n";
  #print "   q: $newSeedQuery\n";
  #print "   s: $newSeedSubj\n";
      $seed->setQueryStart( $startQueryPos );
      $seed->setQueryEnd( $endQueryPos );
      if ( $refDir > 0 ) {
        $seed->setSubjStart( $startSubjPos );
        $seed->setSubjEnd( $endSubjPos );
      }
      else {
        $seed->setSubjStart( $endSubjPos );
        $seed->setSubjEnd( $startSubjPos );
      }
      my $rem = $refConsSize - $seed->getSubjEnd();
      $seed->setSubjRemaining( $rem );
      my $derivedFromFrag = $refinement->clone();
      $derivedFromFrag->setQueryName( $seed->getQueryName() );
      $derivedFromFrag->setQueryString( $newSeedQuery );
      $derivedFromFrag->setSubjString( $newSeedSubj );
      $derivedFromFrag->setQueryStart( $seed->getQueryStart() );
      $derivedFromFrag->setQueryEnd( $seed->getQueryEnd() );
      $derivedFromFrag->setSubjStart( $seed->getSubjStart() );
      $derivedFromFrag->setSubjEnd( $seed->getSubjEnd() );
      $seed->setHitName( $refinement->getHitName() );
      $seed->setScore( $refinement->getScore() );
      $seed->setPctDiverge( $refinement->getPctDiverge() );
      $seed->setPctKimuraDiverge( $refinement->getPctKimuraDiverge() );
      $seed->setPctDelete( $refinement->getPctDelete() );
      $seed->setPctInsert( $refinement->getPctInsert() );
      $seed->setClassName( $refinement->getClassName() );
      $seed->setDerivedFromAnnot( $derivedFromFrag );
    }
    else {

      # mark seed fragment for deletion
      $seed->setHitName( "DELETE_ME" );
    }
    $seed         = $seed->getRightLinkedHit();
    $prevSeedQEnd = $seedQueryEnd;
  }    # End while ( seed )

  #warn "seqIdx < alignlength!\n" if ( $seqIdx < ($refAlignLen-1) );

  print "replaceRMFragmentChainWithRefinement Leaving...\n"
      if ( $DEBUG );
}

#
# OLD OLD OLD OLD OLD OLD OLD OLD OLD OLD OLD OLD OLD
#
# replaceRMFragmentChainWithRefinement:
#   RepeatMasker fragments alignment's that span a ( previously )
#   clipped out repeat.  The RM refinement process is run prior
#   to RM fragmentation and therefore creates contiguous re-alignments.
#   RM does not fragment these re-alignments.  If we choose to replace
#   a RM fragmented alignment with a contiguous re-alignment then
#   we need to fragment the re-alignment ourselves.  This operation
#   is highly subjective as we do not have the alignment data
#   accessible to determine the breakpoint location.  Here are
#   a few examples of how we are doing this:
#
#  Given that b1s4i3 joins to the previously joined
#  RM fragmented repeat b1s6i8:
#
#                                     +-----------+
#         ---b1s4i3--->               |           |
#                          ---b1s6i8--->        -----b1s6i8--->
#
#  and given the relalignment:
#
#                          --------[b1s6i8]---------->
#
#  we must fragment [b1s6i8] into something approximating the
#  original fragments and then replace the original ones.
#
#
# Scenario #1:                    +-----------+
#                                 |           |
# RM Frags ----------------------->           ---->
# Refined  ......................../         /....>
#
# Replace original fragments with new ones:
#                                 +-----------+
#                                 |           |
#          .......................>           ....>
#
#
# Scenario #2:                    +-----------+
#                                 |           |
#          ----------------------->           ---->
#          ......................../         /.>
#
# If fragment coverage is less than 10 than remove fragment:
#          .......................>
# else:
#                                 +-----------+
#                                 |           |
#          .......................>           ..>
#
#
#
# Scenario #2:                    +-----------+
#                                 |           |
#          ----------------------->           ---->
#          .....................>
#
# Remove uncovered fragment
#          .....................>
#
sub replaceRMFragmentChainWithRefinementOLD {
  my $rightAnnot = shift;
  my $rightEquiv = shift;

  my $DEBUG   = 0;
  my $chainId = $rightAnnot->getLineageId();

  print "WARNING: Using old replaceRMFragmentChainWithRefinement routine!\n";

  print "replaceRMFragmentChainWithRefinement: Entered...\n"
      if ( $DEBUG );

  # Make sure we are at the begining of the chain before we attempt to
  # replace with the refinement annotation.
  while ( $rightAnnot->getLeftLinkedHit() ) {
    if ( $rightAnnot->getLeftLinkedHit()->getLineageId() eq $chainId ) {
      $rightAnnot = $rightAnnot->getLeftLinkedHit();
    }
    else {
      last;
    }
  }

  #
  my $newSeq1Width =
      $rightEquiv->getQueryEnd() - $rightEquiv->getQueryStart() + 1;
  my $newConsSize = $rightEquiv->getSubjEnd() + $rightEquiv->getSubjRemaining();
  my $newConsLeft = $rightEquiv->getSubjStart();
  my $newConsPerSeq1 =
      ( $rightEquiv->getSubjEnd() - $rightEquiv->getSubjStart() + 1 ) /
      $newSeq1Width;

  my $currentLinFragPos = 1;
  my $currentLen        =
      ( $rightAnnot->getQueryEnd() - $rightAnnot->getQueryStart() + 1 );

  while ( 1 ) {

    $currentLen =
        ( $rightAnnot->getQueryEnd() - $rightAnnot->getQueryStart() + 1 );

    if ( $DEBUG ) {
      print "  Fix frag starting chain: ";
      $rightAnnot->print();
      print "  With this one: ";
      $rightEquiv->print();
      print "  Current linear frag pos = $currentLinFragPos\n";
    }

    my $overlapStart = $currentLinFragPos;
    $overlapStart = $rightEquiv->getQueryStart()
        if ( $overlapStart < $rightEquiv->getQueryStart() );
    my $overlapEnd = $currentLinFragPos +
        ( $rightAnnot->getQueryEnd() - $rightAnnot->getQueryStart() + 1 );
    $overlapEnd = $rightEquiv->getQueryEnd()
        if ( $overlapEnd > $rightEquiv->getQueryEnd() );
    if ( ( $rightAnnot->getQueryEnd() - $rightAnnot->getQueryStart() + 1 ) < 10
         || ( $overlapEnd - $overlapStart + 1 ) < 10 )
    {
      print "  Marking as deleted $overlapStart - $overlapEnd\n" if ( $DEBUG );

      # NOTE: This is a bit of a synthetic removal.  Since we do not have the
      #       arraylist and it's iterators all we can do is simply alter the
      #       annotation to have a 0 length seq1Length and a silly name like
      #       "DELETE_ME.  In subsequent cycles 0 length repeats get removed.
      $rightAnnot->setQueryStart( $rightAnnot->getQueryEnd() );
      $rightAnnot->setHitName( "DELETE_ME" );
      if ( $rightAnnot->getLeftLinkedHit() ) {
        if ( $rightAnnot->getRightLinkedHit() ) {
          ( $rightAnnot->getRightLinkedHit() )
              ->setLeftLinkedHit( $rightAnnot->getLeftLinkedHit() );
          ( $rightAnnot->getLeftLinkedHit() )
              ->setRightLinkedHit( $rightAnnot->getRightLinkedHit() );
        }
        else {
          ( $rightAnnot->getLeftLinkedHit() )->setRightLinkedHit();
        }
      }
      elsif ( $rightAnnot->getRightLinkedHit() ) {
        ( $rightAnnot->getRightLinkedHit() )->setLeftLinkedHit();
      }
      $rightAnnot->setRightLinkedHit();
      $rightAnnot->setLeftLinkedHit();
    }
    else {
      if ( $rightEquiv->getQueryEnd() < ( $currentLinFragPos + $currentLen ) ) {
        $rightAnnot->setQueryEnd(
                $rightAnnot->getQueryEnd() - $rightEquiv->getQueryRemaining() );
        $rightAnnot->setQueryRemaining(
          $rightAnnot->getQueryRemaining() + $rightEquiv->getQueryRemaining() );

      }

      # Fix queryStart for first fragment
      if ( $rightEquiv->getQueryStart() < ( $currentLinFragPos + $currentLen )
           && $rightEquiv->getQueryStart() > $currentLinFragPos )
      {
        $rightAnnot->setQueryStart(
              $rightAnnot->getQueryStart() + $rightEquiv->getQueryStart() - 1 );
      }

      my $newConsWidth =
          int(
             ( $rightAnnot->getQueryEnd() - $rightAnnot->getQueryStart() + 1 ) *
                 $newConsPerSeq1 );

      $rightAnnot->setSubjStart( $newConsLeft );

      $newConsLeft += $newConsWidth;
      $newConsLeft = $rightEquiv->getSubjEnd()
          if ( $newConsLeft > $rightEquiv->getSubjEnd() );
      $rightAnnot->setSubjEnd( $newConsLeft );
      $rightAnnot->setSubjRemaining( $newConsSize - $newConsLeft );
      $newConsLeft++;

      $rightAnnot->setHitName( $rightEquiv->getHitName() );
      $rightAnnot->setScore( $rightEquiv->getScore() );
      $rightAnnot->setPctDiverge( $rightEquiv->getPctDiverge() );
      $rightAnnot->setPctKimuraDiverge( $rightEquiv->getPctKimuraDiverge() );
      $rightAnnot->setPctDelete( $rightEquiv->getPctDelete() );
      $rightAnnot->setPctInsert( $rightEquiv->getPctInsert() );
      $rightAnnot->setOrientation( $rightEquiv->getOrientation() );
      $rightAnnot->setClassName( $rightEquiv->getClassName() );
    }
    last
        if ( !$rightAnnot->getRightLinkedHit()
             || $rightAnnot->getRightLinkedHit()->getLineageId() ne
             $rightAnnot->getLineageId() );
    $currentLinFragPos +=
        $rightAnnot->getQueryEnd() - $rightAnnot->getQueryStart() + 1;
    $rightAnnot = $rightAnnot->getRightLinkedHit();
  }
  print "replaceRMFragmentChainWithRefinement: Leaving...\n"
      if ( $DEBUG );
}

#
# getRefinedHighScore:
#     Given a RM annotation that has associated refinement ( re-alignment ) data,
#     return the highest re-alignment score in the refinement set.
#
sub getRefinedHighScore {
  my $collection = shift;

  my $highScore = 0;

  if (
       defined(my $refHashEntry = $refinementHash{ $collection->getLineageId() }
       )
      )
  {
    foreach my $hitName ( keys %{$refHashEntry} ) {
      my $refArray = $refHashEntry->{$hitName};
      foreach my $hit ( @{$refArray} ) {
        $highScore = $hit->getScore() if ( $highScore < $hit->getScore() );
      }
    }
  }
  return $highScore;
}

#
# getMatchingRefinedEntries:
#    Given a RM annotation that has associated refinement ( re-alignment ) data,
#    return the re-alignment(s) for a given consensus ID.  NOTE: The consensus
#    ID is passed in the form of a annotation.  Also note that the routine may
#    not return any match.
#
sub getMatchingRefinedEntries {
  my $collection = shift;
  my $annot      = shift;

  $annot = $collection if ( !defined $annot );

  if (
       defined(my $refHashEntry = $refinementHash{ $collection->getLineageId() }
       )
      )
  {
    if ( defined( my $refArray = $refHashEntry->{ $annot->getHitName() } ) ) {
      return @{$refArray};
    }
  }
  return ();
}

#
# getMatchingRefinedEntry:
#    Given a RM annotation that has associated refinement ( re-alignment ) data,
#    return the equivalent re-alignment ( same ID as the RM annotation ) annotation
#    or the highest scoring equivalent if more than one re-alignment annotation is
#    found.
#
sub getMatchingRefinedEntry {
  my $annot = shift;
  my $match;

  if ( defined( my $refHashEntry = $refinementHash{ $annot->getLineageId() } ) )
  {
    if ( defined( my $refArray = $refHashEntry->{ $annot->getHitName() } ) ) {
      my $highScore = 0;
      foreach my $refinedAnnot ( @{$refArray} ) {
        if ( $refinedAnnot->getScore() > $highScore ) {
          $highScore = $refinedAnnot->getScore();
          $match     = $refinedAnnot;
        }
      }
    }
  }
  return $match;
}

#
# getEquivArray:
#    Given a RM annotation that has associated refinement ( re-alignment ) data,
#    return all re-alignments to all consensi for this annotation.
#
sub getEquivArray {
  my $annot  = shift;
  my @annots = ();

  if ( defined( my $refHashEntry = $refinementHash{ $annot->getLineageId() } ) )
  {
    foreach my $key ( keys %{$refHashEntry} ) {
      push @annots, ( @{ $refHashEntry->{$key} } );
    }
  }

  return @annots;
}

#
# Final output routine
#
sub generateOutput {
  my %options                        = %{ shift() };
  my %seq1Lengths                    = %{ shift() };
  my $file                           = shift;
  my $filename                       = shift;
  my $dbversion                      = shift;
  my $numSearchedSeqs                = shift;
  my $lenSearchedSeqs                = shift;
  my $lenSearchedSeqsExcludingXNRuns = shift;
  my $versionmode                    = shift;
  my $engine                         = shift;
  my $sortedAnnotationsList          = shift;
  my $poundformat                    = shift;

  print "\nGenerating output... ";

  my $i              = -1;
  my $cycleAnnotIter = $sortedAnnotationsList->getIterator();

  my $DEBUG = 0;

  # Local to cycle
  my $lastid = 0;
  my $pastAnnot;

  # Globals created for stats
  my %totlength       = ();
  my %uniqCount       = ();
  my %checked         = ();
  my $seq_cnt         = 0;
  my $frac_GC         = 0;
  my $totseqlen       = 0;
  my $nonNSeqLen      = 0;
  my $totalSeqLen     = 0;
  my $maskedpercent   = 0;
  my $maskedlength    = 0;
  my $annotatedlength = 0;

  # Aggregate Stats ( Default match is to "OTHER" )
  my %aggregateStats = (


###############################################################################################################################
###
### HERE TO EDIT - Start Here
### 
###############################################################################################################################


# CLASS I 
                         'RETROTRANS'    => { 'RE' => '^RNA' },
                         'RPNEL'         => { 'RE' => '^Penelope$' },
                         'SINE'    	 => { 'RE' => '^SINE' },
                         'LINE'    	 => { 'RE' => '^LINE' },
                         'LINEI'    	 => { 'RE' => '^LINE-like' },
                         'LTR'           => { 'RE' => '^LTR' },
			 'LTRLARD'       => { 'RE' => '^LARD' },
			 'LTRTRIM'       => { 'RE' => '^TRIM' },
			 
			 'LTRTRGAG'       => { 'RE' => '^TR_GAG' },
			 'LTRBARE2'       => { 'RE' => '^BARE-2' },
			 
			 
			 'LTRGYP'  	 => { 'RE' => '^LTR\/Gypsy' },
			 'LTRCOP'  	 => { 'RE' => '^LTR\/Copia' },

			 'LTRDIR'  	 => { 'RE' => '^DIRS' },
			 'LTRDIRR'  	 => { 'RE' => '^DIRS/DIRS$' },
			 'LTRDIRGR'  	 => { 'RE' => '^DIRS/Ngaro$' },
			 'LTRDIRVPR'  	 => { 'RE' => '^DIRS/VIPER$' },		 
			 
			 
			 'LTRUNK'  	 => { 'RE' => '^LTR\/Unknown' },


# LTR/Copia

			 'LTRALE'  	 => { 'RE' => '^LTR\/Copia\/Ale$' },
                         'LTRALEI'        => { 'RE' => '^LTR\/Copia\/Ale-like' },
                         
            		 'LTRASIA'	 => { 'RE' => '^LTR\/Copia\/Alesia$' },
                         'LTRASIAI'       => { 'RE' => '^LTR\/Copia\/Alesia-like' },             
                         
			 'LTRANG'  	 => { 'RE' => '^LTR\/Copia\/Angela$' },
                         'LTRANGI'        => { 'RE' => '^LTR\/Copia\/Angela-like' },

			 'LTRBIA'	 => { 'RE' => '^LTR\/Copia\/Bianca$' },
                         'LTRBIAI'        => { 'RE' => '^LTR\/Copia\/Bianca-like' },

			 'LTRBRCO'	 => { 'RE' => '^LTR\/Copia\/Bryco$' },
                         'LTRBRCOI'        => { 'RE' => '^LTR\/Copia\/Bryco-like' },

			 'LTRLYCO'	 => { 'RE' => '^LTR\/Copia\/Lyco$' },
                         'LTRLYCOI'        => { 'RE' => '^LTR\/Copia\/Lyco-like' },

			 'LTRGYCI'	 => { 'RE' => '^LTR\/Copia\/Gymco-I$' },
                         'LTRGYCIL'        => { 'RE' => '^LTR\/Copia\/Gymco-I-like' },

			 'LTRGYCII'	 => { 'RE' => '^LTR\/Copia\/Gymco-II$' },
                         'LTRGYCIIL'        => { 'RE' => '^LTR\/Copia\/Gymco-II-like' },

			 'LTRGYCIII'	 => { 'RE' => '^LTR\/Copia\/Gymco-III$' },
                         'LTRGYCIIIL'        => { 'RE' => '^LTR\/Copia\/Gymco-III-like' },

			 'LTRGYCIV'	 => { 'RE' => '^LTR\/Copia\/Gymco-IV$' },
                         'LTRGYCIVL'        => { 'RE' => '^LTR\/Copia\/Gymco-IV-like' },

			 'LTRIKER'	 => { 'RE' => '^LTR\/Copia\/Ikeros$' },
                         'LTRIKERI'       => { 'RE' => '^LTR\/Copia\/Ikeros-like' },

			 'LTRIVA'  	 => { 'RE' => '^LTR\/Copia\/Ivana$' },
                         'LTRIVAI'        => { 'RE' => '^LTR\/Copia\/Ivana-like' },
                         
                         'LTROSSER'	 => { 'RE' => '^LTR\/Copia\/Osser$' },
                         'LTROSSERI'       => { 'RE' => '^LTR\/Copia\/Osser-like' },
                         
			 'LTRSIRE'	 => { 'RE' => '^LTR\/Copia\/SIRE$' },
                         'LTRSIREI'       => { 'RE' => '^LTR\/Copia\/SIRE-like' },

			 'LTRTAR'  	 => { 'RE' => '^LTR\/Copia\/TAR$' },
                         'LTRTARI'        => { 'RE' => '^LTR\/Copia\/TAR-like' },

			 'LTRTOR'  	 => { 'RE' => '^LTR\/Copia\/Tork$' },
                         'LTRTORI'        => { 'RE' => '^LTR\/Copia\/Tork-like' },

			 'LTRTY1'  	 => { 'RE' => '^LTR\/Copia\/Ty1-outgroup$' },
                         'LTRTY1I'        => { 'RE' => '^LTR\/Copia\/Ty1-outgroup-like' },



#LTR/Gypsy

			 'LTRNCRO'  	 => { 'RE' => '^LTR\/Gypsy\/non-chromo-outgroup$' },
			 'LTRNCROI'  	 => { 'RE' => '^LTR\/Gypsy\/non-chromo-outgroup-like' },
			 
			 'LTRPHYGY'  	 => { 'RE' => '^LTR\/Gypsy\/Phygy$' },
                         'LTRPHYGYI'        => { 'RE' => '^LTR\/Gypsy\/Phygy-like' },

			 'LTRSELGY'  	 => { 'RE' => '^LTR\/Gypsy\/Selgy$' },
                         'LTRSELGYI'        => { 'RE' => '^LTR\/Gypsy\/Selgy-like' },
			 
			 'LTROTA'  	 => { 'RE' => '^LTR\/Gypsy\/OTA$' },
                         'LTROTAI'        => { 'RE' => '^LTR\/Gypsy\/OTA-like' }, 
			 
			 'LTRATH'  	 => { 'RE' => '^LTR\/Gypsy\/Athila$' },
                         'LTRATHI'        => { 'RE' => '^LTR\/Gypsy\/Athila-like' },
			 
			 'LTRTATI'  	 => { 'RE' => '^LTR\/Gypsy\/TatI$' },
                         'LTRTATIL'        => { 'RE' => '^LTR\/Gypsy\/TatI-like' },

			 'LTRTATII'  	 => { 'RE' => '^LTR\/Gypsy\/TatII$' },
                         'LTRTATIIL'        => { 'RE' => '^LTR\/Gypsy\/TatII-like' },

			 'LTRTATIII'  	 => { 'RE' => '^LTR\/Gypsy\/TatIII$' },
                         'LTRTATIIIL'        => { 'RE' => '^LTR\/Gypsy\/TatIII-like' },

			 'LTROGRE'  	 => { 'RE' => '^LTR\/Gypsy\/Ogre$' },
                         'LTROGREI'       => { 'RE' => '^LTR\/Gypsy\/Ogre-like' },

			 'LTROGRV'  	 => { 'RE' => '^LTR\/Gypsy\/Retand$' },
			 'LTROGRVI'  	 => { 'RE' => '^LTR\/Gypsy\/Retand-like' },

			 'LTRCHLVIR'  	 => { 'RE' => '^LTR\/Gypsy\/Chlamyvir$' },
                         'LTRCHLVIRI'        => { 'RE' => '^LTR\/Gypsy\/Chlamyvir-like' },

			 'LTRTCN1'  	 => { 'RE' => '^LTR\/Gypsy\/Tcn1$' },
                         'LTRTCN1I'        => { 'RE' => '^LTR\/Gypsy\/Tcn1-like' },

			 'LTRCRO'  	 => { 'RE' => '^LTR\/Gypsy\/chromo-outgroup$' },
                         'LTRCROI'        => { 'RE' => '^LTR\/Gypsy\/chromo-outgroup-like' },

             		 'LTRCRM'  	 => { 'RE' => '^LTR\/Gypsy\/CRM$' },
                         'LTRCRMI'        => { 'RE' => '^LTR\/Gypsy\/CRM-like' },
                         
               		 'LTRGALA'  	 => { 'RE' => '^LTR\/Gypsy\/Galadriel$' },
                         'LTRGALAI'       => { 'RE' => '^LTR\/Gypsy\/Galadriel-like' },         
                         
			 'LTRTEK'  	 => { 'RE' => '^LTR\/Gypsy\/Tekay$' },
                         'LTRTEKI'        => { 'RE' => '^LTR\/Gypsy\/Tekay-like' },                         

			 'LTRREI'  	 => { 'RE' => '^LTR\/Gypsy\/Reina$' },
                         'LTRREII'        => { 'RE' => '^LTR\/Gypsy\/Reina-like' },

			 'LTRCROUN'  	 => { 'RE' => '^LTR\/Gypsy\/chromo-unclass$' },
                         'LTRCROUNI'        => { 'RE' => '^LTR\/Gypsy\/chromo-unclass-like' },

			 #'LTRDEL'  	 => { 'RE' => '^LTR\/Gypsy\/Del$' },
                         #'LTRDELI'        => { 'RE' => '^LTR\/Gypsy\/Del-like' },

			 'PARARET'	 => { 'RE' => '^pararetrovirus' },


# CLASS II 

			'DNTIR'   =>   { 'RE' => '^TIR' },
			
			'DMITE'   =>   { 'RE' => '^MITE' },

			'DNSPM'   =>   { 'RE' => '^TIR\/EnSpm_CACTA' },

			'DNHAT'   =>   { 'RE' => '^TIR\/hAT' },

			'DNKOLOB'   =>   { 'RE' => '^TIR\/Kolobok' },
			
			'DNMERL'   =>   { 'RE' => '^TIR\/Merlin' },
			
			'DNMUDR'  =>   { 'RE' => '^TIR\/MuDR_Mutator' },
			
			'DNNOVO'  =>   { 'RE' => '^TIR\/Novosib' },
			
			'DNPPP'  =>   { 'RE' => '^TIR\/P$' },			
			
			'DNPIF'   =>   { 'RE' => '^TIR\/PIF_Harbinger' },
			
			'DNPIGB'   =>   { 'RE' => '^TIR\/PiggyBac' },	
			
			'DNSOLA1'   =>   { 'RE' => '^TIR\/Sola1' },				
					
			'DNSOLA2'   =>   { 'RE' => '^TIR\/Sola2' },		
			
			'DNMARIN'   =>   { 'RE' => '^TIR\/TIR\/Tc1_Mariner' },				
			
			
			'DNHEL'   =>   { 'RE' => '^DNA\/Helitron' },
                        'DNHELCO'   =>   { 'RE' => '^DNA\/Helitron\/autonomous' },
                        'DNHELIN'   =>   { 'RE' => '^DNA\/Helitron\/non-auto' },



			'DNUNK'   =>   { 'RE' => '^DNA\/Unknown' },



                         'OTHER'   => { 'RE' => '^Unknown|^Composite|^Other' },
                         'RNA'     => { 'RE' => 'RNA$' },
                         'SATEL'   => { 'RE' => 'Satel' },
                         'SIMPLE'  => { 'RE' => '^Simple|^SSR' },
                         'LOWCOMP' => { 'RE' => '^Low' },
  );


###############################################################################################################################
###
### HERE TO EDIT - End Here
### 
###############################################################################################################################



  # calculate stats
  while ( $cycleAnnotIter->hasNext() ) {
    $i++;
    print "." if ( $i + 1 ) % 1000 == 0;
    my $currentAnnot = $cycleAnnotIter->next();

    #
    # Stats
    #
    my $CN = $currentAnnot->getClassName();
    $CN =~ s/\?$//;    # I'm counting them with the class, even if I'm not sure
    if ( !defined $uniqCount{$CN} ) {
      $uniqCount{$CN} = 0;
      $totlength{$CN} = 0 if !defined $totlength{$CN};
    }

    # Define length of coverage based on possibly overlapping
    # fragments.
    my $length = $currentAnnot->getQueryEnd - $currentAnnot->getQueryStart + 1;
    if (    $pastAnnot
         && $currentAnnot->getQueryName eq $pastAnnot->getQueryName()
         && $currentAnnot->getQueryStart <= $pastAnnot->getQueryEnd
         && $currentAnnot->getQueryEnd > $pastAnnot->getQueryEnd )
    {
      $length -= ( $pastAnnot->getQueryEnd - $currentAnnot->getQueryStart + 1 );
    }

    # Determine if this is fragment of a previously counted element
    my $checked = 0;
    if (    $currentAnnot->getLeftLinkedHit()
         && $currentAnnot->getLeftLinkedHit() != $currentAnnot )
    {
      $checked = 1;
    }

    # Class Name Stats
    $uniqCount{$CN}++ unless $checked;
    $totlength{$CN}  += $length;
    $annotatedlength += $length;

    # Aggregate Stats
    my $cataloged = 0;
    foreach my $aggKey ( keys( %aggregateStats ) ) {
      my $regExp = $aggregateStats{$aggKey}->{'RE'};
      if ( $CN =~ /$regExp/ ) {
        $aggregateStats{$aggKey}->{'count'}++ unless $checked;
        $aggregateStats{$aggKey}->{'length'} += $length;
        $cataloged = 1;
      }
    }
    if ( !$cataloged ) {
      $aggregateStats{'OTHER'}->{'count'}++ unless $checked;
      $aggregateStats{'OTHER'}->{'length'} += $length;
    }

    $checked{ $currentAnnot->getPRID() }++;

    $pastAnnot = $currentAnnot;
  }

  #
  # Now go through the dataset and renumber the ids
  #
  $cycleAnnotIter = $sortedAnnotationsList->getIterator();
  my %id = ();
  while ( $cycleAnnotIter->hasNext() ) {
    my $currentAnnot = $cycleAnnotIter->next();

    #
    # Build the id{} datastructure for renumbering the annotations
    #
    print "About to renumber\n" if ( $DEBUG );
    my $tmpID = $currentAnnot->getPRID();
    $currentAnnot->print() if ( $DEBUG );
    if (    $currentAnnot->getLeftLinkedHit()
         && $currentAnnot->getLeftLinkedHit() != $currentAnnot )
    {
      if ( $DEBUG ) {
        print "Left link is:\n";
        $currentAnnot->getLeftLinkedHit()->print();
        print "Setting to left's id{ "
            . $currentAnnot->getLeftLinkedHit()->getPRID() . " } = "
            . $id{ $currentAnnot->getLeftLinkedHit()->getPRID() } . "\n";
      }
      $id{$tmpID} = $id{ $currentAnnot->getLeftLinkedHit()->getPRID() };
    }
    else {
      print "Setting to new number $lastid + 1\n" if ( $DEBUG );
      $id{$tmpID} = ++$lastid;
    }
  }    # End while
       #printHitArrayList( $sortedAnnotationsList );

  ##
  ##  Annotation Output
  ##
  # Get column widths
  my %colWidths = &getMaxColWidths( $sortedAnnotationsList );

  # Some option to do this
  if ( $options{'html'} ) {
    &printHTMLAnnots( "$file.out.html", \%id, \%seq1Lengths, \%colWidths,
                      $sortedAnnotationsList );
  }

  if ( $options{'a'} ) {
    &printAlignAnnots( "$file.align", \%id, \%seq1Lengths, \%colWidths,
                       $sortedAnnotationsList );
  }

  #
  # Print the out, xm, ace, poly and gff files
  #
  $cycleAnnotIter = $sortedAnnotationsList->getIterator();
  my $headerWritten = 0;
  my $pastAnnot     = undef;
  open( OUTFULL, ">$file.out" ) || die "can't create $file.out\n";
  $options{'xm'}
      && ( open( OUTXM, ">$file.out.xm" )
           || die "can't create $file.out.xm\n" );
  $options{'ace'}
      && ( open( OUTACE, ">$file.out.ace" )
           || die "can't create $file.out.ace\n" );
  $options{'poly'}
      && ( open( OUTPOLY, ">$file.polyout" )
           || die "can't create $file.out.polyout\n" );

  if ( $options{'gff'} ) {
    open( OUTGFF, ">$file.out.gff" ) || die "can't create $file.out.gff\n";
    print OUTGFF "##gff-version 2\n";
    printf OUTGFF "##date %4d-%02d-%02d\n", ( localtime )[ 5 ] + 1900,
        ( localtime )[ 4 ] + 1, ( localtime )[ 3 ];    # date as 1999-09-24...
    ( my $seqname = $file ) =~ s/^.*\///;
    print OUTGFF "##sequence-region $seqname\n";
  }
  while ( $cycleAnnotIter->hasNext() ) {

    my $currentAnnot = $cycleAnnotIter->next();

    # Get the next annot
    my $nextAnnot = undef;
    if ( $cycleAnnotIter->hasNext ) {
      $nextAnnot = $cycleAnnotIter->next();
      $cycleAnnotIter->previous();

      # NOTE: If you are going to remove anything in this
      #       cycle you should move back and forward so
      #       the last thing returned is the previous one.
    }

    #
    # Indicate overlapping sequences in table
    #
    my $Overlapped = "";
    if (
         (
              $pastAnnot
           && $currentAnnot->getQueryName eq $pastAnnot->getQueryName
           && $currentAnnot->getQueryStart <= $pastAnnot->getQueryEnd
           && $currentAnnot->getScore < $pastAnnot->getScore
           && $currentAnnot->getStage() eq $pastAnnot->getStage()
         )
         || (    $nextAnnot
              && $currentAnnot->getQueryName eq $nextAnnot->getQueryName()
              && $currentAnnot->getQueryEnd >= $nextAnnot->getQueryStart()
              && $currentAnnot->getScore < $nextAnnot->getScore()
              && $currentAnnot->getStage() eq $nextAnnot->getStage() )
        )
    {
      $Overlapped = "*";
    }

    # format fields
    my $LeftOver = $seq1Lengths{ $currentAnnot->getQueryName } -
        $currentAnnot->getQueryEnd;
    my $LeftOverPrint = "(" . $LeftOver . ")";

    my $Seq2BeginPrint     = "(" . $currentAnnot->getSubjRemaining . ")";
    my $LeftUnalignedPrint = $currentAnnot->getSubjStart();
    if ( $currentAnnot->getOrientation eq '+' ) {
      $Seq2BeginPrint     = $currentAnnot->getSubjStart();
      $LeftUnalignedPrint = "(" . $currentAnnot->getSubjRemaining . ")";
    }

    my $printid = $id{ $currentAnnot->getPRID() };
    if ( $options{'no_id'} ) {
      $printid = "";
    }

    my $PctSubst  = sprintf "%4.1f", $currentAnnot->getPctDiverge;
    my $PctDelete = sprintf "%4.1f", $currentAnnot->getPctDelete;
    my $PctInsert = sprintf "%4.1f", $currentAnnot->getPctInsert;

    if ( $options{'xm'} ) {
      print OUTXM ""
          . $currentAnnot->getScore() . " "
          . $PctSubst . " "
          . $PctDelete . " "
          . $PctInsert . " "
          . $currentAnnot->getQueryName() . " "
          . $currentAnnot->getQueryStart() . " "
          . $currentAnnot->getQueryEnd() . " "
          . $LeftOverPrint . " "
          . $currentAnnot->getOrientation() . " "
          . $currentAnnot->getHitName() . "\#"
          . $currentAnnot->getClassName() . " "
          . $Seq2BeginPrint . " "
          . $currentAnnot->getSubjEnd() . " "
          . $LeftUnalignedPrint . " "
          . $Overlapped . "\n";
    }

    if ( $options{'ace'} ) {
      if ( $currentAnnot->getOrientation eq "C" ) {
        print OUTACE "Motif_homol \""
            . $currentAnnot->getHitName()
            . "\" \"RepeatMasker\" "
            . $PctSubst . " "
            . $currentAnnot->getQueryStart() . " "
            . $currentAnnot->getQueryEnd() . " - "
            . $currentAnnot->getSubjEnd() . " "
            . $currentAnnot->getSubjStart() . "\n";
      }
      else {
        print OUTACE "Motif_homol \""
            . $currentAnnot->getHitName()
            . "\" \"RepeatMasker\" "
            . $PctSubst . " "
            . $currentAnnot->getQueryStart() . " "
            . $currentAnnot->getQueryEnd() . " + "
            . $currentAnnot->getSubjEnd() . " "
            . $currentAnnot->getSubjStart() . "\n";
      }
    }

    if (    $options{'poly'}
         && $currentAnnot->getClassName eq "Simple_repeat"
         && $PctSubst + $PctDelete + $PctInsert < 10 )
    {
      printf OUTPOLY "%${colWidths{'SW'}}d  %${colWidths{'PctSubst'}}s "
          . "%${colWidths{'PctDelete'}}s "
          . "%${colWidths{'PctInsert'}}s  "
          . "%-${colWidths{'Seq1Name'}}s  "
          . "%${colWidths{'BeginAlign'}}s "
          . "%${colWidths{'EndAlign'}}s "
          . "%${colWidths{'LeftOver'}}s %1s "
          . "%-${colWidths{'HitName'}}s "
          . "%-${colWidths{'class'}}s "
          . "%${colWidths{'Seq2Begin'}}s "
          . "%${colWidths{'Seq2End'}}s "
          . "%${colWidths{'LeftUnaligned'}}s %1s\n", $currentAnnot->getScore(),
          $PctSubst, $PctDelete, $PctInsert, $currentAnnot->getQueryName(),
          $currentAnnot->getQueryStart(), $currentAnnot->getQueryEnd(),
          $LeftOverPrint, $currentAnnot->getOrientation(),
          $currentAnnot->getHitName(), $currentAnnot->getClassName(),
          $Seq2BeginPrint, $currentAnnot->getSubjEnd(), $LeftUnalignedPrint,
          $Overlapped;
    }    # if $options{'poly'}

    if ( $options{'gff'} ) {
      my $source;
      if ( $currentAnnot->getHitName =~ /Alu/ ) {
        $source = 'RepeatMasker_SINE';
      }
      else {
        $source = 'RepeatMasker';
      }
      print OUTGFF ""
          . $currentAnnot->getQueryName() . "\t"
          . $source
          . "\tsimilarity\t"
          . $currentAnnot->getQueryStart() . "\t"
          . $currentAnnot->getQueryEnd() . "\t"
          . $PctSubst . "\t";
      if ( $currentAnnot->getOrientation() eq "C" ) {
        print OUTGFF "-\t.\t";
      }
      else {
        print OUTGFF "+\t.\t";
      }
      print OUTGFF "Target \"Motif:"
          #. $currentAnnot->getHitName() . "\" "
          . $currentAnnot->getClassName() . "\" "

          . $currentAnnot->getSubjStart() . " "
          . $currentAnnot->getSubjEnd() . "\n";
    }

    if ( !$headerWritten ) {
      my $widthposquery = $colWidths{'BeginAlign'} + $colWidths{'EndAlign'} +
          $colWidths{'LeftOver'} + 2;
      my $widthposrepeat = $colWidths{'Seq2Begin'} + $colWidths{'Seq2End'} +
          $colWidths{'LeftUnaligned'} + 2;

      # First line of header
      if ( $engine =~ /nhmmer/ || $engine =~ /nhmmscan/ ) {
        printf OUTFULL "%${colWidths{'SW'}}s  %${colWidths{'PctSubst'}}s "
            . "%${colWidths{'PctDelete'}}s "
            . "%${colWidths{'PctInsert'}}s  "
            . "%-${colWidths{'Seq1Name'}}s  "
            . "%-${widthposquery}s   "
            . "%-${colWidths{'HitName'}}s %-${colWidths{'class'}}s "
            . "%${widthposrepeat}s\n", 'bit', 'perc', 'perc', 'perc', 'query',
            'position in query', 'matching', 'repeat', 'position in repeat';
      }
      else {
        printf OUTFULL "%${colWidths{'SW'}}s  %${colWidths{'PctSubst'}}s "
            . "%${colWidths{'PctDelete'}}s "
            . "%${colWidths{'PctInsert'}}s  "
            . "%-${colWidths{'Seq1Name'}}s  "
            . "%-${widthposquery}s   "
            . "%-${colWidths{'HitName'}}s %-${colWidths{'class'}}s "
            . "%${widthposrepeat}s\n", 'SW', 'perc', 'perc', 'perc', 'query',
            'position in query', 'matching', 'repeat', 'position in repeat';
      }

      # Second line of header
      printf OUTFULL "%${colWidths{'SW'}}s  %${colWidths{'PctSubst'}}s "
          . "%${colWidths{'PctDelete'}}s "
          . "%${colWidths{'PctInsert'}}s  "
          . "%-${colWidths{'Seq1Name'}}s  "
          . "%-${colWidths{'BeginAlign'}}s "
          . "%-${colWidths{'EndAlign'}}s "
          . "%${colWidths{'LeftOver'}}s   "
          . "%-${colWidths{'HitName'}}s "
          . "%-${colWidths{'class'}}s "
          . "%-${colWidths{'Seq2Begin'}}s "
          . "%-${colWidths{'Seq2End'}}s "
          . "%-${colWidths{'LeftUnaligned'}}s ", 'score', 'div.', 'del.',
          'ins.', 'sequence', 'begin', 'end', '(left)', 'repeat',
          'class/family', 'begin', 'end', '(left)', 'ID';

      unless ( $options{'no_id'} ) {
        printf OUTFULL "%${colWidths{'ID'}}s", 'ID';
      }

      printf OUTFULL "\n\n";

      $headerWritten = 1;
    }

    if ( $options{'lcambig'} ) {

      # Use repeat name case to highlight ambiguous DNA
      # transposon fragments
      $currentAnnot->setHitName( uc( $currentAnnot->getHitName() ) );
      $currentAnnot->setHitName( lc( $currentAnnot->getHitName() ) )
          if (    $currentAnnot->getEquivHash()
               && $currentAnnot->getClassName() =~ /DNA/ );
    }

    printf OUTFULL "%${colWidths{'SW'}}d  %${colWidths{'PctSubst'}}s "
        . "%${colWidths{'PctDelete'}}s "
        . "%${colWidths{'PctInsert'}}s  "
        . "%-${colWidths{'Seq1Name'}}s  "
        . "%${colWidths{'BeginAlign'}}s "
        . "%${colWidths{'EndAlign'}}s "
        . "%${colWidths{'LeftOver'}}s %1s "
        . "%-${colWidths{'HitName'}}s "
        . "%-${colWidths{'class'}}s "
        . "%${colWidths{'Seq2Begin'}}s "
        . "%${colWidths{'Seq2End'}}s "
        . "%${colWidths{'LeftUnaligned'}}s ", $currentAnnot->getScore(),
        $PctSubst, $PctDelete, $PctInsert, $currentAnnot->getQueryName(),
        $currentAnnot->getQueryStart(), $currentAnnot->getQueryEnd(),
        $LeftOverPrint, $currentAnnot->getOrientation(),
        $currentAnnot->getHitName(), $currentAnnot->getClassName(),
        $Seq2BeginPrint, $currentAnnot->getSubjEnd(), $LeftUnalignedPrint;

    unless ( $options{'no_id'} ) {
      printf OUTFULL "%${colWidths{'ID'}}s %1s\n", $printid, $Overlapped;
    }
    else {
      printf OUTFULL "%1s\n", $Overlapped;
    }

    # Currently only available in html output
    #if ( $options{'source'} ) {
    #  #print  "Doing source output\n";
    #  printSourceAnnots( $currentAnnot, \%colWidths, 1 );
    #}
    $pastAnnot = $currentAnnot;
  }    # while loop
  close OUTFULL;
  close OUTXM   if $options{'xm'};
  close OUTACE  if $options{'ace'};
  close OUTGFF  if $options{'gff'};
  close OUTPOLY if $options{'poly'};

  ##
  ##  Table Output
  ##

  #
  # Now mask so we can get stats on the seq for the table output
  #
  # GLOBAL for use in format statements
  my $usePerc  = 1;
  my $exclnote = "";
  if ( -f $options{'maskSource'} ) {
    print "\nmasking";
    my $db = FastaDB->new(
                           fileName    => $options{'maskSource'},
                           openMode    => SeqDBI::ReadOnly,
                           maxIDLength => 50
    );
    my $maskFormat = '';
    $maskFormat = 'x'      if ( $options{'x'} );
    $maskFormat = 'xsmall' if ( $options{'xsmall'} );
    ( $seq_cnt, $totseqlen, $nonNSeqLen, $frac_GC, $maskedlength ) =
        &maskSequence( $maskFormat, $db, "$file.out",
                       $options{'maskSource'} . ".masked" );
    $totalSeqLen = $totseqlen;
    if ( $options{'excln'} ) {
      $totseqlen = $nonNSeqLen;
      $exclnote  = "Runs of >=20 X/Ns in query were excluded in % calcs\n";
    }
    $nonNSeqLen    = "($nonNSeqLen bp excl N/X-runs)";
    $maskedpercent = ( $maskedlength / $totseqlen ) * 100;
  }
  elsif ( $numSearchedSeqs ) {
    $seq_cnt   = $numSearchedSeqs;
    $totseqlen = $lenSearchedSeqs;
    if ( $options{'excln'} ) {
      $totseqlen = $lenSearchedSeqsExcludingXNRuns;
      $exclnote  = "Runs of >=20 X/Ns in query were excluded in % calcs\n";
    }
    $totalSeqLen   = $totseqlen;
    $nonNSeqLen    = "($lenSearchedSeqsExcludingXNRuns bp excl N/X-runs)";
    $maskedlength  = $annotatedlength;
    $maskedpercent = ( $maskedlength / $totseqlen ) * 100;
    $frac_GC       = "Unknown";
  }
  else {
    warn "\nWarning: Calculation of statistics hampered by missing\n"
        . "sequence sizes in the input file *and* missing -maskSource\n"
        . "parameter!  Cannot calculate percentage masked values.\n";
    $usePerc       = 0;
    $totseqlen     = 1;
    $nonNSeqLen    = "";
    $maskedpercent = 0;
    $maskedlength  = $annotatedlength;
  }

  my $totallength =
      $aggregateStats{'SINE'}->{'length'} +
      $aggregateStats{'LINE'}->{'length'} + $aggregateStats{'LTR'}->{'length'} +
      $aggregateStats{'DNA'}->{'length'} + $aggregateStats{'OTHER'}->{'length'};

  my $customLib;
  if ( $options{'lib'} ) {
    $options{'lib'} =~ s/.*(\/.*?$)/\.\.\.$1/;    # full path too long
         # obnoxiously, emacs' indentation can't handle that line;
         # nothing wrong
    $customLib = "The query was compared to ";
    if ( $poundformat ) {
      $customLib .= "classified sequences in ";
    }
    else {
      $customLib .= "unclassified sequences in ";
    }

    $customLib = $customLib . "\"" . $options{'lib'} . "\"";
  }

  # future aim is to use same format for at least all mammals
  if ( $options{'primate'} ) {
    my $OUT;
    open( $OUT, ">$file.tbl" )
        || die "can't create $file.tbl\n";
    printf $OUT "==================================================\n";
    printf $OUT "file name: %-25s\n",             $filename;
    printf $OUT "sequences:       %7d\n",         $seq_cnt;
    printf $OUT "total length: %10d bp  %-25s\n", $totalSeqLen, $nonNSeqLen;
    printf $OUT "GC level:        %6s \%\n",      $frac_GC;
    printf $OUT "bases masked: %10d bp ( %4.2f \%)\n", $maskedlength,
        $maskedpercent;
    printf $OUT "==================================================\n";
    printf $OUT "               number of      length   percentage\n";
    printf $OUT "               elements*    occupied  of sequence\n";
    printf $OUT "--------------------------------------------------\n";
    printf $OUT "SINEs:           %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'SINE'}->{'count'}, $aggregateStats{'SINE'}->{'length'},
        $aggregateStats{'SINE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ALUs       %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"SINE/Alu"}, $totlength{"SINE/Alu"},
        $totlength{"SINE/Alu"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      MIRs       %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"SINE/MIR"}, $totlength{"SINE/MIR"},
        $totlength{"SINE/MIR"} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "LINEs:           %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'LINE'}->{'count'}, $aggregateStats{'LINE'}->{'length'},
        $aggregateStats{'LINE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "      LINE1      %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LINE/L1"}, $totlength{"LINE/L1"},
        $totlength{"LINE/L1"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      LINE2      %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LINE/L2"}, $totlength{"LINE/L2"},
        $totlength{"LINE/L2"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      L3/CR1     %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LINE/CR1"}, $totlength{"LINE/CR1"},
        $totlength{"LINE/CR1"} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "LTR elements:    %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'LTR'}->{'count'}, $aggregateStats{'LTR'}->{'length'},
        $aggregateStats{'LTR'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ERVL       %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LTR/ERVL"}, $totlength{"LTR/ERVL"},
        $totlength{"LTR/ERVL"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ERVL-MaLRs %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LTR/ERVL-MaLR"}, $totlength{"LTR/ERVL-MaLR"},
        $totlength{"LTR/ERVL-MaLR"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ERV_classI %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LTR/ERV1"}, $totlength{"LTR/ERV1"},
        $totlength{"LTR/ERV1"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ERV_classII%6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LTR/ERVK"}, $totlength{"LTR/ERVK"},
        $totlength{"LTR/ERVK"} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "DNA elements:    %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'DNA'}->{'count'}, $aggregateStats{'DNA'}->{'length'},
        $aggregateStats{'DNA'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "     hAT-Charlie %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"DNA/hAT-Charlie"}, $totlength{"DNA/hAT-Charlie"},
        $totlength{"DNA/hAT-Charlie"} * 100 * $usePerc / $totseqlen;
    printf $OUT "     TcMar-Tigger%6d   %10d bp   %5.2f \%\n",
        $uniqCount{"DNA/TcMar-Tigger"}, $totlength{"DNA/TcMar-Tigger"},
        $totlength{"DNA/TcMar-Tigger"} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "Unclassified:    %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'OTHER'}->{'count'},
        $aggregateStats{'OTHER'}->{'length'},
        $aggregateStats{'OTHER'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "Total interspersed repeats:%9d bp   %5.2f \%\n", $totallength,
        $totallength * 100 * $usePerc / $totseqlen;
    printf $OUT "\n\n";
    printf $OUT "Small RNA:       %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'RNA'}->{'count'}, $aggregateStats{'RNA'}->{'length'},
        $aggregateStats{'RNA'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "Satellites:      %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'SATEL'}->{'count'},
        $aggregateStats{'SATEL'}->{'length'},
        $aggregateStats{'SATEL'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "Simple repeats:  %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'SIMPLE'}->{'count'},
        $aggregateStats{'SIMPLE'}->{'length'},
        $aggregateStats{'SIMPLE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "Low complexity:  %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'LOWCOMP'}->{'count'},
        $aggregateStats{'LOWCOMP'}->{'length'},
        $aggregateStats{'LOWCOMP'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "==================================================\n";
    printf $OUT "\n";
    printf $OUT "* most repeats fragmented by insertions or deletions\n";
    printf $OUT "  have been counted as one element\n";
    printf $OUT "%54s\n", $exclnote;
    printf $OUT "\n";
    printf $OUT "The query species was assumed to be %-14s\n",
        $options{'species'};
    printf $OUT "%-82s\n", substr( $versionmode, 0, 82 );
    printf $OUT "$engine\n";
    printf $OUT "$customLib\n" if ( $customLib ne "" );
    printf $OUT "$dbversion\n";
    close $OUT;
  }
  elsif ( $options{'mus'} ) {
    my $OUT;
    open( $OUT, ">$file.tbl" )
        || die "can't create $file.tbl\n";
    printf $OUT "==================================================\n";
    printf $OUT "file name: %-25s\n",             $filename;
    printf $OUT "sequences:       %7d\n",         $seq_cnt;
    printf $OUT "total length: %10d bp  %-25s\n", $totalSeqLen, $nonNSeqLen;
    printf $OUT "GC level:        %6s \%\n",      $frac_GC;
    printf $OUT "bases masked: %10d bp ( %4.2f \%)\n", $maskedlength,
        $maskedpercent;
    printf $OUT "==================================================\n";
    printf $OUT "               number of      length   percentage\n";
    printf $OUT "               elements*    occupied  of sequence\n";
    printf $OUT "--------------------------------------------------\n";
    printf $OUT "SINEs:            %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'SINE'}->{'count'}, $aggregateStats{'SINE'}->{'length'},
        $aggregateStats{'SINE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "      Alu/B1      %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"SINE/Alu"}, $totlength{"SINE/Alu"},
        $totlength{"SINE/Alu"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      B2-B4       %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"SINE/B2"} + $uniqCount{"SINE/B4"},
        $totlength{"SINE/B2"} + $totlength{"SINE/B4"},
        ( $totlength{"SINE/B2"} + $totlength{"SINE/B4"} ) * 100 * $usePerc /
        $totseqlen;
    printf $OUT "      IDs         %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"SINE/ID"}, $totlength{"SINE/ID"},
        $totlength{"SINE/ID"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      MIRs        %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"SINE/MIR"}, $totlength{"SINE/MIR"},
        $totlength{"SINE/MIR"} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "LINEs:            %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'LINE'}->{'count'}, $aggregateStats{'LINE'}->{'length'},
        $aggregateStats{'LINE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "      LINE1       %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LINE/L1"}, $totlength{"LINE/L1"},
        $totlength{"LINE/L1"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      LINE2       %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LINE/L2"}, $totlength{"LINE/L2"},
        $totlength{"LINE/L2"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      L3/CR1      %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LINE/CR1"}, $totlength{"LINE/CR1"},
        $totlength{"LINE/CR1"} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "LTR elements:     %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'LTR'}->{'count'}, $aggregateStats{'LTR'}->{'length'},
        $aggregateStats{'LTR'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ERVL        %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LTR/ERVL"}, $totlength{"LTR/ERVL"},
        $totlength{"LTR/ERVL"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ERVL-MaLRs  %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LTR/ERVL-MaLR"}, $totlength{"LTR/ERVL-MaLR"},
        $totlength{"LTR/ERVL-MaLR"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ERV_classI  %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LTR/ERV1"}, $totlength{"LTR/ERV1"},
        $totlength{"LTR/ERV1"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ERV_classII %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LTR/ERVK"}, $totlength{"LTR/ERVK"},
        $totlength{"LTR/ERVK"} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "DNA elements:     %6d    %10dbp   %5.2f \%\n",
        $aggregateStats{'DNA'}->{'count'}, $aggregateStats{'DNA'}->{'length'},
        $aggregateStats{'DNA'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "      hAT-Charlie %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"DNA/hAT-Charlie"}, $totlength{"DNA/hAT-Charlie"},
        $totlength{"DNA/hAT-Charlie"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      TcMar-Tigger%6d   %10d bp   %5.2f \%\n",
        $uniqCount{"DNA/TcMar-Tigger"}, $totlength{"DNA/TcMar-Tigger"},
        $totlength{"DNA/TcMar-Tigger"} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "Unclassified:     %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'OTHER'}->{'count'},
        $aggregateStats{'OTHER'}->{'length'},
        $aggregateStats{'OTHER'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "Total interspersed repeats:%10d bp   %5.2f \%\n", $totallength,
        $totallength * 100 * $usePerc / $totseqlen;
    printf $OUT "\n\n";
    printf $OUT "Small RNA:        %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'RNA'}->{'count'}, $aggregateStats{'RNA'}->{'length'},
        $aggregateStats{'RNA'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "Satellites:       %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'SATEL'}->{'count'},
        $aggregateStats{'SATEL'}->{'length'},
        $aggregateStats{'SATEL'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "Simple repeats:   %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'SIMPLE'}->{'count'},
        $aggregateStats{'SIMPLE'}->{'length'},
        $aggregateStats{'SIMPLE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "Low complexity:   %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'LOWCOMP'}->{'count'},
        $aggregateStats{'LOWCOMP'}->{'length'},
        $aggregateStats{'LOWCOMP'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "==================================================\n";
    printf $OUT "\n";
    printf $OUT "* most repeats fragmented by insertions or deletions\n";
    printf $OUT "  have been counted as one element\n";
    printf $OUT "%54s\n", $exclnote;
    printf $OUT "\n";
    printf $OUT "The query species was assumed to be %-14s\n",
        $options{'species'};
    printf $OUT "%-82s\n", substr( $versionmode, 0, 82 );
    printf $OUT "$engine\n";
    printf $OUT "$customLib\n" if ( $customLib ne "" );
    printf $OUT "$dbversion\n";
    close $OUT;
  }
  elsif ( $options{'mammal'} ) {
    my $OUT;
    open( $OUT, ">$file.tbl" )
        || die "can't create $file.tbl\n";
    printf $OUT "==================================================\n";
    printf $OUT "file name: %-25s\n",             $filename;
    printf $OUT "sequences:       %7d\n",         $seq_cnt;
    printf $OUT "total length: %10d bp  %-25s\n", $totalSeqLen, $nonNSeqLen;
    printf $OUT "GC level:        %6s \%\n",      $frac_GC;
    printf $OUT "bases masked: %10d bp ( %4.2f \%)\n", $maskedlength,
        $maskedpercent;
    printf $OUT "==================================================\n";
    printf $OUT "               number of      length   percentage\n";
    printf $OUT "               elements*    occupied  of sequence\n";
    printf $OUT "--------------------------------------------------\n";
    printf $OUT "SINEs:            %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'SINE'}->{'count'}, $aggregateStats{'SINE'}->{'length'},
        $aggregateStats{'SINE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "      Alu/B1      %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"SINE/Alu"}, $totlength{"SINE/Alu"},
        $totlength{"SINE/Alu"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      MIRs        %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"SINE/MIR"}, $totlength{"SINE/MIR"},
        $totlength{"SINE/MIR"} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "LINEs:            %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'LINE'}->{'count'}, $aggregateStats{'LINE'}->{'length'},
        $aggregateStats{'LINE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "      LINE1       %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LINE/L1"}, $totlength{"LINE/L1"},
        $totlength{"LINE/L1"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      LINE2       %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LINE/L2"}, $totlength{"LINE/L2"},
        $totlength{"LINE/L2"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      L3/CR1      %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LINE/CR1"}, $totlength{"LINE/CR1"},
        $totlength{"LINE/CR1"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      RTE         %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'LINERTE'}->{'count'},
        $aggregateStats{'LINERTE'}->{'length'},
        $aggregateStats{'LINERTE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "LTR elements:     %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'LTR'}->{'count'}, $aggregateStats{'LTR'}->{'length'},
        $aggregateStats{'LTR'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ERVL        %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LTR/ERVL"}, $totlength{"LTR/ERVL"},
        $totlength{"LTR/ERVL"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ERVL-MaLRs  %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LTR/ERVL-MaLR"}, $totlength{"LTR/ERVL-MaLR"},
        $totlength{"LTR/ERVL-MaLR"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ERV_classI  %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LTR/ERV1"}, $totlength{"LTR/ERV1"},
        $totlength{"LTR/ERV1"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      ERV_classII %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"LTR/ERVK"}, $totlength{"LTR/ERVK"},
        $totlength{"LTR/ERVK"} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "DNA elements:     %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'DNA'}->{'count'}, $aggregateStats{'DNA'}->{'length'},
        $aggregateStats{'DNA'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "      hAT-Charlie %6d   %10d bp   %5.2f \%\n",
        $uniqCount{"DNA/hAT-Charlie"}, $totlength{"DNA/hAT-Charlie"},
        $totlength{"DNA/hAT-Charlie"} * 100 * $usePerc / $totseqlen;
    printf $OUT "      TcMar-Tigger%6d   %10d bp   %5.2f \%\n",
        $uniqCount{"DNA/TcMar-Tigger"}, $totlength{"DNA/TcMar-Tigger"},
        $totlength{"DNA/TcMar-Tigger"} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "Unclassified:     %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'OTHER'}->{'count'},
        $aggregateStats{'OTHER'}->{'length'},
        $aggregateStats{'OTHER'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "Total interspersed repeats:%10d bp   %5.2f \%\n", $totallength,
        $totallength * 100 * $usePerc / $totseqlen;
    printf $OUT "\n\n";
    printf $OUT "Small RNA:        %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'RNA'}->{'count'}, $aggregateStats{'RNA'}->{'length'},
        $aggregateStats{'RNA'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "\n";
    printf $OUT "Satellites:       %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'SATEL'}->{'count'},
        $aggregateStats{'SATEL'}->{'length'},
        $aggregateStats{'SATEL'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "Simple repeats:   %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'SIMPLE'}->{'count'},
        $aggregateStats{'SIMPLE'}->{'length'},
        $aggregateStats{'SIMPLE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "Low complexity:   %6d   %10d bp   %5.2f \%\n",
        $aggregateStats{'LOWCOMP'}->{'count'},
        $aggregateStats{'LOWCOMP'}->{'length'},
        $aggregateStats{'LOWCOMP'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "==================================================\n";
    printf $OUT "\n";
    printf $OUT "* most repeats fragmented by insertions or deletions\n";
    printf $OUT "  have been counted as one element\n";
    printf $OUT "%54s\n", $exclnote;
    printf $OUT "\n";
    printf $OUT "The query species was assumed to be %-14s\n",
        $options{'species'};
    printf $OUT "%-82s\n", substr( $versionmode, 0, 82 );
    printf $OUT "$engine\n";
    printf $OUT "$customLib\n" if ( $customLib ne "" );
    printf $OUT "$dbversion\n";
    close $OUT;
  }
  else {

###############################################################################################################################
###
### HERE TO EDIT - Start Here
### 
###############################################################################################################################


   my $OUT;
    open( $OUT, ">$file.tbl" ) || die "can't create $file.tbl\n";

    printf $OUT "======================================================================\n";
    printf $OUT "file name: %-25s\n",             $filename;
    printf $OUT "sequences:       %7d\n",         $seq_cnt;
    printf $OUT "total length: %10d bp  %-25s\n", $totalSeqLen, $nonNSeqLen;
    #printf $OUT "GC level:        %6s \%\n",      $frac_GC;
    printf $OUT "bases masked: %10d bp ( %4.2f \%)\n", $maskedlength,
        $maskedpercent;
    printf $OUT "======================================================================\n";
    printf $OUT "               			number of      length   percentage\n";
    printf $OUT "               			elements*    occupied  of sequence\n";
    printf $OUT "----------------------------------------------------------------------\n";
    printf $OUT "----------------------------Class I:Results---------------------------\n";
    printf $OUT "Class I Total:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LINE'}->{'count'} +
        $aggregateStats{'LINEI'}->{'count'} +
        $aggregateStats{'SINE'}->{'count'} +
        $aggregateStats{'LTRLARD'}->{'count'} +
        $aggregateStats{'LTRTRIM'}->{'count'} +
        $aggregateStats{'LTRTRGAG'}->{'count'} +
        $aggregateStats{'LTRBARE2'}->{'count'} +
        $aggregateStats{'RETROTRANS'}->{'count'} + 
	$aggregateStats{'LTR'}->{'count'} +
        $aggregateStats{'PARARET'}->{'count'} +
        $aggregateStats{'LTRUNK'}->{'count'} +
	$aggregateStats{'RPNEL'}->{'count'} +
	$aggregateStats{'DIRS'}->{'count'},
	#
        $aggregateStats{'LINE'}->{'length'} +
        $aggregateStats{'LINEI'}->{'length'} +
        $aggregateStats{'SINE'}->{'length'} +
        $aggregateStats{'LTRLARD'}->{'length'} +
        $aggregateStats{'LTRTRIM'}->{'length'} +
        $aggregateStats{'LTRTRGAG'}->{'length'} +
        $aggregateStats{'LTRBARE2'}->{'length'} +
        $aggregateStats{'RETROTRANS'}->{'length'} + 
	$aggregateStats{'LTR'}->{'length'} +
	$aggregateStats{'PARARET'}->{'length'} +
        $aggregateStats{'LTRUNK'}->{'length'} +
	$aggregateStats{'RPNEL'}->{'length'} +
	$aggregateStats{'LTRDIR'}->{'length'},
	#
	($aggregateStats{'LINE'}->{'length'} +
        $aggregateStats{'LINEI'}->{'length'} +
        $aggregateStats{'SINE'}->{'length'} +
        $aggregateStats{'LTRLARD'}->{'length'} +
        $aggregateStats{'LTRTRIM'}->{'length'} +
        $aggregateStats{'LTRTRGAG'}->{'length'} +
        $aggregateStats{'LTRBARE2'}->{'length'} +
        $aggregateStats{'RETROTRANS'}->{'length'} + 
	$aggregateStats{'LTR'}->{'length'} +
	$aggregateStats{'PARARET'}->{'length'} +
        $aggregateStats{'LTRUNK'}->{'length'} +	
	$aggregateStats{'RPNEL'}->{'length'} +
	$aggregateStats{'LTRDIR'}->{'length'})  * 100 * $usePerc / $totseqlen;

 
       

### Non-LTR 
    print $OUT "----------------------------------------------------------------------\n";
    printf $OUT "|-Non-LTR:			%6d	%10d bp	%5.2f \%\n",
    $aggregateStats{'SINE'}->{'count'} + $aggregateStats{'LINE'}->{'count'}  + $aggregateStats{'LINEI'}->{'count'},
    $aggregateStats{'SINE'}->{'length'} + $aggregateStats{'LINE'}->{'length'}  + $aggregateStats{'LINEI'}->{'length'},
    ($aggregateStats{'SINE'}->{'length'} + $aggregateStats{'LINE'}->{'length'} + $aggregateStats{'LINEI'}->{'length'})* 100 * $usePerc / $totseqlen;

    printf $OUT "|  |-SINEs:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'SINE'}->{'count'}, $aggregateStats{'SINE'}->{'length'},
        $aggregateStats{'SINE'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|  |-LINEs:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LINE'}->{'count'} + $aggregateStats{'LINEI'}->{'count'}, 
        $aggregateStats{'LINE'}->{'length'} + $aggregateStats{'LINEI'}->{'length'},
        ($aggregateStats{'LINE'}->{'length'} + $aggregateStats{'LINEI'}->{'length'}) * 100 * $usePerc / $totseqlen;
    printf $OUT "|    |-LINE-like:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LINEI'}->{'count'},
        $aggregateStats{'LINEI'}->{'length'},
        $aggregateStats{'LINEI'}->{'length'} * 100 * $usePerc / $totseqlen;


### LTR - Non Autonomous 
    print $OUT "|\n";
    print $OUT "|-LTR\n";
    printf $OUT "|   |-LTR Non-auto:		%6d	%10d bp	%5.2f \%\n",
    $aggregateStats{'LTRLARD'}->{'count'} + $aggregateStats{'LTRTRIM'}->{'count'} + $aggregateStats{'LTRTRGAG'}->{'count'} + $aggregateStats{'LTRBARE2'}->{'count'},
    $aggregateStats{'LTRLARD'}->{'length'} + $aggregateStats{'LTRTRIM'}->{'length'} + $aggregateStats{'LTRTRGAG'}->{'length'} + $aggregateStats{'LTRBARE2'}->{'length'},
    ($aggregateStats{'LTRLARD'}->{'length'} + $aggregateStats{'LTRTRIM'}->{'length'} + $aggregateStats{'LTRTRGAG'}->{'length'} + $aggregateStats{'LTRBARE2'}->{'length'})* 100 * $usePerc / $totseqlen;

    printf $OUT "|   |  |-LARDs:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRLARD'}->{'count'},
        $aggregateStats{'LTRLARD'}->{'length'},
        $aggregateStats{'LTRLARD'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|   |  |-TRIMs:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTRIM'}->{'count'},
        $aggregateStats{'LTRTRIM'}->{'length'},
        $aggregateStats{'LTRTRIM'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|   |  |-TR_GAG:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTRGAG'}->{'count'},
        $aggregateStats{'LTRTRGAG'}->{'length'},
        $aggregateStats{'LTRTRGAG'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|   |  |-BARE-2:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRBARE2'}->{'count'},
        $aggregateStats{'LTRBARE2'}->{'length'},
        $aggregateStats{'LTRBARE2'}->{'length'} * 100 * $usePerc / $totseqlen;


### LTR - Autonomous 
    print $OUT "|   |\n";
    printf $OUT "|   |-LTR auto:			%6d	%10d bp	%5.2f \%\n",
    $aggregateStats{'LTR'}->{'count'}, $aggregateStats{'LTR'}->{'length'},
    $aggregateStats{'LTR'}->{'length'} * 100 * $usePerc / $totseqlen;

   #printf $OUT "\n";
   #printf $OUT "LTR Copia\n";

### LTR - Copia


    printf $OUT "|   | |-LTR/Copia:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRCOP'}->{'count'},
        $aggregateStats{'LTRCOP'}->{'length'},
        $aggregateStats{'LTRCOP'}->{'length'} * 100 * $usePerc / $totseqlen;
    #printf $OUT "|-Lineages\n";
 
 
    printf $OUT "|   |    |-Ale:			%6d	%10d bp   %5.2f \%\n",
        $aggregateStats{'LTRALE'}->{'count'},
        $aggregateStats{'LTRALE'}->{'length'},
        $aggregateStats{'LTRALE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Ale-like:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRALEI'}->{'count'},
        $aggregateStats{'LTRALEI'}->{'length'},
        $aggregateStats{'LTRALEI'}->{'length'} * 100 * $usePerc / $totseqlen;
   
   
    printf $OUT "|   |    |-Alesia:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRASIA'}->{'count'},
        $aggregateStats{'LTRASIA'}->{'length'},
        $aggregateStats{'LTRASIA'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Alesia-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRASIAI'}->{'count'},
        $aggregateStats{'LTRASIAI'}->{'length'},
        $aggregateStats{'LTRASIAI'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|   |    |-Angela:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRANG'}->{'count'},
        $aggregateStats{'LTRANG'}->{'length'},
        $aggregateStats{'LTRANG'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Angela-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRANGI'}->{'count'},
        $aggregateStats{'LTRANGI'}->{'length'},
        $aggregateStats{'LTRANGI'}->{'length'} * 100 * $usePerc / $totseqlen;
   
    printf $OUT "|   |    |-Bianca:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRBIA'}->{'count'},
        $aggregateStats{'LTRBIA'}->{'length'},
        $aggregateStats{'LTRBIA'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Bianca-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRBIAI'}->{'count'},
        $aggregateStats{'LTRBIAI'}->{'length'},
        $aggregateStats{'LTRBIAI'}->{'length'} * 100 * $usePerc / $totseqlen;


    printf $OUT "|   |    |-Bryco:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRBRCO'}->{'count'},
        $aggregateStats{'LTRBRCO'}->{'length'},
        $aggregateStats{'LTRBRCO'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Bryco-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRBRCOI'}->{'count'},
        $aggregateStats{'LTRBRCOI'}->{'length'},
        $aggregateStats{'LTRBRCOI'}->{'length'} * 100 * $usePerc / $totseqlen;


    printf $OUT "|   |    |-Lyco:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRLYCO'}->{'count'},
        $aggregateStats{'LTRLYCO'}->{'length'},
        $aggregateStats{'LTRLYCO'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Lyco-like:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRLYCOI'}->{'count'},
        $aggregateStats{'LTRLYCOI'}->{'length'},
        $aggregateStats{'LTRLYCOI'}->{'length'} * 100 * $usePerc / $totseqlen;


    printf $OUT "|   |    |-Gymco-I:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRGYCI'}->{'count'},
        $aggregateStats{'LTRGYCI'}->{'length'},
        $aggregateStats{'LTRGYCI'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Gymco-I-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRGYCIL'}->{'count'},
        $aggregateStats{'LTRGYCIL'}->{'length'},
        $aggregateStats{'LTRGYCIL'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|   |    |-Gymco-II:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRGYCII'}->{'count'},
        $aggregateStats{'LTRGYCII'}->{'length'},
        $aggregateStats{'LTRGYCII'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Gymco-II-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRGYCIIL'}->{'count'},
        $aggregateStats{'LTRGYCIIL'}->{'length'},
        $aggregateStats{'LTRGYCIIL'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|   |    |-Gymco-III:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRGYCIII'}->{'count'},
        $aggregateStats{'LTRGYCIII'}->{'length'},
        $aggregateStats{'LTRGYCIII'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Gymco-III-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRGYCIIIL'}->{'count'},
        $aggregateStats{'LTRGYCIIIL'}->{'length'},
        $aggregateStats{'LTRGYCIIIL'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|   |    |-Gymco-IV:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRGYCIV'}->{'count'},
        $aggregateStats{'LTRGYCIV'}->{'length'},
        $aggregateStats{'LTRGYCIV'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Gymco-IV-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRGYCIVL'}->{'count'},
        $aggregateStats{'LTRGYCIVL'}->{'length'},
        $aggregateStats{'LTRGYCIVL'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|   |    |-Ikeros:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRIKER'}->{'count'},
        $aggregateStats{'LTRIKER'}->{'length'},
        $aggregateStats{'LTRIKER'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Ikeros-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRIKERI'}->{'count'},
        $aggregateStats{'LTRIKERI'}->{'length'},
        $aggregateStats{'LTRIKERI'}->{'length'} * 100 * $usePerc / $totseqlen;
        
    printf $OUT "|   |    |-Ivana:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRIVA'}->{'count'},
        $aggregateStats{'LTRIVA'}->{'length'},
        $aggregateStats{'LTRIVA'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Ivana-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRIVAI'}->{'count'},
        $aggregateStats{'LTRIVAI'}->{'length'},
        $aggregateStats{'LTRIVAI'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|   |    |-Osser:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTROSSER'}->{'count'},
        $aggregateStats{'LTROSSER'}->{'length'},
        $aggregateStats{'LTROSSER'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Osser-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTROSSERI'}->{'count'},
        $aggregateStats{'LTROSSERI'}->{'length'},
        $aggregateStats{'LTROSSERI'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|   |    |-SIRE:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRSIRE'}->{'count'},
        $aggregateStats{'LTRSIRE'}->{'length'},
        $aggregateStats{'LTRSIRE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-SIRE-like:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRSIREI'}->{'count'},
        $aggregateStats{'LTRSIREI'}->{'length'},
        $aggregateStats{'LTRSIREI'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|   |    |-TAR:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTAR'}->{'count'},
        $aggregateStats{'LTRTAR'}->{'length'},
        $aggregateStats{'LTRTAR'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-TAR-like:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTARI'}->{'count'},
        $aggregateStats{'LTRTARI'}->{'length'},
        $aggregateStats{'LTRTARI'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|   |    |-Tork:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTOR'}->{'count'},
        $aggregateStats{'LTRTOR'}->{'length'},
        $aggregateStats{'LTRTOR'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Tork-like:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTORI'}->{'count'},
        $aggregateStats{'LTRTORI'}->{'length'},
        $aggregateStats{'LTRTORI'}->{'length'} * 100 * $usePerc / $totseqlen;
    
    printf $OUT "|   |    |-Ty1-outgroup:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTY1'}->{'count'},
        $aggregateStats{'LTRTY1'}->{'length'},
        $aggregateStats{'LTRTY1'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|   |    | |-Ty1-out-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTY1I'}->{'count'},
        $aggregateStats{'LTRTY1I'}->{'length'},
        $aggregateStats{'LTRTY1I'}->{'length'} * 100 * $usePerc / $totseqlen;
    #printf $OUT "\n";



### LTR - Gypsy

    print $OUT "|   | \n";

   #printf $OUT "\n";
   #printf $OUT "------------------------LTR Gypsy--------------------------\n";
    printf $OUT "|   |---LTR/Gypsy:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRGYP'}->{'count'},
        $aggregateStats{'LTRGYP'}->{'length'},
        $aggregateStats{'LTRGYP'}->{'length'} * 100 * $usePerc / $totseqlen;
   # printf $OUT "Lineages\n";

     print $OUT "|     |-non-chromovirus    \n";
    printf $OUT "|     |  |-non-chromo-outgroup: %6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRNCRO'}->{'count'},
        $aggregateStats{'LTRNCRO'}->{'length'},
        $aggregateStats{'LTRNCRO'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|     |  |  |-non-chr-out-like: %6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRNCROI'}->{'count'},
        $aggregateStats{'LTRNCROI'}->{'length'},
        $aggregateStats{'LTRNCROI'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|     |  |-Phygy:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRPHYGY'}->{'count'},
        $aggregateStats{'LTRPHYGY'}->{'length'},
        $aggregateStats{'LTRPHYGY'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|     |  |  |-Phygy-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRPHYGYI'}->{'count'},
        $aggregateStats{'LTRPHYGYI'}->{'length'},
        $aggregateStats{'LTRPHYGYI'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|     |  |-Selgy:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRSELGY'}->{'count'},
        $aggregateStats{'LTRSELGY'}->{'length'},
        $aggregateStats{'LTRSELGY'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|     |  |  |-Selgy-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRSELGYI'}->{'count'},
        $aggregateStats{'LTRSELGYI'}->{'length'},
        $aggregateStats{'LTRSELGYI'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|     |  |-OTA:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTROTA'}->{'count'},
        $aggregateStats{'LTROTA'}->{'length'},
        $aggregateStats{'LTROTA'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|     |  |  |-OTA-like:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTROTAI'}->{'count'},
        $aggregateStats{'LTROTAI'}->{'length'},
        $aggregateStats{'LTROTAI'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|     |  |-OTA|Athila:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRATH'}->{'count'},
        $aggregateStats{'LTRATH'}->{'length'},
        $aggregateStats{'LTRATH'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|     |  |  |-OTA|Athila-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRATHI'}->{'count'},
        $aggregateStats{'LTRATHI'}->{'length'},
        $aggregateStats{'LTRATHI'}->{'length'} * 100 * $usePerc / $totseqlen;


    printf $OUT "|     |  |-OTA|TatI:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTATI'}->{'count'},
        $aggregateStats{'LTRTATI'}->{'length'},
        $aggregateStats{'LTRTATI'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|     |  |  |-OTA|TatI-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTATIL'}->{'count'},
        $aggregateStats{'LTRTATIL'}->{'length'},
        $aggregateStats{'LTRTATIL'}->{'length'} * 100 * $usePerc / $totseqlen;


    printf $OUT "|     |  |-OTA|TatII:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTATII'}->{'count'},
        $aggregateStats{'LTRTATII'}->{'length'},
        $aggregateStats{'LTRTATII'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|     |  |  |-OTA|TatII-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTATIIL'}->{'count'},
        $aggregateStats{'LTRTATIIL'}->{'length'},
        $aggregateStats{'LTRTATIIL'}->{'length'} * 100 * $usePerc / $totseqlen;


    printf $OUT "|     |  |-OTA|TatIII:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTATIII'}->{'count'},
        $aggregateStats{'LTRTATIII'}->{'length'},
        $aggregateStats{'LTRTATIII'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|     |  |  |-OTA|TatIII-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTATIIIL'}->{'count'},
        $aggregateStats{'LTRTATIIIL'}->{'length'},
        $aggregateStats{'LTRTATIIIL'}->{'length'} * 100 * $usePerc / $totseqlen;
    
    
    printf $OUT "|     |  |-OTA|Tat|Ogre:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTROGRE'}->{'count'},
        $aggregateStats{'LTROGRE'}->{'length'},
        $aggregateStats{'LTROGRE'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|     |  |  |-OTA|Tat|Ogre-like:%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTROGREI'}->{'count'},
        $aggregateStats{'LTROGREI'}->{'length'},
        $aggregateStats{'LTROGREI'}->{'length'} * 100 * $usePerc / $totseqlen;
    
    printf $OUT "|     |  |-OTA|Tat|Retand:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTROGRV'}->{'count'},
        $aggregateStats{'LTROGRV'}->{'length'},
        $aggregateStats{'LTROGRV'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|     |  |  |-OTA|Tat|Retlike:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTROGRVI'}->{'count'},
        $aggregateStats{'LTROGRVI'}->{'length'},
        $aggregateStats{'LTROGRVI'}->{'length'} * 100 * $usePerc / $totseqlen;


     print $OUT "|     |\n";
     print $OUT "|     |-chromovirus\n";
    printf $OUT "|        |-Chlamyvir:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRCHLVIR'}->{'count'},
        $aggregateStats{'LTRCHLVIR'}->{'length'},
        $aggregateStats{'LTRCHLVIR'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|        |  |-Chlamyvir-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRCHLVIRI'}->{'count'},
        $aggregateStats{'LTRCHLVIRI'}->{'length'},
        $aggregateStats{'LTRCHLVIRI'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|        |-Tcn1:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTCN1'}->{'count'},
        $aggregateStats{'LTRTCN1'}->{'length'},
        $aggregateStats{'LTRTCN1'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|        |  |-Tcn1-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTCN1I'}->{'count'},
        $aggregateStats{'LTRTCN1I'}->{'length'},
        $aggregateStats{'LTRTCN1I'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|        |-chromo-outgroup:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRCRO'}->{'count'},
        $aggregateStats{'LTRCRO'}->{'length'},
        $aggregateStats{'LTRCRO'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|        |  |-chr-outg-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRCROI'}->{'count'},
        $aggregateStats{'LTRCROI'}->{'length'},
        $aggregateStats{'LTRCROI'}->{'length'} * 100 * $usePerc / $totseqlen;


    printf $OUT "|        |-CRM:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRCRM'}->{'count'},
        $aggregateStats{'LTRCRM'}->{'length'},
        $aggregateStats{'LTRCRM'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|        |  |-CRM-like:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRCRMI'}->{'count'},
        $aggregateStats{'LTRCRMI'}->{'length'},
        $aggregateStats{'LTRCRMI'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|        |-Galadriel:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRGALA'}->{'count'},
        $aggregateStats{'LTRGALA'}->{'length'},
        $aggregateStats{'LTRGALA'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|        |  |-Galadriel-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRGALAI'}->{'count'},
        $aggregateStats{'LTRGALAI'}->{'length'},
        $aggregateStats{'LTRGALAI'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|        |-Tekay:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTEK'}->{'count'},
        $aggregateStats{'LTRTEK'}->{'length'},
        $aggregateStats{'LTRTEK'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|        |  |-Tekay-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRTEKI'}->{'count'},
        $aggregateStats{'LTRTEKI'}->{'length'},
        $aggregateStats{'LTRTEKI'}->{'length'} * 100 * $usePerc / $totseqlen;
    
    printf $OUT "|        |-Reina:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRREI'}->{'count'},
        $aggregateStats{'LTRREI'}->{'length'},
        $aggregateStats{'LTRREI'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|        |  |-Reina-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRREII'}->{'count'},
        $aggregateStats{'LTRREII'}->{'length'},
        $aggregateStats{'LTRREII'}->{'length'} * 100 * $usePerc / $totseqlen;


    printf $OUT "|        |-chromo-unclass:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRCROUN'}->{'count'},
        $aggregateStats{'LTRCROUN'}->{'length'},
        $aggregateStats{'LTRCROUN'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "|           |-chromo-un-like:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRCROUNI'}->{'count'},
        $aggregateStats{'LTRCROUNI'}->{'length'},
        $aggregateStats{'LTRCROUNI'}->{'length'} * 100 * $usePerc / $totseqlen;



### Class I - Others 
    printf $OUT "|\n";
    printf $OUT "|-Class I others:		%6d	%10d bp	%5.2f \%\n",
    $aggregateStats{'RPNEL'}->{'count'} + $aggregateStats{'LTRDIR'}->{'count'} + $aggregateStats{'PARARET'}->{'count'},
    $aggregateStats{'RPNEL'}->{'length'} + $aggregateStats{'LTRDIR'}->{'length'} + $aggregateStats{'PARARET'}->{'length'},
    ($aggregateStats{'RPNEL'}->{'length'} + $aggregateStats{'LTRDIR'}->{'length'} + $aggregateStats{'PARARET'}->{'length'})* 100 * $usePerc / $totseqlen;
    
    printf $OUT "   |-Penelope:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'RPNEL'}->{'count'}, 
        $aggregateStats{'RPNEL'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "   |-DIRS:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRDIR'}->{'count'}, 
        $aggregateStats{'LTRDIR'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "   |-Pararetrovirus:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'PARARET'}->{'count'},
        $aggregateStats{'PARARET'}->{'length'},
        $aggregateStats{'PARARET'}->{'length'} * 100 * $usePerc / $totseqlen;

   printf $OUT "-Class I Unknown:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'LTRUNK'}->{'count'},
        $aggregateStats{'LTRUNK'}->{'length'},
        $aggregateStats{'LTRUNK'}->{'length'} * 100 * $usePerc / $totseqlen;
   printf $OUT "\n";

   printf $OUT "-----------------------------Class II:Results--------------------------\n";

    printf $OUT "Class II Total:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNTIR'}->{'count'} + 
        $aggregateStats{'DMITE'}->{'count'} +
        $aggregateStats{'DNHEL'}->{'count'} +
        $aggregateStats{'DNUNK'}->{'count'} ,
        $aggregateStats{'DNTIR'}->{'length'} + 
        $aggregateStats{'DMITE'}->{'length'} +
        $aggregateStats{'DNHEL'}->{'length'} +
        $aggregateStats{'DNUNK'}->{'length'} ,
        ($aggregateStats{'DNTIR'}->{'length'} + 
        $aggregateStats{'DMITE'}->{'length'} +
        $aggregateStats{'DNHEL'}->{'length'} +
        $aggregateStats{'DNUNK'}->{'length'}) * 100 * $usePerc / $totseqlen;


### TIRs 
    printf $OUT "-----------------------------------------------------------------------\n";

    print $OUT "-Subclass_1\n";
    printf $OUT "|  |-TIRs:			%6d	%10d bp	%5.2f \%\n",
    $aggregateStats{'DNTIR'}->{'count'} + $aggregateStats{'DMITE'}->{'count'},
    $aggregateStats{'DNTIR'}->{'length'} + $aggregateStats{'DMITE'}->{'length'},
    ($aggregateStats{'DNTIR'}->{'length'} + $aggregateStats{'DMITE'}->{'length'})* 100 * $usePerc / $totseqlen;
    
    print $OUT "|     |-non-autonomous\n";
    printf $OUT "|     |  |-MITEs:		%6d	%10d bp	%5.2f \%\n",
    	$aggregateStats{'DMITE'}->{'count'},
    	$aggregateStats{'DMITE'}->{'length'},
    	$aggregateStats{'DMITE'}->{'length'} * 100 * $usePerc / $totseqlen;

    print $OUT "|     |-autonomous\n";
    printf $OUT "|        |-EnSpm_CACTA:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNSPM'}->{'count'},
        $aggregateStats{'DNSPM'}->{'length'},
        $aggregateStats{'DNSPM'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|        |-hAT:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNHAT'}->{'count'},
        $aggregateStats{'DNHAT'}->{'length'},
        $aggregateStats{'DNHAT'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|        |-Kolobok:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNKOLOB'}->{'count'},
        $aggregateStats{'DNKOLOB'}->{'length'},
        $aggregateStats{'DNKOLOB'}->{'length'} * 100 * $usePerc / $totseqlen;  
        
    printf $OUT "|        |-Merlin:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNMERL'}->{'count'},
        $aggregateStats{'DNMERL'}->{'length'},
        $aggregateStats{'DNMERL'}->{'length'} * 100 * $usePerc / $totseqlen;       
        
    printf $OUT "|        |-MuDR_Mutator:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNMUDR'}->{'count'},
        $aggregateStats{'DNMUDR'}->{'length'},
        $aggregateStats{'DNMUDR'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|        |-Novosib:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNNOVO'}->{'count'},
        $aggregateStats{'DNNOVO'}->{'length'},
        $aggregateStats{'DNNOVO'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|        |-P element:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNPPP'}->{'count'},
        $aggregateStats{'DNPPP'}->{'length'},
        $aggregateStats{'DNPPP'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|        |-PIF_Harbinger:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNPIF'}->{'count'},
        $aggregateStats{'DNPIF'}->{'length'},
        $aggregateStats{'DNPIF'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|        |-PiggyBac:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNPIGB'}->{'count'},
        $aggregateStats{'DNPIGB'}->{'length'},
        $aggregateStats{'DNPIGB'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "|        |-Sola1:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNSOLA1'}->{'count'},
        $aggregateStats{'DNSOLA1'}->{'length'},
        $aggregateStats{'DNSOLA1'}->{'length'} * 100 * $usePerc / $totseqlen;
        
    printf $OUT "|        |-Sola2:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNSOLA2'}->{'count'},
        $aggregateStats{'DNSOLA2'}->{'length'},
        $aggregateStats{'DNSOLA2'}->{'length'} * 100 * $usePerc / $totseqlen;        
        
    printf $OUT "|        |-Tc1_Mariner:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNMARIN'}->{'count'},
        $aggregateStats{'DNMARIN'}->{'length'},
        $aggregateStats{'DNMARIN'}->{'length'} * 100 * $usePerc / $totseqlen;  



    #printf $OUT "-----------------------------------------------------------\n";
    print $OUT "-Subclass_2\n";
    printf $OUT "   |-RC/Helitron:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNHEL'}->{'count'},
        $aggregateStats{'DNHEL'}->{'length'},
        $aggregateStats{'DNHEL'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "      |-Helitron-Auto:		%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNHELCO'}->{'count'},
        $aggregateStats{'DNHELCO'}->{'length'},
        $aggregateStats{'DNHELCO'}->{'length'} * 100 * $usePerc / $totseqlen;

    printf $OUT "      |-Helitron-Non-auto:	%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'DNHELIN'}->{'count'},
        $aggregateStats{'DNHELIN'}->{'length'},
        $aggregateStats{'DNHELIN'}->{'length'} * 100 * $usePerc / $totseqlen;


    #printf $OUT "-----------------------------------------------------------\n";
    printf $OUT "-Class II Unknown:		%6d  %10d bp   %5.2f \%\n",
        $aggregateStats{'DNUNK'}->{'count'},
        $aggregateStats{'DNUNK'}->{'length'},
        $aggregateStats{'DNUNK'}->{'length'} * 100 * $usePerc / $totseqlen;
    #printf $OUT "-----------------------------------------------------------\n";

    printf $OUT "-----------------------------------------------------------------------\n";
    printf $OUT "\n";
    printf $OUT "-Unclassified:			%6d	%10d bp	%5.2f \%\n",
        $aggregateStats{'OTHER'}->{'count'},
        $aggregateStats{'OTHER'}->{'length'},
        $aggregateStats{'OTHER'}->{'length'} * 100 * $usePerc / $totseqlen;
   printf $OUT "\n";
 
    printf $OUT "-----------------------------------------------------------------------\n";

#    printf $OUT "\n";
#    printf $OUT "\n";
#    printf $OUT "Total interspersed repeats:	%10d bp	%5.2f \%\n",
#        $totallength, $totallength * 100 * $usePerc / $totseqlen;
#    printf $OUT "\n\n";


#    printf $OUT "Small RNA:          %6d   %10d bp   %5.2f \%\n",
#        $aggregateStats{'RNA'}->{'count'}, $aggregateStats{'RNA'}->{'length'},
#        $aggregateStats{'RNA'}->{'length'} * 100 * $usePerc / $totseqlen;
#    printf $OUT "\n";
#    printf $OUT "Satellites:         %6d   %10d bp   %5.2f \%\n",
#        $aggregateStats{'SATEL'}->{'count'},
#        $aggregateStats{'SATEL'}->{'length'},
#        $aggregateStats{'SATEL'}->{'length'} * 100 * $usePerc / $totseqlen;
#    printf $OUT "SSRs:               %6d   %10d bp   %5.2f \%\n",
#    printf $OUT "SSRs:	%6d	%10d bp	%5.2f \%\n",
#        $aggregateStats{'SIMPLE'}->{'count'},
#        $aggregateStats{'SIMPLE'}->{'length'},
#        $aggregateStats{'SIMPLE'}->{'length'} * 100 * $usePerc / $totseqlen;
#    printf $OUT "Low complexity:     %6d   %10d bp   %5.2f \%\n",
#        $aggregateStats{'LOWCOMP'}->{'count'},
#        $aggregateStats{'LOWCOMP'}->{'length'},
#        $aggregateStats{'LOWCOMP'}->{'length'} * 100 * $usePerc / $totseqlen;
    printf $OUT "=======================================================================\n";
    printf $OUT "\n";
    printf $OUT "* most repeats fragmented by insertions or deletions\n";
    printf $OUT "  have been counted as one element\n";
    printf $OUT "%54s\n", $exclnote;
    printf $OUT "\n";
    printf $OUT "The query species was assumed to be %-14s\n",
        $options{'species'};
    printf $OUT "%-82s\n", substr( $versionmode, 0, 82 );
    printf $OUT "$engine\n";
    printf $OUT "$customLib\n" if ( $customLib ne "" );
    printf $OUT "$dbversion\n";
    printf $OUT "\n";
    printf $OUT "Plant TEs classification based on Orozco-Arias et al.,2019";
    printf $OUT "\n";
    printf $OUT "=======================================================================\n";
    close $OUT;
  }


###############################################################################################################################
###
### HERE TO EDIT - End Here
### 
###############################################################################################################################


}    # sub generateOutput();

##-------------------------------------------------------------------------##
## Use: my ( $chainBegRef, $chainEndRef ) =
##                                 &cycleReJoin( $sortedAnnotationsList );
##
##      $sortedAnnotationsList       : Annotations to be processed
##
##      Join fragments broken up by RepeatMasker's clipping strategy.
##      The signature ( currently ) for these fragments is:
##
##              +-----+
##              |     |
##         ------     -------       --------
##           F1         F2            F3
##
##           SW   PctSub  PctDel  PctIns
##      F1 = 100    10%    3%       2%
##      F2 = 100    10%    3%       2%
##      F3 = 323    15%    2%       7%
##
##     Fragments which come from the same alignment will have
##     the same Score, PctSub, PctDel, and PctIns.  F3 in this case
##     may be related to F1/F2 but will not be linked until later
##     stages of PR.
##
##  Returns
##      Two references to hashes.  The hashes store the seq2beg/end for
##      each ID ie. $chainBegRef->{ID} = #.  These data structures are
##      currently used in cycles 2 & 3.
##
##      The returned
##      hashes should be also be made into Hit properties.
##
##-------------------------------------------------------------------------##
sub cycleReJoin {
  my $sortedAnnotationsList = shift;

  $sortedAnnotationsList->sort( \&bySeqSWConbegin );
  my $cycleAnnotIter = $sortedAnnotationsList->getIterator();
  my %chainSeq2Beg   = ();
  my %chainSeq2End   = ();
  my $i              = -1;
  while ( $cycleAnnotIter->hasNext() ) {
    $i++;
    $DEBUG = 0;
    print "." if ( $i + 1 ) % 1000 == 0;
    my $currentAnnot = $cycleAnnotIter->next();
    next
        if (
             (
                  $currentAnnot->getLeftLinkedHit()
               && $currentAnnot->getLeftLinkedHit() != $currentAnnot
             )
             || (    $currentAnnot->getRightLinkedHit()
                  && $currentAnnot->getRightLinkedHit() != $currentAnnot )
        );

    # Simple and Low Complexity repeats should not be rejoined.
    # There are often large gaps and misalignments which do not
    # necessary indicate that the fragments should be part of
    # one alignment.  I.e consider two alus side by side with
    # long poly-A tails.  In some cases the poly-A tails will be
    # joined as one alignment when in fact they are two independent
    # regions.
    next if ( $currentAnnot->getClassName() =~ /Simple|Low_/ );

    #
    #  Join fragments artificially broken up by repeatmasker
    #
    #  Rules: Same HitName
    #         Same Sequence
    #         Same Score, divg's
    #         Cons Boundaries match
    my $proxIter           = $cycleAnnotIter->getIterator();
    my @compatIDs          = ( $currentAnnot );
    my $lastSeq2Begin      = $currentAnnot->getSubjStart();
    my $lastSeq2End        = $currentAnnot->getSubjEnd();
    my $combinedSeq1Length =
        $currentAnnot->getQueryEnd() - $currentAnnot->getQueryStart() + 1;
    my $lowestSeq2Pos = $lastSeq2Begin;
    my $lastAnnot     = $currentAnnot;
    $lowestSeq2Pos = $lastSeq2End
        if ( $lowestSeq2Pos > $lastSeq2End );
    my $highestSeq2Pos = $lastSeq2Begin;
    $highestSeq2Pos = $lastSeq2End
        if ( $highestSeq2Pos < $lastSeq2End );
    my $contained = 0;

    while ( $proxIter->hasNext() ) {
      my $nextAnnot = $proxIter->next();
      if ( $nextAnnot->containsElement( $currentAnnot ) ) {
        $contained = 1;
      }
      last
          unless ( $currentAnnot->getQueryName() eq $nextAnnot->getQueryName()
                   && $nextAnnot->getScore() == $currentAnnot->getScore() );
      my $nextHitName   = $nextAnnot->getHitName();
      my $nextClassName = $nextAnnot->getClassName();

      # Note: Currently annotations in RepeatMasker may skip reporting
      # segments of alignments between clipped out markers "x"s which are
      # smaller than 5 bp long.  I upped the tolerance here to handle
      # these separated fragments.
      if (
           $nextHitName eq $currentAnnot->getHitName()
        && !$nextAnnot->getLeftLinkedHit()
        && !$nextAnnot->getRightLinkedHit()

        # TODO: Check this
        && $nextAnnot->getLineageId() eq $currentAnnot->getLineageId()
        && $nextAnnot->getPctDiverge() == $currentAnnot->getPctDiverge()
        && $nextAnnot->getPctInsert() == $currentAnnot->getPctInsert()
        && $nextAnnot->getPctDelete() == $currentAnnot->getPctDelete()
        && (
          abs( $nextAnnot->getSubjStart() - $lastSeq2End ) < 5
          ||

          # I don't think I need this or
          abs( $nextAnnot->getSubjEnd() - $lastSeq2Begin ) < 5
        )
          )
      {
        if ( $DEBUG ) {
          print "Joining RepeatMasker fragmented alignment:\n";
          $currentAnnot->print();
          print "  because of next:\n";
          $nextAnnot->print();
        }

        if ( $contained && $DEBUG ) {
          print "\n\n\n\n\n\nWARNING WARNING -- containment "
              . "breached!\n\n\n\n\n\n";
        }

        $lastAnnot->join( $nextAnnot );

        if ( $DEBUG ) {
          if (    $currentAnnot->getHitName() eq "AluSx"
               && $currentAnnot->getOrientation eq "C" )
          {
            print "Special!\n";
            print "nexts right partner:\n";
            $nextAnnot->getRightLinkedHit()->print();
            print "currents left partner:\n";
            $currentAnnot->getLeftLinkedHit()->print();
          }
        }

        push @compatIDs, $nextAnnot;
        $lastAnnot = $nextAnnot;
        $combinedSeq1Length +=
            $nextAnnot->getQueryEnd() - $nextAnnot->getQueryStart() + 1;
        $lastSeq2Begin = $nextAnnot->getSubjStart();
        $lastSeq2End   = $nextAnnot->getSubjEnd();
        $lowestSeq2Pos = $nextAnnot->getSubjStart()
            if ( $lowestSeq2Pos > $nextAnnot->getSubjStart() );
        $lowestSeq2Pos = $nextAnnot->getSubjEnd()
            if ( $lowestSeq2Pos > $nextAnnot->getSubjEnd() );
        $highestSeq2Pos = $nextAnnot->getSubjStart()
            if ( $highestSeq2Pos < $nextAnnot->getSubjStart() );
        $highestSeq2Pos = $nextAnnot->getSubjEnd()
            if ( $highestSeq2Pos < $nextAnnot->getSubjEnd() );
      }
    }
    if ( @compatIDs > 1 ) {
      if ( $DEBUG ) {
        print "Chain range = $lowestSeq2Pos - $highestSeq2Pos\n";
      }
      foreach my $annot ( @compatIDs ) {
        print "  Setting:  chainSeq2Beg/End{ " . $annot->getPRID() . " }\n"
            if ( $DEBUG );
        $chainSeq2Beg{ $annot->getPRID() } = $lowestSeq2Pos;
        $chainSeq2End{ $annot->getPRID() } = $highestSeq2Pos;
      }
    }
    else {
      my $singleAnnot = shift @compatIDs;
      if ( $DEBUG ) {
        print "Adding singleton = "
            . ( $currentAnnot->getSubjStart() - $currentAnnot->getSubjEnd() )
            . "ID="
            . $currentAnnot->getPRID() . "\n";
        $currentAnnot->print();
      }
      $chainSeq2Beg{ $singleAnnot->getPRID() } = $currentAnnot->getSubjStart();
      $chainSeq2End{ $singleAnnot->getPRID() } = $currentAnnot->getSubjEnd();
    }
  }
  return ( \%chainSeq2Beg, \%chainSeq2End );
}

sub printAlignAnnots {
  my $fileName    = shift;
  my $id          = shift;
  my $seq1lengths = shift;
  my %colWidths   = %{ shift() };
  my $annots      = shift;

  my $ALIGNOUT = new FileHandle;

  open $ALIGNOUT, ">$fileName" || die "Cannot open $fileName: $!\n";

  #
  # Print the align file.
  #
  my $cycleAnnotIter = $annots->getIterator();
  my $pastAnnot      = undef;
  while ( $cycleAnnotIter->hasNext() ) {

    my $currentAnnot = $cycleAnnotIter->next();

    # Get the next annot
    my $nextAnnot = undef;
    if ( $cycleAnnotIter->hasNext ) {
      $nextAnnot = $cycleAnnotIter->next();
      $cycleAnnotIter->previous();
    }

    #
    # Indicate overlapping sequences in table
    #
    my $Overlapped = "";
    if (
         (
              $pastAnnot
           && $currentAnnot->getQueryName eq $pastAnnot->getQueryName
           && $currentAnnot->getQueryStart <= $pastAnnot->getQueryEnd
           && $currentAnnot->getScore < $pastAnnot->getScore
           && $currentAnnot->getStage() eq $pastAnnot->getStage()
         )
         || (    $nextAnnot
              && $currentAnnot->getQueryName eq $nextAnnot->getQueryName()
              && $currentAnnot->getQueryEnd >= $nextAnnot->getQueryStart()
              && $currentAnnot->getScore < $nextAnnot->getScore()
              && $currentAnnot->getStage() eq $nextAnnot->getStage() )
        )
    {
      $Overlapped = "*";
    }

    # format fields
    my $LeftOver =
        $seq1lengths->{ $currentAnnot->getQueryName } -
        $currentAnnot->getQueryEnd;
    my $LeftOverPrint = "(" . $LeftOver . ")";

    my $Seq2BeginPrint     = "(" . $currentAnnot->getSubjRemaining . ")";
    my $LeftUnalignedPrint = $currentAnnot->getSubjStart();
    if ( $currentAnnot->getOrientation eq '+' ) {
      $Seq2BeginPrint     = $currentAnnot->getSubjStart();
      $LeftUnalignedPrint = "(" . $currentAnnot->getSubjRemaining . ")";
    }

    my $printid = $id->{ $currentAnnot->getPRID() };

    my $PctSubst  = sprintf "%4.1f", $currentAnnot->getPctDiverge;
    my $PctDelete = sprintf "%4.1f", $currentAnnot->getPctDelete;
    my $PctInsert = sprintf "%4.1f", $currentAnnot->getPctInsert;

    if ( $options{'lcambig'} ) {

      # Use repeat name case to highlight ambiguous DNA
      # transposon fragments
      $currentAnnot->setHitName( uc( $currentAnnot->getHitName() ) );
      $currentAnnot->setHitName( lc( $currentAnnot->getHitName() ) )
          if (    $currentAnnot->getEquivHash()
               && $currentAnnot->getClassName() =~ /DNA/ );
    }

   # No longer do we print the *.out lines in the align file.
   #    if ( 0 ) {
   #      print $ALIGNOUT " ";
   #      printf $ALIGNOUT "%${colWidths{'SW'}}d  %${colWidths{'PctSubst'}}s "
   #          . "%${colWidths{'PctDelete'}}s "
   #          . "%${colWidths{'PctInsert'}}s  "
   #          . "%-${colWidths{'Seq1Name'}}s  "
   #          . "%${colWidths{'BeginAlign'}}s "
   #          . "%${colWidths{'EndAlign'}}s "
   #          . "%${colWidths{'LeftOver'}}s %1s "
   #          . $currentAnnot->getHitName()
   #          . "%-${colWidths{'HitName'}}s "
   #          . "%-${colWidths{'class'}}s "
   #          . "%${colWidths{'Seq2Begin'}}s "
   #          . "%${colWidths{'Seq2End'}}s "
   #          . "%${colWidths{'LeftUnaligned'}}s ", $currentAnnot->getScore(),
   #          $PctSubst, $PctDelete, $PctInsert, $currentAnnot->getQueryName(),
   #          $currentAnnot->getQueryStart(), $currentAnnot->getQueryEnd(),
   #          $LeftOverPrint, $currentAnnot->getOrientation(),
   #          $currentAnnot->getHitName(), $currentAnnot->getClassName(),
   #          $Seq2BeginPrint, $currentAnnot->getSubjEnd(), $LeftUnalignedPrint;
   #
   #      printf $ALIGNOUT "%${colWidths{'ID'}}s %1s\n", $printid, $Overlapped;
   #    }

    if ( defined $currentAnnot->getDerivedFromAnnot() ) {
      &printSourceAlignments( $ALIGNOUT, $currentAnnot, \%colWidths, 0,
                              $printid );
    }
    print $ALIGNOUT "\n";

    $pastAnnot = $currentAnnot;
  }    # while loop

  close $ALIGNOUT;

}    # sub printAlignAnnots

sub printHTMLAnnots {
  my $fileName    = shift;
  my $id          = shift;
  my $seq1lengths = shift;
  my %colWidths   = %{ shift() };
  my $annots      = shift;

  my $HTMLOUT = new FileHandle;

  my $hdrTmplFile = "$FindBin::RealBin/HTMLAnnotHeader.html";

  open $HTMLOUT, ">$fileName" || die "Cannot open $fileName\n";

  open HDR, "<$hdrTmplFile"
      || die "printHTMLAnnots(): Cannot open header template $hdrTmplFile\n";
  while ( <HDR> ) {
    print $HTMLOUT $_;
  }
  close HDR;

  my $widthposquery = $colWidths{'BeginAlign'} + $colWidths{'EndAlign'} +
      $colWidths{'LeftOver'} + 2;
  my $widthposrepeat = $colWidths{'Seq2Begin'} + $colWidths{'Seq2End'} +
      $colWidths{'LeftUnaligned'} + 2;

  print $HTMLOUT "<div id=\"repeatTable\" style=\"padding-right: 30px;\">\n";
  print $HTMLOUT
"<div class=\"header\" id=\"colHeaderContainer\" style=\"background-color: #bcc3c8; border-bottom: 2px solid; margin-bottom: 5px;\">\n";
  print $HTMLOUT "<pre><b id=\"colHeaderText\">\n";

  # TODO:
  # Calculate nesting depth and include as parameter to CSS/Javascript

  #
  # Print Header
  #
  #   The header ( and all annotations lines for that matter ) are printed
  #   as preformatted ( <pre> ) text in the HTML file.  It is important
  #   that the correct number of spaces are used between column headings
  #   in order to match the data.
  #
  # First line of header
  my $hdrLine =
      " " x (
       9 + $colWidths{'SW'} + $colWidths{'PctSubst'} + $colWidths{'PctDelete'} +
           $colWidths{'PctInsert'} + $colWidths{'Seq1Name'} )
      . &fmtField(
                   2 + $colWidths{'BeginAlign'} + $colWidths{'EndAlign'} +
                       $colWidths{'LeftOver'},
                   'position in query',
                   "C",
                   "-"
      )
      . " " x ( 5 + $colWidths{'HitName'} + $colWidths{'class'} )
      . &fmtField(
                   2 + $colWidths{'Seq2Begin'} + $colWidths{'Seq2End'} +
                       $colWidths{'LeftUnaligned'},
                   'position in repeat', "C", "-"
      )
      . "\n";

  print $HTMLOUT $hdrLine;

  # Second line of header
  $hdrLine =
        " " x ( 3 + $colWidths{'SW'} )
      . '<span title="Percent divergence.">'
      . &fmtField( $colWidths{'PctSubst'}, "%", "C" )
      . "</span>" . " "
      . '<span title="Percent deletion.">'
      . &fmtField( $colWidths{'PctDelete'}, "%", "C" )
      . "</span>" . " "
      . '<span title="Percent insertion.">'
      . &fmtField( $colWidths{'PctInsert'}, "%", "C" )
      . "</span>" . "  "
      . '<span title="Query sequence name/id.">'
      . &fmtField( $colWidths{'Seq1Name'}, "query", "L" )
      . "</span>"
      . " " x ( 5 + $colWidths{'BeginAlign'} + $colWidths{'EndAlign'} +
                $colWidths{'LeftOver'} )
      . '<span title="Orientation of the repeat c=minus +=plus.">' . "C"
      . "</span>" . " "
      . '<span title="Name/ID of repeat.">'
      . &fmtField( $colWidths{'HitName'}, "matching", "L" )
      . "</span>" . " "
      . '<span title="Repeat class and family.">'
      . &fmtField( $colWidths{'class'}, "repeat", "L" )
      . "</span>" . " "
      . '<span title="Start position or remaining bases in repeat consensus.">'
      . &fmtField( $colWidths{'Seq2Begin'}, "(left)", "C" )
      . "</span>" . " "
      . '<span title="End position in repeat consensus.">'
      . &fmtField( $colWidths{'Seq2End'}, "end", "C" )
      . "</span>" . " "
      . '<span title="Start position or remaining bases in repeat consensus.">'
      . &fmtField( $colWidths{'LeftUnaligned'}, "begin", "C" )
      . "</span>" . " "
      . '<span title="Linked repeats are denoted with duplicate IDs and connecting graphic bars.">'
      . "linkage"
      . "</span>\n";

  print $HTMLOUT $hdrLine;

  # Third line of header
  $hdrLine =
'<span title="Click on this link to expand/collapse individual annotation details.">'
      . "<u>+</u>"
      . "</span>" . " "
      . '<span title="Complexity adjusted Smith Waterman score.">'
      . &fmtField( $colWidths{'SW'}, "score", "L" )
      . "</span>" . " "
      . '<span title="Percent divergence.">'
      . &fmtField( $colWidths{'PctSubst'}, "div.", "R" )
      . "</span>" . " "
      . '<span title="Percent deletion.">'
      . &fmtField( $colWidths{'PctDelete'}, "del.", "R" )
      . "</span>" . " "
      . '<span title="Percent insertion.">'
      . &fmtField( $colWidths{'PctInsert'}, "ins.", "R" )
      . "</span>" . "  "
      . '<span title="Query sequence name/id.">'
      . &fmtField( $colWidths{'Seq1Name'}, "sequence", "L" )
      . "</span>" . "  "
      . '<span title="Start of annotation in sequence.  The first base is numbered 1.">'
      . &fmtField( $colWidths{'BeginAlign'}, "begin", "C" )
      . "</span>" . " "
      . '<span title="End of annotation in sequence.  The first base is numbered 1.">'
      . &fmtField( $colWidths{'EndAlign'}, "end", "C" )
      . "</span>" . " "
      . '<span title="The number of bases remaining in sequence.">'
      . &fmtField( $colWidths{'LeftOver'}, "(left)", "C" )
      . "</span>" . " "
      . '<span title="Orientation of the repeat c=minus +=plus.">' . "+"
      . "</span>" . " "
      . '<span title="Name/ID of repeat.">'
      . &fmtField( $colWidths{'HitName'}, "repeat", "L" )
      . "</span>" . " "
      . '<span title="Repeat class and family.">'
      . &fmtField( $colWidths{'class'}, "class/family", "L" )
      . "</span>" . " "
      . '<span title="Start position or remaining bases in repeat consensus.">'
      . &fmtField( $colWidths{'Seq2Begin'}, "begin", "C" )
      . "</span>" . " "
      . '<span title="End position in repeat consensus.">'
      . &fmtField( $colWidths{'Seq2End'}, "end", "C" )
      . "</span>" . " "
      . '<span title="Start position or remaining bases in repeat consensus.">'
      . &fmtField( $colWidths{'LeftUnaligned'}, "(left)", "C" )
      . "</span>" . " "
      . '<span title="Linked repeats are denoted with duplicate IDs and connecting graphic bars.">'
      . "id/graphic"
      . "</span></b>\n";

  print $HTMLOUT $hdrLine;

  # First line of header
  #printf $HTMLOUT " %${colWidths{'SW'}}s  %${colWidths{'PctSubst'}}s "
  #     . "%${colWidths{'PctDelete'}}s "
  #     . "%${colWidths{'PctInsert'}}s  "
  #     . "%-${colWidths{'Seq1Name'}}s  "
  #     . "%-${widthposquery}s   "
  #     . "%-${colWidths{'HitName'}}s %-${colWidths{'class'}}s "
  #     . "%${widthposrepeat}s %s\n", 'SW', 'perc', 'perc', 'perc', 'query',
  #       position in query', 'matching', 'repeat', 'position in repeat',
  #       ' linkage';

# Second line of header
#printf $HTMLOUT " %${colWidths{'SW'}}s  %${colWidths{'PctSubst'}}s "
#     . "%${colWidths{'PctDelete'}}s "
#     . "%${colWidths{'PctInsert'}}s  "
#     . "%-${colWidths{'Seq1Name'}}s  "
#     . "%-${colWidths{'BeginAlign'}}s "
#     . "%-${colWidths{'EndAlign'}}s "
#     . "%${colWidths{'LeftOver'}}s   "
#     . "%-${colWidths{'HitName'}}s "
#     . "%-${colWidths{'class'}}s "
#     . "%-${colWidths{'Seq2Begin'}}s "
#     . "%-${colWidths{'Seq2End'}}s "
#     . "%-${colWidths{'LeftUnaligned'}}s %${colWidths{'ID'}}s</b>", 'score', 'div.', 'del.',
#     'ins.', 'sequence', 'begin', 'end', '(left)', 'repeat',
#     'class/family', 'begin', 'end', '(left)', 'id / graphic';

  print $HTMLOUT "</pre>\n";
  print $HTMLOUT "</div>\n";

  #
  # Print the out file.
  #
  my $cycleAnnotIter = $annots->getIterator();
  my $pastAnnot      = undef;
  my $blueDivToggle  = 0;
  my $hspsID         = 1;
  while ( $cycleAnnotIter->hasNext() ) {

    my $currentAnnot = $cycleAnnotIter->next();

    # Get the next annot
    my $nextAnnot = undef;
    if ( $cycleAnnotIter->hasNext ) {
      $nextAnnot = $cycleAnnotIter->next();
      $cycleAnnotIter->previous();

      # NOTE: If you are going to remove anything in this
      #       cycle you should move back and forward so
      #       the last thing returned is the previous one.
    }

    #
    # Indicate overlapping sequences in table
    #
    my $Overlapped = "";
    if (
         (
              $pastAnnot
           && $currentAnnot->getQueryName eq $pastAnnot->getQueryName
           && $currentAnnot->getQueryStart <= $pastAnnot->getQueryEnd
           && $currentAnnot->getScore < $pastAnnot->getScore
           && $currentAnnot->getStage() eq $pastAnnot->getStage()
         )
         || (    $nextAnnot
              && $currentAnnot->getQueryName eq $nextAnnot->getQueryName()
              && $currentAnnot->getQueryEnd >= $nextAnnot->getQueryStart()
              && $currentAnnot->getScore < $nextAnnot->getScore()
              && $currentAnnot->getStage() eq $nextAnnot->getStage() )
        )
    {
      $Overlapped = "*";
    }

    # format fields
    my $LeftOver =
        $seq1lengths->{ $currentAnnot->getQueryName } -
        $currentAnnot->getQueryEnd;
    my $LeftOverPrint = "(" . $LeftOver . ")";

    my $Seq2BeginPrint     = "(" . $currentAnnot->getSubjRemaining . ")";
    my $LeftUnalignedPrint = $currentAnnot->getSubjStart();
    if ( $currentAnnot->getOrientation eq '+' ) {
      $Seq2BeginPrint     = $currentAnnot->getSubjStart();
      $LeftUnalignedPrint = "(" . $currentAnnot->getSubjRemaining . ")";
    }

    my $printid = $id->{ $currentAnnot->getPRID() };

    my $PctSubst  = sprintf "%4.1f", $currentAnnot->getPctDiverge;
    my $PctDelete = sprintf "%4.1f", $currentAnnot->getPctDelete;
    my $PctInsert = sprintf "%4.1f", $currentAnnot->getPctInsert;

    if ( $options{'lcambig'} ) {

      # Use repeat name case to highlight ambiguous DNA
      # transposon fragments
      $currentAnnot->setHitName( uc( $currentAnnot->getHitName() ) );
      $currentAnnot->setHitName( lc( $currentAnnot->getHitName() ) )
          if (    $currentAnnot->getEquivHash()
               && $currentAnnot->getClassName() =~ /DNA/ );
    }

    if ( !$currentAnnot->getLeftLinkedHit() ) {
      print $HTMLOUT "<div class=\"annotSet\">\n";
    }
    if ( $blueDivToggle ) {
      print $HTMLOUT "<div class=\"bluediv\">";
    }
    print $HTMLOUT "<pre>";

    if ( defined $currentAnnot->getDerivedFromAnnot() ) {

      # print link
      print $HTMLOUT
"<a href=\"javascript:;\" onmousedown=\"toggleDiv(\'hsps$hspsID\');\">+</a>";
    }
    else {
      print $HTMLOUT " ";
    }

    print $HTMLOUT "<b>";
    printf $HTMLOUT "%${colWidths{'SW'}}d  %${colWidths{'PctSubst'}}s "
        . "%${colWidths{'PctDelete'}}s "
        . "%${colWidths{'PctInsert'}}s  "
        . "%-${colWidths{'Seq1Name'}}s  "
        . "%${colWidths{'BeginAlign'}}s "
        . "%${colWidths{'EndAlign'}}s "
        . "%${colWidths{'LeftOver'}}s %1s "
        . "<a class='nound' href='http://www.repeatmasker.org/cgi-bin/ViewRepeat?id="
        . $currentAnnot->getHitName() . "'>"
        . "%-${colWidths{'HitName'}}s</a> "
        . "%-${colWidths{'class'}}s "
        . "%${colWidths{'Seq2Begin'}}s "
        . "%${colWidths{'Seq2End'}}s "
        . "%${colWidths{'LeftUnaligned'}}s ", $currentAnnot->getScore(),
        $PctSubst, $PctDelete, $PctInsert, $currentAnnot->getQueryName(),
        $currentAnnot->getQueryStart(), $currentAnnot->getQueryEnd(),
        $LeftOverPrint, $currentAnnot->getOrientation(),
        $currentAnnot->getHitName(), $currentAnnot->getClassName(),
        $Seq2BeginPrint, $currentAnnot->getSubjEnd(), $LeftUnalignedPrint;

    printf $HTMLOUT "%${colWidths{'ID'}}s %1s", $printid, $Overlapped;

    print $HTMLOUT "</b></pre>";

    if ( defined $currentAnnot->getDerivedFromAnnot() ) {
      print $HTMLOUT
          "<div id=\"hsps$hspsID\" style=\"display:none; padding: 10px\">\n";
      print $HTMLOUT "<pre>\n";
      print $HTMLOUT "<b>ANNOTATION EVIDENCE:</b>\n";
      &printSourceAlignments( $HTMLOUT, $currentAnnot, \%colWidths, 1, " " );
      print $HTMLOUT "</pre>\n</div>\n";
      $hspsID++;
    }

    if ( $blueDivToggle ) {
      print $HTMLOUT "</div>";
    }
    $blueDivToggle ^= 1;

    print $HTMLOUT "\n";

    if ( !$currentAnnot->getRightLinkedHit() ) {
      print $HTMLOUT "</div>\n";
    }

    $pastAnnot = $currentAnnot;
  }    # while loop

  close $HTMLOUT;

}    # sub printHTMLAnnots

sub fmtField {
  my $fldWidth = shift;
  my $string   = shift;
  my $just     = shift;
  my $pad      = shift;

  my $retStr = "";
  if ( length( $string ) > $fldWidth ) {

    # Must truncate
    if ( defined $just && $just =~ /C/i ) {
      $retStr =
          substr( $string, int( ( length( $string ) - $fldWidth ) / 2 ),
                  $fldWidth );
    }
    elsif ( defined $just && $just =~ /R/i ) {
      $retStr = substr( $string, length( $string ) - $fldWidth, $fldWidth );
    }
    else {
      $retStr = substr( $string, 0, $fldWidth );
    }
    return $retStr;
  }

  my $padChar = " ";
  if ( defined $pad ) {
    $padChar = $pad;
  }

  # Must pad
  if ( defined $just && $just =~ /C/i ) {
    my $padPerSide = ( $fldWidth - length( $string ) ) / 2;
    if ( int( $padPerSide ) != $padPerSide ) {
      $retStr =
            $padChar x ( int( $padPerSide ) ) . $string
          . $padChar x ( int( $padPerSide ) + 1 );
    }
    else {
      $retStr =
            $padChar x ( int( $padPerSide ) ) . $string
          . $padChar x ( int( $padPerSide ) );
    }
  }
  elsif ( defined $just && $just =~ /R/i ) {
    $retStr = $padChar x ( $fldWidth - length( $string ) ) . $string;
  }
  else {
    $retStr = $string . $padChar x ( $fldWidth - length( $string ) );
  }
  return $retStr;
}

sub printSourceAlignments {
  my $FILE      = shift;
  my $annot     = shift;
  my $widthsRef = shift;
  my $html      = shift;
  my $fixedID   = shift;

  my %colWidths = undef;
  %colWidths = %{$widthsRef}
      if ( defined $widthsRef );

  if ( !defined $annot->getDerivedFromAnnot() ) {

    # Allow ID to be overriden.
    my $displayID = $annot->getPRID();
    $displayID = $fixedID if ( $fixedID );

    # print
    if ( defined $widthsRef ) {
      if ( $html ) {
        printf $FILE "%${colWidths{'SW'}}d  %${colWidths{'PctSubst'}}s "
            . "%${colWidths{'PctDelete'}}s "
            . "%${colWidths{'PctInsert'}}s  "
            . "%-${colWidths{'Seq1Name'}}s  "
            . "%${colWidths{'BeginAlign'}}s "
            . "%${colWidths{'EndAlign'}}s "
            . "%${colWidths{'LeftOver'}}s %1s "
            . "<a class='nound' href='http://www.repeatmasker.org/cgi-bin"
            . "/ViewRepeat?id="
            . $annot->getHitName() . "'>"
            . "%-${colWidths{'HitName'}}s</a> "
            . "%-${colWidths{'class'}}s "
            . "%${colWidths{'Seq2Begin'}}s "
            . "%${colWidths{'Seq2End'}}s "
            . "%${colWidths{'LeftUnaligned'}}s %${colWidths{'ID'}}s\n",
            $annot->getScore(), $annot->getPctDiverge(), $annot->getPctDelete(),
            $annot->getPctInsert(),      $annot->getQueryName(),
            $annot->getQueryStart(),     $annot->getQueryEnd(),
            $annot->getQueryRemaining(), $annot->getOrientation(),
            $annot->getHitName(),        $annot->getClassName(),
            $annot->getSubjStart(),      $annot->getSubjEnd(),
            $annot->getSubjRemaining(),  $displayID;
        print $FILE $annot->getAlignData();
      }
      else {
        $annot->setOverlap( $displayID );
        my $str = $annot->toStringFormatted( SearchResult::AlignWithQuerySeq );
        print $FILE "$str";
      }
    }
  }
  else {

    # recurse
    ## May need to sort by seq1beg.  Look for examples
    my @srcMembers = @{ $annot->getDerivedFromAnnot() };
    foreach my $member ( @srcMembers ) {
      if ( $member == $annot ) {
        warn "printSourceAlignments(): Warning - a loop was detected!\n"
            . "Please notify the site administrator of this problem.\n";
        print $FILE "WARNING: A loop was detected in the evidence reporting\n";
        print $FILE "code.  Please notify the site administrator of this\n";
        print $FILE "problem.\n";
        return;
      }
      &printSourceAlignments( $FILE, $member, $widthsRef, $html, $fixedID );
    }
  }
}

sub printSourceAlignmentsOrig {
  my $FILE      = shift;
  my $annot     = shift;
  my $widthsRef = shift;
  my $html      = shift;
  my $fixedID   = shift;

  my %colWidths = undef;
  %colWidths = %{$widthsRef}
      if ( defined $widthsRef );

  if ( !defined $annot->getDerivedFromAnnot() ) {

    # Allow ID to be overriden.
    my $displayID = $annot->getPRID();
    $displayID = $fixedID if ( $fixedID );

    # print
    if ( defined $widthsRef ) {
      if ( $html ) {
        printf $FILE
            "Annotation: %${colWidths{'SW'}}d  %${colWidths{'PctSubst'}}s "
            . "%${colWidths{'PctDelete'}}s "
            . "%${colWidths{'PctInsert'}}s  "
            . "%-${colWidths{'Seq1Name'}}s  "
            . "%${colWidths{'BeginAlign'}}s "
            . "%${colWidths{'EndAlign'}}s "
            . "%${colWidths{'LeftOver'}}s %1s "
            . "<a class='nound' href='http://www.repeatmasker.org/cgi-bin"
            . "/ViewRepeat?id="
            . $annot->getHitName() . "'>"
            . "%-${colWidths{'HitName'}}s</a> "
            . "%-${colWidths{'class'}}s "
            . "%${colWidths{'Seq2Begin'}}s "
            . "%${colWidths{'Seq2End'}}s "
            . "%${colWidths{'LeftUnaligned'}}s %${colWidths{'ID'}}s\n",
            $annot->getScore(), $annot->getPctDiverge(), $annot->getPctDelete(),
            $annot->getPctInsert(),      $annot->getQueryName(),
            $annot->getQueryStart(),     $annot->getQueryEnd(),
            $annot->getQueryRemaining(), $annot->getOrientation(),
            $annot->getHitName(),        $annot->getClassName(),
            $annot->getSubjStart(),      $annot->getSubjEnd(),
            $annot->getSubjRemaining(),  $displayID;
      }
      else {
        if ( $annot->getOrientation() eq "C" ) {
          printf $FILE
              "Annotation: %${colWidths{'SW'}}d  %${colWidths{'PctSubst'}}s "
              . "%${colWidths{'PctDelete'}}s "
              . "%${colWidths{'PctInsert'}}s  "
              . "%-${colWidths{'Seq1Name'}}s  "
              . "%${colWidths{'BeginAlign'}}s "
              . "%${colWidths{'EndAlign'}}s "
              . "%${colWidths{'LeftOver'}}s %1s "
              . "%-${colWidths{'HitName'}}s "
              . "%-${colWidths{'class'}}s "
              . "%${colWidths{'LeftUnaligned'}}s "
              . "%${colWidths{'Seq2End'}}s "
              . "%${colWidths{'Seq2Begin'}}s %${colWidths{'ID'}}s\n",
              $annot->getScore(),       $annot->getPctDiverge(),
              $annot->getPctDelete(),   $annot->getPctInsert(),
              $annot->getQueryName(),   $annot->getQueryStart(),
              $annot->getQueryEnd(),    "(" . $annot->getQueryRemaining() . ")",
              $annot->getOrientation(), $annot->getHitName(),
              $annot->getClassName(),   "(" . $annot->getSubjRemaining() . ")",
              $annot->getSubjEnd(),     $annot->getSubjStart(), $displayID;
        }
        else {
          printf $FILE "%${colWidths{'SW'}}d  %${colWidths{'PctSubst'}}s "
              . "%${colWidths{'PctDelete'}}s "
              . "%${colWidths{'PctInsert'}}s  "
              . "%-${colWidths{'Seq1Name'}}s  "
              . "%${colWidths{'BeginAlign'}}s "
              . "%${colWidths{'EndAlign'}}s "
              . "%${colWidths{'LeftOver'}}s %1s "
              . "%-${colWidths{'HitName'}}s "
              . "%-${colWidths{'class'}}s "
              . "%${colWidths{'Seq2Begin'}}s "
              . "%${colWidths{'Seq2End'}}s "
              . "%${colWidths{'LeftUnaligned'}}s %${colWidths{'ID'}}s\n",
              $annot->getScore(),       $annot->getPctDiverge(),
              $annot->getPctDelete(),   $annot->getPctInsert(),
              $annot->getQueryName(),   $annot->getQueryStart(),
              $annot->getQueryEnd(),    "(" . $annot->getQueryRemaining() . ")",
              $annot->getOrientation(), $annot->getHitName(),
              $annot->getClassName(),   $annot->getSubjStart(),
              $annot->getSubjEnd(),     "(" . $annot->getSubjRemaining() . ")",
              $displayID;
        }
      }
    }
    print $FILE "Evidence:\n";
    print $FILE $annot->getAlignData();
  }
  else {

    # recurse
    ## May need to sort by seq1beg.  Look for examples
    my @srcMembers = @{ $annot->getDerivedFromAnnot() };
    foreach my $member ( @srcMembers ) {
      if ( $member == $annot ) {
        warn "printSourceAlignments(): Warning - a loop was detected!\n"
            . "Please notify the site administrator of this problem.\n";
        print $FILE "WARNING: A loop was detected in the evidence reporting\n";
        print $FILE "code.  Please notify the site administrator of this\n";
        print $FILE "problem.\n";
        return;
      }
      &printSourceAlignments( $FILE, $member, $widthsRef, $html, $fixedID );
    }
  }
}

sub getMaxColWidths {
  my $annotationListRef = shift;

  my %widths = (
                 'SW'            => 5,
                 'PctSubst'      => 5,
                 'PctInsert'     => 4,
                 'PctDelete'     => 4,
                 'Seq1Name'      => 8,
                 'BeginAlign'    => 5,
                 'EndAlign'      => 5,
                 'LeftOver'      => 6,
                 'HitName'       => 8,
                 'class'         => 10,
                 'Seq2Begin'     => 6,
                 'Seq2End'       => 6,
                 'LeftUnaligned' => 6,
                 'ID'            => 3
  );

  if ( !defined $annotationListRef ) {
    return ( %widths );
  }

  my $annotIter = $annotationListRef->getIterator();

  while ( $annotIter->hasNext() ) {
    my $annot = $annotIter->next();

    my $Seq2BeginLen     = length "(" . $annot->getSubjRemaining . ")";
    my $LeftUnalignedLen = length $annot->getSubjStart();
    if ( $annot->getOrientation eq '+' ) {
      $Seq2BeginLen     = length $annot->getSubjStart();
      $LeftUnalignedLen = length "(" . $annot->getSubjRemaining . ")";
    }
    $widths{'SW'} = length $annot->getScore
        if $widths{'SW'} < length $annot->getScore;
    $widths{'Seq1Name'} = length $annot->getQueryName
        if $widths{'Seq1Name'} < length $annot->getQueryName;
    $widths{'BeginAlign'} = length $annot->getQueryStart
        if $widths{'BeginAlign'} < length $annot->getQueryStart;
    $widths{'EndAlign'} = length $annot->getQueryEnd
        if $widths{'EndAlign'} < length $annot->getQueryEnd;
    $widths{'LeftOver'} = length( $annot->getQueryRemaining() ) + 2
        if $widths{'LeftOver'} < length( $annot->getQueryRemaining() ) + 2;
    $widths{'HitName'} = length $annot->getHitName()
        if $widths{'HitName'} < length $annot->getHitName();
    $widths{'class'} = length $annot->getClassName
        if $widths{'class'} < length $annot->getClassName;
    $widths{'Seq2Begin'} = $Seq2BeginLen
        if $widths{'Seq2Begin'} < $Seq2BeginLen;
    $widths{'Seq2End'} = length $annot->getSubjEnd
        if $widths{'Seq2End'} < length $annot->getSubjEnd;
    $widths{'LeftUnaligned'} = $LeftUnalignedLen
        if $widths{'LeftUnaligned'} < $LeftUnalignedLen;
    $widths{'ID'} = length $annot->getPRID()
        if $widths{'ID'} < length $annot->getPRID();
  }

  return ( %widths );
}

sub printSourceAnnots {
  my $annot     = shift;
  my $widthsRef = shift;
  my $level     = shift;

  my %colWidths = %{$widthsRef};
  return if ( !defined $annot->getDerivedFromAnnot() );
  my @srcMembers = @{ $annot->getDerivedFromAnnot() };
  foreach my $member ( @srcMembers ) {
    print OUTFULL "  " x ( $level ) . "-> ";
    printf OUTFULL "%${colWidths{'SW'}}d  %${colWidths{'PctSubst'}}s "
        . "%${colWidths{'PctDelete'}}s "
        . "%${colWidths{'PctInsert'}}s  "
        . "%-${colWidths{'Seq1Name'}}s  "
        . "%${colWidths{'BeginAlign'}}s "
        . "%${colWidths{'EndAlign'}}s "
        . "%${colWidths{'LeftOver'}}s %1s "
        . "%-${colWidths{'HitName'}}s "
        . "%-${colWidths{'class'}}s "
        . "%${colWidths{'Seq2Begin'}}s "
        . "%${colWidths{'Seq2End'}}s "
        . "%${colWidths{'LeftUnaligned'}}s %${colWidths{'ID'}}s\n",
        $member->getScore(), $member->getPctDiverge(), $member->getPctDelete(),
        $member->getPctInsert(),      $member->getQueryName(),
        $member->getQueryStart(),     $member->getQueryEnd(),
        $member->getQueryRemaining(), $member->getOrientation(),
        $member->getHitName(), $member->getClassName(), $member->getSubjStart(),
        $member->getSubjEnd(), $member->getSubjRemaining(), $member->getPRID();
    &printSourceAnnots( $member, $widthsRef, $level++ );
  }
}

## FOR TESTING
sub printSTDOUTSourceAnnots {
  my $annot     = shift;
  my $widthsRef = shift;
  my $level     = shift;

  return if ( !defined $annot->getDerivedFromAnnot() );
  my @srcMembers = @{ $annot->getDerivedFromAnnot() };
  foreach my $member ( @srcMembers ) {
    print "SOURCE" . "  " x ( $level ) . "-> ";
    print ""
        . join(
                " ",
                (
                  $member->getScore(),       $member->getPctDiverge(),
                  $member->getPctDelete(),   $member->getPctInsert(),
                  $member->getQueryName(),   $member->getQueryStart(),
                  $member->getQueryEnd(),    $member->getQueryRemaining(),
                  $member->getOrientation(), $member->getHitName(),
                  $member->getClassName(),   $member->getSubjStart(),
                  $member->getSubjEnd(),     $member->getSubjRemaining(),
                  $member->getPRID()
                )
        )
        . "\n";
    &printSTDOUTSourceAnnots( $member, $widthsRef, $level++ );
  }
}

sub scoreLINEPair {
  my $annot1          = shift;
  my $annot2          = shift;
  my $elementDistance = shift;
  my $optRef          = shift;

  my $score = 0;
  my $DEBUG = 0;

  if ( $DEBUG ) {
    print "scoreLINEPair(): Scoring these two:\n";
    $annot1->print();
    $annot2->print();
  }

  # Establish position order
  my $leftAnnot  = $annot1;
  my $rightAnnot = $annot2;
  if ( $annot1->comparePositionOrder( $annot2 ) > 0 ) {
    $leftAnnot  = $annot2;
    $rightAnnot = $annot1;
  }

  # Calculate query overlap
  my $queryOverlap = $rightAnnot->getQueryOverlap( $leftAnnot );

  # Calculate consensus overlap & consensus gap
  my $consensusOverlap = $rightAnnot->getConsensusOverlap( $leftAnnot );
  my $consensusGap     = -$consensusOverlap;
  my $adjConOverlap    = $consensusOverlap;
  $adjConOverlap -= $queryOverlap if $queryOverlap > 0;

  # Determine name compatibility
  my $namesCompat = 0;
  if ( $leftAnnot->getSubjName() eq $rightAnnot->getSubjName() ) {
    $namesCompat = 1;
  }
  else {
    my $nameHash = undef;
    if ( defined $RepeatAnnotationData::lineHash{ $leftAnnot->getHitName() } ) {
      $nameHash = $RepeatAnnotationData::lineHash{ $leftAnnot->getHitName() };
    }
    elsif (
          defined $RepeatAnnotationData::lineHash{ $rightAnnot->getHitName() } )
    {

      #warn "RepeatAnnotationData does not contain data on " .
      #     $leftAnnot->getHitName() . "\n";
      $nameHash = $RepeatAnnotationData::lineHash{ $rightAnnot->getHitName() };
    }
    else {

      #warn "RepeatAnnotationData does not contain data on " .
      #     $rightAnnot->getHitName() . "\n";
    }

    if ( $nameHash ) {
      my $nameEntry = undef;
      if ( defined $nameHash->{ $rightAnnot->getHitName() } ) {
        $nameEntry = $nameHash->{ $rightAnnot->getHitName() };
      }
      elsif ( defined $nameHash->{ $leftAnnot->getHitName() } ) {

        #warn "RepeatAnnotationData contains a non-reciprocal entry " .
        #     $rightAnnot->getHitName() . "\n";
        $nameEntry = $nameHash->{ $leftAnnot->getHitName() };
      }

      if ( $nameEntry ) {
        my $overlapThresh = $nameEntry->{'overThresh'};
        print "Names compatible: "
            . $rightAnnot->getHitName() . " "
            . $leftAnnot->getHitName()
            . " ot=$overlapThresh\n"
            if ( $DEBUG );
        if ( $overlapThresh >= 0 ) {
          $namesCompat = 1
              if ( $overlapThresh == 0
                   || ( $queryOverlap > $overlapThresh ) );
        }
      }    # if ( $nameEntry...
    }    # if ( $nameHash...
    else {
    }
  }    #else names are equal

  #
  # First use essential qualifiers
  #  - Same query sequence
  #  - Same orientation
  #
  if (    $annot1->getQueryName() eq $annot2->getQueryName()
       && $annot1->getOrientation() eq $annot2->getOrientation() )
  {

    print "scoreLINEPair() getSubjRemaining = "
        . $leftAnnot->getSubjRemaining . "\n"
        if ( $DEBUG );

    #
    # Consensus Positions Make Sense
    #
    #     i.e   100----->  50----->
    #        or <------200 <------320
    #
    if (
         (
              $leftAnnot->getOrientation() eq "+"
           && $rightAnnot->getSubjStart() >= $leftAnnot->getSubjStart() - 5
           || $leftAnnot->getOrientation() eq "C"
           && $leftAnnot->getSubjStart() >= $rightAnnot->getSubjStart() - 5
         )
        )
    {

      #
      # Is the model order valid and is there room
      # for model extension?
      #
      # i.e. do not allow:
      #       5 <--- 3
      #  or   3 ---> 5
      #
      # Also do not allow ( because? ):
      #
      #      3 --->|  anything
      #  or  anything |<---- 5
      #
      my $modelCompat = 1;
      if (
              $leftAnnot->getOrientation() eq "+"
           && $leftAnnot->getSubjName() =~ /_3end/
           && (    $rightAnnot->getSubjName() =~ /_5end/
                || $leftAnnot->getSubjRemaining() < 10 )
           || $rightAnnot->getOrientation() eq "C"
           && $rightAnnot->getSubjName() =~ /_3end/
           && (    $leftAnnot->getSubjName() =~ /_5end/
                || $rightAnnot->getQueryRemaining() < 10 )
          )
      {
        $modelCompat = 0;
      }

      if ( $modelCompat ) {
        if ( $namesCompat ) {

          #
          # Calculate score:
          #   - divergence difference  ( large = bad )
          #   - query overlap          ( overlap = good, gap = worse )
          #   - consensus overlap      ( large overlap = bad, large gap = bad )
          #   distfine = CO < 33 && CG <=200 ||
          #      really complex CO/QO & Div formula
          #

          # divDiff = The closer the two divergences are to each
          #          other the closer divDiff gets to its max of
          #          1.54.  NOTE: It's later limited to 1.2
          #          wha? wha? wha?
          my $divDiff;
          if (    $rightAnnot->getPctDiverge() > $leftAnnot->getPctDiverge()
               && $rightAnnot->getPctDiverge() > 0 )
          {
            $divDiff = (
                ( $leftAnnot->getPctDiverge() / $rightAnnot->getPctDiverge() ) /
                    0.65 ) - (
                ( $rightAnnot->getPctDiverge() - $leftAnnot->getPctDiverge() ) /
                    100 );
          }
          elsif (    $leftAnnot->getPctDiverge() > $rightAnnot->getPctDiverge()
                  && $leftAnnot->getPctDiverge() > 0 )
          {
            $divDiff =
                ( $rightAnnot->getPctDiverge() / $leftAnnot->getPctDiverge() ) /
                0.65 -
                ( $leftAnnot->getPctDiverge() - $rightAnnot->getPctDiverge() ) /
                100;
          }
          else {
            $divDiff = 1.2;
          }
          $divDiff = 1.2 if $divDiff > 1.2;

          # Factor decreasing with number of intervening
          # elements ( of same type ); should prevent way distant link-ups
          my $elementDistanceFactor = 1 - ( $elementDistance - 1 ) / 30;

          my $avgLeftUnaligned = $leftAnnot->getSubjRemaining();
          $avgLeftUnaligned = $rightAnnot->getSubjRemaining()
              if ( $avgLeftUnaligned < $rightAnnot->getSubjRemaining() );

          if ( $DEBUG ) {
            print "Stats: queryOverlap = $queryOverlap,\n"
                . "       consensusOverlap = $consensusOverlap,\n"
                . "       divDiff = $divDiff > 0.1,\n"
                . "       elementDistance = $elementDistance,\n"
                . "       elementDistanceFactor = $elementDistanceFactor,\n"
                . "       avgLeftUnaligned = $avgLeftUnaligned,\n";
            print "       adjConOverlap = $adjConOverlap <= "
                . ( ( 3.75 * $avgLeftUnaligned**0.48 - 47 ) *
                    $elementDistanceFactor**2 * $divDiff )
                . ",\n";
            print "       consGap = $consensusGap <= "
                . (
                   $elementDistanceFactor * $divDiff * $avgLeftUnaligned / 1.4 )
                . "\n";
          }

          if (

            # The allowed conensus overlap is dependent on the position
            # in the LINE1 consensus.  The further it is from the 3' end
            # ($LeftUnaligned) the more overlap is tolerated, this
            # somewhat has to do with the relatively poor representation
            # of 5' region consensus sequences, but largely because of
            # the presence of tandem promoter units. This should be
            # solved in a better way, e.g. identifying the tandem
            # repeats in the consensus sequences and treating those
            # regions as we treat satellites.

            # The overlap quadratically relates to the distance in IDs.
            (
                 $adjConOverlap == 0
              || $adjConOverlap <= ( 3.75 * $avgLeftUnaligned**0.48 - 47 ) *
              $elementDistanceFactor**2 * $divDiff
            )
            && $divDiff > 0.1    # I'm being generous here
            && $consensusGap <=
            $elementDistanceFactor * $divDiff * $avgLeftUnaligned / 1.4
              )
          {

            # consensus gap should be allowed to be larger the more 5'
            # you get, since these regions are getting rarer
            #print  "****DISTFINE SET*****\n";
            print "   -- We call this good!\n" if ( $DEBUG );
            $score = 1;
          }

        }
        elsif ( $DEBUG ) {
          print "scoreLINEPair(): Names Not Compat Rule\n";
        }    # ...if ( $namesCompat...

      }
      elsif ( $DEBUG ) {
        print "scoreLINEPair(): Invalid Model Order or "
            . "Insufficient Unaligned\n";
      }    # if ( $modelCompat...

    }
    elsif ( $DEBUG ) {
      print "scoreLINEPair(): Invalid Consensus Order\n";
    }    # Do consensus positions make sense?

    #
    # Determine ShortHitName Compat
    #
    my $shortHitNameCompatible = 0;
    my $HitName                = $rightAnnot->getHitName();
    $HitName =~ s/_orf2$//;

    # TODO: This is a special case of an element which needs
    #       a portion of it's sequence masked out in a separate stage.
    #       The sequence is a simple repeats which is scored too high
    #       otherwise. I am refering to the endX designation.
    $HitName =~ s/(.*)_[35]endX?$/$1/;
    $HitName =~ s/_strong$//;

    # could use latter as a general tool to indicate a diagnostic fragment
    # rename carnivore LINEs who's name have been adjusted
    # temporarily to allow neighboring fragment recognition
    if ( $HitName =~ /^L1_Ca/ ) {
      $HitName =~ s/^L1_Canis0/L1_Cf/;
      $HitName =~ s/^L1_Canis4/L1_Canid/;
      $HitName =~ s/^L1_Canis5/L1_Canid2/;
    }
    my $shortHitName = $HitName;
    if ( $HitName =~ /^L1M/ ) {
      $shortHitName =~ s/(^\w{5}).*/$1/;
    }
    elsif ( $optRef->{'mammal'} && $HitName =~ /^L1_/ ) {
      $shortHitName = "L1_";
    }
    else {
      $shortHitName =~ s/(\S+\d)[a-zA-Z]$/$1/;
    }
    $shortHitName = quotemeta $shortHitName;
    my $leftHitName = $leftAnnot->getHitName();
    $leftHitName =~ s/_orf2$//;
    $leftHitName =~ s/(.*)_[35]endX?$/$1/;
    $leftHitName =~ s/_strong$//;
    if ( $leftHitName =~ /^L1_Ca/ ) {
      $leftHitName =~ s/^L1_Canis0/L1_Cf/;
      $leftHitName =~ s/^L1_Canis4/L1_Canid/;
      $leftHitName =~ s/^L1_Canis5/L1_Canid2/;
    }
    print "scoreLINEPair(): shortHitName = $shortHitName\n"
        if ( $DEBUG );
    if ( $leftHitName =~ /^$shortHitName/ ) {
      $shortHitNameCompatible = 1;
      print "scoreLINEPair(): shortHitNameCompatible -- yes\n"
          if ( $DEBUG );
    }

    #
    # Less stringent compatability test
    #
    #       shortHitNameCompatible
    #       gapMax = 2500 -> 3750 ( names exact )
    #       divDiff = abs( div1 - div2 )
    #       gapMax decreases with greater divDiff
    #       gapMax decreases with greater annotation distance
    #
    if ( $score == 0 && $shortHitNameCompatible ) {
      print "scoreLINEPair():  last chance test ( names compat )\n"
          if ( $DEBUG );
      my $gapMax = 2500;
      $gapMax *= 1.5
          if ( $leftAnnot->getHitName() eq $rightAnnot->getHitName() );

      # Need to revise the way div diff is calc'd
      my $divDiff = $leftAnnot->getPctDiverge() - $rightAnnot->getPctDiverge();
      $divDiff = -$divDiff if ( $divDiff < 0 );
      $gapMax *= ( 10 - $divDiff ) / 10;
      $gapMax *= ( 10 - $elementDistance ) / 10;
      if ( $DEBUG ) {
        print " divDiff = $divDiff\n";
        print " gapMax = $gapMax > cg="
            . $leftAnnot->getConsensusGap( $rightAnnot ) . "\n";
      }
      if (    $leftAnnot->getConsensusOverlap( $rightAnnot ) < 33
           && $leftAnnot->getConsensusOverlap( $rightAnnot ) > -$gapMax )
      {
        print "scoreLINEPair():   Hmmm....questionable...but "
            . "going to do it\n"
            if ( $DEBUG );
        $score = 0.5;
      }
    }

    #
    # What is this catching???
    #
    #    - The sequences overlap ( but not contain )
    #    - The sequences are shortHitNameCompatible
    #    - Query Overlap is >= 33
    #    - Consensus Overlap is < 50
    #
    if ( $score == 0 ) {
      print "scoreLINEPair():  lastiness test\n"
          if ( $DEBUG );
      if (    $leftAnnot->getQueryEnd() >= $rightAnnot->getQueryStart()
           && $rightAnnot->getQueryEnd() > $leftAnnot->getQueryEnd() )
      {

        #
        # If these elements have the same class, orientation,
        # similar names with small overlap or simply just
        # a large overlap then join them!!!  Arghhh
        #
        if (    $shortHitNameCompatible
             && $rightAnnot->getQueryStart() <= $leftAnnot->getQueryEnd() - 33
             && $leftAnnot->getConsensusOverlap( $rightAnnot ) < 50 )
        {
          if ( !$namesCompat ) {

            #warn "Must add "
            #    . $leftAnnot->getHitName() . " and "
            #    . $rightAnnot->getHitName()
            #    . " to the compat hash\n";
          }
          print "scoreLINEPair(): Well if you insist\n" if ( $DEBUG );
          $score = 0.25;
        }
      }
    }

  }
  elsif ( $DEBUG ) {
    print "scoreLINEPair(): Wrong Seq or Orientation Rule\n";
  }    # Same queryName and Same orientation

  if ( $score ) {
    my $conOverlapFactor = -1;
    $conOverlapFactor = 1 / abs( $adjConOverlap + $queryOverlap )
        if ( $adjConOverlap + $queryOverlap != 0 );

    if ( $DEBUG ) {
      print "adjConOverlap = $adjConOverlap + "
          . "queryOverlap = $queryOverlap conOverlapFactor "
          . "= $conOverlapFactor\n";
      print "score = $score\n";
    }

    if ( $conOverlapFactor > 0 ) {
      $score += $conOverlapFactor;
    }
    else {
      print "Using elementdistance = $elementDistance\n" if ( $DEBUG );
      $score += 1 / $elementDistance;
    }
  }

  print "scoreLINEPair(): Final Score = $score\n"
      if ( $DEBUG );

  return ( $score );
}

sub areLINENamesCompat {
  my $line1 = shift;
  my $line2 = shift;

  # If name incompatible then return low score early
  my $compat         = 0;
  my $line1Name      = $line1->getHitName();
  my $line1ClassName = $line1->getClassName();
  my $line2Name      = $line2->getHitName();
  my $line2ClassName = $line2->getClassName();

  # Establish position order
  my $leftAnnot  = $line1;
  my $rightAnnot = $line2;
  if ( $line1->comparePositionOrder( $line2 ) > 0 ) {
    $leftAnnot  = $line2;
    $rightAnnot = $line1;
  }

  my $queryOverlap = $rightAnnot->getQueryOverlap( $leftAnnot );

  if ( $line1->getSubjName() eq $line2->getSubjName() ) {
    $compat = 1;
  }
  elsif ( defined $RepeatAnnotationData::lineHash{$line1Name}->{$line2Name} ) {
    my $overlapThresh =
        $RepeatAnnotationData::lineHash{$line1Name}->{$line2Name}
        ->{'overThresh'};
    if ( $overlapThresh >= 0 ) {
      $compat = 1
          if ( $overlapThresh == 0
               || ( $queryOverlap > $overlapThresh ) );
    }
  }
  elsif ( defined $RepeatAnnotationData::lineHash{$line2Name}->{$line1Name} ) {
    my $overlapThresh =
        $RepeatAnnotationData::lineHash{$line2Name}->{$line1Name}
        ->{'overThresh'};
    if ( $overlapThresh >= 0 ) {
      $compat = 1
          if ( $overlapThresh == 0
               || ( $queryOverlap > $overlapThresh ) );
    }
  }
  else {
    print "Names not compatible\n" if ( $DEBUG );
  }

  return ( $compat );
}

#
#
# Given a fragment annotation "c" and a set of
# putative related fragments M.  Also given a
# set of transforms "transforms()" for c and
# members of M.
#
# for all transforms of "c" find the maximal
# scoring transform where maximal is determined
# by the transform which is compatible with the
# most elements of M.
#
# foreach transform "tc" in transforms("c")
#   foreach element "m" in M
#     foreach transform "tm" in transforms("m")
#       is "tc" + "tm" compatible?
#
#
# Things to consider:
#    - Perhaps the score should consider
#      the liklihood that two annotations
#      would be fused? i.e. minimize the
#      consensus gap distance??
#
#    - It would be parsomonious to choose
#      the set name which covers the most
#      of the given consensus.
#
#
sub joinDNATransposonFragments {
  my $chainBegHash         = shift;
  my $chainEndHash         = shift;
  my $repeatDB             = shift;
  my $currentAnnot         = shift;
  my $dnaTransposonCluster = shift;

  $DEBUG = 0;
  if ( $DEBUG ) {
    print "joinDNATransposonFragments(): Entered...\n";
    print "  Considering Element:\n    ";
    $currentAnnot->printBrief();
    print "  Neighbor Cluster:\n";
    foreach my $potAnnot ( @{$dnaTransposonCluster} ) {
      print "    ";
      $potAnnot->printBrief();
    }
    print "\n";
  }

  next if ( $currentAnnot->getRightLinkedHit() );

  my ( $curHitName, $curClassName ) =
      split( /\#/, $currentAnnot->getSubjName() );

  my $curEquivHash = $currentAnnot->getEquivHash();
  $curEquivHash = {} if ( !defined $curEquivHash );
  my @curNames = ( $curHitName, ( sort ( keys( %{$curEquivHash} ) ) ) );

  my %nameScores   = ();
  my %nameAnnots   = ();
  my $proposedName = "";
  my $isCompatible = 0;
  my ( $adjCurBegin,       $adjCurEnd );
  my ( $adjCandidateBegin, $adjCandidateEnd );

  my $highestScore = 0;
  my $highName     = "";
  my $highCurRange;
  my $highMembers;

  #
  #  Consider all names that the current element may go by
  #  including it's current name and all aliases.
  #
  foreach my $curName ( @curNames ) {
    print "  Current Element Name: $curName\n" if ( $DEBUG );

    # Fake a range if hit name
    my @curRanges = ();
    if ( $curName eq $curHitName ) {
      push @curRanges,
          {
            'start'   => 1,
            'end'     => $chainEndHash->{ $currentAnnot->getPRID() },
            'eqstart' => 1,
            'eqend'   => $chainEndHash->{ $currentAnnot->getPRID() }
          };
    }
    if ( defined $curEquivHash->{$curName} ) {
      push @curRanges, @{ $curEquivHash->{$curName} };
    }

    my $highestRangeScore      = 0;
    my $highestScoringCurRange = undef;
    my $highestScoringMembers;
    foreach my $curNameRange ( @curRanges ) {
      print "    Current Element Range: [$curNameRange->{'start'}-"
          . "$curNameRange->{'end'}]-->[$curNameRange->{'eqstart'}-"
          . "$curNameRange->{'eqend'}]\n"
          if ( $DEBUG );
      my $curNameRangeScore  = 0;
      my @curNameRangeAnnots = ();
      ( $adjCurBegin, $adjCurEnd ) =
          &translateCoord( $currentAnnot->getSubjStart(),
                           $currentAnnot->getSubjEnd(),
                           $curNameRange );
      my $curNameRangeLastBegin = $adjCurBegin;
      my $curNameRangeLastEnd   = $adjCurEnd;
      my $seedSeq1Pos           = $currentAnnot->getQueryStart();
      my $seedSeq1End           = $currentAnnot->getQueryEnd();

      foreach my $potAnnot ( @{$dnaTransposonCluster} ) {
        ## Don't consider fragments that would be
        ##   inherited from the first one.
        ## TODO: Doesn't it make more sense to not consider
        ##       currentAnnots with RightLinkedHits?
        next if ( $potAnnot->getLeftLinkedHit() );

        my ( $potHitName, $potClassName ) =
            split( /\#/, $potAnnot->getSubjName() );
        my $potEquivHash = $potAnnot->getEquivHash();
        $potEquivHash = {} if ( !defined $potEquivHash );
        my @potNames = ( $potHitName, ( sort ( keys( %{$potEquivHash} ) ) ) );
        my $adjPotStrand = $potAnnot->getOrientation();

        if ( $DEBUG ) {
          print "      Potential Element:\n        " if ( $DEBUG );
          $potAnnot->printBrief()                    if ( $DEBUG );
        }

        foreach my $potName ( @potNames ) {

          # Fake a range if hit name
          my @potRanges = ();
          if ( $potName eq $potHitName ) {
            push @potRanges,
                {
                  'start'   => 1,
                  'end'     => $chainEndHash->{ $potAnnot->getPRID() },
                  'eqstart' => 1,
                  'eqend'   => $chainEndHash->{ $potAnnot->getPRID() }
                };
          }
          if ( defined $potEquivHash->{$potName} ) {
            push @potRanges, ( @{ $potEquivHash->{$potName} } );
          }

          foreach my $potNameRange ( @potRanges ) {

            # Test comparison
            print "           Equiv Names: "
                . "$potName: ["
                . $potNameRange->{"start"} . "-"
                . $potNameRange->{"end"} . "]-->["
                . $potNameRange->{"eqstart"} . "-"
                . $potNameRange->{"eqend"} . "]\n"
                if ( $DEBUG );

            if ( $curName eq $potName ) {

              # Are the orientations correct?
              if (
                   (
                        $potNameRange->{'compl'} == $curNameRange->{'compl'}
                     && $currentAnnot->getOrientation() eq
                     $potAnnot->getOrientation()
                   )
                   || (    $potNameRange->{'compl'} != $curNameRange->{'compl'}
                        && $currentAnnot->getOrientation() ne
                        $potAnnot->getOrientation() )
                  )
              {

                ( $adjCandidateBegin, $adjCandidateEnd ) =
                    &translateCoord( $potAnnot->getSubjStart(),
                                     $potAnnot->getSubjEnd(), $potNameRange );

                # Are the coordinates sensible?
                if ( $potAnnot->getOrientation() eq "C"
                     && defined $potNameRange->{'compl'} )
                {
                  $adjPotStrand = "+";
                }
                elsif ( $potAnnot->getOrientation() eq "+"
                        && defined $potNameRange->{'compl'} )
                {
                  $adjPotStrand = "C";
                }

                #$adjCurBegin, $adjCurEnd,
                $isCompatible = &isTransposonPairCompatible(
                            1,                          $curNameRangeLastBegin,
                            $curNameRangeLastEnd,       $adjCandidateBegin,
                            $adjCandidateEnd,           $adjPotStrand,
                            $seedSeq1Pos,               $seedSeq1End,
                            $potAnnot->getQueryStart(), $potAnnot->getQueryEnd()
                );
                if ( $isCompatible ) {
                  print "            ---> isCompatible = $isCompatible\n"
                      if ( $DEBUG );
                  $curNameRangeLastBegin = $adjCandidateBegin;
                  $curNameRangeLastEnd   = $adjCandidateEnd;

                  # Seq1 coordinates move along as we connect fragments.
                  $seedSeq1Pos = $potAnnot->getQueryStart();
                  $seedSeq1End = $potAnnot->getQueryEnd();

                  ## TODO: Look into adding other factors into this score.
                  ##       Those would include, all things being equal take
                  ##       the higher scoring matches etc.
                  $curNameRangeScore++;
                  push @curNameRangeAnnots,
                      { 'annot' => $potAnnot, 'range' => $potNameRange };
                  ## TODO: Make this a recursive function or fuse overlapping
                  ##       elements first.  I prefer the first option.
                  last;
                }
              }    # if ( ...are orientations correct
            }    # are the names the same
          }    # foreach potNameRange
        }    # foreach potName
      }    # foreach $pot

      # Update stats:  We now know which name produced the highest element
      #                count for the current element, name, and range.
      #my $highestScoringName = (sort( keys( %curNameRangeScores )))[0];
      if ( $curNameRangeScore > $highestRangeScore ) {
        $highestRangeScore      = $curNameRangeScore;
        $highestScoringCurRange = $curNameRange;
        $highestScoringMembers  = [ @curNameRangeAnnots ];
        print "    New high score = $curNameRangeScore\n" if ( $DEBUG );
      }
    }    # foreach curNameRange

    if ( $highestRangeScore > $highestScore ) {
      print "  New high score = $highestRangeScore\n" if ( $DEBUG );
      $highestScore = $highestRangeScore;
      $highName     = $curName;
      $highCurRange = $highestScoringCurRange;
      $highMembers  = [ @{$highestScoringMembers} ];

      #print "Dump: " . Dumper( $highMembers ) . "\n";
    }
  }    # foreach curName

  print "\n  highestScore = $highestScore\n" if ( $DEBUG );

  if ( $highestScore > 0 ) {
    print "  highCurrentName/Range = $highName: ["
        . $highCurRange->{"start"} . "-"
        . $highCurRange->{"end"} . "]-->["
        . $highCurRange->{"eqstart"} . "-"
        . $highCurRange->{"eqend"} . "]\n"
        if ( $DEBUG );

    &translateAnnotation( $currentAnnot, $highCurRange, $highName, $repeatDB );

    if ( $currentAnnot->getRightLinkedHit()
         && !$currentAnnot->getLeftLinkedHit() )
    {
      my $tmpAnnot = $currentAnnot;
      while ( $tmpAnnot->getRightLinkedHit() ) {
        $tmpAnnot = $tmpAnnot->getRightLinkedHit();
        &translateAnnotation( $tmpAnnot, $highCurRange, $highName, $repeatDB );
      }
    }

    # Correct the coordinates & orientation of the member elements
    my $lastAnnot     = $currentAnnot;
    my $lastBegin     = $adjCurBegin;
    my $lastEnd       = $adjCurEnd;
    my $lastSeq1Begin = $currentAnnot->getQueryStart();
    my $lastSeq1End   = $currentAnnot->getQueryEnd();

    my %memberSeen = ();
    foreach my $member ( @{$highMembers} ) {
      print "Considering member:\n" if ( $DEBUG );
      $member->{'annot'}->print()   if ( $DEBUG );
      my ( $memberHitName, $memberClassName ) =
          split( /\#/, $member->{'annot'}->getSubjName() );
      my ( $adjMemberBegin, $adjMemberEnd ) =
          &translateCoord( $member->{'annot'}->getSubjStart(),
                           $member->{'annot'}->getSubjEnd(),
                           $member->{'range'} );

      # First check to see if this needs to be fused
      if (    $adjMemberBegin <= $lastEnd
           && $adjMemberEnd >= $lastBegin
           && $member->{'annot'}->getQueryStart() <= $lastSeq1Begin
           && $member->{'annot'}->getQueryEnd() >= $lastSeq1End )
      {

        # add fused element to our derived from list
        if ( $options{'source'} ) {

          # RMH: 2/12/14: Bug fix -- was trying to add $member not
          #               $member->{'annot'}
          $lastAnnot->addDerivedFromAnnot( $member->{'annot'} );
        }

        # Modify the last one
        # Add bases to either the end or begining of the consensus position
        #print  "lastRange = $lastBegin  - $lastEnd\n";
        $lastAnnot->setSubjRemaining(
                $lastAnnot->getSubjRemaining() - ( $lastEnd - $adjMemberEnd ) );
        $lastAnnot->setSubjEnd( $adjMemberEnd );

        # Remove ourselves
        $member->{'annot'}->setStatus( "DELETED" );

        # Adjust other things like score, div stats etc
        if ( $member->{'annot'}->getScore() > $lastAnnot->getScore() ) {
          $lastAnnot->setScore( $member->{'annot'}->getScore() );
        }
        if ( $member->{'annot'}->getPctDiverge() < $lastAnnot->getPctDiverge() )
        {
          my $totalLastLength =
              $lastAnnot->getQueryEnd() - $lastAnnot->getSubjStart();
          my $lastRemainder = $totalLastLength - getOverlapSize(
                                            $member->{'annot'}->getQueryStart(),
                                            $member->{'annot'}->getQueryEnd(),
                                            $lastAnnot->getQueryStart(),
                                            $lastAnnot->getQueryEnd()
          );

          $lastAnnot->setPctDiverge(
                                     $member->{'annot'}->getPctDiverge() + (
                                       $lastAnnot->getPctDiverge() *
                                           ( $lastRemainder / $totalLastLength )
                                     )
          );
          $lastAnnot->setPctDelete(
            $member->{'annot'}->getPctDelete() + (
              $lastAnnot->getPctDelete() * ( $lastRemainder / $totalLastLength )
            )
          );
          $lastAnnot->setPctInsert(
            $member->{'annot'}->getPctInsert() + (
              $lastAnnot->getPctInsert() * ( $lastRemainder / $totalLastLength )
            )
          );

        }
        else {
          my $totalLastLength =
              $member->{'annot'}->getQueryEnd() -
              $member->{'annot'}->getSubjStart();
          my $lastRemainder = $totalLastLength - getOverlapSize(
                                            $lastAnnot->getQueryStart(),
                                            $lastAnnot->getQueryEnd(),
                                            $member->{'annot'}->getQueryStart(),
                                            $member->{'annot'}->getQueryEnd()
          );

          $member->{'annot'}->setPctDiverge(
                                     $lastAnnot->getPctDiverge() + (
                                       $member->{'annot'}->getPctDiverge() *
                                           ( $lastRemainder / $totalLastLength )
                                     )
          );
          $member->{'annot'}->setPctDelete(
                                     $lastAnnot->getPctDelete() + (
                                       $member->{'annot'}->getPctDelete() *
                                           ( $lastRemainder / $totalLastLength )
                                     )
          );
          $member->{'annot'}->setPctInsert(
                                     $lastAnnot->getPctInsert() + (
                                       $member->{'annot'}->getPctInsert() *
                                           ( $lastRemainder / $totalLastLength )
                                     )
          );

        }

        # Adjust seq1positions
      }
      else {

        &translateAnnotation( $member->{'annot'}, $member->{'range'}, $highName,
                              $repeatDB );

        if ( $member->{'annot'}->getRightLinkedHit()
             && !$member->{'annot'}->getLeftLinkedHit() )
        {
          my $tmpAnnot = $member->{'annot'};
          while ( $tmpAnnot->getRightLinkedHit() ) {
            $tmpAnnot = $tmpAnnot->getRightLinkedHit();
            &translateAnnotation( $tmpAnnot, $member->{'range'},
                                  $highName, $repeatDB );
          }
        }

        if ( $DEBUG ) {
          print "   Doing the join of\n" if ( $DEBUG );
          $lastAnnot->print();
          $member->{'annot'}->print();
        }

        $lastAnnot->join( $member->{'annot'} );
        $lastAnnot     = $member->{'annot'};
        $lastEnd       = $adjMemberEnd;
        $lastBegin     = $adjMemberBegin;
        $lastSeq1Begin = $member->{'annot'}->getQueryStart();
        $lastSeq1End   = $member->{'annot'}->getQueryEnd();
      }    # is fusable else
    }    # end foreach

    if ( $DEBUG ) {
      print "  New current element:\n    ";
      $currentAnnot->printBrief();
      print "  New member elements:\n";
      foreach my $member ( @{$highMembers} ) {
        print "     " . $member->{'annot'}->getStatus() . ":";
        $member->{'annot'}->printBrief();
      }
    }
  }
  print "joinDNATransposonFragments(): Exiting...\n\n" if ( $DEBUG );
}

sub translateAnnotation {
  my $annot      = shift;
  my $transRange = shift;
  my $transName  = shift;
  my $repeatDB   = shift;

  # Correct the coordinates & orientation of the current element first
  my ( $curHitName, $curClassName ) =
      split( /\#/, $annot->getSubjName() );
  my ( $adjCurBegin, $adjCurEnd ) =
      &translateCoord( $annot->getSubjStart(), $annot->getSubjEnd(),
                       $transRange );

  # Modify end coordinates and left unaligned if necessary.
  if (    $adjCurEnd == $annot->getSubjEnd()
       && $curHitName eq $transName )
  {

    # Nothing to do...coordinates didn't change.
  }
  elsif ( defined $repeatDB->{ lc( $transName ) }->{'conlength'} ) {
    $annot->setSubjEnd( $adjCurEnd );
    $annot->setSubjRemaining(
        $repeatDB->{ lc( $transName ) }->{'conlength'} - $annot->getSubjEnd() );
  }
  else {
    die "Cannot find the consensus length for element $transName!\n"
        . "consensus unaligned length will be incorrect in the\n"
        . "annotation. Annotation is\n"
        . $annot->print() . "\n";
  }

  # If we are changing the name we might have changed the class as well.
  if ( defined $repeatDB->{ lc( $transName ) } ) {
    my $className = $repeatDB->{ lc( $transName ) }->{'type'};
    if ( $repeatDB->{ lc( $transName ) }->{'subtype'} ne "" ) {
      $className .= "/" . $repeatDB->{ lc( $transName ) }->{'subtype'};
    }
    $annot->setClassName( $className );
  }

  $annot->setHitName( $transName );
  $annot->setSubjStart( $adjCurBegin );
  $annot->setStatus( "JOINED" );
  if ( $annot->getOrientation() eq "C"
       && defined $transRange->{'compl'} )
  {
    $annot->setOrientation( "+" );
  }
  elsif ( $annot->getOrientation() eq "+"
          && defined $transRange->{'compl'} )
  {
    $annot->setOrientation( "C" );
  }
}    # sub translateAnnotation

##sorting subroutines
# Cycle 0B
sub bySeqSWConbegin ($$) {
  ( $_[ 0 ]->getQueryName() ) cmp( $_[ 1 ]->getQueryName() )
      || ( $_[ 0 ]->getScore() ) <=>     ( $_[ 1 ]->getScore() )
      || ( $_[ 0 ]->getSubjStart() ) <=> ( $_[ 1 ]->getSubjStart() );
}

# Lots of places
sub byNameBeginEndrevSWrev ($$) {
  ( $_[ 0 ]->getQueryName() ) cmp( $_[ 1 ]->getQueryName() )
      || ( $_[ 0 ]->getQueryStart() ) <=> ( $_[ 1 ]->getQueryStart() )
      || ( $_[ 1 ]->getQueryEnd() ) <=>   ( $_[ 0 ]->getQueryEnd() )
      || ( $_[ 1 ]->getScore() ) <=>      ( $_[ 0 ]->getScore() );
  ### note: takes the longer sequence starting at the same position first
}

# Cycle 0Da
sub byNameClassBeginEndrevAndSWrev ($$) {
  my ( $aSeqName, $aClassName ) = $_[ 0 ]->getSubjName() =~ /(.*)#(.*)/;
  my ( $bSeqName, $bClassName ) = $_[ 1 ]->getSubjName() =~ /(.*)#(.*)/;
  ( $_[ 0 ]->getQueryName() ) cmp( $_[ 1 ]->getQueryName() )
      || ( $aClassName ) cmp( $bClassName )
      || ( $_[ 0 ]->getQueryStart() ) <=> ( $_[ 1 ]->getQueryStart() )
      || ( $_[ 1 ]->getQueryEnd() ) <=> ( $_[ 0 ]->getQueryEnd() )
      || ( $_[ 1 ]->getScore() ) <=> ( $_[ 0 ]->getScore() );
}

# Line Preprocessing notes:
#
#
#  TODO: Eventually this routine should keep track of the adjustments
#        independent of the original annotation.  That way we can
#        track the evidence for each final annotation.
#
#  Marsupials are adjusted to L1_Mdo1
#  To be done: HAL1_Opos1_3end is not so close to normal LINE1s,
#              but probably still warrants to be lined up with L1.
#  opt_mammals and L1* are adjusted to L1_Canid
#  in future all mammalian LINEs need to have one startpoint, e.g. L1M2_ORF2
#  We change L1_Cf so that it can be recognized in fragment comparisons
#    with L1_Canis subs. Similarly for L1_Canid.
#
# LINE subfamilies have widely variable length 5' ends. To be able to
# merge closely related LINE subfamilies, the positions need to be
# adjusted to a standard. The ORF2 is basically of identical length
# between all known subfamilies, so the start of ORF2 is probably the
# best place to match the positions of the 5' end consensus
# sequences. I've taken L1PA2 as a standard for L1, where ORF2 starts
# at 2110. Many 5' end consensus sequences extend to overlap 150 bp
# with the ORF2, but many others only describe sequences further 5' in
# the element, usually because another subfamily has a very closely
# matching sequence over ORF1.
# The "left over in the consensus sequence" number (now reflecting
# how far the consensus extends 3') is adjusted to reflect what
# would be left in a full element (add 3294 for ORF2 + length best
# matching 3' end consensus - 2x 150 bp for overlaps)
# The first number fed to ChangePos is subtracted from the given
# position. Thus, a consensus that is longer than the standard
# gets a positive number, one that is shorter a negative number.
# When making adjustments dependent on position in consensus with the
# subroutine ChangePos begin-limit of doing so should be >= or <
# end-limit when the position number is decreased or increased, resp.
# L1PA4 ORF2 start 2110; L1 ORF2 length 3294 bp
#
#
# L1P4b-e are adjusted to L1P4a
# L1MEf_5end -- 3'end not yet known; used same as L1MDa
# L1MEg_5end -- 3' end not yet known; used same as L1MDa
# L3b, L3_Mars -- Are adjust to the ancient L3 consensus, even
#   if this consensus is incomplete. If this consensus is
#   updated, these adjustments need to be changed
sub preProcessLINE {
  my $chainBegHash   = shift;
  my $chainEndHash   = shift;
  my $conPosCorrHash = shift;
  my $annot          = shift;

  my $DEBUG = 0;
  if ( $DEBUG ) {
    print "preProcessLINE(): Before preprocessing\n";
    $annot->print();
  }

  my $HitName = $annot->getHitName();
  my $ID      = $annot->getPRID();

  if ( defined $RepeatAnnotationData::preProcData{$HitName} ) {
    my $adjChainBeg = 0;
    my $adjChainEnd = 0;

    # Adjust consensus positions
    if (
      defined $RepeatAnnotationData::preProcData{$HitName}->{'relToReference'} )
    {
      print " relToReference = "
          . $RepeatAnnotationData::preProcData{$HitName}->{'relToReference'}
          . "\n"
          if ( $DEBUG );
      $annot->setSubjStart( $annot->getSubjStart() +
             $RepeatAnnotationData::preProcData{$HitName}->{'relToReference'} );
      $annot->setSubjEnd( $annot->getSubjEnd() +
             $RepeatAnnotationData::preProcData{$HitName}->{'relToReference'} );
      $adjChainBeg =
          $chainBegHash->{$ID} +
          $RepeatAnnotationData::preProcData{$HitName}->{'relToReference'};
      $adjChainEnd =
          $chainEndHash->{$ID} +
          $RepeatAnnotationData::preProcData{$HitName}->{'relToReference'};

      # I.e _5ends and full length elements?
      # TODO: Make this a function is3End isOrf etc..
      unless ( $HitName =~ /_3end|_orf2/ ) {
        $conPosCorrHash->{$ID} =
            -$RepeatAnnotationData::preProcData{$HitName}->{'relToReference'};
      }
    }

    # Adjust LeftUnaligned
    if ( defined $RepeatAnnotationData::preProcData{$HitName}->{'3EndLength'} )
    {
      print " 3EndLength = "
          . $RepeatAnnotationData::preProcData{$HitName}->{'3EndLength'} . "\n"
          if ( $DEBUG );
      $annot->setSubjRemaining( $annot->getSubjRemaining() +
                 $RepeatAnnotationData::preProcData{$HitName}->{'3EndLength'} );
    }

    # Rename based on adjusted consensus coordinates
    if ( defined $RepeatAnnotationData::preProcData{$HitName}->{'rangeNames'} )
    {
      foreach my $range (
             @{ $RepeatAnnotationData::preProcData{$HitName}->{'rangeNames'} } )
      {
        my $newHitName = $annot->getHitName();

        # range has maxEnd
        if ( defined $range->{'maxEnd'} && $DEBUG ) {
          print "Considering maxEnd= "
              . $range->{'maxEnd'}
              . " and hitname = "
              . $range->{'name'}
              . " and adjchainend=$adjChainEnd\n";
        }
        if ( defined $range->{'maxEnd'}
             && $adjChainEnd <= $range->{'maxEnd'} )
        {
          $newHitName = $range->{'name'};
        }

        #
        if ( defined $range->{'maxArianEndScore'}
             && ( $adjChainEnd + $annot->getScore() ) <=
             $range->{'maxArianEndScore'} )
        {
          $newHitName = $range->{'name'};
        }

        #
        if ( defined $range->{'minBeg'}
             && $adjChainBeg >= $range->{'minBeg'} )
        {
          $newHitName = $range->{'name'};
        }

        #
        if ( defined $range->{'relLeftUnaligned'}
             && $HitName ne $newHitName )
        {
          print " newHitName = $newHitName and relLeftUnaligned = "
              . $range->{'relLeftUnaligned'} . "\n"
              if ( $DEBUG );
          $annot->setSubjRemaining(
                    $annot->getSubjRemaining() + $range->{'relLeftUnaligned'} );
        }

        #
        $annot->setHitName( $newHitName );
      }
    }
  }
  if ( $DEBUG ) {
    print "After preprocessing\n";
    $annot->print();
    print "cons pos correction = " . $conPosCorrHash->{$ID} . "\n";
  }
}

sub preProcessDNATransp {
  my $chainBegHash = shift;
  my $chainEndHash = shift;
  my $annot        = shift;
  my $repeatDB     = shift;

  if ( defined $repeatDB->{ lc( $annot->getHitName() ) } ) {
    my $dbRec = $repeatDB->{ lc( $annot->getHitName() ) };
    $DEBUG = 0;
    if ( defined $dbRec->{'equiv'} ) {
      my $rangeSlack = 6;
      my %compHash   = ();
      foreach my $equivRec ( @{ $dbRec->{'equiv'} } ) {

        # Sorted in start order
        foreach my $rangeRec ( @{ $equivRec->{'ranges'} } ) {

          # No need to check ranges which start after we end
          last
              if (
                  $chainEndHash->{ $annot->getPRID() } < $rangeRec->{'start'} );

          # Are we contained in this range? Leave some range slack
          # for search run through.
          if ( $chainBegHash->{ $annot->getPRID() } >=
                  $rangeRec->{'start'} - $rangeSlack
               && $chainEndHash->{ $annot->getPRID() } <=
               $rangeRec->{'end'} + $rangeSlack )
          {

            # Contained by a non-unique range
            # Not uniq to this consensus...push comparable
            push @{ $compHash{ $equivRec->{'name'} } }, $rangeRec;
          }
        }
      }
      if ( keys %compHash ) {
        if ( $DEBUG ) {
          print "\n\n***NOT UNIQUE***\n";
          $annot->print();
          print "Comps:\n";
          foreach my $key ( keys( %compHash ) ) {
            print "$key: " . Dumper( $compHash{$key} ) . "\n";
          }
        }
        $annot->setEquivHash( {%compHash} );
      }
      $DEBUG = 0;
    }
  }
}

# Temporarily adjusts consensus sequence position info to allow
# merging of matches to different subfamilies. The position is usually
# later readjusted based on the "conPosCorrection" hash.  Note that positive
# numbers fed to the subroutine are subtracted (longer subfamilies are
# adjusted with higher numbers, shorter with negatives)
sub ChangePos {
  my $chainBegHash   = shift;
  my $chainEndHash   = shift;
  my $conPosCorrHash = shift;
  my $annot          = shift;

  my $ID = $annot->getPRID();
  $conPosCorrHash->{$ID} = shift;
  $annot->setSubjStart( $annot->getSubjStart() - $conPosCorrHash->{$ID} );
  $chainBegHash->{$ID} -= $conPosCorrHash->{$ID};
  $annot->setSubjEnd( $annot->getSubjEnd() - $conPosCorrHash->{$ID} );
  $chainEndHash->{$ID} -= $conPosCorrHash->{$ID};
  $annot->setSubjRemaining( $annot->getSubjRemaining() + $_[ 0 ] )
      if $_[ 0 ];
}

#
# Returns overlap size for a range.
#
# TODO: Replace this with getQueryOverlap in object
#
sub getOverlapSize {
  my $range1Begin = shift;
  my $range1End   = shift;
  my $range2Begin = shift;
  my $range2End   = shift;

  my $overlap = 0;
  if (    $range1Begin >= $range2Begin
       && $range1Begin <= $range2End )
  {

    #      -------
    #   ------
    # or
    #     -----
    #   --------
    if ( $range1End <= $range2End ) {

      #     -----
      #   --------
      $overlap = $range1End - $range1Begin + 1;
    }
    else {

      #      -------
      #   ------
      $overlap = $range2End - $range1Begin + 1;
    }
  }
  elsif (    $range1End >= $range2Begin
          && $range1End <= $range2End )
  {

    #   -------
    #      ------
    # or
    #   --------
    #    -----
    if ( $range1End >= $range2End ) {

      #   --------
      #    -----
      $overlap = $range2End - $range2Begin + 1;
    }
    else {

      #   -------
      #      ------
      $overlap = $range1End - $range2Begin + 1;
    }
  }
  return $overlap;
}

sub isTransposonPairCompatible {
  my $cycle          = shift;
  my $adjCurBegin    = shift;
  my $adjCurEnd      = shift;
  my $adjNextBegin   = shift;
  my $adjNextEnd     = shift;
  my $curStrand      = shift;
  my $curBeginAlign  = shift;
  my $curEndAlign    = shift;
  my $nextBeginAlign = shift;
  my $nextEndAlign   = shift;

  my $DEBUG = 0;
  if ( $DEBUG ) {
    print " adjCurBegEndStrand=$adjCurBegin $adjCurEnd  $curStrand\n";
    print " adjNextBegEnd=$adjNextBegin $adjNextEnd\n";
  }

  my $conGap;
  my $conExt = 0;
  if ( $curStrand ne "C" ) {

    #   ---current--->  (gap)   ---next--->
    $conGap = $adjNextBegin - $adjCurEnd;
    $conExt = ( $adjNextEnd - $adjNextBegin + 1 ) - $conGap;
  }
  else {

    #   <--current---  (gap)   <--next---
    $conGap = $adjCurBegin - $adjNextEnd;
    $conExt = ( $adjNextEnd - $adjNextBegin + 1 ) - $conGap;
  }

  my $seqGap;
  if ( $curBeginAlign > $nextEndAlign ) {

    #   ---next---  (gap)   ---current---
    $seqGap = $curBeginAlign - $nextEndAlign - 1;
  }
  else {

    #   ---current---  (gap)   ---next---
    $seqGap = $nextBeginAlign - $curEndAlign - 1;
  }

  ## TODO:  Do not attach pieces to complete consensi
  print "conGap = $conGap, seqGap = $seqGap: "
      . "Is conGap > -75 && ( conGap < 500 )\n"
      if ( $DEBUG );
  if (
       $conGap > -75
    && $conGap < 500
    && ( ( $curStrand eq "C" && $adjCurBegin - $conExt > -10 ) )
    ## TODO: Must check that we don't go beyond the length
    ##       of the adjusted consensus.
      )
  {
    return ( 1 );
  }
  return ( 0 );
}

##
##
##
sub translateCoord {
  my $unBegin   = shift;
  my $unEnd     = shift;
  my $transHash = shift;

  ## Correction for run-through ranges
  $unBegin = $transHash->{'start'} if ( $unBegin < $transHash->{'start'} );
  $unEnd   = $transHash->{'end'}   if ( $unEnd > $transHash->{'end'} );

  my $rangeLen   = $transHash->{'end'} - $transHash->{'start'} + 1;
  my $eqRangeLen = $transHash->{'eqend'} - $transHash->{'eqstart'} + 1;
  my $conBegin = sprintf(
                          "%0.d",
                          (
                            (
                              ( $unBegin - $transHash->{'start'} ) * $eqRangeLen
                            ) / $rangeLen
                              ) + $transHash->{'eqstart'}
  );
  my $conEnd = sprintf(
                        "%0.d",
                        (
                          ( ( $unEnd - $transHash->{'start'} ) * $eqRangeLen ) /
                              $rangeLen
                            ) + $transHash->{'eqstart'}
  );

  return ( $conBegin, $conEnd );
}

#
# isTooDiverged():
#
# Return true of past element substitution percentage is 2x as
# high *and* greater than 10% higher than the current elements
# substitution percentage.
#
# A true value indicates that the past element is neither likely to
# be related to the current element nor is it likely that a
# fragment of the younger current element lies beyond the past element.
#
sub isTooDiverged {
  my $currentElementPctSub = shift;
  my $pastElementPctSub    = shift;
  $pastElementPctSub > 2 * $currentElementPctSub
      && $pastElementPctSub > $currentElementPctSub + 10;
}

sub printHitArrayList {
  my $sortedAnnotationsList = shift;

  my $cycleAnnotIter = $sortedAnnotationsList->getIterator();
  my %newID          = ();
  my $ind            = 1;
  while ( $cycleAnnotIter->hasNext() ) {
    my $currentAnnot = $cycleAnnotIter->next();
    if (    $currentAnnot->getLeftLinkedHit()
         && $newID{ $currentAnnot->getLeftLinkedHit()->getUniqID() } > 0 )
    {
      $newID{ $currentAnnot->getUniqID() } =
          $newID{ $currentAnnot->getLeftLinkedHit()->getUniqID() };
    }
    else {
      $newID{ $currentAnnot->getUniqID() } = $ind++;
    }
  }

  $cycleAnnotIter = $sortedAnnotationsList->getIterator();
  print "RESULTS OF JOINS\n";
  while ( $cycleAnnotIter->hasNext() ) {
    my $currentAnnot = $cycleAnnotIter->next();
    $currentAnnot->print( 1 );
    print "" . $newID{ $currentAnnot->getUniqID() } . " ";
    print "<-" if ( $currentAnnot->getLeftLinkedHit() );
    print "->" if ( $currentAnnot->getRightLinkedHit() );
    print "\n";
    if (    $currentAnnot->getScore() == 8027
         && $currentAnnot->getLeftLinkedHit() )
    {
      print " <=== ";
      $currentAnnot->getLeftLinkedHit()->print( 1 );
      print "\n";
    }
    ## print source annots
    printSTDOUTSourceAnnots( $currentAnnot );
  }
  print "END RESULTS OF JOINS\n";

}

sub scoreRefinedSINEPair {
  my $annot1             = shift;
  my $annot2             = shift;
  my $compatibleDistance = shift;

  # Establish position order
  my $DEBUG      = 0;
  my $leftAnnot  = $annot1;
  my $rightAnnot = $annot2;
  if ( $annot1->comparePositionOrder( $annot2 ) > 0 ) {
    $leftAnnot  = $annot2;
    $rightAnnot = $annot1;
  }

  if ( $DEBUG ) {
    print "   scoreRefinedSINEPair():\n    ";
    $leftAnnot->print();
    print "   vs ";
    $rightAnnot->print();
  }

  my $score = 0;
  if (
       $leftAnnot->getHitName()      eq $rightAnnot->getHitName()
    && $rightAnnot->getOrientation() eq $leftAnnot->getOrientation()
    && $rightAnnot->getQueryOverlap( $leftAnnot ) <= 21
    && -( $rightAnnot->getConsensusOverlap( $leftAnnot ) ) <= 100
    && -( $rightAnnot->getQueryOverlap( $leftAnnot ) ) <= 1000

    && ( $rightAnnot->getConsensusOverlap( $leftAnnot ) <= 21
         || -( $rightAnnot->getQueryOverlap( $leftAnnot ) ) < 0
         && $rightAnnot->getConsensusOverlap( $leftAnnot ) -
         $rightAnnot->getQueryOverlap( $leftAnnot ) <= 20 )
      )
  {
    my $gap = $rightAnnot->getQueryStart() - $leftAnnot->getQueryEnd();
    $gap = 1 if ( $gap == 0 );
    $score =
        ( $rightAnnot->getScore() + $leftAnnot->getScore() ) *
        ( 1 / ( $compatibleDistance ) ) * ( 1 / ( $gap ) );

    if ( $DEBUG ) {
      print "scoreRefinedSINEPair():   Scoring ( $score ) [ "
          . ( $rightAnnot->getQueryStart() - $leftAnnot->getQueryEnd() )
          . " ] to:" . "\n";
      print "  -> ";
      $leftAnnot->print();
      print "  -> ";
      $rightAnnot->print();
    }
  }

  print "newScore.... score = $score\n" if ( $DEBUG );
  return $score;

}

sub scoreGenericPair {
  my $annot1               = shift;
  my $annot2               = shift;
  my $elementDistance      = shift;
  my $classElementDistance = shift;

  # Establish position order
  my $DEBUG      = 0;
  my $leftAnnot  = $annot1;
  my $rightAnnot = $annot2;
  if ( $annot1->comparePositionOrder( $annot2 ) > 0 ) {
    $leftAnnot  = $annot2;
    $rightAnnot = $annot1;
  }

  my $score          = 0;
  my $currentHitName = $rightAnnot->getHitName();
  my $prevHitName    = $leftAnnot->getHitName();
  if (    $leftAnnot->getQueryName() eq $rightAnnot->getQueryName()
       && $rightAnnot->getOrientation() eq $leftAnnot->getOrientation() )
  {
    print "   --- Same orient/seq\n" if ( $DEBUG );
    print "   --- qo = "
        . $rightAnnot->getQueryOverlap( $leftAnnot )
        . "\n       co = "
        . $rightAnnot->getConsensusOverlap( $leftAnnot ) . "\n"
        if ( $DEBUG );
    if (
         $rightAnnot->getStage() == $leftAnnot->getStage()
         && (    $currentHitName eq $prevHitName
              || $currentHitName =~ /$prevHitName/
              || $prevHitName    =~ /$currentHitName/ )
         && -( $rightAnnot->getQueryOverlap( $leftAnnot ) ) <= 10
         && -( $rightAnnot->getConsensusOverlap( $leftAnnot ) ) <= 100
         && ( $rightAnnot->getConsensusOverlap( $leftAnnot ) <= 21
              || -( $rightAnnot->getQueryOverlap( $leftAnnot ) ) < 0
              && $rightAnnot->getConsensusOverlap( $leftAnnot ) -
              $rightAnnot->getQueryOverlap( $leftAnnot ) <= 20 )
        )
    {
      $score = 1;
    }
    my $HitName      = $rightAnnot->getHitName();
    my $shortHitName = $HitName;
    $shortHitName =~ s/(\S+\d)[a-zA-Z]$/$1/;
    $shortHitName = quotemeta $shortHitName;

    # Less stringent
    if ( $score == 0 && $leftAnnot->getHitName() =~ /^$shortHitName/ ) {
      print "scoreGenericPair():  last chancy test ( names compat )\n"
          if ( $DEBUG );
      my $gapMax = 2500;
      $gapMax *= 1.5
          if ( $leftAnnot->getHitName() eq $rightAnnot->getHitName() );

      # Need to revise the way div diff is calc'd
      my $divDiff = $leftAnnot->getPctDiverge() - $rightAnnot->getPctDiverge();
      print "scoreGenericPair(): gapMax = $gapMax "
          . "divDiff = $divDiff elemedist = $elementDistance\n"
          if ( $DEBUG );
      $divDiff = -$divDiff if ( $divDiff < 0 );
      $gapMax *= ( 10 - $divDiff ) / 10;
      $gapMax *= ( 15 - $elementDistance ) / 15;
      print "scoreGenericPair(): gapMax = $gapMax " . "divDiff = $divDiff\n"
          if ( $DEBUG );
      if (    $leftAnnot->getConsensusOverlap( $rightAnnot ) < 33
           && $leftAnnot->getConsensusOverlap( $rightAnnot ) > -$gapMax )
      {
        print "scoreGenericPair():   Hmmm....I guess so.. " . "\n"
            if ( $DEBUG );
        $score = 0.5;
      }
    }
  }
  return ( $score );
}

#####################################################################
################ C O N T A I N S   M E T A   D A T A ################
#################           metadata                 ################
#####################################################################

# TODO: This used to be part of the SINE code.  We need to include
#       a refinement MIR eventually.
#    # if SINE/ALU
#       # Make MIR's generic if they are not in the
#       # unique regions.  NOTE: Unique regions are
#       # a good possibility for generalization.
#  elsif ( $HitName eq 'MIR3' ) {
#    if (    $chainBegHash->{$ID} >= 16
#         && $chainEndHash->{$ID} <= 153 )
#    {
#      $HitName = 'MIR';
#    }
#  }

sub preProcessLTR {
  my $chainBegHash   = shift;
  my $chainEndHash   = shift;
  my $conPosCorrHash = shift;
  my $annot          = shift;

  my $ID      = $annot->getPRID();
  my $HitName = $annot->getHitName();

  # all MLT2s adjusted to MLT2B3 or 4
  if ( $chainBegHash->{$ID} > 180 ) {
    if ( $HitName =~ /^MLT2A/ ) {
      &ChangePos( $chainBegHash, $chainEndHash, $conPosCorrHash, $annot, -108 )
          if $chainBegHash->{$ID} > 270;
    }
    elsif ( $HitName =~ /^MLT2B[12]$/ ) {
      &ChangePos( $chainBegHash, $chainEndHash, $conPosCorrHash, $annot, -47 )
          if $chainBegHash->{$ID} > 265;
    }
    elsif ( $HitName eq "MLT2B5" ) {
      if ( $chainBegHash->{$ID} > 415 ) {
        &ChangePos( $chainBegHash, $chainEndHash, $conPosCorrHash, $annot,
                    162 );
      }
      else {
        &ChangePos( $chainBegHash, $chainEndHash, $conPosCorrHash, $annot,
                    116 );
      }
    }
    elsif ( $HitName eq "MLT2C1" ) {
      &ChangePos( $chainBegHash, $chainEndHash, $conPosCorrHash, $annot, -166 )
          if $chainBegHash->{$ID} > 220;
    }
    elsif ( $HitName eq "MLT2C2" ) {
      &ChangePos( $chainBegHash, $chainEndHash, $conPosCorrHash, $annot, -95 )
          if $chainBegHash->{$ID} > 275;
    }
    elsif ( $HitName eq "MLT2D" ) {
      &ChangePos( $chainBegHash, $chainEndHash, $conPosCorrHash, $annot, -146 )
          if $chainBegHash->{$ID} > 225;
    }
    elsif ( $HitName eq "MLT2E" ) {
      &ChangePos( $chainBegHash, $chainEndHash, $conPosCorrHash, $annot, 65 )
          if $chainBegHash->{$ID} > 520;
    }
    elsif ( $HitName eq "MLT2F" ) {
      &ChangePos( $chainBegHash, $chainEndHash, $conPosCorrHash, $annot, 100 )
          if $chainBegHash->{$ID} > 550;
    }
  }
}

sub scoreSINEPair {
  my $annot1          = shift;
  my $annot2          = shift;
  my $elementDistance = shift;

  # Establish position order
  my $DEBUG      = 0;
  my $leftAnnot  = $annot1;
  my $rightAnnot = $annot2;
  if ( $annot1->comparePositionOrder( $annot2 ) > 0 ) {
    $leftAnnot  = $annot2;
    $rightAnnot = $annot1;
  }

  my $score          = 0;
  my $currentHitName = $rightAnnot->getHitName();
  my $prevHitName    = $leftAnnot->getHitName();
  if (    $leftAnnot->getQueryName() eq $rightAnnot->getQueryName()
       && $rightAnnot->getOrientation() eq $leftAnnot->getOrientation() )
  {
    print "   --- Same orient/seq\n" if ( $DEBUG );
    print "   --- qo = "
        . $rightAnnot->getQueryOverlap( $leftAnnot )
        . "\n       co = "
        . $rightAnnot->getConsensusOverlap( $leftAnnot ) . "\n"
        if ( $DEBUG );
    if (
      $rightAnnot->getStage() == $leftAnnot->getStage()
      && (    $currentHitName eq $prevHitName
           || $currentHitName =~ /$prevHitName/
           || $prevHitName    =~ /$currentHitName/ )
      && -( $rightAnnot->getQueryOverlap( $leftAnnot ) ) <= 10
      && -( $rightAnnot->getConsensusOverlap( $leftAnnot ) ) <= 100

      && ( $rightAnnot->getConsensusOverlap( $leftAnnot ) <= 21
           || -( $rightAnnot->getQueryOverlap( $leftAnnot ) ) < 0
           && $rightAnnot->getConsensusOverlap( $leftAnnot ) -
           $rightAnnot->getQueryOverlap( $leftAnnot ) <= 20 )
        )
    {
      print "    --- good score  ( 1 )\n" if ( $DEBUG );
      $score = 1;
    }
    my $HitName      = $rightAnnot->getHitName();
    my $shortHitName = $HitName;
    if ( $HitName =~ /^Alu/ ) {
      $shortHitName =~ s/(^\w{5}).*/$1/;
    }
    else {
      $shortHitName =~ s/(\S+\d)[a-zA-Z]$/$1/;
    }
    $shortHitName = quotemeta $shortHitName;

    # Less stringent
    if ( $score == 0 && $leftAnnot->getHitName() =~ /^$shortHitName/ ) {
      print "scoreSINEPair():  last chancy test ( names compat )\n"
          if ( $DEBUG );
      my $gapMax = 2500;
      $gapMax *= 1.5
          if ( $leftAnnot->getHitName() eq $rightAnnot->getHitName() );

      # Need to revise the way div diff is calc'd
      my $divDiff = $leftAnnot->getPctDiverge() - $rightAnnot->getPctDiverge();
      print "scoreSINEPair(): gapMax = $gapMax "
          . "divDiff = $divDiff elemedist = $elementDistance\n"
          if ( $DEBUG );
      $divDiff = -$divDiff if ( $divDiff < 0 );
      $gapMax *= ( 10 - $divDiff ) / 10;
      $gapMax *= ( 15 - $elementDistance ) / 15;
      print "scoreSINEPair(): gapMax = $gapMax " . "divDiff = $divDiff\n"
          if ( $DEBUG );
      if (    $leftAnnot->getConsensusOverlap( $rightAnnot ) < 33
           && $leftAnnot->getConsensusOverlap( $rightAnnot ) > -$gapMax )
      {
        print "scoreSINEPair():   Hmmm....I guess so.. " . "\n"
            if ( $DEBUG );
        $score = 0.5;
      }
    }
  }
  return ( $score );
}

sub scoreLTRPair {
  my $annot1      = shift;
  my $annot2      = shift;
  my $eleDistance = shift;
  my $ltrDistance = shift;

  my $DEBUG = 0;
  if ( $DEBUG ) {
    print "scoreLTRPair(): Considering...\n";
    $annot1->print();
    $annot2->print();
  }

  # Establish position order
  my $leftAnnot  = $annot1;
  my $rightAnnot = $annot2;
  if ( $annot1->comparePositionOrder( $annot2 ) > 0 ) {
    $leftAnnot  = $annot2;
    $rightAnnot = $annot1;
  }

  my $intScore = 0;
  my $hybrid   = 0;

  # Ensure compatible names and orientation agreement
  if (    &areLTRNamesCompat( $annot1, $annot2 )
       && $annot1->getOrientation() eq $annot2->getOrientation() )
  {
    print "scoreLTRPair():  Names are compatible\n" if ( $DEBUG );

    #
    # Model component specific checks
    #
    if ( &isInternal( $annot1 ) && &isInternal( $annot2 ) ) {
      print "scoreLTRPair():   Both internals\n" if ( $DEBUG );

      # Both internal
      #    Names are compatible loosely compatible.
      my $CO = $leftAnnot->getConsensusOverlap( $rightAnnot );
      my $CG = -$CO;

      if (    $CO <= 111 && $CG <= 1234
           || $leftAnnot->getHitName() eq $rightAnnot->getHitName()
           && $CO <= 111
           && $CG <= 5555 )
      {
        print "scoreLTRPair():   INT Good One\n" if ( $DEBUG );
        $intScore = 1;
      }
      else {
        print "scoreLTRPair():   Failed: CO=$CO>111, " . "CG=$CG>1234 etc..\n"
            if ( $DEBUG );
      }

    }
    elsif ( &isLTR( $annot1 ) && &isLTR( $annot2 ) ) {
      print "scoreLTRPair():   Both ltrs\n" if ( $DEBUG );

      # Both LTR
      #   Join if:
      #      Class is MaLR or
      #      Both are MLT2.. variations or
      #      Hitnames are shorthitname alike
      #    And
      #      LastFields = 5
      #      CG <= 220 - ( number of LTRs distant + 1 ) * 20
      #      CO <= 50
      #      Same orientation
      #    And
      #      Unaligned edges are >= 10bp long
      if (
           (
             (
                  $annot1->getClassName() =~ /ERVL-MaLR/
               && $annot2->getClassName() =~ /ERVL-MaLR/
             )
             || (    $annot1->getHitName() =~ /MLT2/
                  && $annot2->getHitName() =~ /MLT2/ )
             || &areLTRNamesCompat( $annot1, $annot2 ) == 1
           )
           && ( $annot1->isMasked() && $annot2->isMasked() )
           && ( $leftAnnot->getConsensusOverlap( $rightAnnot ) >
                -( 220 - $ltrDistance * 20 ) )
           && ( $leftAnnot->getConsensusOverlap( $rightAnnot ) <= 50 )
           && ( $leftAnnot->getOrientation() eq $rightAnnot->getOrientation() )
          )
      {
        print "scoreLTRPair():      Good distance\n" if ( $DEBUG );
        if (

          # --ltr--> --ltr-->
          (
               $annot1->getOrientation() eq "+"
            && $leftAnnot->getSubjRemaining() >= 10
            && $rightAnnot->getSubjStart() >= 10
          )

          # <--ltr-- <--ltr---
          || (    $annot2->getOrientation() eq "C"
               && $leftAnnot->getSubjStart() >= 10
               && $rightAnnot->getSubjRemaining() >= 10 )
            )
        {
          $intScore = 1;
        }
      }
      elsif ( $DEBUG ) {
        print "scoreLTRPair(): areLTRNamesCompat="
            . &areLTRNamesCompat( $annot1, $annot2 ) . "\n"
            . "    annot1Masked = "
            . $annot1->isMasked() . "\n"
            . "    annot2Masked = "
            . $annot2->isMasked() . "\n"
            . "    annot1Id = "
            . $annot1->getLineageId() . "\n"
            . "    annot2Id = "
            . $annot2->getLineageId() . "\n";
      }
    }
    else {

      # Mixture of internal and ltr
      $hybrid = 1;
      print "scoreLTRPair():   Mixture of ltr/internal: "
          . "eleDist = $eleDistance\n"
          if ( $DEBUG );

      # Mixture of internal and ltr fragments
      # Stringent:
      #    - Names are compatible: loosely compatible.
      #    - <= 33 bp unaligned on each fragment
      #    - Same orientation
      #    - No more than 2 insertions
      #    - No more than 350 bp gap in query
      # No more than 2 insertions

      ## TODO: Should lower stringency based on the exactness of the
      ## flanking name.
      if (    $eleDistance <= 2
           && $annot1->getQueryOverlap( $annot2 ) > -350 )
      {
        print "scoreLTRPair():  eleDistance OK and queryOverlap OK\n"
            if ( $DEBUG );
        if (

          # ----> ---int--->
          # ---int--> ----->
          (
               $annot1->getOrientation() eq "+"
            && $leftAnnot->getSubjRemaining() <= 33
            && $rightAnnot->getSubjStart() <= 33
          )

          # <---- <--int---
          # <---int-- <-----
          || (    $annot2->getOrientation() eq "C"
               && $leftAnnot->getSubjStart() <= 33
               && $rightAnnot->getSubjRemaining() <= 33 )
            )
        {
          print "scoreLTRPair():   Good One\n" if ( $DEBUG );
          $intScore = 1;
        }
      }
    }

    # Less stringent
    # Loose applies to all combinations of elements:
    #    - No more than 10,000 bp gap in query
    #    - Same orientation
    #    - No intervening element with > 1.33 * PctSubst than
    #      the *higher-query-position* member of the pair.
    #    - Similar names: shorthitname rules
    #    - Gap < 500
    #        gapallowed = 1.5*2500
    #           if exact name
    #        diff = difference in substitution ( max 10% )
    #        gapallowed *= %difference in substition
    #    - gapallowed *= # of intervening elements ( max 10 )
    #    - Consensus overlap is < 33 and the gap < gapallowed
    if ( $intScore == 0 && &areLTRNamesCompat( $annot1, $annot2 ) == 1 ) {
      print "scoreLTRPair():  last chance test ( names compat )\n"
          if ( $DEBUG );
      my $gapMax = 2500;
      $gapMax *= 1.5 if ( $annot1->getHitName() eq $annot2->getHitName() );

      # Need to revise the way div diff is calc'd
      my $divDiff = $annot1->getPctDiverge() - $annot2->getPctDiverge();
      $divDiff = -$divDiff if ( $divDiff < 0 );
      $gapMax *= ( 10 - $divDiff ) / 10;
      $gapMax *= ( 10 - $eleDistance ) / 10;
      if (
           $leftAnnot->getConsensusOverlap( $rightAnnot ) > -$gapMax
           && (
                $hybrid
                || (    $leftAnnot->getConsensusOverlap( $rightAnnot ) < 33
                     && $annot1->isMasked()
                     && $annot2->isMasked() )
           )
          )
      {
        print "scoreLTRPair():   Ok\n" if ( $DEBUG );
        $intScore = 0.5;
      }
      elsif ( $DEBUG ) {
        print "scoreLTRPair():   Not Ok: cg = "
            . $leftAnnot->getConsensusGap( $rightAnnot ) . "\n";
        print "scoreLTRPair():           co = "
            . $leftAnnot->getConsensusOverlap( $rightAnnot )
            . "< gapMax = -$gapMax  or \n"
            . "                           hybrid = $hybrid = 0 , co > 33\n";
        print "scoreLTRPair():            or "
            . $leftAnnot->isMasked() . " != "
            . $rightAnnot->isMasked()
            . " != 5\n";
      }
    }

    ## Last last chance from cycle 4
    if ( $intScore == 0 ) {
      print "scoreLTRPair():  last last chance test\n"
          if ( $DEBUG );
      if (    $leftAnnot->getQueryEnd() >= $rightAnnot->getQueryStart()
           && $rightAnnot->getQueryEnd() > $leftAnnot->getQueryEnd() )
      {

        #
        # If these element shave the same class, orientation,
        # similar names with small overlap or simply just
        # a large overlap then join them!!!  Arghhh
        #
        if (    &areLTRNamesCompat( $annot1, $annot2 ) == 1
             && $rightAnnot->getQueryStart() <= $leftAnnot->getQueryEnd() - 12
             || $rightAnnot->getQueryStart() <= $leftAnnot->getQueryEnd() - 33 )
        {
          print "scoreLTRPair():   Well if you insist\n" if ( $DEBUG );
          $intScore = 0.25;
        }
      }
    }

  }
  elsif ( $DEBUG ) {
    print "scoreLTRPair():   Names are not compatible\n";
  }

  if ( $intScore ) {
    print "Using elementdistance = $eleDistance\n" if ( $DEBUG );
    $intScore += 1 / $eleDistance;
  }

  print "scoreLTRPair():    Returning score = $intScore\n" if ( $DEBUG );
  return $intScore;
}    # scoreLTRPair()

sub isInternal {
  my $annot = shift;

  my $HitName = $annot->getHitName();

  if (
       ( $HitName !~ /LTR/ || $HitName =~ /int$/ )
       && (    $HitName =~ /int|ERV|PRIMA41|Harlequin|HUERS/i
            || $HitName =~ /.*[-_]I(_\S+)?$/
            || $HitName =~ /MMERGLN|MMURS|MMVL30|MULV|MURVY|ETn|^IAP/ )
      )
  {
    return ( 1 );
  }
  return ( 0 );
}

sub isLTR {
  my $annot = shift;

  return ( !&isInternal( $annot ) );
}

sub areLTRNamesCompat {
  my $annot1 = shift;
  my $annot2 = shift;

  my $annot1Name  = $annot1->getHitName();
  my $annot1Class = $annot1->getClassName();
  my $annot2Name  = $annot2->getHitName();
  my $annot2Class = $annot2->getClassName();
  my $DEBUG       = 0;

  if ( $DEBUG ) {
    print "areLTRNamesCompat(): $annot1Name vs $annot2Name\n";
  }

  #
  # Rules when annot1Name is internal
  #
  if ( $annot1Class eq $annot2Class ) {
    my $shortHitName = $annot2Name;
    if ( $annot2Name =~ /^MER\d{2}|^LTR\d{2}/ ) {
      $shortHitName =~ s/(^\w{5}).*/$1/;
    }
    elsif ( $annot2Name =~ /^MER\d[A-Z_a-z]|^LTR\d[A-Z_a-z]|ORR1/ ) {
      $shortHitName =~ s/(^\w{4}).*/$1/;
    }
    else {
      $shortHitName =~ s/(\S+\d)[\-a-zA-Z].*/$1/;
    }
    $shortHitName = quotemeta $shortHitName;

    print "areLTRNamesCompat(): comparing $annot1Name =~ $shortHitName\n"
        if ( $DEBUG );

    if ( $annot1Name =~ /$shortHitName/ ) {
      print "areLTRNamesCompat(): returning 1\n" if ( $DEBUG );
      return ( 1 );
    }

    if (
         $annot1Class !~ /ERVL-MaLR/
      && $annot2Name !~ /pTR5/

      # pTR5 is not a product of retrovrial transposition but
      # appears like a "processed pseudogene". Obviously cant
      # act like an LTR.
      # The following are all MaLR names
      || (    $annot1Name =~ /^THE1/ && $annot2Name =~ /THE1|MST[AB-]/
           || $annot1Name =~ /^MST/ && $annot2Name =~ /THE1[BC-]|MST|MLT1[AB-]/
           || $annot1Name =~ /^MLT-int/
           && $annot2Name =~ /THE1C|MST[ABCD]|MLT1[ABC]/
           || $annot1Name =~ /^MLT1[A-]/ && $annot2Name =~ /MST[CD-]|MLT1[ABC-]/
           || $annot1Name =~ /^MLT1F/ && $annot2Name =~ /MLT1[DEFGHIJKL]/
           || $annot1Name =~ /MLT1[B-H]/ && $annot2Name =~ /MLT1/
           || $annot1Name =~ /^ORR1/ && $annot2Name =~ /^ORR1|^MT/
           || $annot1Name =~ /^MT/ && $annot2Name =~ /^MT|^ORR1/ )
        )
    {
      print "areLTRNamesCompat(): returning 0.5\n" if ( $DEBUG );
      return ( 0.5 );
    }
    if (
         $annot2Class !~ /ERVL-MaLR/
         || ( $annot2Name =~ /^THE1/ && $annot1Name =~ /THE1|MST[AB-]/
           || $annot2Name =~ /^MST/ && $annot1Name =~ /THE1[BC-]|MST|MLT1[AB-]/
           || $annot2Name =~ /^MLT-int/
           && $annot1Name =~ /THE1C|MST[ABCD]|MLT1[ABC]/
           || $annot2Name =~ /^MLT1[A-]/ && $annot1Name =~ /MST[CD-]|MLT1[ABC-]/
           || $annot2Name =~ /^MLT1F/ && $annot1Name =~ /MLT1[DEFGHIJKL]/
           || $annot2Name =~ /MLT1[B-H]/ && $annot1Name =~ /MLT1/
           || $annot2Name =~ /^ORR1/ && $annot1Name =~ /^ORR1|^MT/
           || $annot2Name =~ /^MT/ && $annot1Name =~ /^MT|^ORR1/ )
        )
    {
      print "areLTRNamesCompat(): returning 0.5\n" if ( $DEBUG );
      return ( 0.5 );
    }
  }

  # Not compat
  if ( $DEBUG ) {
    print "areLTRNamesCompat(): Not compatible!\n";
  }
  return ( 0 );

}

##########################################################################
##########################################################################
##########################################################################

##-------------------------------------------------------------------------##
## Use:  my ( $seq_cnt, $totalSeqLen, $nonMaskedSeqLen, $totGCLevel,
##             $totBPMasked ) =
##                    &maskSequence ( $seqDB, $annotationFile,
##                                    $outputFile );
##  Returns
##
##     $seq_cnt:          The number of sequences in the FASTA file.
##     $totalSeqLen:      The absoulte length of all sequences combined.
##     $nonMaskedSeqLen:  Length of sequence (excluding runs of >20 N's
##                         and X's) of the pre-masked sequence.
##     $totGCLevel:       The GC content of the original sequence.
##     $totBPMasked:      The total bp we masked
##
##-------------------------------------------------------------------------##
sub maskSequence {
  my $maskFormat     = shift;
  my $seqDB          = shift;
  my $annotationFile = shift;
  my $outputFile     = shift;

  print "ProcessRepeats::maskSequence()\n" if ( $DEBUG );

  my %annots = ();

  #
  # Open up a search results object
  #
  my $searchResults =
      CrossmatchSearchEngine::parseOutput( searchOutput => $annotationFile );

  #
  # Read in annotations and throw away the rest
  #
  my $prevResult;
  for ( my $i = 0 ; $i < $searchResults->size() ; $i++ ) {
    my $result = $searchResults->get( $i );
    my $start  = $result->getQueryStart();
    my $end    = $result->getQueryEnd();
    if (    defined $prevResult
         && $prevResult->getQueryName() eq $result->getQueryName()
         && $prevResult->getQueryEnd() >= $start )
    {
      next if ( $prevResult->getQueryEnd() >= $end );
      $start = $prevResult->getQueryEnd() + 1;
    }
    push @{ $annots{ $result->getQueryName() } },
        {
          'begin' => $start,
          'end'   => $end
        };
    $prevResult = $result;
  }
  undef $searchResults;

  my @seqIDs     = $seqDB->getIDs();
  my $seq_cnt    = scalar( @seqIDs );
  my $sublength  = $seqDB->getSubtLength();
  my $totGCLevel = 100 * $seqDB->getGCLength() / $sublength;
  $totGCLevel = sprintf "%4.2f", $totGCLevel;
  my $totalSeqLen     = 0;
  my $totBPMasked     = 0;
  my $nonMaskedSeqLen = 0;
  my $workseq         = "";
  open OUTFILE, ">$outputFile";

  foreach my $seqID ( @seqIDs ) {
    my $seq = $seqDB->getSequence( $seqID );
    $totalSeqLen += length $seq;
    $workseq = $seq;
    $nonMaskedSeqLen += length $workseq;

    while ( $workseq =~ /([X,N]{20,})/ig ) {
      $nonMaskedSeqLen -= length( $1 );
    }

    foreach my $posRec ( @{ $annots{$seqID} } ) {
      my $beginPos = $posRec->{'begin'};
      my $endPos   = $posRec->{'end'};
      my $repLen   = $endPos - $beginPos + 1;
      if ( $maskFormat eq 'xsmall' ) {
        substr( $seq, $beginPos - 1, $repLen ) =
            lc( substr( $seq, $beginPos - 1, $repLen ) );
      }
      elsif ( $maskFormat eq 'x' ) {
        substr( $seq, $beginPos - 1, $repLen ) = "X" x ( $repLen );
      }
      else {
        substr( $seq, $beginPos - 1, $repLen ) = "N" x ( $repLen );
      }
      $totBPMasked += $repLen;
    }
    print OUTFILE ">" . $seqID;
    my $desc = $seqDB->getDescription( $seqID );
    if ( $desc ne "" ) {
      print OUTFILE " " . $desc;
    }
    print OUTFILE "\n";
    $seq =~ s/(\S{50})/$1\n/g;
    $seq .= "\n"
        unless ( $seq =~ /.*\n+$/s );
    print OUTFILE $seq;
  }
  close OUTFILE;

  return ( $seq_cnt, $totalSeqLen, $nonMaskedSeqLen, $totGCLevel,
           $totBPMasked );
}

sub parseCATFile {
  my %nameValuePairs = @_;

  croak( "parseCATFile(): Missing 'file' parameter!\n" )
      if ( !defined $nameValuePairs{'file'} );

  my $optParams = "";
  my $resultCollection;

  my $INCAT;
  if ( $nameValuePairs{'file'} =~ /.*\.gz$/ ) {
    open( $INCAT, "gunzip -c $nameValuePairs{'file'} |" )
        || die "Can\'t open file $nameValuePairs{'file'}\n";
  }
  else {
    open( $INCAT, "$nameValuePairs{'file'}" )
        || die "Can\'t open file $nameValuePairs{'file'}\n";
  }

  if ( defined $nameValuePairs{'noAlignData'} ) {
    $resultCollection = CrossmatchSearchEngine::parseOutput(
                                                         searchOutput => $INCAT,
                                                         excludeAlignments => 1
    );
  }
  else {
    $resultCollection =
        CrossmatchSearchEngine::parseOutput( searchOutput => $INCAT );
  }
  close $INCAT;

  if (    $resultCollection->size()
       && $resultCollection->get( 0 )->getLineageId !~ /\[?[mc]_b.*/ )
  {
    die "\n    The input file:\n        $nameValuePairs{'file'}\n"
        . "    was generated using an older RepeatMasker format.\n"
        . "    Please use ProcessRepeats from RepeatMasker v3.3.0\n"
        . "    to process this file.\n\n";
  }

  # Recast
  for ( my $i = 0 ; $i < $resultCollection->size() ; $i++ ) {
    bless $resultCollection->get( $i ), "PRSearchResult";
  }

  return ( $resultCollection );

}

package main;
