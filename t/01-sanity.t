#!perl
use Test::More tests => 23;
BEGIN
{
    print STDERR 
        "\n*** This test will take a long time, please be patient ***\n",
        "*** Starting on ", scalar(localtime), "\n";
    use_ok("DateTime::Calendar::Chinese");
}

my $cc;
# 1 Jan 2004 is cycle (78) year 20 (Gui-Wei [Sheep]) month 12, day 10

my $dt = DateTime->new(year => 2004, month => 1, day => 1, time_zone => 'Asia/Taipei');
$cc    = DateTime::Calendar::Chinese->from_object(object => $dt);

can_ok($cc, "cycle", "cycle_year", "month", "leap_month", "day",
      "utc_rd_values");
check_cc($cc, 78, 20, 12, 10, $dt->day_of_week, ($dt->utc_rd_values())[0]);

my $dt2 = DateTime->new(year => 2003, month => 11, day => 25, time_zone => 'Asia/Taipei');

$cc->set(month => 11, day => 3);
check_cc($cc, 78, 20, 11, 3, $dt2->day_of_week, ($dt2->utc_rd_values())[0]);

$cc    = DateTime::Calendar::Chinese->new(
    cycle      => 78,
    cycle_year => 20,
    month      => 12,
    day        => 10,
    time_zone  => 'Asia/Taipei'
);
check_cc($cc, 78, 20, 12, 10, $dt->day_of_week, ($dt->utc_rd_values())[0]);


sub check_cc
{
    my($cc, $cc_cycle, $cc_cycle_year, $cc_month, $cc_day, $cc_day_of_week, $cc_rd_days) = @_;

    isa_ok($cc, "DateTime::Calendar::Chinese");
    
    is($cc->cycle,       $cc_cycle);
    is($cc->cycle_year,  $cc_cycle_year);
    is($cc->month,       $cc_month);
    is($cc->day,         $cc_day);
    is($cc->day_of_week, $cc_day_of_week);
    
    my @vals = $cc->utc_rd_values();
    is($vals[0], $cc_rd_days);
}
