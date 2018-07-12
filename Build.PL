use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name       => 'Gulp::Analyser',
	license           => 'perl',
	dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
	dist_version_from => 'lib/Gulp/Analyser.pm',
	requires          => {
		'perl'             => 5.008,
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
