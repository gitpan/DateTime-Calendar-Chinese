#!perl
# $Id: Build.PL,v 1.4 2005/06/28 02:18:19 lestrrat Exp $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'DateTime::Calendar::Chinese',
    dist_name => 'DateTime-Calendar-Chinese',
    license => 'perl',
    requires => {
        'DateTime'                      => 0,
        'DateTime::Util::Calc'          => '>= 0.08',
        'DateTime::Util::Astro::Common' => '>= 0.02',
        'DateTime::Util::Astro::Moon'   => '>= 0.04',
        'DateTime::Event::Chinese'      => '>= 0.04',
        'DateTime::Event::Lunar'        => '>= 0.04',
        'DateTime::Event::SolarTerm'    => '>= 0.04',
        'Math::Round'                   => 0,
        'Params::Validate'              => 0,
    },
    recommends => {
        'perl' => '5.6.1',
    },
    create_makefile_pl => 'traditional'
);
$build->create_build_script;
