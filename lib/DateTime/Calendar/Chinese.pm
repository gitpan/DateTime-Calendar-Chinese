package DateTime::Calendar::Chinese;
use strict;
use vars qw($VERSION);
BEGIN
{
    $VERSION = '0.01';
}

use DateTime;
use DateTime::Event::Chinese;
use DateTime::Event::Lunar;
use DateTime::Event::SolarTerm;
use DateTime::Util::Astro::Common qw(MEAN_TROPICAL_YEAR);
use DateTime::Util::Astro::Moon qw(MEAN_SYNODIC_MONTH);
use DateTime::Util::Calc qw(moment dt_from_moment amod);
use Math::Round qw(round);
use Params::Validate();
use constant GREGORIAN_CHINESE_EPOCH => DateTime->new(
    year => -2636, month => 2, day => 15, time_zone => 'UTC');
use constant GREGORIAN_CHINESE_EPOCH_MOMENT => moment(GREGORIAN_CHINESE_EPOCH);

my %BasicValidate = (
    cycle => {
        default => 1,
    },
    cycle_year  => {
        default   => 1,
        callbacks => {
            'is between 1 and 60' => sub { $_[0] >= 1 && $_[0] <= 60 }
        }
    },
    month => {
        default   => 1,
        callbacks => {
            'is between 1 and 12' => sub { $_[0] >= 1 && $_[0] <= 12 }
        }
    },
    leap_month => {
        default => 0,
        type => Params::Validate::BOOLEAN()
    },
    day        => {
        default   => 1,
        type => Params::Validate::SCALAR()
    },
    hour   => {
        type => Params::Validate::SCALAR(), default => 0,
        callbacks => {
            'is between 0 and 23' => sub { $_[0] >= 0 && $_[0] <= 23 },
        },
    },
    minute => {
        type => Params::Validate::SCALAR(), default => 0,
        callbacks => {
            'is between 0 and 59' => sub { $_[0] >= 0 && $_[0] <= 59 },
        },
    },
    second => {
        type => Params::Validate::SCALAR(), default => 0,
        callbacks => {
            'is between 0 and 61' => sub { $_[0] >= 0 && $_[0] <= 61 },
        },
    },
    nanosecond => {
        type => Params::Validate::SCALAR(), default => 0,
        callbacks => {
            'cannot be negative' => sub { $_[0] >= 0 },
        }
    },
    locale    => { type => Params::Validate::SCALAR() | Params::Validate::OBJECT(), optional => 1 },
    language  => { type => Params::Validate::SCALAR() | Params::Validate::OBJECT(), optional => 1 },
);

my %NewValidate = (
    %BasicValidate,
    time_zone  => { type => Params::Validate::SCALAR() | Params::Validate::OBJECT(), default => 'floating' },
);
sub new
{
    my $class = shift;
    my %args  = Params::Validate::validate(@_, \%NewValidate);

    # XXX - currently _calc_gregorian_components() calculates the
    # date component only, then we set the time
    my %hash;
    $hash{cycle}      = delete $args{cycle};
    $hash{cycle_year} = delete $args{cycle_year};
    $hash{month}      = delete $args{month};
    $hash{leap_month} = delete $args{leap_month};
    $hash{day}        = delete $args{day};

    my $self  = bless \%hash, $class;
    $self->_calc_gregorian_components();

    if (exists $args{time_zone}) {
        $self->{gregorian}->set_time_zone(delete $args{time_zone});
    }
    $self->{gregorian}->set(%args);

    $self;
}

# XXX - these values are proxies directly to the underlying DateTime
# (Gregorian) object.
sub utc_rd_values { $_[0]->{gregorian}->utc_rd_values }
sub hour          { $_[0]->{gregorian}->hour }
sub minute        { $_[0]->{gregorian}->minute }
sub second        { $_[0]->{gregorian}->second }
sub day_of_week   { $_[0]->{gregorian}->day_of_week }
sub set_time_zone { shift->{gregorian}->set_time_zone(@_) }

# XXX - accessors for DT::C::C specific fields
sub cycle      { $_[0]->{cycle} }
sub cycle_year { $_[0]->{cycle_year} }
sub month      { $_[0]->{month} }
sub leap_month { $_[0]->{leap_month} }
sub day        { $_[0]->{day} }

my %SetValidate = %BasicValidate;
foreach my $spec (values %SetValidate) {
    delete $spec->{default};
    $spec->{optional} = 1;
}

sub set
{
    my $self = shift;
    my %args  = Params::Validate::validate(@_, \%SetValidate);
    $self->{cycle}      = delete $args{cycle} if exists $args{cycle};
    $self->{cycle_year} = delete $args{cycle_year} if exists $args{cycle_year};
    $self->{month}      = delete $args{month} if exists $args{month};
    $self->{leap_month} = delete $args{leap_month} if exists $args{leap_month};
    $self->{day}        = delete $args{day} if exists $args{day};

    $self->_calc_gregorian_components();
    $self->{gregorian}->set(%args) if keys %args;
    $self;
}

sub from_epoch
{
    my $class = shift;
    my $self  = bless {}, $class;
    my $dt    = DateTime->from_epoch(@_);
    $self->{gregorian} = $dt;
    $self->_calc_local_components();
    return $self;
    
}
sub now { $_[0]->from_epoch(@_, epoch => time()) }

sub from_object
{
    my $class = shift;
    my $self  = bless {}, $class;
    my $dt    = DateTime->from_object(@_);

    $self->{gregorian} = $dt;
    $self->_calc_local_components();
    return $self;
}

sub _calc_gregorian_components
{
    my $self = shift;

    my $mid_year = POSIX::floor(
        GREGORIAN_CHINESE_EPOCH_MOMENT + 
        (($self->cycle() - 1) * 60 + $self->cycle_year() - 1 + 0.5) *
        MEAN_TROPICAL_YEAR);
    my $new_year = DateTime::Event::Chinese->new_year_before(
        datetime     => dt_from_moment($mid_year),
        on_or_before => 1
    );
    my $p = DateTime::Event::Lunar->new_moon_after(
        datetime    => dt_from_moment( moment($new_year) + ($self->month - 1) * 29 ),
        on_or_after => 1
    );
    my $d = ref($self)->from_object(object => $p);

    my $prior_new_moon = 
        $d->month == $self->month && $d->leap_month == $self->leap_month ?
        $p :
        DateTime::Event::Lunar->new_moon_after(
            datetime    => $p + DateTime::Duration->new(days => 1),
            on_or_after => 1);

    $self->{gregorian} = $prior_new_moon + DateTime::Duration->new(days => $self->day - 1);
#    $self->_calc_local_components
}

sub _calc_local_components
{
    my $self = shift;
    my $dt   = $self->{gregorian};

    # winter solstice
    my $s1 = DateTime::Event::SolarTerm->prev_term_at(
        datetime  => $dt,
        longitude => 270);

    my $s2 = DateTime::Event::SolarTerm->prev_term_at(
        datetime  => $s1 + DateTime::Duration->new(days => 370),
        longitude => 270);

    my $m12 = DateTime::Event::Lunar->new_moon_after(
        datetime    => $s1 + DateTime::Duration->new(days => 1),
        on_or_after => 1);
    my $next_m11 = DateTime::Event::Lunar->new_moon_before(
        datetime => $s1 + DateTime::Duration->new(days => 1));
    my $m = DateTime::Event::Lunar->new_moon_before(
        datetime => $dt + DateTime::Duration->new(days => 1 ));

    my $leap_year =
        round((moment($next_m11) - moment($m12)) / MEAN_SYNODIC_MONTH) == 12;
    my $month = amod(
        round((moment($m) - moment($m12)) / MEAN_SYNODIC_MONTH) -
        $leap_year && $self->_prior_leap_month($m12, $m) ? 1 : 0, 12);
    my $elapsed_years = POSIX::floor(
        1.5 - $month / 12 + (moment($dt) - GREGORIAN_CHINESE_EPOCH_MOMENT) / MEAN_TROPICAL_YEAR);

    $self->{cycle}      = POSIX::floor( ($elapsed_years - 1) / 60) + 1;
    $self->{cycle_year} = amod($elapsed_years, 60);
    $self->{month}      = $month;
    $self->{day}        = POSIX::ceil(moment($dt) - moment($m) + 1);

    $self->{leap_month} = ($leap_year && DateTime::Event::SolarTerm->no_major_term_on($m) &&
        !$self->_prior_leap_month($m12,
            DateTime::Event::Lunar->new_moon_before(datetime => $m))) ? 1 : 0;
}

# [1] p.250
sub _prior_leap_month
{
    my $class = shift;
    my($start, $end) = @_;

    return $start <= $end && (
        DateTime::Event::SolarTerm->no_major_term_on(datetime => $end) or
        $class->_prior_leap_month($start,
            DateTime::Event::Lunar->new_moon_before(datetime => $end) ) );
}

1;
__END__

=head1 NAME

DateTime::Calendar::Chinese - Traditional Chinese Calendar Implementation

=head1 SYNOPSIS

  use DateTime::Calendar::Chinese;

  my $dt = DateTime::Calendar::Chinese->now();
  my $dt = DateTime::Calendar::Chinese->new(
    cycle      => $cycle,
    cycle_year => $cycle_year,
    month      => $month,
    leap_month => $loeap_month,
    day        => $day,
  );

  $dt->cycle;
  $dt->cycle_year; # 1 - 60
  $dt->month;      # 1-12
  $dt->leap_month; # true/false
  $dt->day;        # 1-30 

  my ($rd_days, $rd_secs, $rd_nanosecs) = $dt->utc_rd_values();

=head1 DESCRIPTION

This is an implementation of the Chinese calendar as described in 
"Calendrical Calculations" [1]. Please note that the following description
is the description from [1], and the author has not made attempts to verify
the correctness of statements with other sources.

The Chinese calendar described in [1] is expressed in terms of "cycle",
"cycle_year", "month", "a boolean leap_month", and "day".

Traditional Chinese years have been counted using the "Sexagecimal Cycle
of Names", which is a cycle of 60 names for each year. The names are
the combination of a "celestial stem" (tian gan), with a "terrestial branch"
(di zhi):

    Celestial Stems         Terrestial Branches
  -------------------     -----------------------
  | Jia             |     | Zi (Rat)            |
  -------------------     -----------------------
  | Yi              |     | Chou (Ox)           |
  -------------------     -----------------------
  | Bing            |     | Yin (Tiger)         |
  -------------------     -----------------------
  | Ding            |     | Mao (Hare)          |
  -------------------     -----------------------
  | Wu              |     | Chen (Dragon)       |
  -------------------     -----------------------
  | Ji              |     | Si (Snake)          |
  -------------------     -----------------------
  | Geng            |     | Wu (Horse)          |
  -------------------     -----------------------
  | Xin             |     | Wei (Sheep)         |
  -------------------     -----------------------
  | Ren             |     | Shen (Monkey)       |
  -------------------     -----------------------
  | Gui             |     | You (Fowl)          |
  -------------------     -----------------------
                          | Xu (Dog)            |
                          -----------------------
                          | Hai (Pig)           |
                          -----------------------

Names are assigned by running each list sequentially, so the first year
woud be jiazi, then yuchou, bingyin, and so on. 

Chinese months are true lunar months, which starts on a new moon and runs
until the day before the next new moon. Therefore each month consists of
 exactly 29 or 30 days. The month numbers are calculated based on a logic
that combines lunar months and solar terms (which is too hard to explain
here -- read "Calendrical Calculation" you must know), and may include
leap months.

Leap months can be inserted anywhere in the year, so months are numbered
from 1 to 12, with the boolean flag "leap_month" that indicates if the
month is a leap month or not.

=head1 METHODS

=head2 new

This class method accepts parameters for each date and time component: "cycle",
"cycle_year", "month", "leap_month", "day", "hour", "minute", "second",
"nanosecond". It also accepts "locale" and "time_zone" parameters.

=head2 now

This class method is equivalent to calling from_epoch() with the value
returned from Perl's time() function. 

=head2 from_object(object => ...)

This class method can be used to construct a new DateTime::Calendar::Chinese
object from any object that implements the utc_rd_values() method. 

=head2 from_epoch(epoch => ...)

This class method can be used to construct a new DateTime::Calendar::Chinese
object from an epoch time instead of components.  

=head2 set(...)

This method is identical to that of DateTime, except the date components
that can be set are restricted to the Chinese ones ("cycle", "cycle_year",
"month", "leap_month", "day"). The time components are the same as 
that of DateTime (See L<CAVEATS|/CAVEATS>).

=head2 utc_rd_values()

Returns the current UTC Rata Die days, seconds, and nanoseconds as a three
element list. This method is identical to that of L<DateTime>.

=head2 cycle

Returns the current cycle of the sexagecimal names since the Chinese epoch
(defined to be 25 Feb, -2636 gregorian).

=head2 cycle_year

Returns the current year in the current cycle. 

=head2 month

Returns the current month.

=head2 leap_month

Returns true if the current month is a leap month.

=head2 day

Returns the current day.

=head1 CAVEATS

Because "Calendrical Calculations" did not go much in detail about the
Chinese time system, this module simply uses the time components from the
underlying DateTime module (XXX - Note: we may implement this later, so
be careful not to use the time components too much for now)

=head1 AUTHOR

Daisuke Maki E<lt>daisuke@cpan.orgE<gt>

=head1 REFERENCES

  [1] Edward M. Reingold, Nachum Dershowitz
      "Calendrical Calculations (Millenium Edition)", 2nd ed.
       Cambridge University Press, Cambridge, UK 2002

=head1 SEE ALSO

L<DateTime>
L<DateTime::Event::Chinese>

=cut

