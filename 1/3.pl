use strict;
use warnings;

use DDP;
use Data::Dumper;
use String::Util qw(trim);

my @res = ();
while (<>) {
    my @array = split(':');
    for (@array) {
        $_ = trim($_)
    }
    push @res, \@array
}
p @res;
print Dumper(@res)
