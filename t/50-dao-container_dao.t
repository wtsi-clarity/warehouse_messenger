use strict;
use warnings;

use Moose;
use Test::More tests => 12;
use Test::MockObject::Extends;
use Test::Exception;
use XML::LibXML;

use_ok('warehouse_messenger::dao::container_dao');

my $container_doc = XML::LibXML->load_xml(location => 't/data/container_dao/containers.27-3314');
my $artifact1     = XML::LibXML->load_xml(location => 't/data/container_dao/artifacts.2-121338');
my $artifact2     = XML::LibXML->load_xml(location => 't/data/container_dao/artifacts.2-121415');

{
  my $lims_id = '27-3314';
  my $container_dao = warehouse_messenger::dao::container_dao->new(lims_id => $lims_id);
  isa_ok($container_dao, 'warehouse_messenger::dao::container_dao');
}

{
  my $lims_id = '27-3314';
  my $container_dao = warehouse_messenger::dao::container_dao->new(lims_id => $lims_id);

  is($container_dao->flgen_well_position('A:1', 16, 6), q/S001/, 'Converts well A:1 to Fluidigm well position S001');
  is($container_dao->flgen_well_position('B:1', 16, 6), q/S002/, 'Converts well B:1 to Fluidigm well position S002');
  is($container_dao->flgen_well_position('A:2', 16, 6), q/S017/, 'Converts well A:2 to Fluidigm well position S017');
  is($container_dao->flgen_well_position('P:6', 16, 6), q/S096/, 'Converts well F:6 to Fluidigm well position S096');
}

{
  my $lims_id = '27-3314';

  my $container_dao = Test::MockObject::Extends->new(
    warehouse_messenger::dao::container_dao->new(lims_id => $lims_id)
  );

  $container_dao->mock(q/_get_xml/, sub {
    my ($self, $resource_type, $lims_id) = @_;
    if ($resource_type eq 'containers') {
      return $container_doc;
    } elsif ($resource_type eq 'artifacts') {
      if ($lims_id eq '2-121338') {
        return $artifact1;
      } elsif ($lims_id eq '2-121415') {
        return $artifact2;
      }
    }
  });

  $container_dao->mock(q/type/, sub {
    my $anon_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Class::MOP::Attribute->new(
            plate_size => (
              accessor => 'plate_size',
              default  => 96,
          )
        ),
        Class::MOP::Attribute->new(
            x_dimension_size => (
              accessor => 'x_dimension_size',
              default  => 6,
          )
        ),
        Class::MOP::Attribute->new(
            y_dimension_size => (
              accessor => 'y_dimension_size',
              default  => 16,
          )
        ),
      ],
    );
    return $anon_class->new_object();
  });

  my $_xml;
  lives_ok { $_xml = $container_dao->_xml} 'got container xml';
  isa_ok($_xml, 'XML::LibXML::Document');

  is($container_dao->id_flgen_plate_lims, q{27-3314}, 'Extracts id_flgen_plate_lims');
  is($container_dao->plate_barcode_lims, q{8754679423576}, 'Extracts plate_barcode_lims');
  is($container_dao->plate_size, 96, 'Gets the plate size from container type');

  $container_dao->mock(q/_get_sample/, sub {
    my $anon_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Class::MOP::Attribute->new(
            name => (
              accessor => 'name',
              default  => 'kk229sk22-sadfdsaf-asjdfsadf',
          )
        ),
        Class::MOP::Attribute->new(
            project_limsid => (
              accessor => 'project_limsid',
              default  => 'pr-123',
          )
        ),
      ],
    );

    return $anon_class->new_object();
  });

  $container_dao->mock(q/_get_study/, sub {
    my $anon_class = Moose::Meta::Class->create_anon_class(
      attributes => [
        Class::MOP::Attribute->new(
            id => (
              accessor => 'id',
              default  => 1234,
          )
        ),
        Class::MOP::Attribute->new(
          cost_code => (
            accessor => 'cost_code',
            default  => 987,
          )
        ),
      ],
    );

    return $anon_class->new_object();
  });

  my $well = {
    'study_id' => 1234,
    'well_label' => 'S001',
    'sample_uuid' => 'kk229sk22-sadfdsaf-asjdfsadf',
    'cost_code' => 987
  };

  is_deeply($container_dao->_build_well('2-121338'), $well, 'Builds a well correctly');
}

1;