#!perl

# This is a test that iterates through *each* date for a span that's
# about a bit longer than a year. DT::C::Chinese calculates local
# date components using a very funky algorithm, and it turned out that
# even if one date is converted okay, by the next new moon we may have
# problems... so instead, we just go through one date at a time and
# just verify each component (that we can)

# This test won't be run by default. You'd haev to set an environment
# variable DO_EXTENDED_CHINESE_TESTS. (Hey, after all people will get
# pissed if an installation takes like an hour)

BEGIN
{
    require Test::More;
    if ($ENV{DO_EXTENDED_CHINESE_TESTS}) {
        Test::More->import(tests => 366);
        diag("*** This test will take an eternity to finish! Beware...***");
        diag("Starting on " . scalar(localtime));
        use_ok("DateTime::Calendar::Chinese");
    } else {
        Test::More->import(skip_all => "won't run extended tests unless explicitly specified");
    }
}


# Go from Jan 1 2003 to Jan 31 2004
my $start = DateTime->new(year => 2003, month => 1, day => 1, time_zone => 'Asia/Taipei');
my $end   = DateTime->new(year => 2004, month => 1, day => 31, time_zone => 'Asia/Taipei');

# Feb 1, 2003 and Jan 22, 2004 are the new years
my $ny2003 = DateTime->new(year => 2003, month => 2, day => 1, time_zone => 'Asia/Taipei');
my $ny2004 = DateTime->new(year => 2004, month => 1, day => 22, time_zone => 'Asia/Taipei');

diag("Generating new moons...");
# Generate the new moons so we know months roll over
my $new_moon  = DateTime::Event::Lunar->new_moon();
my $span      = DateTime::Span->new(start => $start, end => $end);
my $set       = $new_moon->intersection($span);
my @new_moons = $set->as_list();

my $dt   = $start->clone;
my $prev = undef;
while ($dt <= $end) {
    diag("Testing " . $dt->datetime);
    my $cc = DateTime::Calendar::Chinese->from_object(object => $dt);
    diag("elapsed years: " . $cc->elapsed_years . " cycle: " . $cc->cycle .
        " cycle_year: " . $cc->cycle_year . " month: " . $cc->month .
        " day: " . $cc->day);

    # during 2003 - 2004, the cycle is always 78
    is($cc->cycle, 78);
    if ($dt < $ny2003) {
        is($cc->cycle_year, 19);
    } elsif ($dt < $ny2004) {
        is($cc->cycle_year, 20);
    } else {
        is($cc->cycle_year, 21);
    }

    if ($prev) {
        my $dt_from_cc   = DateTime->from_object(object => $cc);
        my $dt_from_prev = DateTime->from_object(object => $prev);
        is($dt_from_cc->compare($prev), 1);

        if ($dt == $ny2003 || $dt == $ny2004) {
            is($prev->cycle_year, $cc->cycle_year - 1);
        } else {
            is($prev->cycle_year, $cc->cycle_year);
        }

        if (grep { $dt_from_cc == $_ } @new_moons) {
            if ($cc->month == 1) {
                is($prev->month, 12);
            } else {
                is($prev->month, $cc->month - 1);
            }
        }
    }

    $prev = $cc;
    $dt->add(days => 1);
    
}

