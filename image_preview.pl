use strict;
use warnings;

use Irssi;
use LWP::Simple;
use IPC::Cmd qw[can_run run];
use File::Temp qw/ tempfile /;

use vars qw($VERSION %IRSSI);
our $VERSION = '1.00';
our %IRSSI = (
    authors     => 'Bastien Wirtz',
    contact     => 'bastien.wirtz@gmail.com',
    name        => 'Image preview',
    description => 'Use img2txt (libcaca) to preview images link in channel message',
    license     => 'GNU GPLv3',
);

sub init {
    if (can_run('img2txt')) { 
        Irssi::signal_add('message public', 'messageHandler');
    } else { 
        Irssi::print('Unable to find img2txt !');
    }
}

sub messageHandler {
    my ($server, $msg, $nick, $nick_addr, $target) = @_;

    # Find all image link in messages
    my (@Matches) = ( $msg =~ m/((http|https):\/\/[^\s]+\.(jpeg|jpg|png))/g );

    my ($fh, $tempfile) = tempfile();
    for ( my $i = 0 ; $i < $#Matches ; $i += 3 ) {

        if (!downloadFile($Matches[$i], $tempfile)) {
            $server->print($target, "Fail to get $Matches[$i] for preview", MSGLEVEL_CRAP);
            return;          
        }

        my ($status, @preview) = preview($tempfile);
        if ($status) {
            $server->print($target, "Fail to generate preview for $Matches[$i]", MSGLEVEL_CRAP);
            return;
        }

        $server->print($target, "Preview of $Matches[$i]", MSGLEVEL_CRAP);
        foreach my $line(@preview) {
            $server->print($target, $line, MSGLEVEL_CRAP);
        }
    }    
}

sub downloadFile {
    my ($url, $dest) = @_;
    return is_success(getstore($url, $dest));
}

sub preview {
    my ($file) = @_;
    my @preview  = `img2txt --format=irc $file 2> /dev/null`;
    my $status   = $?;

    chomp(@preview);

    return ($status, @preview);
}

init();
