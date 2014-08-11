use strict;
use Test::More 0.98;

use JSON::RPC::Spec;
use JSON::XS;

my $rpc = new_ok 'JSON::RPC::Spec';

$rpc->register(
    sum => sub {
        my ($params) = @_;
        my $sum = 0;
        for my $num (@{$params}) {
            $sum += $num;
        }
        return $sum;
    }
);

sub subtract {
    my ($params) = @_;
    if (ref $params eq 'HASH') {
        return $params->{minuend} - $params->{subtrahend};
    }
    return $params->[0] - $params->[1];
}

$rpc->register(subtract => \&subtract);

$rpc->register(update       => sub {1});
$rpc->register(get_data     => sub { ['hello', 5] });
$rpc->register(notify_sum   => sub {1});
$rpc->register(notify_hello => sub {1});

my $coder = JSON::XS->new->utf8;
my $res;

subtest 'rpc call with positional parameters' => sub {
    $res
      = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}'
      );
    is_deeply $coder->decode($res),
      $coder->decode('{"jsonrpc": "2.0", "result": 19, "id": 1}')
      or diag explain $res;

    $res
      = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "subtract", "params": [23, 42], "id": 2}'
      );
    is_deeply $coder->decode($res),
      $coder->decode('{"jsonrpc": "2.0", "result": -19, "id": 2}')
      or diag explain $res;
};

subtest 'rpc call with named parameters' => sub {

    $res
      = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "subtract", "params": {"subtrahend": 23, "minuend": 42}, "id": 3}'
      );
    is_deeply $coder->decode($res),
      $coder->decode('{"jsonrpc": "2.0", "result": 19, "id": 3}')
      or diag explain $res;

    $res
      = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "subtract", "params": {"minuend": 42, "subtrahend": 23}, "id": 4}'
      );
    is_deeply $coder->decode($res),
      $coder->decode('{"jsonrpc": "2.0", "result": 19, "id": 4}')
      or diag explain $res;
};

subtest 'a Notification' => sub {
    $res = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "update", "params": [1,2,3,4,5]}');
    ok !$res or diag explain $res;

    $res = $rpc->parse('{"jsonrpc": "2.0", "method": "foobar"}');
    ok !$res or diag explain $res;
};

subtest 'rpc call of non-existent method' => sub {

    $res = $rpc->parse('{"jsonrpc": "2.0", "method": "foobar", "id": "1"}');
    is_deeply $coder->decode($res),
      $coder->decode(
        '{"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "1"}'
      ) or diag explain $res;
};

subtest 'rpc call with invalid JSON' => sub {
    $res = $rpc->parse(
        '{"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]');
    is_deeply $coder->decode($res),
      $coder->decode(
        '{"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error"}, "id": null}'
      ) or diag explain $res;
};

subtest 'rpc call with invalid Request object' => sub {
    $res = $rpc->parse('{"jsonrpc": "2.0", "method": 1, "params": "bar"}');
    is_deeply $coder->decode($res),
      $coder->decode(
        '{"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}'
      ) or diag explain $res;
};

subtest 'rpc call Batch, invalid JSON' => sub {
    $res = $rpc->parse(
        '[
  {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},
  {"jsonrpc": "2.0", "method"
]'
    );
    is_deeply $coder->decode($res),
      $coder->decode(
        '{"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error"}, "id": null}'
      ) or diag explain $res;
};

subtest 'rpc call with an empty Array' => sub {
    $res = $rpc->parse('[]');
    is_deeply $coder->decode($res),
      $coder->decode(
        '{"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}'
      ) or diag explain $res;
};

subtest 'rpc call with an invalid Batch (but not empty)' => sub {
    $res = $rpc->parse('[1]');
    is_deeply $coder->decode($res), $coder->decode(
        '[
  {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}
]'
    ) or diag explain $res;
};

subtest 'rpc call with invalid Batch' => sub {
    $res = $rpc->parse('[1,2,3]');
    is_deeply $coder->decode($res), $coder->decode(
        '[
  {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null},
  {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null},
  {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null}
]'
    ) or diag explain $res;
};

subtest 'rpc call Batch' => sub {
    $res = $rpc->parse(
        '[
        {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},
        {"jsonrpc": "2.0", "method": "notify_hello", "params": [7]},
        {"jsonrpc": "2.0", "method": "subtract", "params": [42,23], "id": "2"},
        {"foo": "boo"},
        {"jsonrpc": "2.0", "method": "foo.get", "params": {"name": "myself"}, "id": "5"},
        {"jsonrpc": "2.0", "method": "get_data", "id": "9"}
    ]'
    );
    is_deeply $coder->decode($res), $coder->decode(
        '[
        {"jsonrpc": "2.0", "result": 7, "id": "1"},
        {"jsonrpc": "2.0", "result": 19, "id": "2"},
        {"jsonrpc": "2.0", "error": {"code": -32600, "message": "Invalid Request"}, "id": null},
        {"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "5"},
        {"jsonrpc": "2.0", "result": ["hello", 5], "id": "9"}
    ]'
    ) or diag explain $res;
};

subtest 'rpc call Batch (all notifications)' => sub {
    $res = $rpc->parse(
        '[
        {"jsonrpc": "2.0", "method": "notify_sum", "params": [1,2,4]},
        {"jsonrpc": "2.0", "method": "notify_hello", "params": [7]}
    ]'
    );
    ok !$res or diag explain $res;
};

done_testing;
