use strict;
use warnings;

use Test::More tests => 28;
use Test::Exception;
use Test::MockObject::Extends;
use Moose;
use XML::LibXML;
use JSON;

use_ok('warehouse_messenger::dao::study_dao');

my $base = 't/data/study_dao/';
my $study_xml = XML::LibXML->load_xml(location => $base . 'projects.SYY154');

{
  my $lims_id = '1234';
  my $study_dao = warehouse_messenger::dao::study_dao->new(lims_id => $lims_id);
  isa_ok($study_dao, 'warehouse_messenger::dao::study_dao');
}

{
  my $lims_id = 'SYY154';
  my $study_dao = Test::MockObject::Extends->new(warehouse_messenger::dao::study_dao->new(lims_id => $lims_id));

  $study_dao->mock(q/_get_xml/, sub {
    return $study_xml;
  });

  my $_xml;
  lives_ok { $_xml = $study_dao->_xml} 'got study artifacts';
  isa_ok($_xml, 'XML::LibXML::Document');

  is($study_dao->id, q{SYY154}, 'Returns the correct id of the study');
  is($study_dao->name, q{SS_TEST}, 'Returns the correct name of the study');
  is($study_dao->reference_genome, q{test reference genome}, 'Returns the correct reference genome of the study');
  is($study_dao->state, q{active}, 'Returns the correct state of the study');
  is($study_dao->study_type, q{Exome Sequencing}, 'Returns the correct study type of the study');
  is($study_dao->abstract, q{test abstract}, 'Returns the correct abstract of the study');
  is($study_dao->abbreviation, q{tt}, 'Returns the correct abbreviation of the study');
  is($study_dao->accession_number, q{1111111}, 'Returns the correct accession number of the study');
  is($study_dao->description, q{test description}, 'Returns the correct description of the study');
  is($study_dao->contains_human_dna, q{true}, 'Returns correctly if the sample(s) of the study contains Human DNA');
  is($study_dao->contaminated_human_dna, q{false}, 'Returns correctly if the sample(s) of the study contaminated with Human DNA');
  is($study_dao->data_release_strategy, q{Managed}, 'Returns the correct data release strategy of the study');
  is($study_dao->data_release_timing, q{Standard}, 'Returns the correct data release timing of the study');
  is($study_dao->data_access_group, q{cancer}, 'Returns the correct data access group of the study');
  is($study_dao->study_title, q{Pseudogene RNAseq}, 'Returns the correct title of the study');
  is($study_dao->ega_dac_accession_number, q{1111111}, 'Returns the correct ega dac accession number of the study');
  is($study_dao->remove_x_and_autosomes, q{false}, 'Returns the correct remove_x_and_autosomes flag of the study');
  is($study_dao->separate_y_chromosome_data, q{false}, 'Returns the correct separate_y_chromosome_data flag of the study');
  is($study_dao->cost_code, q{s098}, 'Returns the correct project cost code');

  my $expected_study_user_ids = [21];
  is_deeply($study_dao->study_user_ids, $expected_study_user_ids, 'Returns the correct id of the user of the study');

  $study_dao->mock(q/_get_study_user/, sub {
    my $anon_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Class::MOP::Attribute->new(
            name => (
              accessor => 'name',
              default  => 'John Smith',
          )
        ),
        Class::MOP::Attribute->new(
          email => (
            accessor => 'email',
            default  => 'js123@test.com',
          )
        ),
        Class::MOP::Attribute->new(
          login => (
            accessor => 'login',
            default  => 'js123',
          )
        )
      ],
    );
    return $anon_class->new_object();
  });

  my $study_user_json = JSON->new->utf8->encode([ {name => "John Smith", email => "js123\@test.com", login => "js123"} ]);
  is($study_dao->manager, $study_user_json, 'Returns the correct user of the study');

  my $study_json;
  lives_ok { $study_json = $study_dao->to_message } 'can serialize study object';

  like($study_json, qr/$lims_id/, 'Lims id serialised correctly');
  lives_ok { warehouse_messenger::dao::study_dao->thaw($study_json) }
    'can read json string back';
}

1;