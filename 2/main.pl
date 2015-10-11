use strict;
use warnings;
use POSIX qw( isdigit );
use feature 'switch';

my %priority = (
    '+' => 3,
    '-' => 3,
    '*' => 2,
    '/' => 2,
    '^' => 1
);

sub get_lexems {
    my @lexems = ();
    my @array = split(//, $_[0]);
    my $number = '';
    my $prev_char = undef;

    foreach (@array) {
        if ($prev_char eq '*') {
            if ($_ eq '*') {
                push @lexems, '^'; # replace ** with ^
                $prev_char = undef;
                next
            } else {
                push @lexems, '*';
            }
        } 

        if (isdigit($_) or $_ eq '.') {
            $number .= $_ ;
        } else {
            push @lexems, $number;
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

sub convert_to_polish {
    my @stack_num = ();
    my @stack_op = ();
    my @result = ();
    my $pos = 0;

    foreach (@_) {
        if (isdigit($_)) {
            push @stack_num, $_
        } else {
            my $op_prior = $priority{$_};
            while (@stack_op and $priority{$stack_op[-1]} <= $op_prior and $_ ne '^') {
                print "hi\n";
                my $cur_op = pop @stack_op;
                #@result and push @result, (pop @stack_num) or push @result, (pop @stack_num) and push @result, (pop @stack_num);
                if (@result) { 
                    unshift @result, pop @stack_num;
                    push @result, $cur_op
                } else { 
                    my $b = pop @stack_num;
                    my $a = pop @stack_num;
                    push @result, ($a, $b, $cur_op)
                }
            }
            push @stack_op, $_
        }
    }
    #print join ' ', @stack_op, "\n";
    while (@stack_op) {
        my $cur_op = pop @stack_op;
        if (@result) { 
            unshift @result, pop @stack_num;
            push @result, $cur_op
        } else {
            my $b = pop @stack_num;
            my $a = pop @stack_num;
            print $a, "\n";
            push @result, ($a, $b, $cur_op)
        }
    }
    return @result;
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
=pod
        my $len = scalar @stack;
        print "DEBUG: len=$len ";
        foreach my $c (@stack) {
            print $c, ' ';
        }
        print "\n";
=cut
    }
    return pop @stack
};


sub evaluate_expr {
    return eval_polish(convert_to_polish(get_lexems($_[0])));
}

#my $line = readline(*STDIN);
my $line = '5-9^0.5';
my @items = get_lexems($line);
print join ' ', @items, "\n";
print join ' ', convert_to_polish(@items), "\n";
print eval_polish(convert_to_polish(@items));
#print evaluate_expr($line);
=pod
foreach (@items) {
    print $_, ' ', $priority{$_}, "\n"
}
=cut
