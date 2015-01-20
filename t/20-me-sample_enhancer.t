use warnings;
use strict;

use Test::More tests => 8;
use Test::Exception;
use Test::MockObject::Extends;
use XML::LibXML;

use_ok('warehouse_messenger::me::sample_enhancer');

my $base_dir = 't/data/sample_enhancer/';

{
  my $me = warehouse_messenger::me::sample_enhancer->new(
    process_url => 'http://testserver.com:1234/processes/999',
    step_url    => 'http://testserver.com:1234/processes/999/step/2',
    timestamp   => '2014-11-25 12:06:27',
  );

  isa_ok($me, 'warehouse_messenger::me::sample_enhancer');
  can_ok($me, qw/ process_url step_url prepare_messages /);
}

# Test for getting back the correct sample limsids
{

  my $process_xml = XML::LibXML->load_xml(location => $base_dir . 'processes.24-22682');

  my $me = Test::MockObject::Extends->new(warehouse_messenger::me::sample_enhancer->new(
    process_doc => $process_xml,
    process_url => '/processes/24-22682',
    step_url    => '/steps/24-22682',
    timestamp   => '2014-11-25 12:06:27',
  ));

  $me->mock(q{input_artifacts}, sub {
    return XML::LibXML->load_xml(location => $base_dir . 'artifacts.batch');
  });

  my @expected_sample_limsids = [ q{SYY154A2}, q{SYY154A3}, q{SYY154A1} ];

  my $lims_ids = $me->_lims_ids;

  is(scalar @{$lims_ids}, 3, 'correct number of sample limsids');
  is_deeply($lims_ids, @expected_sample_limsids, 'Got back the correct sample ids');
}

{
  my $me = Test::MockObject::Extends->new( warehouse_messenger::me::sample_enhancer->new(
    _lims_ids   => [ q{SYY154A2}, q{SYY154A3}, q{SYY154A1} ],
    process_url => '/processes/24-22682',
    step_url    => '/steps/24-22682',
    timestamp   => '2014-11-25 12:06:27',
  ) ) ;

  $me->mock(q{_get_model_message}, sub {
    my %test_msg = ( 'key1' => 'value1', 'key2' => 'value2');
    return \%test_msg;
  });

  my $messages = $me->prepare_messages;

  is(scalar @{$messages}, 3, 'correct number of sample messages');
  is(scalar keys %{@{$messages}[0]}, 2, 'Got back the right number of keys');
  my @expected_keys = ('lims', 'sample');
  is(scalar keys %{@{$messages}[0]}, @expected_keys, 'Got back the correct keys');
}

1;