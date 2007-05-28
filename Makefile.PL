use strict;
use inc::Module::Install;

name('DateTime-Calendar-Chinese');
all_from('lib/DateTime/Calendar/Chinese.pm');

requires 'DateTime::Event::Chinese' => 0.05;
requires 'Math::Round';
requires 'Params::Validate';
auto_install;
WriteAll;