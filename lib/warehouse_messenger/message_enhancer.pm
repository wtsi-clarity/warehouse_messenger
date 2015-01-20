package warehouse_messenger::message_enhancer;

use Moose::Role;
use XML::LibXML;
use Readonly;
use List::MoreUtils qw/uniq/;

with qw/warehouse_messenger::roles::clarity_process warehouse_messenger::configurable/;

our $VERSION = '0.0';

## no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
Readonly::Scalar my $SAMPLE_LIMS_ID_PATH  => q{/art:details/art:artifact/sample/@limsid};
## use critic

has 'step_url' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has 'timestamp' => (
  isa        => 'Str',
  is         => 'ro',
  required   => 1,
);

has '_lims_ids' => (
  isa             => 'ArrayRef',
  is              => 'rw',
  required        => 0,
  lazy_build      => 1,
);

requires qw/ type _build__lims_ids/;

sub prepare_messages {
  my $self = shift;
  my @messages = map { $self->_get_formatted_message($_) } @{$self->_lims_ids};
  return \@messages;
}

sub get_message {
  my ($self, $model_limsid) = @_;

  my $dao_type = q[warehouse_messenger::dao::] . $self->type . q[_dao];

  my $model_dao = $dao_type->new(lims_id => $model_limsid);
  return $model_dao->to_message;
}

sub get_values_from_nodelist {
  my ($self, $function, $nodelist) = @_;
  my @values = uniq( map { $_->$function } $nodelist->get_nodelist());
  return \@values;
}

sub sample_limsid_node_list {
  my $self = shift;
  return $self->input_artifacts->findnodes($SAMPLE_LIMS_ID_PATH);
}

sub _get_formatted_message {
  my ($self, $lims_id) = @_;
  my $msg = $self->get_message($lims_id);
  return $self->_format_message($msg);
}

sub _format_message {
  my ($self, $msg) = @_;

  my $formatted_msg = {};
  $formatted_msg->{$self->type} = $msg;
  $formatted_msg->{'lims'} = $self->config->clarity_mq->{'id_lims'};

  return $formatted_msg;
}

1;

__END__

=head1 NAME

warehouse_messenger::message_enhancer

=head1 SYNOPSIS

  my $message_enhancer = wtsi_clarity::warehouse_messenger::message_enhancer->new();
  $message_enhancer->prepare_messages;

=head1 DESCRIPTION

 Base class of the message producers, which are preparing messages
 for publishing them to the unified warehouse queue.

=head1 SUBROUTINES/METHODS

=head2 prepare_messages

  Using the model's module populating a model related message with the model's data.

=head2 sample_limsid_node_list

  Getting the sample nodes list from the input artifacts.

=head2 get_values_from_nodelist

  Accepts an XML::LibXML::Nodelist and a Node method method name. Invokes the method on each
  Node within the Nodelist and returns an array (without duplicates)

=head2 get_message

  Get a json string of a message to be sent

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item XML::LibXML

=item Readonly

=item wtsi_clarity::util::roles::clarity_process_base sadfsaf

=item wtsi_clarity::warehouse_messenger::configurable

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
