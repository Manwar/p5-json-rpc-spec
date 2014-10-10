requires 'perl', '5.008001';
requires 'Moo';
requires 'JSON::MaybeXS';
requires 'Router::Boom';
requires 'Try::Tiny';

recommends 'Cpanel::JSON::XS';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Fatal';
};
