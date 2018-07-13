package Gulp::Analyser;

# Created on: 2018-07-13 20:01:46
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use List::MoreUtils qw/uniq/;
use English qw/ -no_match_vars /;
use FindBin qw/$Bin/;
use File::stat;

our $VERSION = 0.001;

has gulp => (
    is => 'ro',
);
has depth => (
    is      => 'rw',
    default => 10,
);

sub generate_report {
    my ($self, $task, $depth, @pre_tasks) = @_;
    $depth ||= 0;

    return if $depth >= $self->depth;

    for my $pre_task (@pre_tasks) {
        $self->run_gulp($pre_task);
    }

    my $report = {};
    my $states = $self->file_states('.');
    $report->{tasks} = $self->run_gulp($task);
    my $final = $self->file_states('.');
    $report->{files} = $self->files_changed($states, $final);

    for my $sub_task (@{ $report->{tasks} }) {
        $sub_task->{report} = $self->generate_report($sub_task->{task}, $depth + 1, @pre_tasks);
        push @pre_tasks, $sub_task->{task};
    }

    return $report;
}

sub files_changed {
    my ($self, $orig, $result) = @_;
    my %changed;

    my @files = uniq sort keys %$orig, keys %$result;

    for my $file (@files) {
        next if $orig->{$file}
            && $result->{$file}
            && $orig->{$file}{size} == $result->{$file}{size}
            && $orig->{$file}{mtime} == $result->{$file}{mtime};

        $changed{$file} = $orig->{$file} && !$result->{$file} ? 'removed'
            : !$orig->{$file} && $result->{$file}             ? 'added'
            :                                                   'changed';
    }

    return \%changed;
}

sub run_gulp {
    my ($self, $task) = @_;
    my @report;

    my @log = `$self->{gulp} $task`;
    for my $log_line (@log) {
        my ($sub_task, $time, $unit) = $log_line =~ /Finished \s+ '([^']+)' \s+ after \s+ (\d+) \s+ (\w+)/xms;
        next if !$sub_task;
        push @report, {
            task => $sub_task,
            time => $time,
            unit => $unit,
        };
    }

    return \@report;
}

sub file_states {
    my ($self, $dir, $states) = @_;
    $states ||= {};

    my @files = glob("$dir/*");
    for my $file (@files) {
        if ( -d $file ) {
            $self->file_states($file, $states);
        }
        else {
            my $stats = stat($file);
            $states->{$file} = {
                size  => $stats->size,
                atime => $stats->atime,
                mtime => $stats->mtime,
                ctime => $stats->ctime,
            };
        }
    }

    return $states;
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
