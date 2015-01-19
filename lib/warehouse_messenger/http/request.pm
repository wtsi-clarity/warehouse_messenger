package warehouse_messenger::http::request;

use Moose;
use Carp;
use English qw( -no_match_vars );
use MooseX::StrictConstructor;
use MooseX::ClassAttribute;
use LWP::UserAgent;
use HTTP::Request;
use Readonly;

with 'warehouse_messenger::configurable';
with 'warehouse_messenger::http::batch';

our $VERSION = '0.0';

Readonly::Scalar my $REALM => q[GLSSecurity];

=head1 NAME

warehouse_messenger::http::request

=head1 SYNOPSIS

=head1 DESCRIPTION

Performs requests to Clarity API.
Retrieves requested contents either from a specified URI or from a cache.
When retrieving the contents from URI can, optionally, save the resource
to cache.

The location of the cache is stored in an environment variable

=head1 SUBROUTINES/METHODS

=cut

Readonly::Scalar our $LWP_TIMEOUT => 60;
Readonly::Scalar our $DEFAULT_METHOD => q[GET];
Readonly::Scalar our $DEFAULT_CONTENT_TYPE => q[application/xml];

Readonly::Scalar my $EXCEPTION_MESSAGE_PATH => q[exc:exception/message];

=head2 content_type

Content type to accept

=cut
has 'content_type'=> (isa      => 'Str',
                      is       => 'ro',
                      required => 0,
                      default  => $DEFAULT_CONTENT_TYPE,
                     );

=head2 user

Username of a user authorised to use API;
if not given will be read from the configuration file.

=cut
has 'user'      => (isa        => 'Str',
                    is         => 'ro',
                    required   => 0,
                    lazy_build => 1,
                   );
sub _build_user {
    my $self = shift;
    my $user = $self->config->clarity_api->{'username'} ||
        croak q[Cannot retrieve username from the configuration file];
    return $user;
}

=head2 password

Password of a user authorised to use API;
if not given will be read from the configuration file.

=cut
has 'password'      => (isa        => 'Str',
                        is         => 'ro',
                        required   => 0,
                        lazy_build => 1,
                       );
sub _build_password {
    my $self = shift;
    my $p = $self->config->clarity_api->{'password'} ||
        croak q[Cannot retrieve password from the configuration file];
    return $p;
}

=head2 useragent

Useragent for making an HTTP request.

=cut
has 'useragent' => (isa        => 'Object',
                    is         => 'ro',
                    required   => 0,
                    lazy_build => 1,
                   );
sub _build_useragent {
    my $self = shift;
    if (!$self->config->clarity_api->{'base_uri'}) {
        croak q[Base uri is needed for authentication];
    }
    my $ua = LWP::UserAgent->new();
    $ua->agent(join q[/], __PACKAGE__, $VERSION);
    $ua->timeout($LWP_TIMEOUT);
    $ua->env_proxy();
    return $ua;
}

=head2 get

Contacts a web service to perform a GET request.
Optionally saves the content of a requested web resource
to a cache. If a global variable whose name is returned by
$self->cache_dir_var_name is set, for GET requests retrieves the
requested resource from a cache.

=cut
sub get {
    my ($self, $uri) = @_;
    return $self->_request('GET', $uri);
}

=head2 post

Contacts a web service to perform a POST request.

=cut
sub post {
    my ($self, $uri, $content) = @_;
    return $self->_request('POST',$uri, $content);
}

=head2 put

Contacts a web service to perform a PUT request.

=cut
sub put {
    my ($self, $uri, $content) = @_;
    return $self->_request('PUT',$uri, $content);
}

=head2 del

Contacts a web service to perform a DELETE request.

=cut
sub del {
    my ($self, $uri, $content) = @_;
    return $self->_request('DELETE', $uri);
}

sub _request {
    my ($self, $type, $uri, $content) = @_;

    if ( !$type || $type !~ /GET|POST|PUT|DELETE/smx) {
        $type = !defined $type ? 'undefined' : $type;
        croak qq[Invalid request type "$type", valid types are GET, POST, PUT, DELETE];
    }

    my $response = $self->_from_web($type, $uri, $content);

    if (!$response) {
        croak qq[Empty document at $uri];
    }

    return $response;
}

sub _from_web {
    my ($self, $type, $uri, $content) = @_;

    my $req = HTTP::Request->new($type, $uri,undef, $content);
    $req->header('encoding' =>   'UTF-8');
    $req->header('Accept',       $self->content_type);
    $req->header('Content-Type', $self->content_type);
    $req->header('User-Agent',   $self->useragent->agent());

    my $res=$self->useragent()->request($req);

    return $res->decoded_content;
}

1;

__END__

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::StrictConstructor

=item Readonly

=item Carp

=item English

=item LWP::UserAgent

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Marina Gourtovaia

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL, by Marina Gourtovaia

This file is part of wtsi_clarity project.

wtsi_clarity is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
