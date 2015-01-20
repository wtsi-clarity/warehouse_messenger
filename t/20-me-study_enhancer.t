use warnings;
use strict;

use Test::More tests => 8;
use Test::Exception;
use Test::MockObject::Extends;
use Moose;

use_ok('warehouse_messenger::me::study_enhancer');

my $base_dir = 't/data/study_enhancer/';

{
  my $me = warehouse_messenger::me::study_enhancer->new(
    process_url => 'http://testserver.com:1234/processes/999',
    step_url    => 'http://testserver.com:1234/processes/999/step/2',
    timestamp   => '2014-11-25 12:06:27',
  );

  isa_ok($me, 'warehouse_messenger::me::study_enhancer');
  can_ok($me, qw/ process_url step_url prepare_messages /);
}

# Test for getting back the correct study limsids
{
  my $process_xml = XML::LibXML->load_xml(location => $base_dir . 'processes.24-22682');

  my $me = Test::MockObject::Extends->new( warehouse_messenger::me::study_enhancer->new(
    process_xml => $process_xml,
    process_url => '/processes/24-22682',
    step_url    => '/steps/24-22682',
    timestamp   => '2014-11-25 12:06:27',
  ));

  $me->mock(q{input_artifacts}, sub {
    return XML::LibXML->load_xml(location => $base_dir . 'artifacts.batch');
  });

  $me->mock(q{_get_sample}, sub {

    my $anon_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Class::MOP::Attribute->new(
            project_limsid => (
              accessor => 'project_limsid',
              default  => 'SYY154',
          )
        )
      ],
    );

    return $anon_class->new_object();
  });

  my @expected_study_limsids = [ q{SYY154} ];

  my $lims_ids = $me->_lims_ids;

  is(scalar @{$lims_ids}, 1, 'correct number of study limsids');
  is_deeply($lims_ids, @expected_study_limsids, 'Got back the correct study ids');
}

{
  my $me = Test::MockObject::Extends->new(warehouse_messenger::me::study_enhancer->new(
    _lims_ids   => [q/SYY154/],
    process_url => '/processes/24-22682',
    step_url    => '/steps/24-22682',
    timestamp   => '2014-11-25 12:06:27',
  ));

  $me->mock(q{get_message}, sub {
    my %test_msg = ( 'key1' => 'value1', 'key2' => 'value2');
    return \%test_msg;
  });

  my $messages = $me->prepare_messages;

  is(scalar @{$messages}, 1, 'correct number of study messages');
  is(scalar keys %{@{$messages}[0]}, 2, 'Got back the right number of keys');
  my @expected_keys = ('lims', 'study');
  is(scalar keys %{@{$messages}[0]}, @expected_keys, 'Got back the correct keys');
}

1;