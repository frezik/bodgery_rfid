#!perl
use v5.14;
use Audio::Beep::Linux::beep;

my $player = Audio::Beep::Linux::beep->new;

my $music = "g' f bes' c8 f d4 c8 f d4 bes c g f2";
$player->play( $music );
