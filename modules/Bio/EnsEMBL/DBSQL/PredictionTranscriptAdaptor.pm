# EnsEMBL Exon reading writing adaptor for mySQL
#
# Copyright EMBL-EBI 2001
#
# Author: Arne Stabenau
# 
# Date : 22.11.2001
#

=head1 NAME

Bio::EnsEMBL::DBSQL::PredictionTranscriptAdaptor - 
  MySQL Database queries to load and store PredictionExons

=head1 SYNOPSIS

=head1 CONTACT

  Arne Stabenau: stabenau@ebi.ac.uk
  Ewan Birney  : birney@ebi.ac.uk

=head1 APPENDIX

=cut



package Bio::EnsEMBL::DBSQL::PredictionTranscriptAdaptor;

use vars qw( @ISA );
use strict;


use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::DBSQL::AnalysisAdaptor;
use Bio::EnsEMBL::PredictionTranscript;

@ISA = qw( Bio::EnsEMBL::DBSQL::BaseAdaptor );



=head2 fetch_by_dbID

  Arg  1    : int $dbID
              database internal id for a PredictionTranscript
  Function  : Retrieves PredictionTranscript from db with given dbID.
  Returntype: Bio::EnsEMBL::PredictionTranscript
  Exceptions: returns undef when not found
  Caller    : general

=cut



sub fetch_by_dbID {
  my ( $self, $dbID ) = @_;
  my $hashRef;
  my @exons;

  if( !defined $dbID ) {
      $self->throw("Give a prediction_transcript_id");
  }

  my $query = qq {
    SELECT  p.prediction_transcript_id
      , p.contig_id
      , p.contig_start
      , p.contig_end
      , p.contig_strand
      , p.start_phase
      , p.exon_rank
      , p.score
      , p.p_value	
      , p.analysis_id
      , p.exon_count

    FROM prediction_transcript p
    WHERE p.prediction_transcript_id = ?
    ORDER BY p.prediction_transcript_id, p.exon_rank
  };

  my $sth = $self->prepare( $query );
  $sth->execute( $dbID );

  my @res = $self->_ptrans_from_sth( $sth );
  return $res[0];
}

sub fetch_by_Contig{
  my ($self, $contig, $logic_name) = @_;

  my @results = $self->fetch_by_contig_id($contig->dbID, $logic_name);
  
  return @results;
}

sub fetch_by_contig_id{
 my ($self, $contig_id, $logic_name) = @_;
 
 my $constraint = undef;

 if($logic_name){
    my $analysis  = $self->db->get_AnalysisAdaptor->fetch_by_logic_name($logic_name);
   $constraint = " analysis_id = ".$analysis->dbID;
 }

 my @results = $self->fetch_by_contig_id_constraint($contig_id, $constraint);

 return @results;

}

=head2 fetch_by_contig_id_constraint

  Arg  1    : Bio::EnsEMBL::RawContig $contig
              Only dbID in Contig is used.
  Function  : returns all PredicitonTranscipts on given contig
  Returntype: listref Bio::EnsEMBL::PredictionTranscript
  Exceptions: none, if there are none, the list is empty.
  Caller    : Bio::EnsEMBL::RawContig->get_genscan_peptides();

=cut


sub fetch_by_contig_id_constraint {
  my $self = shift;
  my $contig_id = shift;
  my $constraint = shift;

  my $query = qq {
    SELECT  p.prediction_transcript_id
      , p.contig_id
      , p.contig_start
      , p.contig_end
      , p.contig_strand
      , p.start_phase
      , p.exon_rank
      , p.score
      , p.p_value	
      , p.analysis_id
      , p.exon_count

    FROM prediction_transcript p
    WHERE p.contig_id = ?
   };

  if($constraint){
    $query .= " and ".$constraint;
  }

  $query .= " order by p.prediction_transcript_id, p.exon_rank";
  #print $query."\n";
  my $sth = $self->prepare( $query );
  $sth->execute( $contig_id );

  my @res = $self->_ptrans_from_sth( $sth );
  return @res;
}


sub fetch_by_Slice{
  my ($self, $slice, $logic_name) = @_;

  my $constraint = undef;

  if($logic_name){
    my $analysis  = $self->db->get_AnalysisAdaptor->fetch_by_logic_name($logic_name);
    $constraint = " analysis_id = ".$analysis->dbID;
  }
  
  my @results = $self->fetch_by_assembly_location_constraint($slice->chr_start, $slice->chr_end, $slice->chr_name, $slice->assembly_type, $constraint);

  my @out;

 GENE: foreach my $transcript(@results){
    my $exon_count = 1;
    my $pred_t = Bio::EnsEMBL::PredictionTranscript->new();
    $pred_t->dbID($transcript->dbID);
    $pred_t->adaptor($self);
    $pred_t->analysis($transcript->analysis);
    $pred_t->set_exon_count($transcript->get_exon_count);
    my @exons = $transcript->get_all_Exons;
    my @sorted_exons;
    if($exons[0]->strand == 1){
      @sorted_exons = sort{$a->start <=> $b->start} @exons;
    }else{
      @sorted_exons = sort{$b->start <=> $a->start} @exons;
    }
    my $contig = $sorted_exons[0]->contig;
  EXON:foreach my $e(@sorted_exons){
      my $start = ($e->start - ($slice->chr_start - 1));
      my $end = ($e->end - ($slice->chr_start - 1));
      my $exon = $self->_new_Exon($start, $end, $e->strand, $e->phase, $e->score, $e->p_value, $contig);
      $pred_t->add_Exon( $exon, $exon_count );
      $exon_count++;
    }
    push(@out, $pred_t);
  }
  

  return @out;
}

sub fetch_by_assembly_location{
  my ($self, $chr_start, $chr_end, $chr, $type, $logic_name) = @_;

  my $constraint = undef;

  if($logic_name){
    my $analysis  = $self->db->get_AnalysisAdaptor->fetch_by_logic_name($logic_name);
    $constraint = " analysis_id = ".$analysis->dbID;
  }
  
  my @results = $self->fetch_by_assembly_location_constraint($chr_start, $chr_end, $chr, $type, $constraint);

  return @results;
}


sub fetch_by_assembly_location_constraint{
  my ($self, $chr_start, $chr_end, $chr, $type, $constraint) = @_;

  if( !defined $type ) {
    $self->throw("Assembly location must be start,end,chr,type");
  }
  
  if( $chr_start !~ /^\d/ || $chr_end !~ /^\d/ ) {
    $self->throw("start/end must be numbers not $chr_start,$chr_end (have you typed the location in the right way around - start,end,chromosome,type)?");
  }
  
  my $mapper = $self->db->get_AssemblyMapperAdaptor->fetch_by_type($type);
  
  $mapper->register_region($chr,$chr_start,$chr_end);
  
  my @cids = $mapper->list_contig_ids($chr, $chr_start ,$chr_end);
  my %ana;
  my $cid_list = join(',',@cids);
  
  my $sql = qq {
    SELECT  p.prediction_transcript_id
          , p.contig_id
	  , p.contig_start
	  , p.contig_end
	  , p.contig_strand
	  , p.start_phase
          , p.exon_rank
          , p.score
          , p.p_value	
          , p.analysis_id
          , p.exon_count

    FROM prediction_transcript p
    WHERE
   };

  $sql .= "contig_id in($cid_list) ";

  if($constraint){
    $sql .= " and $constraint";
  }

  my $sth = $self->prepare($sql);
  $sth->execute;

  my @results = $self->_ptrans_from_sth($sth);
  my @out;
  GENE: foreach my $transcript(@results){
      my $exon_count = 1;
      my $pred_t = Bio::EnsEMBL::PredictionTranscript->new();
      $pred_t->dbID($transcript->dbID);
      $pred_t->adaptor($self);
      $pred_t->analysis($transcript->analysis);
      $pred_t->set_exon_count($transcript->get_exon_count);
      my @exons = $transcript->get_all_Exons;
      my @sorted_exons;
      if($exons[0]->strand == 1){
	@sorted_exons = sort{$a->start <=> $b->start} @exons;
      }else{
	@sorted_exons = sort{$b->start <=> $a->start} @exons;
      }
      my $contig = $sorted_exons[0]->contig;
    EXON:foreach my $e(@sorted_exons){
	my @coord_list = $mapper->map_coordinates_to_assembly($e->contig->dbID, $e->start, $e->end, $e->strand, "rawcontig");
	if( scalar(@coord_list) > 1 ) {
	  #$self->warn("maps to ".scalar(@coord_list)." coordinate objs not all of feature will be on golden path skipping\n");
	  next GENE;
	}
	
	if($coord_list[0]->isa("Bio::EnsEMBL::Mapper::Gap")){
	  #$self->warn("this feature is on a part of $contig_id which isn't on the golden path skipping");
	  next GENE;
	}
	if(!($coord_list[0]->start >= $chr_start) ||
	   !($coord_list[0]->end <= $chr_end)) {
	  next GENE;
	}
	my $exon = $self->_new_Exon($coord_list[0]->start, $coord_list[0]->end, $coord_list[0]->strand, $e->phase, $e->score, $e->p_value, $contig);
	$pred_t->add_Exon( $exon, $exon_count );
	$exon_count++;
      }
      push(@out, $pred_t);
    }

  return @out;
}




=head2 _ptrans_from_sth

  Arg  1    : DBI:st $statement_handle
              an already executed statement handle.
  Function  : Generate PredictionTranscripts from the handle. Obviously 
              this needs to come from a query on prediciton_transcript.
              Needs to be sorted on exon_rank and p.._t.._id.
  Returntype: list Bio::EnsEMBL::PredictionTranscript
  Exceptions: none, list can be empty
  Caller    : internal

=cut


sub _ptrans_from_sth {
  my $self = shift;
  my $sth = shift;

  my $analysis;
  my $pre_trans = undef; 
  my $pre_trans_id = undef;
  my @result = ();
  my $count = 0;
  my $exon_count = 0;
  while( my $hashRef = $sth->fetchrow_hashref() ) {
    if(( ! defined $pre_trans  ) ||
       ( $pre_trans_id != $hashRef->{'prediction_transcript_id'} )) {
      $count++;
      $pre_trans = Bio::EnsEMBL::PredictionTranscript->new(); 
      $pre_trans_id = $hashRef->{'prediction_transcript_id'};
      $pre_trans->dbID( $pre_trans_id );
      $pre_trans->adaptor( $self );
      my $anaAdaptor = $self->db()->get_AnalysisAdaptor();
      $analysis = $anaAdaptor->fetch_by_dbID( $hashRef->{'analysis_id'} );
      $pre_trans->analysis( $analysis );
      $pre_trans->set_exon_count( $hashRef->{'exon_count'} );
      push( @result, $pre_trans );
    }

    my $exon = $self->_new_Exon_from_hashRef( $hashRef );
    $pre_trans->add_Exon( $exon, $hashRef->{'exon_rank'} );
    $exon_count++;
  }
  #print "have created ".$count." transcripts and ".$exon_count." exons\n";
  return @result;
}


=head2 _new_Exon_from_hashRef

  Arg  1    : hashref $exon_attributes
              Data from a line in prediction_transcript
  Function  : Creates an Exon from the data
  Returntype: Bio::EnsEMBL::Exon
  Exceptions: none
  Caller    : internal

=cut



sub _new_Exon_from_hashRef {
  my $self = shift;
  my $hashRef = shift;
  
  my $exon = Bio::EnsEMBL::Exon->new();
  my $contig_adaptor = $self->db()->get_RawContigAdaptor();
  
  my $contig = Bio::EnsEMBL::RawContig->new
    ( $hashRef->{'contig_id'}, $contig_adaptor );
  
  $exon->start( $hashRef->{'contig_start'} );
  $exon->end( $hashRef->{'contig_end'} );
  $exon->strand( $hashRef->{'contig_strand'} );
  $exon->phase( $hashRef->{start_phase} );
  
  $exon->contig( $contig );
  $exon->attach_seq( $contig );
  $exon->ori_start( $exon->start );
  $exon->ori_end( $exon->end );
  $exon->ori_strand( $exon->strand );
  
  # does exon not have score?
  $exon->score( $hashRef->{'score'} );
  $exon->p_value( $hashRef->{'p_value'} );
  
  return $exon;
}



sub _new_Exon{
  my ($self, $start, $end, $strand, $phase, $score, $pvalue, $contig) = @_; 
  my $exon = Bio::EnsEMBL::Exon->new();
  
  $exon->start( $start);
  $exon->end( $end );
  $exon->strand( $strand );
  $exon->phase( $phase );
  
  $exon->contig( $contig );
  $exon->attach_seq( $contig );
  $exon->ori_start( $start );
  $exon->ori_end( $end );
  $exon->ori_strand( $strand );
  
  # does exon not have score?
  $exon->score( $score );
  $exon->p_value( $pvalue );
  
  return $exon;
}

=head2 store

  Arg  1    : Bio::EnsEMBL::PredictionTranscript $pt
  Function  : Stores given $pt in database. Puts dbID and Adaptor into $pt 
              object. Returns the dbID.
  Returntype: int
  Exceptions: on wrong argument type
  Caller    : general

=cut

sub store {
  my ( $self, $pre_trans ) = @_;

  if( ! $pre_trans->isa('Bio::EnsEMBL::PredictionTranscript') ) {
    $self->throw("$pre_trans is not a EnsEMBL PredictionTranscript - not dumping!");
  }

  if( $pre_trans->dbID && $pre_trans->adaptor == $self ) {
    $self->warn("Already stored");
  }


  my $exon_sql = q{
       INSERT into prediction_transcript ( prediction_transcript_id, exon_rank, contig_id, 
                                           contig_start, contig_end, contig_strand, 
                                           start_phase, score, p_value,
                                           analysis_id, exon_count )
		 VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
	       };

  my $exonst = $self->prepare($exon_sql);

  my $exonId = undef;

  my @exons = $pre_trans->get_all_Exons();
  my $dbID = undef;
  my $rank = 1;
  
  for my $exon ( @exons ) {
    if( ! defined $exon ) { $rank++; next; }
    
    my $contig_id = $exon->contig->dbID();
    my $contig_start = $exon->start();
    my $contig_end = $exon->end();
    my $contig_strand = $exon->strand();
    
    my $start_phase = $exon->phase();
    my $end_phase = $exon->end_phase();

    # this is only in PredictionExon
    my $score = $exon->score();
    my $p_value = $exon->p_value();
    #print "storing exon with pvalue ".$exon->p_value." and score ".$exon->score."\n";
    my $analysis = $pre_trans->analysis->dbID;

    if( $rank == 1 ) {
      $exonst->execute( undef, 1, $contig_id, $contig_start, $contig_end, $contig_strand,
			$start_phase, $score, $p_value, $analysis, scalar( @exons) );
      $dbID =   $exonst->{'mysql_insertid'};
    } else {
      $exonst->execute( $dbID, $rank, $contig_id, $contig_start, $contig_end, $contig_strand,
			$start_phase, $score, $p_value, $analysis, scalar( @exons ) );
    }
    $rank++;
  }

  $pre_trans->dbID( $dbID );
  $pre_trans->adaptor( $self );
  
  return $dbID;
}



=head2 remove

  Arg  1    : Bio::EnsEMBL::PredictionTranscript $pt
  Function  : removes given $pt from database. Expects access to
              internal db via $pt->{'dbID'} to set it undef.
  Returntype: none
  Exceptions: none
  Caller    : general

=cut


sub remove {
  my $self = shift;
  my $pre_trans = shift;
  
  if ( ! defined $pre_trans->dbID() ) {
    return;
  }

  my $sth = $self->prepare( "delete from prediction_transcript where prediction_transcript_id = ?" );
  $sth->execute( $pre_trans->dbID );

  # uhh, didnt know another way of resetting to undef ...
  $pre_trans->{dbID} = undef;
  $pre_trans->{adaptor} = undef;
}







1;
