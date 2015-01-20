use strict;
use warnings;

use Test::More tests => 19;
use Test::Exception;
use Test::MockObject::Extends;
use XML::LibXML;

use_ok('warehouse_messenger::dao::sample_dao');

my $base = 't/data/sample_dao/';
my $sample_doc = XML::LibXML->load_xml(location => $base . 'samples.SYY154A1');

{
  my $lims_id = '1234';
  my $sample_dao = warehouse_messenger::dao::sample_dao->new(lims_id => $lims_id);
  isa_ok($sample_dao, 'warehouse_messenger::dao::sample_dao');
}

{
  my $lims_id = 'SYY154A1';

  my $sample_dao = Test::MockObject::Extends->new(
    warehouse_messenger::dao::sample_dao->new(lims_id => $lims_id)
  );

  $sample_dao->mock(q/_get_xml/, sub {
    return $sample_doc;
  });

  my $_xml;
  lives_ok { $_xml = $sample_dao->_xml} 'got sample artifacts';
  isa_ok($_xml, 'XML::LibXML::Document');

  is($sample_dao->id, q{SYY154A1}, 'Returns the correct id of the sample');
  is($sample_dao->uuid, q{111}, 'Returns the correct uuid of the sample');
  is($sample_dao->name, q{111}, 'Returns the correct name of the sample');
  is($sample_dao->reference_genome, q{Test Reference Genome}, 'Returns the correct reference genome of the sample');
  is($sample_dao->organism, q{Homo Sapiens}, 'Returns the correct organism of the sample');
  is($sample_dao->common_name, q{Test Supplier Sample Name}, 'Returns the correct common name of the sample');
  is($sample_dao->taxon_id, q{9606}, 'Returns the correct taxon id of the sample');
  is($sample_dao->gender, q{Female}, 'Returns the correct gender of the sample');
  is($sample_dao->control, q{false}, 'Returns the correct control of the sample');
  is($sample_dao->supplier_name, q{me}, 'Returns the correct supplier name of the sample');
  is($sample_dao->public_name, q{Test Supplier Sample Name}, 'Returns the correct public name of the sample');
  is($sample_dao->donor_id, q{1}, 'Returns the correct donor id of the sample');
}

{
  my $lims_id = 'SYY154A1';
  my $sample_dao = warehouse_messenger::dao::sample_dao->new(
    lims_id => $lims_id,
    _xml    => $sample_doc,
  );

  my $sample_json;

  lives_ok { $sample_json = $sample_dao->to_message } 'can serialize sample object';

  like($sample_json, qr/$lims_id/, 'Lims id serialised correctly');

  lives_ok { warehouse_messenger::dao::sample_dao->thaw($sample_json) }
    'can read json string back';
}

1;