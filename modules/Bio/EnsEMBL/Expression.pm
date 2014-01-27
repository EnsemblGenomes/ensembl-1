=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut


=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.

=cut

=head1 NAME

Bio::EnsEMBL::Expression - A generic Expression class.

=head1 SYNOPSIS

  use Bio::EnsEMBL::Expression;

  my $expression = Bio::EnsEMBL::Expression->new
       (-NAME => 'My Tissue',
        -DESCRIPTION => 'This is my tissue description.',
        -ONTOLOGY => 'EFO:0000302',
        -VALUE => '0.8');

  print $expression->name(), "\n";
  print $expression->description(), "\n";
  print $expression->ontology(), "\n";
  print $expression->value(), "\n";

=head1 DESCRIPTION

This is a generic attribute class used to represent attributes
associated with seq_regions (and their Slices) and MiscFeatures.

=head1 SEE ALSO

Bio::EnsEMBL::DBSQL::ExpressionAdaptor

=cut

package Bio::EnsEMBL::Expression;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Argument qw(rearrange);
use Scalar::Util qw(weaken isweak);

=head2 new

  Arg [-NAME]        : string - the name for this tissue
  Arg [-DESCRIPTION] : string - a description for this tissue
  Arg [-VALUE]       : value  - the expression value for the tissue in a given object
  Example            :   my $expression = Bio::EnsEMBL::Expression->new
                           (-NAME => 'My Tissue',
                            -DESCRIPTION => 'This is my tissue description.',
                            -VALUE => '0.8');
  Description        : Constructor.  Instantiates a Bio::EnsEMBL::Expression object.
  Returntype         : Bio::EnsEMBL::Expression
  Exceptions         : none
  Caller             : general
  Status             : Stable

=cut


sub new {
  my $caller = shift;

  # allow to be called as class or object method
  my $class = ref($caller) || $caller;

  my ($name, $desc, $ontology, $object, $analysis, $value, $value_type) =
    rearrange([qw(NAME DESCRIPTION ONTOLOGY OBJECT ANALYSIS VALUE VALUE_TYPE)], @_);

  return bless {'name'        => $name,
                'description' => $desc,
                'ontology'    => $ontology,
                'object'      => $object,
                'analysis'    => $analysis,
                'value_type'  => $value_type,
                'value'       => $value}, $class;
}

=head2 new_fast

  Arg [1]    : hashref to be blessed
  Description: Construct a new Bio::EnsEMBL::Expression using the hashref.
  Exceptions : none
  Returntype : Bio::EnsEMBL::Expression
  Caller     : general, subclass constructors
  Status     : Stable

=cut


sub new_fast {
  my $class = shift;
  my $hashref = shift;
  my $self = bless $hashref, $class;
  weaken($self->{adaptor})  if ( ! isweak($self->{adaptor}) );
  return $self;
}


=head2 name

  Arg [1]    : string $name (optional)
  Example    : $name = $attribute->name();
  Description: Getter/Setter for name attribute
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub name {
  my $self = shift;
  $self->{'name'} = shift if(@_);
  return $self->{'name'};
}

=head2 description

  Arg [1]    : string $description (optional)
  Example    : $description = $expression->description();
  Description: Getter/Setter for description attribute
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub description {
  my $self = shift;
  $self->{'description'} = shift if(@_);
  return $self->{'description'};
}

=head2 ontology

  Arg [1]    : string $ontology (optional)
  Example    : $ontology = $expression->ontology();
  Description: Getter/Setter for ontology attribute
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub ontology {
  my $self = shift;
  $self->{'ontology'} = shift if(@_);
  return $self->{'ontology'};
}


=head2 value

  Arg [1]    : string $value (optional)
  Example    : $value = $expression->value();
  Description: Getter/Setter for value attribute
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub value {
  my $self = shift;
  $self->{'value'} = shift if(@_);
  return $self->{'value'};
}


=head2 value_type

  Arg [1]    : string $value_type (optional)
  Example    : $value_type = $expression->value_type();
  Description: Getter/Setter for value_type attribute
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub value_type {
  my $self = shift;
  $self->{'value_type'} = shift if(@_);
  return $self->{'value_type'};
}


=head2 object

  Arg [1]    : string $object (optional)
  Example    : $object = $expression->object();
  Description: Getter/Setter for object expression
  Returntype : string
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub object {
  my $self = shift;
  $self->{'object'} = shift if(@_);
  return $self->{'object'};
}



=head2 analysis

  Arg [1]    : Bio::EnsEMBL::Analysis $analysis (optional)
  Example    : $analysis = $expression->analysis();
  Description: Getter/Setter for the analysis associated
               with the expression
  Returntype : Bio::EnsEMBL::Analysis
  Exceptions : thrown if argument is not a Bio::EnsEMBL::Analysis object
  Caller     : general
  Status     : Stable

=cut

sub analysis {
  my $self = shift;

  if(@_) {
    my $an = shift;
    if(defined($an) && (!ref($an) || !$an->isa('Bio::EnsEMBL::Analysis'))) {
      throw('analysis argument must be a Bio::EnsEMBL::Analysis');
    }
    $self->{'analysis'} = $an;
  }

  return $self->{'analysis'};
}




1;
