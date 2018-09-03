package Gulp::Analyser;

# Created on: 2018-07-13 20:01:46
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use Carp qw/carp croak cluck confess longmess/;
use List::MoreUtils qw/uniq/;
use English qw/ -no_match_vars /;
use FindBin qw/$Bin/;
use File::stat;
use Gulp::Analyser::Run;
use Data::Dumper;

our $VERSION = 0.001;
our $last_build = '';

has runner => (
    is => 'rw',
);
has depth => (
    is      => 'rw',
    default => 10,
);
has tasks => (
    is      => 'rw',
    default => sub {{}},
);

sub BUILD {
    my ($self, $args) = @_;

    $self->runner(Gulp::Analyser::Run->new(gulp => $args->{gulp} || 'gulp'));
}

sub generate_report {
    my ($self, $task, $depth, @pre_tasks) = @_;
    $depth ||= 0;
    confess "No tasked passed to generate_report!" if !$task;

    return if $depth >= $self->depth;
    return if $self->{tasks}{$task}++;

    warn "$task\n";
    if ( @pre_tasks && $last_build ne $pre_tasks[-1] ) {
        for my $pre_task (@pre_tasks) {
            # we shouldn't need to care about these out puts
            warn +(' ' x $depth), "gulp $pre_task\n";
            my $log = $self->runner->pre_run($task);
            if ( $log =~ /^Error / ) {
                warn $log;
                warn "Errored running task $pre_task\n";
                return {};
            }
        }
    }

    my $report = $self->runner()->run($task);
    my @tasks = @{ $report->{tasks} };
    $report->{tasks} = [];

    while ( my $sub_task  = shift @tasks) {
        next if $sub_task eq $task;
        push @{ $report->{tasks} }, $sub_task;
        $sub_task->{report} = $self->generate_report($sub_task->{task}, $depth + 1, @pre_tasks);
        push @pre_tasks, $sub_task->{task};

        if ( $sub_task->{report} && @{ $sub_task->{report}{tasks} } > 1 ) {
            # this task is a super task, so remove the child tasks form $task's list
            for my $child_task (@{ $sub_task->{report}{tasks} }[1 .. $#{ $sub_task->{report}{tasks} }]) {
                my @new_tasks;
                for my $parent (@tasks) {
                    push @new_tasks, $parent if $parent->{task} ne $child_task->{task};
                }
                @tasks = @new_tasks;
            }
        }
    }

    return $report;
}

1;

__END__

=head1 NAME

Gulp::Analyser - Analyse gulp tasks for what they actually do

=head1 VERSION

This documentation refers to Gulp::Analyser version 0.001

=head1 SYNOPSIS

   use Gulp::Analyser;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

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
