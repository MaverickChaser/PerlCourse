use strict;
use warnings;
use DDP;
use feature 'say';

my $NUMBER = qr{
    \s*
    (
    [-]*
    (?:0|[1-9]+)
    (?:\.\d+)?
    (?:(?:[eE][+-]\d+))?
    )
}x;

my $STRING = qr{   
    "
    (
    (?:[^"]|\\")*
    )
    "
}x;

sub proc_string {
    $_ = $_[0];
    s/\\"/"/g;
    s/\\\\/\\/g; 
    s!\\/!/!g;
    s/\\t/\t/g;
    s/\\b/\b/g;
    s/\\f/\f/g;
    s/\\n/\n/g;
    s/\\r/\r/g;
    s/\\u([0-9a-f]{4})/chr(hex($1))/ge;
    return $_;
};

my $input;

sub parse_array {
    if (not $input =~ /\G\s*\[/gc) { # array must begin with [
        die 'Invalid JSON: expected [';
    }
    my $aref = [];
    if ($input =~ /\G\s*\]/gc) { # handle empty array
        return $aref;   
    }
    do {
        my $value = parse_value($_);
        push $aref, $value;
    } while ($input =~ /\G\s*,/gc); # has elements? => go on 

    if (not $input =~ /\G\s*\]/gc) { # array must begin with [
        die 'Invalid JSON: expected ]';
    }
    return $aref;
}

sub parse_value {
    if ($input =~ /\G\s*(?=([{\["tfn]))/gc) { # get the first character of value
        if ($1 eq '{') { # object
            my $href = parse_object($_);
            return $href;
        } elsif ($1 eq '[') {
            my $aref = parse_array($_);
            return $aref;
        } elsif ($1 eq '"') {
            if ($input =~ /\G$STRING/gc) {
                return $1;
            } else {
                die 'Invalid JSON: expected "';
            }
        } elsif ($1 eq 't') {
            if ($input =~ /\Gtrue/gc) {
                return 1;
            }
            die 'Invalid JSON: expected true';
        } elsif ($1 eq 'f') {
            if ($input =~ /\Gfalse/gc) {
                return 0;
            }
            die 'Invalid JSON: expected false';
        } elsif ($1 eq 'n') {
            if ($input =~ /\Gnull/gc) {
                return 0;
            }
            die 'Invalid JSON: expected null';
        } else {
            die 'Invalid JSON: unexpected value';
        }
    } else {
        if ($input =~ /\G$NUMBER/gc) {
            return $1;
        } else {
            die 'Invalid JSON: unexpected value';
        }
    }
};

sub parse_object {
    if (not $input =~ /\G\s*{/gc) { # object must begin with {
        die 'Invalid JSON: expected {';
    }
    my $href = {};
    if ($input =~ /\G\s*\}/gc) {
        return $href;
    }
    do { 
        if ($input =~ /\G\s*$STRING\s*:/gc) { # look for a key:
            my $key = $1;
            $key = proc_string($key);
            my $value = parse_value($_);
            $href->{$key} = $value;
        } else {
            die 'Invalid JSON: expected a key';
        }
    } while ($input =~ /\G\s*,/gc); # has elements? => go on

    if (not $input =~ /\G\s*}/gc) { # object must end with }
        die 'Invalid JSON: expected }';
    }
    return $href;
};  

binmode STDOUT, ":encoding(utf-8)";

sub decode_json {
    $input = $_[0];
    my $result = parse_object();
    if (not $input =~ /\G\s*$/gc) { # object must end with }
        die 'Invalid JSON: expected end of object';
    }
    return $result;
}

my $data = do { # чтение фаийла
    open my $f,'<:raw', $ARGV[0]
    or die "open `$ARGV[0]' failed: $!";
    local $/; <$f>
};

use Encode qw(encode decode);
$data = decode("utf-8", $data);

my $struct = decode_json($data);
p $struct;
