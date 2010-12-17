use strict;
use warnings;
use Test::More;

use MongoDB;
use Try::Tiny;
use threads;

my $conn = try {
    MongoDB::Connection->new({
        host => exists $ENV{MONGOD} ? $ENV{MONGOD} : 'localhost',
    });
}
catch {
    plan skip_all => $_;
};

my $col = $conn->get_database('moo')->get_collection('kooh');
$col->drop;

{
    my $ret = try {
        threads->create(sub {
            $col->insert({ foo => 42 }, { safe => 1 });
        })->join->value;
    }
    catch {
        daig $_;
    };

    ok $ret, 'we survived destruction of a cloned connection';

    my $o = $col->find_one({ foo => 42 });
    is $ret, $o->{_id}, 'we inserted and joined the OID back';
}

done_testing;