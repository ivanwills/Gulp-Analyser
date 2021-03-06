package Gulp::Analyser::Log;

# Created on: 2018-07-16 11:52:51
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

our $VERSION = 0.001;

has name => (
    is       => 'rw',
    required => 1,
);
has log => (
    is      => 'rw',
    default => '',
);

sub log_report {
    my ($self, $log) = @_;
    my %report;
    my @report;
    my @stack;

    # [11:53:44] Starting 'build-widget-require-config'...
    # [11:53:44] Finished 'build-component-css' after 39 s

    my $line_re = qr/(Starting|Finished) \s+ '([^']+)'(?: [.][.][.] | \s+ after \s+ (\d+(?:[.]\d+)?) \s+ (\w+))/xms;

    for my $line (split /\n/, $log) {
        my ($type, $sub_task, $time, $unit) = $line =~ /$line_re/;
        next if !$type || !$sub_task;

        if ( $type eq 'Starting' ) {
            warn +('  ' x ($#stack + 1)), "+$sub_task\n";
            push @stack, $sub_task;
        }
        elsif ( $type eq 'Finished' ) {
            warn +('  ' x $#stack), "-$sub_task\n";
            warn +(join '/', @stack), "\n" if $stack[-2] && $stack[-2] eq $sub_task;
            pop @stack if $stack[-1] eq $sub_task || ($stack[-2] && $stack[-2] eq $sub_task);
            pop @stack if $stack[-1] && $stack[-1] eq $sub_task;
        }
    }

    return \@report;
}

sub get_stack {
    my ($self, $report, @stack) = @_;
    my $stack = $report;

    for my $item (@stack) {
        $stack->{$item} ||= {};
        $stack = $stack->{$item};
    }

    return $stack;
}

sub TO_JSON {
    my ($self) = @_;

    return ;
}

1;

__END__

=head1 NAME

Gulp::Analyser::Log - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to Gulp::Analyser::Log version 0.001

=head1 SYNOPSIS

   use Gulp::Analyser::Log;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.

May include numerous subsections (i.e., =head2, =head3, etc.).


=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.

These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module
provides.

Name the section accordingly.

In an object-oriented module, this section should begin with a sentence (of the
form "An object of this class represents ...") to give the reader a high-level
context to help them understand the methods that are subsequently described.


=head3 C<new ( $search, )>

Param: C<$search> - type (detail) - description

Return: Gulp::Analyser::Log -

Description:

=cut


=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate (even
the ones that will "never happen"), with a full explanation of each problem,
one or more likely causes, and any suggested remedies.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all of the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also, a list of restrictions on the features the module does provide: data types
that cannot be handled, performance issues and the circumstances in which they
may arise, practical limitations on the size of data sets, special cases that
are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
