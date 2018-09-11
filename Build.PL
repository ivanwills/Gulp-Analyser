use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Gulp::Analyser',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/Gulp/Analyser.pm',
    requires          => {
        'perl'                      => '5.008',
        'AnyEvent'                  => '7.14',
        'AnyEvent::Handle'          => '7.14',
        'AnyEvent::Inotify::Simple' => '0.03',
        'CHI::Memoize'              => '0.07',
        'JSON::XS'                  => '3.04',
        'List::MoreUtils'           => '0.416',
        'Moo'                       => '2.003004',
        'Path::Tiny'                => '0.104',
        'Test::More'                => '1.302073',
        'Time::HiRes'               => '1.9741',
        'YAML::XS'                  => '0.69',
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => 0,
        'Test::Warnings' => 0,
    },
    add_to_cleanup     => [ 'Gulp-Analyser-*' ],
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/Gulp-Analyser.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Gulp::Analyser',
        },
    },
);

$builder->create_build_script();
