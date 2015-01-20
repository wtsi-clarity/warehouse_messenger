package warehouse_messenger::config;

use Moose;
use File::Spec::Functions;
use Readonly;
use Config::Auto;
use Carp;
use Moose::Util::TypeConstraints;

our $VERSION = '0.0';

Readonly::Scalar my $WTSI_CLARITY_HOME_VAR_NAME => q[WTSI_CLARITY_HOME];
Readonly::Scalar my $CONF_DIR        => q[.wtsi_clarity];
Readonly::Scalar my $CONF_FILE_NAME  => q[message_enhancer];
Readonly::Array  my @CONF_ITEMS      => qw/ clarity_api
                                            clarity_mq
                                            warehouse_mq
                                          /;

##no critic(BuiltinFunctions::ProhibitUselessTopic)
subtype 'ReadableFile'
      => as 'Str'
      => where { -r $_ };

subtype 'Directory'
      => as 'Str'
      => where { -d $_ };

##use critic

has 'dir_path'  => (
    isa             => 'Directory',
    is              => 'ro',
    required        => 0,
    lazy_build      => 1,
);
sub _build_dir_path {
  my $self = shift;
  my $home = $ENV{'HOME'};
  my $clarity_home = $ENV{$WTSI_CLARITY_HOME_VAR_NAME};
  my $error =
      q[Neither WTSI_CLARITY_HOME not HOME environment variable is defined, cannot find location of the message_enhancer project configuration directory];
  return $clarity_home ? $clarity_home : (
         $home ? catdir($home, $CONF_DIR) : croak $error);
}

has 'file'  => (
    isa        => 'ReadableFile',
    is         => 'ro',
    required   => 0,
    lazy_build => 1,
);
sub _build_file {
  my $self = shift;
  return catfile($self->dir_path, $CONF_FILE_NAME);
}

has '_data' => (
    is         => 'ro',
    isa        => 'HashRef',
    required   => 0,
    lazy_build => 1,
);
sub _build__data {
  my $self = shift;
  return Config::Auto::parse($self->file);
}

foreach my $conf_item ( @CONF_ITEMS ) {
  has $conf_item =>
    (is => 'ro', init_arg => undef, isa  => 'HashRef', required => 0, lazy_build => 1,);
}

sub BUILD {
  my $self = shift;
  _inject_conf_option_builders();
  return;
}

sub _inject_conf_option_builders {
  foreach my $conf_item (@CONF_ITEMS) {
    my $build_method = '_build_' . $conf_item;
    ##no critic (TestingAndDebugging::ProhibitNoStrict TestingAndDebugging::ProhibitNoWarnings)
    no strict 'refs';
    no warnings 'redefine';
    *{$build_method} = sub {
        my $self = shift;
        if (!exists $self->_data->{$conf_item}) {
          croak qq["$conf_item" configuration option is not defined in ] . $self->file;
        }
        return $self->_data->{$conf_item};
    };
  }
  return;
}

1;

__END__

=head1 NAME

warehouse_messenger::config

=head1 SYNOPSIS

=head1 DESCRIPTION

 Access to configuration options for the message_enhancer project.
 Either WTSI_CLARITY_HOME or HOME environment variable is examined
 as a location for the project configuration directory, .wtsi_clarity.
 The default name of the configuration file is config.

=head1 SUBROUTINES/METHODS

=head2 BUILD - custom post Moose constructor code, dynamically creates
  build methods for some attributes

=head2 dir_path - directory for configuration files

=head2 file - a full path of the configuration file

=head2 clarity_api - returns a hash reference corresponding to this
   section of a configuration file

=head2 clarity_mq - returns a hash reference corresponding to this
   section of a configuration file

=head2 warehouse_mq - returns a hash reference corresponding to this
   section of a configuration file

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item File::Spec::Functions

=item Readonly

=item Config::Auto

=item Carp

=item Moose::Util::TypeConstraints;

=back

=head1 AUTHOR

Author: Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

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
