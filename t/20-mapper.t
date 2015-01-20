use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

use_ok('warehouse_messenger::mapper');

{
  my $mq_mapper = warehouse_messenger::mapper->new();
  isa_ok($mq_mapper, 'warehouse_messenger::mapper');
}

{
  my $mq_mapper = warehouse_messenger::mapper->new();
  is($mq_mapper->package_name('sample'), 'warehouse_messenger::me::sample_enhancer', 'Creates the correct package name');
}

{
  my $mq_mapper = warehouse_messenger::mapper->new();
  throws_ok { $mq_mapper->package_name('jibberish') }
    qr/Purpose jibberish could not be found/,
    'Throws an error when purpose can not be found';
}