use strict;
use warnings;

use Test::More tests => 5;
use Test::MockObject::Extends;
use Test::Exception;
use XML::LibXML;

use_ok('warehouse_messenger::dao::containertypes_dao');

my $containertypes_doc = XML::LibXML->load_xml(location => 't/data/containertypes_dao/12');

{
  my $lims_id = '12';
  my $containertypes_dao = warehouse_messenger::dao::containertypes_dao->new(lims_id => $lims_id);
  isa_ok($containertypes_dao, 'warehouse_messenger::dao::containertypes_dao');
}

{
  my $lims_id = '12';

  my $containertypes_dao = Test::MockObject::Extends->new(
    warehouse_messenger::dao::containertypes_dao->new(lims_id => $lims_id)
  );

  $containertypes_dao->mock(q/_get_xml/, sub {
    return $containertypes_doc;
  });

  my $_xml;
  lives_ok { $_xml = $containertypes_dao->_xml} 'got container xml';
  isa_ok($_xml, 'XML::LibXML::Document');

  is($containertypes_dao->plate_size, 96, 'Returns the correct plate size');
}

1;