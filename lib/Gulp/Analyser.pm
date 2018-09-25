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
has gulp => (
    is      => 'rw',
    default => 'gulp',
);
has filter => (
    is      => 'rw',
    default => sub {[qr/(?:[.]git|node_modules)/]},
);

sub generate_report {
    my ($self, $task, $depth, @pre_tasks) = @_;
    $depth ||= 0;

    return if $depth >= $self->depth;
    return if $self->{tasks}{$task // '"default"'}++;

    my $runner = Gulp::Analyser::Run->new(%$self);

    if ( @pre_tasks && $last_build ne $pre_tasks[-1] ) {
        for my $pre_task (@pre_tasks) {
            # we shouldn't need to care about these out puts
            my $log = $runner->pre_run($pre_task);
            if ( $log =~ /^Error / ) {
                warn "Errored running task $pre_task\n";
                return {};
            }
        }
    }

    warn +('  ' x $depth) . ($task // '"default"') . "\n";
    my $keys = Dumper({ %$self });
    $keys =~ s/^.VAR1\s+=\s+//;
    $keys =~ s/;\n?\Z//;
    $keys =~ s/'/'\\''/g;
    $task //= '';
    my $report = `perl -MData::Dumper -MGulp::Analyser::Run -e 'print Dumper(Gulp::Analyser::Run->new($keys)->run("$task"))'`;
    #my $report = $runner->run($task);
    undef $runner;
    $report =~ s/^.VAR1\s+=\s+//;
    $report = eval $report; ## no critic
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

sub describe_files {
    my ($self, $task, $report, @files) = @_;
    my %answer;
    my %answers;

    if ( $report->{level} ) {
        my @search = @files;
        for my $file (keys %{ $report->{files} || {} }) {
            for my $i (0 .. $#search) {
                next if $search[$i] && $file ne $search[$i];

                my $read   = (grep {$_ eq 'access'} @{ $report->{files}{$file} }) ? 1 : 0;
                my $create = (grep {$_ eq 'modify'} @{ $report->{files}{$file} }) ? 1 : 0;

                if ( $read && $create ) {
                    $answer{$file} = {
                        read   => $read  ,
                        create => $create,
                    };
                }
                else {
                    $answer{$file} = $read ? 'read' : $create ? 'create' : 'other';
                }
                @search = map {$_ != $i ? $search[$_] : ()} 0 .. $#search;
            }
        }
        %answers = ( $task => \%answer );
    }

    for my $task (@{ $report->{tasks} }) {
        next if ! $task->{report};

        $task->{report}{level} = ($report->{level} || 0) + 1;
        my %answer = $self->describe_files($task->{task}, $task->{report}, @files);
        if (%{ $answer{$task->{task}} }) {
            %answers = ( %answers, %answer );
        }
    }

    return %answers;
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

=head1 Properties

=over 4

=item runner

=item depth

=item tasks

=item gulp

=item filter

=back

=head1 SUBROUTINES/METHODS

=head2 C<generate_report ( $task, $depth, @pre_tasks)>

=head2 C<describe ( $task, $report, @files)>

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
