use v6;

use Net::IRC::Bot;

sub parrot-release-after(Date $date is copy = Date.today) {
    $date++ until $date.day-of-week == 2;
    $date += 7 until ($date.day-of-month - 1) div 7 == 2;
    $date;
}

sub rakudo-release-after(Date $date = Date.today) {
    parrot-release-after($date) + 2;
}

sub niecza-release-after(Date $date = Date.today) {
    my $d = $date.truncated-to(:week);
    $d += 7 if $d.month < $date.month;
    $d += 7 while $d.month == ($d + 7).month;
    $d;
}

my $nick = 'p6rd';

class ReleaseDates {
    method !msg($from = Date.today) {
        my @dates = <rakudo parrot niecza>.map(
            { ; $_ => ::("&{$_}-release-after")($from) }
        ).sort: *.value;
        return join ', ', @dates.map: -> $d { $d.key ~ ' ' ~ $d.value };
    }
    multi method said($e where { $e.what ~~ /^ $nick ':' <.ws> [ '?' | 'help' | 'h'] /}) {
        $e.msg: "Perl 6 release dates. Usage: $nick: [ 'next' | 'next month' | YYYY-MM | YYYY-MM-DD ]";
    }
    multi method said($e where { $e.what ~~ /^ $nick ':' <.ws> [ 'next' | 'this month' | upcoming | soon ] \s* $ / }) {
        $e.msg: self!msg();
    }
    multi method said($e where { $e.what ~~ /^ $nick ':' <.ws> 'next month' \s* $ / }) {
        my $next-month = (Date.today.truncated-to(:month) + 31).truncated-to(:month);
        $e.msg: self!msg($next-month);
    }
    multi method said($e where { $e.what ~~ /^ $nick ':' <.ws> \d**4 '-' \d ** 2 / }) {
        if $e.what ~~ /^ $nick ':' <.ws> (\d**4) '-' (\d\d) [ '-' (\d\d)]? / {
            my $from = Date.new(+$0, +$1, +($2[0] // 1));
            $e.msg: self!msg($from);
        }
        else {
            die "Internal error: can't match {$e.what}";
        }
    }
    multi method said($e where { $e.what ~~ /^ $nick ':' \s* source / }) {
        $e.msg: 'https://github.com/moritz/p6-release-dates/'
    }

}

Net::IRC::Bot.new(
    :$nick,
    server   => 'irc.freenode.net',
    channels => <#perl6 #bottest>,
    modules  => [ ReleaseDates.new ],
).run;
