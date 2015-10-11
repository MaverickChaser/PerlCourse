use strict;
#use warnings;
use Scalar::Util qw(looks_like_number);
use feature 'switch';

my %priority = (
    '+' => 3,
    '-' => 3,
    '*' => 2,
    '/' => 2,
    '^' => 1,
    '(' => 10,
    ')' => 10
);

sub get_lexems {
    my @lexems = ();
    my @array = split(//, $_[0]);
    my $number = '';
    my $prev_char = '';
    my $exp = 0;

    foreach (@array) {
        if ($prev_char eq '*') {
            if ($_ eq '*') {
                push @lexems, '^'; # replace ** with ^
                $prev_char = '';
                next
            } else {
                push @lexems, '*';
            }
        } 

        if ($exp and ($_ eq '+' or $_ eq '-')) {
            $exp = 0;
            $number .= $_;   # handle numbers in exponential form
            next
        }

        if (looks_like_number($_) or $_ eq '.' or $_ eq 'e') {
            if ($_ eq 'e') {
                $exp = 1
            }
            $number .= $_ ;
        } elsif (exists($priority{$_})) {

            if ($number ne '') {
                push @lexems, $number;
            }
            $number = '';
            if ($_ ne '*') {
                push @lexems, $_
            }
        }
        $prev_char = $_;
    }
    if ($number ne '') {
        push @lexems, $number
    }
    return @lexems
}

sub process {
    my ($num, $op) = @_;
    my $cur_op = pop @$op;
    my $b = pop @$num;
    my $a = pop @$num;
    push @$num, ($a . ' ' . $b . ' ' . $cur_op);
}

sub convert_to_polish {
    my @stack_num = ();
    my @stack_op = ();
    my @result = ();
    my $prev_item = '';
    my $sgn = '';
    foreach (@_) {
        if (looks_like_number($_)) {
            push @stack_num, $sgn . $_;
            $sgn = ''
        } elsif ($_ eq '(') {
            push @stack_op, '('
        } elsif ($_ eq ')') {
            while ($stack_op[-1] ne '(') {
                process(\@stack_num, \@stack_op)
            }
            pop @stack_op
        } else {
            if (($_ eq '+' or $_ eq '-') and not ($prev_item eq ')' or looks_like_number($prev_item))) {
                if ($_ eq '-') {
                    $sgn = ($sgn eq '-') ? '' : '-'
                }
                next # unary operator
            }

            my $op_prior = $priority{$_};
            while (@stack_op and $priority{$stack_op[-1]} <= $op_prior and $_ ne '^') {
                process(\@stack_num, \@stack_op);
            }
            push @stack_op, $_
        }
    } continue {
        $prev_item = $_
    }

    while (@stack_op) {
        process(\@stack_num, \@stack_op);
    }
    return split / /, $stack_num[0];
}

sub eval_polish {
    my @stack = ();
    foreach (@_) {    
        no warnings;
        given ($_) {
            when ('+') { push @stack, (pop @stack) + pop @stack } 
            when ('-') { push @stack, - (pop @stack) + pop @stack }
            when ('*') { push @stack, (pop @stack) * pop @stack }
            when ('/') { push @stack, 1 / (pop @stack) * (pop @stack) }
            when ('^') { push @stack, do { my $b = (pop @stack); my $a = pop @stack; $a ** $b } }
            default { push @stack, $_ }  # number
        }
    }
    return pop @stack
};

sub evaluate_expr {
    return eval_polish(convert_to_polish(get_lexems($_[0])));
}

sub test {
    my $failed = 0;
    while (<>) {
        my $output = evaluate_expr($_);
        my $expected = eval($_);

        if ($output != $expected) {
            print "-----\n";
            print $_, "\n";
            printf "output:%f expected:%f\n--------------\n", $output, $expected;
            $failed++;
        }
    }
    if ($failed) {
        printf "%d tests failed\n", $failed;
    } else {
        print 'OK!';
    }
}

test();