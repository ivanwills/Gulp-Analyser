#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'Gulp::Analyser' );
}

diag( "Testing Gulp::Analyser $Gulp::Analyser::VERSION, Perl $], $^X" );
done_testing();
