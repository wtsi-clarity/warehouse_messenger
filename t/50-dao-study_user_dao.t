use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
use Test::MockObject::Extends;
use XML::LibXML;

use_ok('warehouse_messenger::dao::study_user_dao');
my $base = 't/data/study_user_dao/';
my $study_user_doc = XML::LibXML->load_xml(location => $base . 'researchers.21');

{
  my $lims_id = '1234';
  my $study_user_dao = warehouse_messenger::dao::study_user_dao->new( lims_id => $lims_id );
  isa_ok($study_user_dao, 'warehouse_messenger::dao::study_user_dao');
}

{
  my $lims_id = '21';
  my $study_user_dao = Test::MockObject::Extends->new(
    warehouse_messenger::dao::study_user_dao->new(lims_id => $lims_id)
  );

  $study_user_dao->mock(q/_get_xml/, sub {
    return $study_user_doc;
  });

  my $_xml;
  lives_ok { $_xml = $study_user_dao->_xml} 'got study_user artifacts';
  isa_ok($_xml, 'XML::LibXML::Document');

  is($study_user_dao->id, q{21}, 'Returns the correct id of the user of the study');
  is($study_user_dao->login, q{js123}, 'Returns the correct user login id of the study');
  is($study_user_dao->email, q{js123@test.com}, 'Returns the correct email of the user of the study');
  is($study_user_dao->first_name, q{John}, 'Returns the correct first name of the user of the study');
  is($study_user_dao->last_name, q{Smith}, 'Returns the correct last name of the user of the study');
  is($study_user_dao->name, q{John Smith}, 'Returns the correct name of the user of the study');

  my $study_user_json;
  lives_ok { $study_user_json = $study_user_dao->to_message } 'can serialize study_user object';

  like($study_user_json, qr/$lims_id/, 'Lims id serialised correctly');
  lives_ok { warehouse_messenger::dao::study_user_dao->thaw($study_user_json) }
    'can read json string back';
}

1;