use strict;
use Test::More 0.98;
use Test::Fatal;

use JSON::RPC::Spec;
use JSON::MaybeXS qw(JSON);

use t::Fake::New;
use t::Fake::Decode;
use t::Fake::Encode;
use t::Fake::JSON;
use t::Fake::Match;

my $obj;
subtest 'standard' => sub {
    is(exception { $obj = JSON::RPC::Spec->new }, undef, 'new')
      or diag explain $obj;

    like ref $obj->coder, qr/JSON/, 'coder like JSON' or diag explain $obj;
    isa_ok $obj->router,    'Router::Simple'             or diag explain $obj;
    isa_ok $obj->procedure, 'JSON::RPC::Spec::Procedure' or diag explain $obj;
    is $obj->jsonrpc, '2.0', 'jsonrpc' or diag explain $obj;
};

subtest 'coder change' => sub {
    like(
        exception { $obj = JSON::RPC::Spec->new(coder => undef) },
        qr/\QCan't call method "can" on an undefined value\E/,
        'coder undef'
    ) or diag explain $obj;

    like(
        exception { $obj = JSON::RPC::Spec->new(coder => t::Fake::Decode->new) },
        qr/\Qmethod encode required\E/,
        'coder has decode only'
    ) or diag explain $obj;

    like(
        exception { $obj = JSON::RPC::Spec->new(coder => t::Fake::Encode->new) },
        qr/\Qmethod decode required\E/,
        'coder has encode only'
    ) or diag explain $obj;

    is(
        exception { $obj = JSON::RPC::Spec->new(coder => t::Fake::JSON->new) },
        undef,
        'coder has encode and decode'
    ) or diag explain $obj;
};

subtest 'router change' => sub {
    like(
        exception { $obj = JSON::RPC::Spec->new(router => undef) },
        qr/\QCan't call method "can" on an undefined value\E/,
        'router undef'
    ) or diag explain $obj;

    is(
        exception { $obj = JSON::RPC::Spec->new(router => t::Fake::Match->new) },
        undef,
        'router has match'
    ) or diag explain $obj;
};

done_testing;