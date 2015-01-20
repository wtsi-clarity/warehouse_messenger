package warehouse_messenger::dao::study_dao;

use Moose;
use Readonly;
use JSON;

use warehouse_messenger::dao::study_user_dao;

with 'warehouse_messenger::dao::base_dao';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $STUDY_USER_URI_PATH      => q{/prj:project/researcher/@uri};
# Note 'manager' is the closest role we could use. It might change in the future!
Readonly::Scalar my $STUDY_USER_MANAGER_ROLE  => q{manager};

# In the ATTRIBUTES hash: an element's key is the attribute name
# and the element's value is the XPATH to get the attribute's value

Readonly::Hash my %ATTRIBUTES => {
  'name'                        => q{/prj:project/name},
  'reference_genome'            => q{/prj:project/udf:field[@name='WTSI Study reference genome']},
  'state'                       => q{/prj:project/udf:field[@name='WTSI Project State']},
  'study_type'                  => q{/prj:project/udf:field[@name='WTSI Type']},
  'abstract'                    => q{/prj:project/udf:field[@name='WTSI Project Abstract']},
  'abbreviation'                => q{/prj:project/udf:field[@name='WTSI Project Abbreviation']},
  'accession_number'            => q{/prj:project/udf:field[@name='WTSI Accession Number']},
  'description'                 => q{/prj:project/udf:field[@name='WTSI Project Description']},
  'contains_human_dna'          => q{/prj:project/udf:field[@name='WTSI Do samples contain Human DNA?']},
  'contaminated_human_dna'      => q{/prj:project/udf:field[@name='WTSI Contaminated with Human DNA that needs removal?']},
  'data_release_strategy'       => q{/prj:project/udf:field[@name='WTSI Release Strategy']},
  'data_release_timing'         => q{/prj:project/udf:field[@name='WTSI Data release timing']},
  'data_access_group'           => q{/prj:project/udf:field[@name='WTSI Data Access Group']},
  'study_title'                 => q{/prj:project/udf:field[@name='WTSI Study Title for Publishing']},
  'ega_dac_accession_number'    => q{/prj:project/udf:field[@name='WTSI Accession Number']},
  'remove_x_and_autosomes'      => q{/prj:project/udf:field[@name='WTSI Does the study require the removal of X-chromosome and autosome sequence?']},
  'separate_y_chromosome_data'  => q{/prj:project/udf:field[@name='WTSI Does the study require the removal of Y-chromosome and autosome sequence?']},
};
##critic

our $VERSION = '0.0';

has '+resource_type' => (
  default     => 'projects',
);

has '+attributes' => (
  default     => sub { return \%ATTRIBUTES; },
);

has 'study_user_ids' => (
  traits      => [ 'DoNotSerialize' ],
  isa         => 'ArrayRef[Str]',
  is          => 'rw',
  required    => 0,
  lazy_build  => 1,
);
sub _build_study_user_ids {
  my $self = shift;

  my $study_user_uri_nodes = $self->findnodes($STUDY_USER_URI_PATH);
  my @study_user_uris = map { $_->getValue(); } $study_user_uri_nodes->get_nodelist();

  my @study_userids = map { /researchers\/(\d+)/smx } @study_user_uris;

  return \@study_userids;
}

has 'manager' => (
  isa         => 'Str',
  is          => 'rw',
  required    => 0,
  lazy_build  => 1,
);
sub _build_manager {
  my $self = shift;
  my @users = map { $self->_get_message($_) } @{$self->study_user_ids};
  return to_json(\@users);
}

sub _get_message {
  my ($self, $lims_id) = @_;
  my $study_user = $self->_get_study_user(lims_id => $_);

  return {
    login => $study_user->login,
    email => $study_user->email,
    name => $study_user->name
  }
}

sub _get_study_user {
  my ($self, $lims_id) = @_;
  return warehouse_messenger::dao::study_user_dao->new(lims_id => $lims_id);
}

around 'init' => sub {
  my $next = shift;
  my $self = shift;

  $self->$next();
  $self->manager;

  return;
};

1;

__END__

=head1 NAME

warehouse_messenger::dao::study_dao

=head1 SYNOPSIS
  my $study_dao = warehouse_messenger::dao::study_dao->new(lims_id => "1234");
  $study_dao->to_message();

=head1 DESCRIPTION
 A data object representing a study.
 Its data coming from the study artifact (XML file).

=head1 SUBROUTINES/METHODS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=item JSON

=item warehouse_messenger::dao::study_user_dao

=item warehouse_messenger::dao::base_dao

=back

=head1 AUTHOR

Karoly Erdos E<lt>ke4@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL
This file is part of wtsi_clarity project.
wtsi_clarity is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
