use strict;
use Module::Build;

my $build = Module::Build->new(
	module_name => 'DateTime::Calendar::Chinese',
	dist_name => 'DateTime-Calendar-Chinese',
	license => 'perl',
	requires => {
		'DateTime'                      => 0,
		'DateTime::Util::Calc'          => 0,
		'DateTime::Util::Astro::Common' => 0,
		'DateTime::Util::Astro::Moon'   => 0,
		'DateTime::Event::Chinese'      => 0,
		'DateTime::Event::Lunar'        => 0,
		'DateTime::Event::SolarTerm'    => 0,
        'Math::Round'                   => 0,
		'Params::Validate'              => 0,
	},
	recommends => {
		'perl' => '5.6.1',
	},
	sign => 1,
    create_makefile_pl => 'passthrough'
);
$build->create_build_script;
