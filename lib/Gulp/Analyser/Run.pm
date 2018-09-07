package Gulp::Analyser::Run;

# Created on: 2018-08-27 07:27:50
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use File::stat;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Inotify::Simple;
use Time::HiRes qw/time/;

our $VERSION = 0.001;

has gulp => (
    is      => 'rw',
    default => 'gulp',
);
has filter => (
    is      => 'rw',
    default => sub {[qr/(?:[.]git|node_modules)/]},
);

sub pre_run {
    my ($self, $task) = @_;
    my $cmd = $self->gulp . " $task";

    return `$cmd`;
}

sub run {
    my ($self, $task) = @_;
    my (@tasks, %tasks, %report);
    my $start = 0;
    my $cv = AnyEvent->condvar;

    my $inotify = AnyEvent::Inotify::Simple->new(
        directory => '.',
        filter    => sub {
            my $file = shift;
            return $file =~ m{/(?:[.]git|node_modules)/};
        },
        event_receiver => sub {
            my ($event, $file, $moved_to) = @_;
            $moved_to ||= '';
            return if ! $start || -d $file || $file =~ /^[.]git|node_modules/;
            $report{files}{$file} ||= [];
            push @{ $report{files}{$file} }, $event if ! @{ $report{files}{$file} } || $report{files}{$file}[-1] ne $event;
        },
    );

    `echo "$task" >> gar.log`;
    my $cmd = $self->gulp . " $task | tee -a gar.log";
    open my $fh, '-|', $cmd or die "Could not run '$cmd': $!\n";
    my $timer;
    my $killing;

    my $hdl = AnyEvent::Handle->new(
        fh => $fh,
        on_error => sub {
            my ($hdl, $fatal, $msg) = @_;
            $hdl->destroy;
            $cv->send;
        },
        on_eof => sub {
            my ($hdl, $fatal, $msg) = @_;
            $hdl->destroy;
            $cv->send;
        },
        on_read => sub {
            shift->push_read(
                line => sub {
                    my ($hdl, $line) = @_;

                    if ( $line =~ /^Error /xms ) {
                        $hdl->stop_read();
                        return;
                    }

                    my ($start_task) = $line =~ /Starting '([^']+)'[.][.][.]/;
                    if ($start_task) {
                        if ( ! defined $tasks{$start_task} ) {
                            push @tasks, { task => $start_task };
                            $tasks{$start_task} = $#tasks;
                        }
                        return;
                    }

                    my ($sub_task, $magnitude, $unit) = $line =~ /Finished \s+ '([^']+)' \s+ after \s+ (\d+(?:[.]\d+)?) \s+ (\w+)/xms;
                    return if !$sub_task;

                    $tasks[$tasks{$sub_task}] = {
                        task => $sub_task,
                        time => $self->get_milliseconds($magnitude, $unit),
                        magnitude => $magnitude,
                        unit => $unit,
                    };
                }
            );
        },
    );
    $start = 1;

    my $time = time;
    my $count = 0;
    $timer = AnyEvent->timer(
        interval => 1,
        after    => 1,
        cb => sub {
            my $finished = 1;
            for my $task (@tasks) {
                $finished &&= defined $task->{time};
            }
            if ( $finished && $count++ ) {
                close $fh;
                $hdl->destroy;
                $cv->send;
            }
            else {
                $count = 0;
            }
        },
    );

    $cv->recv;

    $inotify->DEMOLISH();
    $inotify->inotify->DESTROY;
    undef $inotify;
    $killing = 1;
    undef $timer;
    undef $cv;
    $report{tasks} = \@tasks;
    return \%report;
}

sub get_milliseconds {
    my ($self, $magnitude, $unit) = @_;

    my $time = $unit eq 'ms' ? $magnitude
        : $unit eq 's'       ? $magnitude * 1000
        : $unit eq 'min'     ? $magnitude * 1000 * 60
        : $unit eq 'hr'      ? $magnitude * 1000 * 60 * 60
        :                      die "Error unknown unit for '$magnitude $unit'!\n";

    return $time;
}

1;

__END__

=head1 NAME

Gulp::Analyser::Run - Runs gulp commands and records the file they effect

=head1 VERSION

This documentation refers to Gulp::Analyser::Run version 0.0.1


=head1 SYNOPSIS

   use Gulp::Analyser::Run;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 Properties

=over 4

=item gulp

=item filter

=back

=head1 SUBROUTINES/METHODS

=head2 C<pre_run ( $task )>
=head2 C<run ( $task )>
=head2 C<get_milliseconds ( $magnitude, $unit )>

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
