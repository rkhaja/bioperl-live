
#
# BioPerl module for Bio::AnnSeq
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::AnnSeq - Annotated Sequence

=head1 SYNOPSIS

    $stream = Bio::AnnSeqIO->new(-file => 'my.embl',-format => 'EMBL')

    foreach $annseq ( $stream->next_annseq() ) {
	foreach $feat ( $annseq->all_SeqFeatures() ) {
	    print "Feature ",$feat->primary_tag," at ", $feat->start, " ",$feat->end, "\n";
	}
    }

=head1 DESCRIPTION

An AnnSeq is a sequence with sequence features placed on them. The
AnnSeq object is not a Bio::Seq object, but contains one. This is an
important distinction from other packages which tend to have either a
single sequence object with features, or an inheritence relationship
between a "large" and "small" sequence object. In bioperl we have 3
main players:

  Bio::Seq - just the sequence, nothing else.
  Bio::SeqFeature - a location on a sequence, potentially with a sequence.
                    and annotation
  Bio::AnnSeq - A sequence and a collection of seqfeatures (an aggregate) with
                its own annotation.

Although bioperl is not tied to file formats heavily, these distrinctions do map to file formats
sensibly and for some bioinformaticians this might help you:

  Bio::Seq - Fasta file of a sequence
  Bio::SeqFeature - A single entry in an EMBL/GenBank/DDBJ feature table
  Bio::AnnSeq - A single EMBL/GenBank/DDBJ entry

By having this split we avoid alot of nasty ciricular references
(seqfeatures can hold a reference to a sequence without the sequence
holding a reference to the seqfeature).

Ian Korf really helped in the design of the AnnSeq and SeqFeature system.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your comments and suggestions preferably
 to one of the Bioperl mailing lists.
Your participation is much appreciated.

  vsns-bcd-perl@lists.uni-bielefeld.de          - General discussion
  vsns-bcd-perl-guts@lists.uni-bielefeld.de     - Technically-oriented discussion
  http://bio.perl.org/MailList.html             - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bio.perl.org
  http://bio.perl.org/bioperl-bugs/

=head1 AUTHOR - Ewan Birney, inspired by Ian Korf objects

Email birney@sanger.ac.uk

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::AnnSeq;
use vars qw($AUTOLOAD @ISA);
use strict;
use Bio::AnnSeqI;

# Object preamble - inheriets from Bio::Root::Object

use Bio::Root::Object;
use Bio::Annotation;
use Bio::Seq;

@ISA = qw(Bio::Root::Object Bio::AnnSeqI);
# new() is inherited from Bio::Root::Object

# _initialize is where the heavy stuff will happen when new is called

sub _initialize {
  my($self,@args) = @_;
  my($ann);
  my $make = $self->SUPER::_initialize;
  $self->{'_as_feat'} = [];
  $ann = new Bio::Annotation;
  $self->annotation($ann);

# set stuff in self from @args
 return $make; # success - we hope!
}

=head2 seq

 Title   : seq
 Usage   : $obj->seq($newval)
 Function: 
 Example : 
 Returns : value of seq
 Args    : newvalue (optional)


=cut

sub seq{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'seq'} = $value;
      # descend down over all seqfeature objects, seeing whether they
      # want an attached seq.

      foreach my $sf ( $obj->top_SeqFeatures() ) {
	  if( $sf->can("attach_seq") ) {
	      $sf->attach_seq($value);
	  }
      }

    }
    return $obj->{'seq'};

}

=head2 annotation

 Title   : annotation
 Usage   : $obj->annotation($seq_obj)
 Function: 
 Example : 
 Returns : value of annotation
 Args    : newvalue (optional)


=cut

sub annotation{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'annotation'} = $value;
    }
    return $obj->{'annotation'};

}

=head2 add_SeqFeature

 Title   : add_SeqFeature
 Usage   : $annseq->add_SeqFeature($feat);
 Function: Adds t
 Example :
 Returns : 
 Args    :


=cut

sub add_SeqFeature{
   my ($self,@feat) = @_;
   my ($fseq,$aseq);


   foreach my $feat ( @feat ) {
       if( !$feat->isa("Bio::SeqFeatureI") ) {
	   $self->warn("$feat is not a SeqFeatureI and that's what we expect...");
       }
       
       if( $feat->can("seq") ) {
	   $fseq = $feat->seq;
	   $aseq = $self->seq;
	   
	   if( defined $aseq ) {
	       if( defined $fseq ) {
		   if( $aseq ne $fseq ) {
		       $self->warn("$feat has an attached sequence which is not in this annseq. I worry about this");
		   }
	       } else {
		   if( $feat->can("attach_seq") ) {
		       # attach it 
		       $feat->attach_seq($aseq);
		   }
	       }
	   } # end of if aseq
       } # end of if the feat can seq
       
       push(@{$self->{'_as_feat'}},$feat);
   }
}

=head2 top_SeqFeatures

 Title   : top_SeqFeatures
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub top_SeqFeatures{
   my ($self) = @_;

   return @{$self->{'_as_feat'}};
}

=head2 all_SeqFeatures

 Title   : all_SeqFeatures
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub all_SeqFeatures{
   my ($self) = @_;
   my (@array);
   foreach my $feat ( $self->top_SeqFeatures() ){
       push(@array,$feat);
       &_retrieve_subSeqFeature(\@array,$feat);
   }

   return @array;
}


sub _retrieve_subSeqFeature {
    my ($arrayref,$feat) = @_;

    foreach my $sub ( $feat->sub_SeqFeature() ) {
	push(@$arrayref,$sub);
	&_retrieve_subSeqFeature($arrayref,$sub);
    }

}

=head2 fetch_SeqFeatures

 Title   : fetch_SeqFeatures
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub fetch_SeqFeatures{
   my ($self,@args) = @_;

   $self->throw("Not implemented yet");
}


=head2 species

 Title   : species
 Usage   : 
 Function: Gets or sets the species
 Example : $species = $self->species();
 Returns : Bio::Species object
 Args    : Bio::Species object or none;


=cut

sub species {
    my ($self, $species) = @_;

    if ($species) {
        $self->{'species'} = $species;
    } else {
        return $self->{'species'}
    }
}

=head2 species

 Title   : sub_species
 Usage   : 
 Function: Gets or sets the sub_species
 Example : $sub_species = $self->sub_species();
 Returns : Bio::Species object
 Args    : Bio::Species object or none;


=cut

sub sub_species {
    my ($self, $sub_species) = @_;

    if ($sub_species) {
        $self->{'sub_species'} = $sub_species;
    } else {
        return $self->{'sub_species'}
    }
}

=head1 EMBL/GenBank/DDBJ methods

These methods are here to support the EMBL/GenBank/DDBJ format.
The problem is that these formats require a certain amount
of additional information (eg, what division they are from), but
to make bioperl slavishly involved with this is just a bad idea.

If you want to use these methods, B<please> preface them with
a $as->can('method-name'). If this fails, then do something
sensible. This means that we do not have to think about
being in lock-step with EMBL/GenBank/DDBJ but can still support
all the information that is required.

=head2 division

 Title   : division
 Usage   : $obj->division($newval)
 Function: 
 Returns : value of division
 Args    : newvalue (optional)


=cut

sub division{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'division'} = $value;
    }
    return $obj->{'division'};

}

=head2 molecule

 Title   : molecule
 Usage   : $obj->molecule($newval)
 Function: 
 Returns : type of molecule (DNA, mRNA)
 Args    : newvalue (optional)


=cut

sub molecule{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'molecule'} = $value;
    }
    return $obj->{'molecule'};

}

=head2 add_date

 Title   : add_date
 Usage   : $self->add_domment($ref)
 Function: adds a date
 Example :
 Returns : 
 Args    :


=cut

sub add_date{
   my ($self) = shift;
   foreach my $dt ( @_ ) {
       push(@{$self->{'date'}},$dt);
   }
}

=head2 each_Comment

 Title   : each_date
 Usage   : foreach $dt ( $self->each_date() )
 Function: gets an array of dates
 Example :
 Returns : 
 Args    :


=cut

sub each_date{
   my ($self) = @_;
   return @{$self->{'date'}}; 
}

=head2 accession

 Title   : accession
 Usage   : $obj->accession($newval)
 Function: Whilst the underlying sequence object does not 
           have an accession, so we need one here. Wont stay
           when we do the reimplementation.
 Example : 
 Returns : value of accession
 Args    : newvalue (optional)


=cut

sub accession{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'accession'} = $value;
    }
    return $obj->{'accession'};

}

=head2 sv

 Title   : sv
 Usage   : $obj->sv($newval)
 Function: 
 Returns : value of sv
 Args    : newvalue (optional)


=cut

sub sv{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'sv'} = $value;
    }
    return $obj->{'sv'};

}

=head2 keywords

 Title   : keywords
 Usage   : $obj->keywords($newval)
 Function: 
 Returns : value of keywords
 Args    : newvalue (optional)


=cut

sub keywords{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'keywords'} = $value;
    }
    return $obj->{'keywords'};

}






























