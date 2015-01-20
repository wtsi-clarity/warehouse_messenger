package warehouse_messenger::me::study_enhancer;

use Moose;
use warehouse_messenger::dao::sample_dao;
use warehouse_messenger::dao::study_dao;
use List::MoreUtils qw/uniq/;

with 'warehouse_messenger::message_enhancer';

our $VERSION = '0.0';

sub type {
  my $self = shift;

  return 'study';
}

sub _build__lims_ids {
  my $self = shift;

  my @study_lims_ids = ();
  my $sample_limsid_node_list = $self->sample_limsid_node_list;
  my $sample_limsids = $self->get_values_from_nodelist('getValue', $sample_limsid_node_list);
  foreach my $sample_limsid (@{$sample_limsids}) {
    my $sample_dao = $self->_get_sample($sample_limsid);
    push @study_lims_ids, $sample_dao->project_limsid;
  }

  @study_lims_ids = uniq(@study_lims_ids);

  return \@study_lims_ids;
}

sub _get_sample {
  my ($self, $lims_id) = @_;
  return warehouse_messenger::dao::sample_dao->new(lims_id => $lims_id);
}

1;

__END__

=head1 NAME

warehouse_messenger::me::study_enhancer

=head1 SYNOPSIS

  my $study_enhancer = warehouse_messenger::me::study_enhancer->new();
  $study_enhancer->prepare_message();

=head1 DESCRIPTION

 Preparing a study related message to publish to the unified warehouse queue.

=head1 SUBROUTINES/METHODS

=head2 type

  Returns the type of the model.

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item warehouse_messenger::dao::sample_dao

=item warehouse_messenger::dao::study_dao

=item List::MoreUtils

=item warehouse_messenger::mq::message_enhancer

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
