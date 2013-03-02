#!/usr/bin/perl -w

# CheckGmail
# Uses Atom feeds to check Gmail for new mail and displays status in
# system tray; optionally saves password in encrypted form using
# machine-unique passphrase

# version 1.13svn (14/2/2008)
# Copyright © 2005-7 Owen Marshall

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version. 
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details. 
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 
# USA

use strict;
# use utf8;


###########################
# Command-line processing
#

# global variables (can't be set global in the BEGIN block)
my ($version, $silent, $nocrypt, $update, $profile, $disable_monitors_check,
		$private, $cookies, $popup_size, $hosted_tmp, $show_popup_delay, 
		$popup_persistence, $usekwallet, $nologin, $mailno, $debug);
BEGIN {
	$version = "1.13svn";
	$silent = 1;
	$profile = "";
	$cookies = 1;
	$show_popup_delay = 250;
	$popup_persistence = 100;
	
	# simple command line option switch ...
	foreach (@ARGV) {
		next unless m/\-(.*)/;
		for ($1) {
			/profile=(.*)/ && do {
				$profile = "-$1";
				last };
			
			/private/ && do {
				$private = 1;
				last };		
			
			/silent/ && do {
				$silent = 1;
				last };
				
			/disable-monitors-check/ && do {
				$disable_monitors_check = 1;
				last };
				
				
			/no-login/ && do {
				$nologin = 1;
				last };
				
			/cookie_login/ && do {
				$cookies = 1;
				last };
				
			/no_cookies/ && do {
				$cookies = 0;
				last };
				
			# /label=(.*),(\d+)/ && do {
				# $label_tmp{$1} = $2;
				# last };
				
			/hosted=(.*)/ && do {
				$hosted_tmp = $1;
				last };
			
			/popup_delay=(\d+)/ && do {
				$show_popup_delay = $1;
				last };
				
			/popup_size=(\d+)/ && do {
				$popup_size = $1;
				last };
				
			/popup_persistence=(\d+)/ && do {
				$popup_persistence = $1;
				last };
			
			(/v$/ || /verbose/) && do {
				$silent = 0;
				print "CheckGmail v$version\nCopyright Â© 2005-7 Owen Marshall\n\n";
				last };
				
			/nocrypt/ && do {
				$nocrypt = 1;
				last };
				
			/update/ && do {
				$update = 1;
				last };
				
				
			/numbers/ && do {
				$mailno = 1;
				last };
				
			/debug/ && do {
				$debug = 1;
				$silent = 0;
				last };
				
				
				
			print "CheckGmail v$version\nCopyright © 2005-7 Owen Marshall\n\n";
			print "usage: checkgmail [-profile=profile_name] [-popup_delay=millisecs] [-hosted=hosted_domain] [-no_cookies] [-popup_persistence=millisecs] [-private] [-v | -verbose] [-nocrypt] [-disable-monitors-check] [-update] [-h]\n\n";
			exit 1;
			
		}	
	}
}	
	

#######################
# Generate passphrase
#

my ($passphrase);
BEGIN {
	# passphrase generator - needs to run before Crypt::Simple is loaded ...
	
	# The idea here is to at least make a non-local copy of .checkgmail
	# secure (for example, that found on a backup disc) - it's
	# impossible to store the password safely without requiring a user-entered
	# passphrase otherwise, which defeats the purpose of it all. The
	# passphrase used is based on the MAC address of the users ethernet
	# setup if it exists and the entire info from uname - this is the
	# most unique info I can think of to use here, though other suggestions
	# are welcome!
	#
	# (obviously uname info isn't that unique unless you're running a kernel that
	# you compiled yourself - which I do, but many don't ...)
	
	my $uname = `uname -a`;
	chomp($uname);
	
	$_ = `whereis -b ifconfig`;
	my ($ifconfig_path) = m/ifconfig:\s+([\w\/]+)/;
	$ifconfig_path ||= "ifconfig";
	
	my $mac = `$ifconfig_path -a | grep -m 1 HWaddr | sed 's/ //g' | tail -18c`;
	chomp($mac);
	
	$passphrase = "$mac$uname";
	$passphrase =~ s/\s+//g;
}


##################
# Check packages
#

BEGIN {	
	# A modular package checking routine ...
	my $failed_packages;
		
	my $eval_sub = sub {
		print "$_\n" if $debug;
		eval $_;
		if ($@) {
			return unless m/(use|require)\s*([\w:-]+).*?\;/;
			my $package = $2;
			
			$failed_packages .= " $package ";					
			print "Warning: $package not found ...\n";
		}
	};	
	
	# required packages
	foreach (split("\n","
	use Gtk2(\"init\");
	use Gtk2::TrayIcon;
	use threads;
	use Thread::Queue;
	use Thread::Semaphore;
	use threads::shared;
	use Encode;
	use XML::Simple;
	use FileHandle;
	use LWP::UserAgent;
	# use LWP::Debug qw(+);
	use HTTP::Request::Common;
	use Crypt::SSLeay;
	")) {&$eval_sub($_)};
	if ($failed_packages) {
		unless ($failed_packages =~ /Gtk2\s/) {
			# Show a nice GTK2 error dialogue if we can ...
			my $explanation = "Try installing them if they're provided by your distro, and then run CheckGmail again ...";
			if ($failed_packages =~ /threads/i) {
				$explanation = <<EOF;
The threads packages are special: this means you're running a version of Perl that has been built without multi-threading support.  There may be a package for your distro that provides this, or you may have to rebuild Perl.

You'll also have to install the other packages listed above, and then run CheckGmail again ...
EOF
				chomp($explanation);
			}
			my $text = <<EOF;
<b>CheckGmail v$version</b>
Copyright &#169; 2005-6, Owen Marshall
			
Sorry!  CheckGmail can't find the following package(s) on your system.  These packages are needed for CheckGmail to run.

<b>$failed_packages</b> 

$explanation
					
<small>If that fails, you might have to download and install the packages from CPAN (http://search.cpan.org)</small>
EOF
			chomp($text);
			my $dialog = Gtk2::MessageDialog->new_with_markup(undef,
   					'destroy-with-parent',
   					'error',
   					'ok',
					$text,
				);
  			$dialog->run;
			$dialog->destroy;

		}

		print "\nCheckGmail requires the above packages to run\nPlease download and install from CPAN (http://search.cpan.org) and try again ...\n\n";
		exit 1;
	}
	
	# Use kwallet if available
	if (`which kwallet 2>/dev/null`) {
		$usekwallet = 1;
		$nocrypt = 1;
	}
	
	# optional packages for encryption
	unless ($nocrypt) {
		foreach (split("\n","
		use Crypt::Simple passphrase => \"$passphrase\";
		use Crypt::Blowfish;
		use FreezeThaw;
		use Compress::Zlib;
		use Digest::MD5;
		use MIME::Base64;
		")) {&$eval_sub($_)};
		if ($failed_packages) {
			print "\nCheckGmail requires the above packages for password encryption\nPlease download and install from CPAN (http://search.cpan.org) if you want to use this feature ...\n\n";
			$nocrypt = 1;
		}
	}
	

}

# There's something wrong with Debian's Crypt::Simple, and it's causing problems ...
unless (($nocrypt) || (eval("encrypt('test_encryption');"))) {
	print "Hmmmm ... Crypt::Simple doesn't seem to be working!\nNot using Debian or Ubuntu, are you??\n\n";
	print "Your best bet is to download the Crypt::Simple module from CPAN\n(http://search.cpan.org/~kasei/Crypt-Simple/) and install it manually.  Sorry!\n\n";
	print "Disabling encrypted passwords for now ...\n\n";
	$nocrypt = 1;
}

# Show big fat warning if Crypt::Simple not found ...
if ($nocrypt && !$silent && !$usekwallet) {
	print <<EOF;
*** Crypt::Simple not found, not working or disabled ***
*** Passwords will be saved in plain text only ...   ***\n
EOF
}

##################
# Update utility
#

# Pretty damn simple right now, but it works ...
# ... idea taken from a script on the checkgmail forums (thanks, guys!)

# no version checking right now -- but does show the user a diff of the changes ...

if ($update) {
	my $checkgmail_loc = $0;
	my ($exec_dir) = $checkgmail_loc =~ m/(.*)checkgmail/;
	chdir("/tmp");
	print "Downloading latest version of checkgmail from SVN ...\n\n";
	`wget http://checkgmail.svn.sourceforge.net/viewvc/*checkout*/checkgmail/checkgmail`;
	print "\n\nDifferences between old and new versions:\n";
	print "diff -urN checkgmail $checkgmail_loc\n";
	my $diff_out = `diff -urN checkgmail $checkgmail_loc`;
	print "$diff_out\n\n";
	my $do_update = ask("\n\nOK to update to new version via 'sudo mv checkgmail $exec_dir'?(Y/n)");
	if ($do_update eq "Y") {
		print "chmod a+x checkgmail\n";
		`chmod a+x checkgmail`;
		print "sudo mv checkgmail $exec_dir\n";
		`sudo mv checkgmail $exec_dir`;
		print "\nRestarting checkgmail ...\n";
		exec "$0";
	} else {
		print "Update NOT performed ...\n";
		print "Deleting temp file ...\n";
		unlink("checkgmail");
		print "Continuing with application startup ...\n\n";
	}
}	


sub ask {
	my ($question,$prompt)=@_;
	$prompt||="> ";
	print "$question$prompt";
	my $ans = <STDIN>;
	chomp($ans);
	return $ans;
}
			
			
##########################################
# Threads for non-blocking HTTP-requests
#

# Shared variables between threads
# - need to be declared here, unfortunately ... can't do it in the prefs hash :(
my $gmail_address : shared;
my $user : shared;
my $passwd : shared;
my $passwd_decrypt : shared;
my $save_passwd : shared;
my $translations : shared;
my %trans : shared;
my $language : shared;
my $HOME : shared;
my $icons_dir : shared;
my $gmail_at : shared;
my $gmail_hid : shared;
my $gmail_sid : shared;
my $gmail_gausr : shared;
my $delay : shared;
my %label_delay : shared;
# my @labels : shared;
my $hosted : shared = $hosted_tmp;

# URI escape codes to allow non alphanumeric usernames & passwords ...
# thanks to Leonardo Ribeiro for suggesting this, and to the lcwa package for this implementation
my %escapes : shared;
for (0..255) {
    	$escapes{chr($_)} = sprintf("%%%02X", $_);
}

# Thread controls
my $request = new Thread::Queue;
my $request_results = new Thread::Queue;
my $http_status = new Thread::Queue;
my $error_block = new Thread::Semaphore(0);
my $fat_lady = new Thread::Semaphore(0);
my $child_exit : shared = 0; # to signal exit to child

print "About to start new thread ...\n" if $debug;
# Start http checking thread ...
my $http_check = new threads(\&http_check);
print "Parent: Process now continues ...\n" if $debug;


#######################
# Prefs and Variables
#

print "Parent: Setting up global variables ...\n" if $debug;
# Prefs hash
my %pref_variables = (
	user => \$user,
	passwd => \$passwd,
	hosted => \$hosted,
	save_passwd => \$save_passwd,
	atomfeed_address => \$gmail_address,
	language => \$language,
	delay => \$delay,
	label_delay => \%label_delay,
	popup_size => \$popup_size,
	background => \(my $background),
	gmail_command => \(my $gmail_command),
	use_custom_mail_icon => \(my $custom_mail_icon),
	use_custom_no_mail_icon => \(my $custom_no_mail_icon),
	use_custom_error_icon => \(my $custom_error_icon),
	mail_icon => \(my $mail_icon),
	no_mail_icon => \(my $no_mail_icon),
	error_icon => \(my $error_icon),
	popup_delay => \(my $popup_delay),
	show_popup_delay => \$show_popup_delay,
	notify_command => \(my $notify_command),
	nomail_command => \(my $nomail_command),
	time_24 => \(my $time_24),
	archive_as_read => \(my $archive_as_read),
);

# Default prefs
$delay = 120000;
$popup_delay = 6000;
$save_passwd = 0;
$time_24 = 0;
$archive_as_read = 0;
$gmail_command = 'xdg-open %u';
$language = 'English';

# Global variables
$HOME = (getpwuid($<))[7];
my $gmail_web_address = "https://mail.google.com/mail";
my $prefs_dir = "$HOME/.checkgmail";
$icons_dir = "$prefs_dir/attachment_icons";
my $prefs_file_nonxml = "$prefs_dir/prefs$profile";
my $prefs_file = "$prefs_file_nonxml.xml";
$gmail_address = gen_prefix_url()."/feed/atom";
# $gmail_address = $hosted ? "mail.google.com/a/$hosted/feed/atom" : "mail.google.com/mail/feed/atom";

# for every gmail action ...
my %gmail_act = (
	archive => 'rc_%5Ei',
	read => 'rd',
	spam => 'sp',
	delete => 'tr',
	star => 'st',
	unstar => 'xst',
);

# ... there's a gmail re-action :)
my %gmail_undo = (
	archive => 'ib',
	read => 'ur',
	spam => 'us',
	delete => 'ib:trash',
	star => 'xst',
);

my @undo_buffer;
my ($ua, $cookie_jar);
my ($menu_x, $menu_y);
my @popup_status;
my $status_label;
# my $message_flag;

print "Parent: Checking the existence of ~/.checkgmail ...\n" if $debug;
# Create the default .checkgmail directory and migrate prefs from users of older versions
unless (-d $prefs_dir) {
	if (-e "$prefs_dir") {
		print "Moving ~/.checkgmail to ~/.checkgmail/prefs ...\n\n";
		rename("$HOME/.checkgmail", "$HOME/.checkgmailbak");
		mkdir($prefs_dir, 0700);
		rename("$HOME/.checkgmailbak", "$prefs_dir/prefs");
	} else {
		# User hasn't run an old version, just create the dir
		mkdir($prefs_dir, 0700);
	}
}

unless (-d $icons_dir) {
	mkdir($icons_dir, 0700);
}


#########
# Icons
#

print "Parent: Loading icon data ...\n" if $debug;
# we load the pixmaps as uuencoded data
my ($error_data, $no_mail_data, $mail_data, $compose_mail_data, $star_on_data, $star_off_data);
load_icon_data();

my ($no_mail_pixbuf, $mail_pixbuf, $error_pixbuf, $star_pixbuf, $nostar_pixbuf);
my ($custom_no_mail_pixbuf, $custom_mail_pixbuf, $custom_error_pixbuf);
set_icons();

my $image = Gtk2::Image->new_from_pixbuf($no_mail_pixbuf);


##############
# Setup tray
#

print "Parent: Setting up system tray ...\n" if $debug;
my $tray = Gtk2::TrayIcon->new("gmail");
my $eventbox = Gtk2::EventBox->new;
my $tray_hbox = Gtk2::HBox->new(0,0);
$tray_hbox->set_border_width(2);

my $win_notify;
my ($notify_vbox_b, $notifybox);
my ($old_x, $old_y);
my $reshow;
my $notify_enter = 0;
my $popup_win;
# my $scrolled;
# my $vadj;
my %new;
my @messages;
my %messages_ext;
my %issued_h;
my @labels;

$eventbox->add($tray_hbox);
$tray_hbox->pack_start($image,0,0,0);

# number of new mail messages (use -numbers)
my $number_label;
if ($mailno) {
	$number_label = Gtk2::Label->new;
	$number_label->set_markup("0");
	$tray_hbox->pack_start($number_label,0,0,0);
	$number_label->hide;
}


########################
# Read prefs and login
#

print "Parent: Reading translations ...\n" if $debug;
# Read translations if they exist ...
read_translations();

print "Parent: Reading prefs ...\n" if $debug;
# First time configuration ...
unless (read_prefs()) {
	show_prefs();
}

# kdewallet integration if present - thanks to Joechen Hoenicke for this ...
if (($usekwallet) && ($save_passwd)) {
	$passwd = `kwallet -get checkgmail`;
	chomp $passwd;
}

# remove passwd from the pref_variables hash if the user requests it and prompt for login
unless ($save_passwd && !$usekwallet) {
	delete $pref_variables{passwd};
	login($trans{login_title}) unless $passwd;
}


# changing the passphrase causes Crypt::Simple to die horribly -
# here we use an eval routine to catch this and ask the user to login again
# - this will only happen if you change your network interface card or
# recompile your kernel ...
unless ((eval ('$passwd_decrypt = decrypt_real($passwd);'))) {
	login($trans{login_title});
}

chomp($passwd_decrypt) if $passwd_decrypt;

# Continue building tray ...
if ($background) {
	my ($red, $green, $blue) = convert_hex_to_colour($background);
	$eventbox->modify_bg('normal', Gtk2::Gdk::Color->new ($red, $green, $blue));
}

$tray->add($eventbox);
$tray->show_all;
print "Parent: System tray now complete ...\n" if $debug;

############################
# enter/leave notification
#

my $notify_vis = 0;
my $notify_delay = 0;
my $popup_delay_timeout;
$eventbox->signal_connect('enter_notify_event', sub {
	if ($show_popup_delay) {
		# Tooltip-like delay in showing the popup
		# return if $notify_vis;
		# $notify_delay=1;
		$notify_vis =1;
		$popup_delay_timeout = Glib::Timeout->add($show_popup_delay, sub {
			if ($win_notify && $notify_vis) {
				# $notify_delay=0;
				show_notify();
			}
		});
	} else {
		if ($win_notify) {
			show_notify();
			$notify_vis=1;
		}
	}
});

$eventbox->signal_connect('leave_notify_event', sub {
	if (@popup_status) {
		# This allows us to mouse into the popup by continuing to display it after
		# the mouse leaves the tray icon.  We only call it when there are messages
		# displayed - no one (I'm assuming! :) wants to be able to mouse into the 
		# "No new mail" tooltip ... (well, OK, I actually did play around doing exactly
		# that when I wrote the routine, but that doesn't count ... :)
		my $persistence = Glib::Timeout->add($popup_persistence, sub {
			unless ($notify_enter) {
				$win_notify->hide unless ($notify_enter || $notify_vis);
			}
			return 0;
		});
	} else {
		$win_notify->hide if $win_notify;
	}
	
	Glib::Source->remove($popup_delay_timeout) if $popup_delay_timeout;
	$notify_vis=0;
});


##################
# Catch SIGs ...
#

my %check;
# my @labels;

$SIG{ALRM} = sub{
	print "Alarm clock sent ...\n" unless $silent;
	print "Resetting check delay ...\n" unless $silent;
	reinit_checks();
};

$SIG{TERM} = \&exit_prog;


############################
# All set? Let's login ...
#

print "Parent: Sending semaphore to child process ...\n" if $debug;
# She's singing ...
$fat_lady->up;


##############
# Popup Menu
#

my $menu;
pack_menu();

#######################
# Events and Mainloop
#

# set popup trigger
$eventbox->signal_connect('button_press_event', \&handle_button_press);

# set timeout for checking mail
reinit_checks();
my $real_check = Glib::Timeout->add(1000, \&check); # no wait-variables, so we're polling once a second.  No real CPU hit here ...

# do initial check 
queue_check();

Gtk2->main;

################
# Post GUI ...
#

exit_prog();

sub exit_prog {
	# After quitting the GUI we need to logout (if using the cookie_login method) and then clean up the threads ...
	print "Exiting program ...\n" unless $silent;
	
	# if ($cookies) {
		# $http_status->enqueue("Logging out ...");
		# $request->enqueue("LOGOUT:mail.google.com/mail/?logout");
		# sleep 1;
	# }
	
	$child_exit = 1;
	queue_check();
	
	$http_check->join();
	
	exit 0;
}



##############################
# Subroutines start here ...
# 


####################
# Checking thread
#

sub queue_check {
	# Simply adds to the $request queue to signal the http_check thread
	my ($label) = shift;
	$label = $label ? "$label" : "";
	$request->enqueue("GET:$gmail_address $label");
	return 1;
}

sub http_check {
	# Threaded process for sending HTTP requests ...
	print "Child: Checking thread now starting ... waiting for semaphore to continue\n" if $debug;
	
	# Variable initialisation isn't over until the fat lady sings ...
	$fat_lady->down;
	print "Initialisation complete\n" unless $silent;
		
	# set up the useragent ....
	$ua = LWP::UserAgent->new();
	$ua->requests_redirectable (['GET', 'HEAD', 'POST']);
	# push @{ $ua->requests_redirectable }, 'POST';
	
	# set time-out - defaults to 90 seconds or $delay, whichever is shorter
	$ua->timeout($delay/1000<90 ? $delay/1000 : 90);	
		
	# Get the cookie if requested
	if ($cookies) {		
		use HTTP::Cookies;
		$cookie_jar = HTTP::Cookies->new();
		
		$ua->cookie_jar($cookie_jar);
		
		# Here we submit the login form to Google and the authorisation cookie gets saved
		
		# This is only useful when Google's pulling an Error 503 party - it's less efficient
		# as there's a whole lot of unnecessary data associated with the process that slows
		# it all down ...
		
		{
			# this loop is necessary as an incorrect login with Gmail's web form doesn't return a 401
			# So we simply check for the Gmail_AT cookie as confirmation of a successful login
			$http_status->enqueue($trans{notify_login});

			my $URI_user = URI_escape($user);
	        	my $URI_passwd = URI_escape($passwd_decrypt);
			
			# clumsy error detection code uses this variable to differentiate between unable to 
			# connect and unable to login - the Gmail login provides no unauthorised code if unsuccessful
			my $error;
						
			# Thanks to that wonderful Firefox extension LiveHTTPHeaders for 
			# deciphering the login form! :)
			unless ($hosted) {
				# Normal Gmail login action ...
				$error = http_get("Email=$URI_user&Passwd=$URI_passwd", "LOGIN");

				$cookie_jar->scan(\&scan_at);
				unless ($error || !$gmail_sid || !$gmail_gausr) {
					$error = http_get("https://mail.google.com/mail/?pli=1&auth=$gmail_sid&gausr=$gmail_gausr", 'LOGIN');
				}

				# $error = http_get("https://mail.google.com/mail?nsr=0&auth=$gmail_sid&gausr=$gmail_gausr", "LOGIN");
	
			} else {
				# hosted domains work differently ...
				# First we POST a login
				# $error = http_get("https://www.google.com/a/$hosted/LoginAction|at=null&continue=http%3A%2F%2Fmail.google.com%2Fa%2F$hosted&service=mail&userName=$URI_user&password=$URI_passwd", "POST");
				# thanks to Olinto Neto for this fix for hosted domains:
				$error = http_get("https://www.google.com/a/$hosted/LoginAction2|at=null&continue=http%3A%2F%2Fmail.google.com%2Fa%2F$hosted&service=mail&Email=$URI_user&Passwd=$URI_passwd", "POST");

				# Then we grab the HID ("Hosted ID"?) cookie
				$cookie_jar->scan(\&scan_at);
				
				# And now we login with that cookie, which will give us the GMAIL_AT cookie!
				unless ($error || !$gmail_hid) {					
					$error = http_get("https://mail.google.com/a/$hosted?AuthEventSource=Internal&auth=$gmail_hid", 'GET');	
				}
			}

			$cookie_jar->scan(\&scan_at);
			
			unless ($gmail_at) {
				unless ($error) {
					$http_status->enqueue("Error: 401 Unauthorised");
					$error_block->down;
				} else {
					# simple block to prevent checkgmail hogging CPU if not connected!
					sleep 30;
				}
				
				redo;
			}
		}

		print "Logged in ... AT = $gmail_at\n" unless $silent;
	}		

	while ((my $address = $request->dequeue) && ($child_exit==0)) {
		# this is a clumsy hack to allow POST methods to do things like mark messages as spam using the same queue
		# (can't send anonymous arrays down a queue, unfortunately!)
		# Now also used for labels ...
		my ($method, $address_real, $label) = ($address =~ /(.*?):([^\s]*)\s*(.*)/);
		
		my $logon_string = "";
		unless ($cookies) {
			my $URI_user = URI_escape($user);
        		my $URI_passwd = URI_escape($passwd_decrypt);
			$logon_string = "$URI_user:$URI_passwd\@";
		}
		
		$request_results->enqueue(http_get("https://$logon_string$address_real", $method, $label))
	}		
}


sub scan_at {
	my $cookie_ref = \@_;
		
	unless ($silent) {
		# use Data::Dumper;
		# print Dumper(\@_);
		print "Saved cookie: ",$cookie_ref->[1],"\n",$cookie_ref->[2],"\n\n";
	}
	
	# This sub is invoked for each cookie in the cookie jar.
	# What we're looking for here is the Gmail authorisation key, GMAIL_AT
	# - this is needed to interface with the Gmail server for actions on mail messages ...
	# or the HID cookie which is set with Gmail hosted domains
	
	if ($cookie_ref->[1] =~ m/GMAIL_AT/) {
		$gmail_at = $cookie_ref->[2];
	}
	
	if ($cookie_ref->[1] =~ m/HID/) {
		$gmail_hid = $cookie_ref->[2];
	}
	
	if ($cookie_ref->[1] =~ m/GAUSR/) {
		$gmail_gausr = $cookie_ref->[2];
	}
	
	if ($cookie_ref->[1] =~ m/SID/) {
		$gmail_sid = $cookie_ref->[2];
	}
}


sub http_get {
	# this is now called from the http-checking thread
	# - all GUI activities are handled through queues
	my ($address, $method, $label) = @_;
	$label = "/$label" if $label;
	$label||="";
	my $error;
	
	if ($method eq 'POST') {
		# quick hack to use the POST method for Gmail actions ...
		my ($add1, $add2) = ($address =~ m/(.*)\|(.*)/);
		# print "($add1, $add2)\n" unless $silent;
		
		my $req = HTTP::Request->new($method => $add1);
  		$req->content_type('application/x-www-form-urlencoded');
  		$req->content($add2);
		
		$ua->request($req);
		return;
		
	} elsif ($method eq 'LOGIN') {
		# New LOGIN method written by Gerben van der Lubbe on Oct 6, 2009.
		# (based in turn on vially's (https://sourceforge.net/users/vially/) PHP code.
		
		# Well, we did get a URL here, but it doesn't make any sense to send both LOGIN and the URL to this function.
		# So, this URL is just the username and password addition.
		my $req = HTTP::Request->new('GET' => "https://www.google.com/accounts/ServiceLogin?service=mail");
		my $response = $ua->request($req);
		if($response->is_error) {
			my $code = $response->code;
			my $message = $response->message;
			$error = "Error: $code $message";
			$http_status->enqueue($error);
			return $error;
		}
		my $http = $response->content;

		# Find the value of the GALX input field
		my ($post_galx) = ($http =~ m/"GALX".*?value="(.*?)"/ismg);
		unless ($post_galx) {
			print "Error: No GALX input field found\n";
			return "Error: No GALX input field found";
		}
		my $galx = URI_unescape($1);
		$post_galx = URI_escape($galx);
		
		# Find the data to post
		my $post_data;
		$post_data = "ltmpl=default&ltmplcache=2&continue=http://mail.google.com/mail/?ui%3Dhtml&service=mail&rm=false&scc=1&GALX=$post_galx&$address&PersistentCookie=yes&rmShown=1&signIn=Sign+in&asts=";
		
		# Hide personal data from verbose display
		my $post_display = $post_data;
		$post_display =~ s/Email=(.*?)&/Email=******/;
		$post_display =~ s/Passwd=(.*?)&/Passwd=******/;
		print "Logging in with post data $post_display\n" unless $silent;

		# Send the post data to the login URL
		my $post_req = HTTP::Request->new('POST' => "https://www.google.com/accounts/ServiceLoginAuth?service=mail");
		$post_req->content_type('application/x-www-form-urlencoded');
		$post_req->content($post_data);
		$post_req->header('Cookie' => "GALX=$galx");
		my $post_response = $ua->request($post_req);
		if ($post_response->is_error) {
			my $code = $response->code;
			my $message = $response->message;
			$error = "Error: $code $message";
			$http_status->enqueue($error);
			return $error;
		}
		my $post_http = $post_response->content;

		# Find the location we're directed to, if any
		if ($post_http =~ m/location\.replace\("(.*)"\)/) {
			# Rewrite the redirect URI.
			# This URI uses \xXX. Replace those, and just to be sure \\. \" we don't handle, though.
			my $redirect_address = $1;
			$redirect_address =~ s/\\\\/\\/g;
			$redirect_address =~ s/\\x([0-9a-zA-Z]{2})/chr(hex($1))/eg;
			print "Redirecting to ".$redirect_address."\n" unless $silent;

			# And request the actual URL
			my $req = HTTP::Request->new('GET' => $redirect_address);
			my $response = $ua->request($req);
			if($response->is_error) {
				my $code = $response->code;
				my $message = $response->message;
				$error = "Error: $code $message";
				$http_status->enqueue($error);
				return $error;
			}
		} else {
			print "No location.replace found in HTML:\n".$post_http unless $silent;
		}
		
		return $error;
		
	} elsif ($method eq 'LOGOUT') {
		# a  hack to streamline the logout process
		print "Logging out of Gmail ...\n" unless $silent;
		
		my $req = HTTP::Request->new('GET' => "$address");
		my $response = $ua->request($req);
		
		return;
	} elsif ($method eq 'IMAGE') {
		# a hack to grab attachment images
		my $image_name = $label;
		
		my $req = HTTP::Request->new(GET => "$address");
		my $response = $ua->request($req);
		if ($response->is_error) {
			print "error retrieving!\n";
			return 0;
		}
		
		my $http = $response->content;
		
		open (DATA, ">$icons_dir$image_name") || print "Error: Could not open file for writing: $!\n";
		print DATA $http;
		close DATA;
		
		# we need a semaphore here so the GUI doesn't redraw until the image is obtained
		$error_block->up;
		
		return 0;
	}

	
	$http_status->enqueue($trans{notify_check});
		
	my $req = HTTP::Request->new($method => "$address$label");

	my $response = $ua->request($req);
	if ($response->is_error) {
		my $code = $response->code;
		my $message = $response->message;
		$error = "Error: $code $message";
		$http_status->enqueue($error);
		
		# Incorrect username/password??
		if ($code == 401) {
			# Set a semaphore block to prevent multiple incorrect logins
			# This is probably unneccessary because of the locked variables in the Login dialogue
			# ... still, doesn't hurt to be careful ... :)
			$error_block->down;
		}
		
		return 0;
	}
	
	my $http = $response->content;
	
	$label =~ s/\///g;
		
	return "LABEL=$label\n$http";
}


############################
# Main thread checking ...
#

sub check {
	# The check routine is polled every second:
	# we always check first to see if there's a new status message and display it
	# Errors are also caught at this point ...
	my $status = $http_status->dequeue_nb;
	if ($status) {
		notify($status);
		if ($status =~ m/error/i) {
			# General error notification
			$image->set_from_pixbuf($error_pixbuf);
			
			if ($status =~ m/401/) {
				# Unauthorised error
				login("Error: Incorrect username or password");
				Gtk2->main_iteration while (Gtk2->events_pending);
				
				# queue a new request to check mail
				queue_check();
				
				# and release the semaphore block ...
				$error_block->up;
			}

		}
	}
		
	# Return if there aren't any Atom feeds in the queue ...
	return 1 unless my $atom = $request_results->dequeue_nb;
	
	if ($atom =~ m/while\(1\);/) {
		# datapack shortcircuit
		# we use this to grab the full text of messages ...
		
		# uncomment below to see the datapack structure
		print "atom:\n$atom\n\n" unless $silent;
		
		# mb is the message body ... and there's often more than one block!
		my ($mb, $ma); 
		while ($atom =~ m/\["mb","(.*?)",\d\]/g) {
			$mb .= "$1";
		}
		
		# ma is the attachment, if any
		while ($atom =~ m/\["ma",\[(.*?)\]/g) {
			my $att = $1;
			$ma = "/mail/images/paperclip.gif"; # default attachment
			# print "attachment =\n$att\n\n";
			if ($att =~ m/src\\u003d\\\"(.*?)\\\"/g) {
				$ma = $1;
			}
		}
		
		$mb = clean_text_body($mb);
		print "cleaned text is\n$mb\n\n" unless $silent;
						
		# cs is the message id
		my ($cs) = ($atom =~ m/\["cs","(.*?)"/);
		$messages_ext{$cs}->{text} = $mb;
		$messages_ext{$cs}->{shown} = 1;
		$messages_ext{$cs}->{attachment} = $ma;
		
		
		notify();
		return 1;
	}
	
	# Process the Atom feed ...
	my ($label, $atom_txt) = ($atom =~ m/LABEL=(.*?)\n(.*)/s);
	# $label ||= "";
	my $gmail = XMLin($atom_txt, ForceArray => 1);
	
	# # Uncomment below to view xml->array structure
	# use Data::Dumper;
	# print Dumper($gmail);
	
	# Count messages ...
	$new{$label} = 0;
	if ($gmail->{entry}) {
		$new{$label} = @{$gmail->{entry}};
	}
	
	my $new_mail =0;
	
	# remove old messages with the same label ...
	my @new_messages;
	foreach my $i (0 .. @messages) {
		next unless $messages[$i];
		if ($messages[$i]->{label} eq $label) {
			delete $issued_h{$messages[$i]->{time}};
		} else {
			push (@new_messages, $messages[$i]);
		} 
	}
	@messages = @new_messages;
	
	# print "\n--------\nmessages: @messages\n";
	
			
	if ($new{$label}) {
		# New messages - get the details ...
		my (@tip_text, $popup_text, $popup_authors, @issued_l);
		$image->set_from_pixbuf($mail_pixbuf);
					
		CHECK: for my $i (0 .. $new{$label}-1) {
			
			my $author_name = $gmail->{entry}->[$i]->{author}->[0]->{name}->[0];
			my $author_mail = $gmail->{entry}->[$i]->{author}->[0]->{email}->[0];
			my $issued = $gmail->{entry}->[$i]->{issued}->[0];
			my $title = $gmail->{entry}->[$i]->{title}->[0];
			my $summary = $gmail->{entry}->[$i]->{summary}->[0];
			my $href = $gmail->{entry}->[$i]->{link}->[0]->{href};
			
			my ($id) = ($href =~ m/message_id=(.*?)&/);
						
			# No subject, summary or author name?
			ref($title) && ($title = $trans{notify_no_subject});
			ref($summary) && ($summary = $trans{notify_no_text});
			my $author = $author_name || $author_mail;
						
			# clean text for Pango compatible display ...
			$title = clean_text_and_decode($title);
			$author = clean_text_and_decode($author);
			$summary = clean_text_and_decode($summary);
			
			my ($year, $month, $day, $hour, $min, $sec) = ($issued =~ m/(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/);
			my $time_abs = $sec+$min*60+$hour*3600+$day*86400+$month*2678400+$year*32140800;
			
			# check for duplicate labels
			foreach (@messages) {
				next CHECK if $_->{id} eq $id;
			}
			
			unless ($private) {
				push @messages, { href=>$href, id=>$id, time=>$time_abs, issued=>$issued, title=>$title, author=>$author, body=>$summary, label=>$label };
			}
						
			# Save authors and time stamps for popup text below ...
			$issued_h{$time_abs}=$author;
		}
		
		# create the mail details window ...				
		notify('', $new{$label}-1);
		
		# Now check if a popup needs to be displayed:
		
		# find previously unread entries and remove		
		if (@popup_status) {
			for my $i (0 .. $#popup_status) {
				next unless $popup_status[$i];
				# print "$i: ",$popup_status[$i]->{time}," - ", $issued_h{$popup_status[$i]->{time}},"\n";
				$issued_h{$popup_status[$i]->{time}} && delete $issued_h{$popup_status[$i]->{time}};
			}
		}
		
		# build unread authors from what's left
		foreach (keys(%issued_h)) {
			# eliminate duplicate authors
			next if $popup_authors && ($popup_authors =~ m/\Q$issued_h{$_}\E/);
			$popup_authors .= ($popup_authors ? ", $issued_h{$_}" : "$issued_h{$_}");
		}
		
		# Create popup text
		if ($popup_authors) {
			$popup_authors =~ s/, ([\w\s-]+)$/ $trans{notify_and} $1/; # replace final comma with "and"
			$popup_authors = clean_text_and_decode($popup_authors);
			$popup_text = "<span foreground=\"#000000\"><small>$trans{notify_new_mail}$popup_authors ...</small></span>";
		}
		
		# Save current unread list
		@popup_status = @messages;
				
		# Finally, display popup if there's any new mail
		# and run any command that the user has specified in the prefs
		if ($popup_text) {
			popup($popup_text);
			run_command($notify_command) if $notify_command;
		}
				
	} elsif (!$new_mail) {		
		notify();
	}
	
	# Need to return true to keep the timeout going ...
	return 1;
}

# Note -- for some reason (?? why ??) the title does not need decoding; all other data apparently does.  Very strange ...
sub clean_text_and_decode {
	($_) = @_;
	# some basic replacements so that the text is readable ...
	# (these aren't used by pango markup, unlike other HTML escapes)
	s/&hellip;/\.\.\./g;
	s/&\s/\&amp; /g;
	s/\\u003c/</g;
	# s/\\n//g;
	s/<br\s*\/*\\*>/\n/g;
	s/</\&lt;/g;
	s/>/\&gt;/g;
	s/&(?>([\w\d\,\.]+))(?!;)/\&amp;$1/g; #not a great fix, but at least it's simple (heavy irony ... :)
	s/&nbsp;/ /g;
	# s/\\n/\n/g;
	# Encode::from_to($body, 'utf-8', 'iso-8859-15');
	# eval { decode("utf8", $_, Encode::FB_CROAK); };
	# my $body_decode = $@ ? $_ : decode("utf8", $_);
	#my $body_decode= decode("utf-8", $_);
	
	# I have no idea why this works ...
	my $body_encode = encode("utf8", $_);
	my $body_decode = decode("utf8", $body_encode);
	
	return $body_decode;
}

sub clean_text {
	($_) = @_;
	# some basic replacements so that the text is readable ...
	# (these aren't used by pango markup, unlike other HTML escapes)
	s/&hellip;/\.\.\./g;
	s/&\s/\&amp; /g;
	s/\\u003c/</g;
	# s/\\n//g;
	s/<br\s*\/*\\*>/\n/g;
	s/</\&lt;/g;
	s/>/\&gt;/g;
	s/&(?>([\w\d\,\.]+))(?!;)/\&amp;$1/g; #not a great fix, but at least it's simple (heavy irony ... :)
	s/&nbsp;/ /g;
	# s/\\n/\n/g;
	return $_;
}


sub clean_text_body {
	($_) = @_;
	# some basic replacements so that the text is readable ...
	# (these aren't used by pango markup, unlike other HTML escapes)
	s/&hellip;/\.\.\./g;
	# s/&\s/\&amp; /g;
	s/\\u003c/</g;
	s/\>/>/g;
	s/\\u([\d\w]{4})/"&#".hex($1).";";/gex;
	s/&\#(\d+)\;/chr($1)/gex;
			
	s/\\t/\t/g;
	# s/\s\\n//g;
	# s/\\n\s//g;
	# s/\\n/ /g;
	s/(\w)\\n(\w)/$1 $2/g;
	s/\\n//g;
	s/(\\n)+/\n/g;
	s/\\(.)/$1/g;
	s/<br\s*\/*\\*>/\n/g;
	s/<p\s*\/*\\*>/\n\n/g;
	s/<\/div\\*>/\n/g; # GMail now uses div blocks for paragraphs!  Who'd have thought they could be so abhorrent?
	# s/(?:\n\s*){3,}/\n\n/sg;
	s/<a.*?(href=".*?").*?>(.*?)<\/a>/<-a $1>$2<-\/a>/ig;
	s/<[^-].*?>//g;
	# s/<([\/]|[^a])[^a].*?>//g;
	# s/<a\s+>(.*?)<\/a>/$1/g;
	s/<-/</g;
	s/\\'/'/g;
	# s/</\&lt;/g;
	# s/>/\&gt;/g;
	# s/&(?>([\w\d\,\.]+))(?!;)/\&amp;$1/g; #not a great fix, but at least it's simple (heavy irony ... :)
	s/&nbsp;/ /g;
	# s/\\n/\n/g;
	# Encode::from_to($body, 'utf-8', 'iso-8859-15');
	# eval { decode("utf8", $_, Encode::FB_CROAK); };
	# my $body_decode = $@ ? $_ : decode("utf8", $_);
	# my $body_encode = encode("utf8", $_);
	
	# I have no idea why this works either ...
	my $body_decode = decode("utf8", $_);

	return $body_decode;
}


#################################
# External command handling ...
#

sub open_gmail {
	# a routine to open Gmail in a web browser ... or not, as the user prefers!
	my $command = $gmail_command;
	my $login_address = get_login_href($gmail_web_address);
	run_command($command, $login_address);
}

sub run_command {
	my ($command, $address) = @_;
	
	# We now allow the use of '%u' to delineate the web address
	if ($address) {
		$command =~ s/\%u/"$address"/g;
	}
	
	# allows the number of new messages to be used in scripts! :)
	if ($command =~ m/\%m/) {
		my $messages = @messages;
		$command =~ s/\%m/$messages/g;
	}
	
	print "run command: $command\n" unless $silent;
	system("$command &");
}


#############
# Prefs I/O
#

# These routines read or save anything referenced in %pref_variables ... isn't that neat?
# NB: as of version 1.9.3, we've moved over to an XML format - this allows us to save more complex data structures
# (i.e. hashes for the check delay on various labels) with ease ...

sub read_prefs {
	unless (-e $prefs_file) {
		# old, deprecated simple text tile method ...
		return unless -e $prefs_file_nonxml;
		open(PREFS, "<$prefs_file_nonxml") || die "Cannot open $prefs_file_nonxml for reading: $!\n";
		
		# lock shared variables
		lock($user);
		lock($passwd);
		lock($save_passwd);
		lock($gmail_address);
		
		while (<PREFS>) {
			s/[\n\r]//g;
			next if /^$/;
			my ($key, $value) = split m/ = /;
			my $pointer = $pref_variables{$key};
			$$pointer = $value;
		}
		close (PREFS);
	} else {
		# new xml method
		# read translations file if it exists
		open(PREFS, "<$prefs_file") || die("Could not open $prefs_file for reading: $!\n");
		my $prefs = join("",<PREFS>);
		close PREFS;
		
		# lock shared variables
		lock($user);
		lock($passwd);
		lock($save_passwd);
		lock($gmail_address);
				
		my $prefs_xml = XMLin($prefs, ForceArray => 1);

		## For debugging ...
		# use Data::Dumper;
		# print Dumper $prefs_xml;
		
		foreach my $i (keys %pref_variables) {
			my $pointer = $pref_variables{$i};
			for (ref($pointer)) {
				/SCALAR/ && do {
					$$pointer = $prefs_xml->{$i} if defined($prefs_xml->{$i});
					last };
				
				/HASH/ && do {
					# last unless ref($prefs_xml->{$i}) eq "HASH";
					%$pointer = %{ $prefs_xml->{$i}->[0]} if defined($prefs_xml->{$i}->[0]);
					last };
					
				/ARRAY/ && do {
					# last unless ref($prefs_xml->{$i}) eq "HASH";
					@$pointer = @{ $prefs_xml->{$i}->[0]} if defined($prefs_xml->{$i}->[0]);
					last };
			}
		}
	}
	
	convert_labels_from_hash();
	set_icons();
	set_language();
	
	return 1;
}

sub write_prefs {
	# new XML-based preferences routine ...
	
	# lock shared variables
	lock($user);
	lock($passwd);
	lock($save_passwd);
	lock($gmail_address);
	
	convert_labels_from_array();
		
	my %xml_out;
	foreach my $i (keys %pref_variables) {
		my $pointer = $pref_variables{$i};
		for (ref($pointer)) {
				/SCALAR/ && do {
					$xml_out{$i} = $$pointer if defined($$pointer);
					last };
				
				/HASH/ && do {
					$xml_out{$i} = {%$pointer}; # if defined(%$pointer);
					last };
			}
		
	}
	
	my $prefs = XMLout(\%xml_out, AttrIndent=>1);
	open(PREFS, ">$prefs_file") || die("Could not open $prefs_file file for writing: $!");
	binmode PREFS, ":utf8";
	print PREFS $prefs;
	close PREFS;
}

# This seems a bit silly, I know - but I can't seem to share a multi-dimensional data structure,
# and if I keep things as a straightforward hash then we can't have nice GUI editing
# (because I need an ordered structure to do this)
#
# It's very cumbersome though - I'm not all that happy with this solution!!!
sub convert_labels_from_hash {
	@labels=();	
	push @labels, {label => "$_", delay => $label_delay{$_}} foreach sort(keys(%label_delay));
}

sub convert_labels_from_array {
	%label_delay=();
	$label_delay{$_->{label}} = $_->{delay} foreach @labels;
}


#####################
# Notify popups ...
#

sub notify {
	# popup notify code to replace tooltips
	# Why?  Because tooltips can't do nice pango markup! :-)
	my ($status, $text) = @_;	
	my $new_mail = @messages;
	
	# display number of messages
	if ($mailno) {
		print "setting \"$new_mail\"\n";
		$number_label->set_markup("$new_mail");
		$new_mail ? $number_label->show : $number_label->hide;
		# $new_mail ? $number_label->set_markup("$new_mail") : $number_label->set_markup(" ")
	}
	
	my @sorted_messages = sort {$b->{time} <=> $a->{time}} @messages;
	@messages = @sorted_messages;
	
	unless ($status) {
		if ($new_mail > 1) {
			$status = "<small><span foreground=\"#000000\">$trans{notify_multiple1}$new_mail$trans{notify_multiple2}</span></small>";
		} elsif ($new_mail) {
			$status = "<small><span foreground=\"#000000\">$trans{notify_single1}$new_mail$trans{notify_single2}</span></small>";
		} else {
			# No new messages
			$image->set_from_pixbuf($no_mail_pixbuf);
			
			my $time = $time_24 ? `date +\"%k:%M\"` : `date +\"%l:%M %P\"`;
			chomp($time);
			$time =~ s/^\s+//g;
			$status = "<span foreground=\"#000000\">$trans{notify_no_mail} <small>($time)</small></span>";
			
			@popup_status = ();
			
			run_command($nomail_command) if $nomail_command;
		}
	}

	
	# strip markup for command line ...
	unless ($silent) {
		$_ = $status;
		s/\<.*?\>//g;
		print "$_\n";
	}
	
	# Check if popup is currently displayed ...
	my $redisplay = 1 if (($win_notify) && ($win_notify->visible));
	
	# *sigh* ... bloody gtk won't let me do this:
	# if (($win_notify) && ($win_notify->visible)) {
		# print "getting vadj\n";
		# $vadj = $scrolled->get_vadjustment if $scrolled;
	# } else {
		# $vadj = 0;
	# }
	
	# Don't destroy the popup containing mail messages if we're just doing another check ...
	if (@messages && $redisplay && ($status =~ /$trans{notify_check}/ || $status =~ /$trans{notify_undoing}/)) {
		$status_label->set_markup("<span foreground=\"#000000\"><small>$status</small></span>");
		show_notify();
		return;
	}
	
	# return if (@messages && !defined($text));
	
	if (!@messages && !$notify_vis && $redisplay) {
		$redisplay = 0;
		$win_notify->hide;
	}
	
	# Create new popup
	my $win_notify_temp = Gtk2::Window->new('popup');
	
	# If we're using enter/leave notification, we need to create borders with eventboxes
	# - if there's a gap between window and eventbox, moving into the eventbox is considered a leave notification from the window!
	my $notifybox_b = Gtk2::EventBox->new;
	$notifybox_b->modify_bg('normal', Gtk2::Gdk::Color->new (0, 0, 0));
	
	# we use the vbox here simply to give an outer border ...
	$notify_vbox_b = Gtk2::VBox->new (0, 0);
	$notify_vbox_b->set_border_width(1);
	$notifybox_b->add($notify_vbox_b);
	
	$notifybox = Gtk2::EventBox->new;
	$notifybox->modify_bg('normal', Gtk2::Gdk::Color->new (65000, 65000, 65000));
	$notify_vbox_b->pack_start($notifybox,0,0,0);
	
	# we use the vbox here simply to give an internal border ...
	my $notify_vbox = Gtk2::VBox->new (0, 0);
	$notify_vbox->set_border_width(4);
	$notifybox->add($notify_vbox);
	
	# display mail status
	my $status_hbox = Gtk2::HBox->new(0,0);
	$notify_vbox->pack_start($status_hbox,0,0,0);
	
	$status_label = Gtk2::Label->new;
	$status_label->set_markup("<span foreground=\"#000000\">$status</span>");
	$status_hbox->pack_start($status_label,0,0,0);
	
	# $message_flag = @text ? 1 : 0;
	
	if (@messages && $cookies) {
		# mark all as read button and spacer
		my $mark_all_label = Gtk2::Label->new;
		$mark_all_label->set_markup(text_norm($trans{mail_mark_all}, "", ""));
		
		my $mark_all_ebox = Gtk2::EventBox->new();
		$mark_all_ebox->modify_bg('normal', Gtk2::Gdk::Color->new (65000, 65000, 65000));
		my $ma1 = $mark_all_ebox->signal_connect(enter_notify_event=>sub{$mark_all_label->set_markup(text_u($trans{mail_mark_all}, "", ""));});
		my $ma2 = $mark_all_ebox->signal_connect(leave_notify_event=>sub{$mark_all_label->set_markup(text_norm($trans{mail_mark_all}, "", ""));});
		
		$mark_all_ebox->signal_connect(button_press_event=>sub{
			@undo_buffer=();
			my @labels_to_check;
			foreach (@messages) {
				my $id = $_->{id};
				push @labels_to_check, $_->{label};
				$request->enqueue(gen_action_url($gmail_act{read},$id));
				$mark_all_label->set_markup(text_u($trans{mail_marking_all}, "", ""));
				
				# don't want to try to disconnect the signals multiple times!
				if ($ma1) {
					$mark_all_ebox->signal_handler_disconnect($ma1);
					$mark_all_ebox->signal_handler_disconnect($ma2);
					$ma1 = $ma2 = undef;
				}
				show_notify();
				push @undo_buffer, [$id, $_->{label}, 'read'];
			}
			queue_check($_) foreach @labels_to_check;
		});
		
		$mark_all_ebox->add($mark_all_label);
		$status_hbox->pack_end($mark_all_ebox,0,0,0);
		
	}
	
	if (@messages) {
		my $spacer = Gtk2::Label->new;
		$spacer->set_markup("<small> </small>");
		$notify_vbox->pack_start($spacer,0,0,0);
	}
		
	# display messages
	my $number = @messages;
	my $count;
	foreach (@messages) {
		$count++;
		my ($href, $id, $title, $author, $body, $label, $att) = ($_->{href}, $_->{id}, $_->{title}, $_->{author}, $_->{body}, $_->{label}, $_->{attachment});
		my $mb;
		if ($messages_ext{$id}) {
			$mb = $messages_ext{$id}->{text};
			$body = $messages_ext{$id}->{text} if $messages_ext{$id}->{shown};
		}
				
		# --- title and author ---
				
		my $hbox_t = Gtk2::HBox->new(0,0);
		$notify_vbox->pack_start($hbox_t,0,0,0);
		
		my $vbox_t = Gtk2::VBox->new(0,0);
		$hbox_t->pack_start($vbox_t,0,0,0);	
		
		my $hbox_tt = Gtk2::HBox->new(0,0);
		$vbox_t->pack_start($hbox_tt,0,0,0);
			
				
		
		my $title_l = Gtk2::Label->new;
		$title_l->set_markup("<span foreground=\"#000000\"><b><u>$title</u></b></span><small> <span foreground=\"#006633\">$label</span></small>");
		$title_l->set_line_wrap(1);
		
		my $title_l_ebox = Gtk2::EventBox->new();
		$title_l_ebox->modify_bg('normal', Gtk2::Gdk::Color->new (65000, 65000, 65000));
		my $s1 = $title_l_ebox->signal_connect(enter_notify_event=>sub{$title_l->set_markup("<span foreground=\"#000000\"><b><u><i>$title</i></u></b></span><small> <span foreground=\"#006633\">$label</span></small>")});
		my $s2 = $title_l_ebox->signal_connect(leave_notify_event=>sub{$title_l->set_markup("<span foreground=\"#000000\"><b><u>$title</u></b></span><small> <span foreground=\"#006633\">$label</span></small>")});
		$title_l_ebox->signal_connect(button_press_event=>sub{
			# grabbing the full text of a message!
			return unless $cookies;
			$title_l_ebox->signal_handler_disconnect($s1);
			$title_l_ebox->signal_handler_disconnect($s2);
			unless ($mb) {
				# yep, here's the magic code.  This accesses the datapack, which we read with a little hack in the check routine ...
				$request->enqueue("GET:".gen_prefix_url()."/?ui=1&view=cv&search=all&th=$id&qt=&prf=1&pft=undefined&rq=xm&at=$gmail_at");
			} else {
				# this allows the message text to be toggled ...
				# oh yes, we're all about usability here, folks! :)
				$messages_ext{$id}->{shown} = 1-$messages_ext{$id}->{shown};
			}				
			notify();
		});
		
		$title_l_ebox->add($title_l);		
		$hbox_tt->pack_start($title_l_ebox,0,0,0);
		
		# short spacer
		my $title_spacer = Gtk2::HBox->new(0,0);
		$title_spacer->set_border_width(1);
		$vbox_t->pack_start($title_spacer,0,0,0);
		
		# my god, gtk2 has the most stupid packing routines imaginable!!!
		my $hbox_from = Gtk2::HBox->new(0,0);
		$vbox_t->pack_start($hbox_from,0,0,0);
		
		
		# --- Starring messages ---
		# Note: there's no way to check the star-status of a message from the atom feed
		# of course, we're gradually getting to the stage where it'd be much easier to
		# poll the server via http requests now, than to retrieve messages via the feed.
		# (I'm thinking about it!  Definitely thinking about it ... :)
		#
		# In the meantime, the icon adds a quick way to star messages that you'd like
		# to come back to later, but ignore for the present.
		
		# Star icons are taken from Mozilla Firefox 3 (http://getfirefox.com), licensed under
		# the Creative Commons license
		
		my $star_i = Gtk2::Image->new();
		if ($messages_ext{$id}->{star}) {
			$star_i->set_from_pixbuf($star_pixbuf);
		} else {
			$messages_ext{$id}->{star}=0;
			$star_i->set_from_pixbuf($nostar_pixbuf);
		}
		
		my $star_ebox = Gtk2::EventBox->new();
		$star_ebox->modify_bg('normal', Gtk2::Gdk::Color->new (65000, 65000, 65000));
		$star_ebox->signal_connect(button_press_event=>sub{
			# setting the star
			return unless $cookies;
			$messages_ext{$id}->{star} = 1-$messages_ext{$id}->{star};
			if ($messages_ext{$id}->{star}) {
				$star_i->set_from_pixbuf($star_pixbuf);
				$request->enqueue(gen_action_url($gmail_act{star},$id));
			} else {
				$star_i->set_from_pixbuf($nostar_pixbuf);
				$request->enqueue(gen_action_url($gmail_act{unstar},$id));
			}				
		});	
		
		$star_ebox->add($star_i);		
		
		my $star_space = Gtk2::HBox->new(0,0);
		$star_space->set_border_width(3);	
		
		# From: line (with star)
		my $from_l = Gtk2::Label->new;
		$from_l->set_markup("<b>$trans{notify_from}</b> $author");
		$from_l->set_line_wrap(1);
		
		$hbox_from->pack_start($from_l,0,0,0);
		$hbox_from->pack_start($star_space,0,0,0);	
		$hbox_from->pack_start($star_ebox,0,0,0);	
		
		
		# --- Attachment icon ---
		if ($messages_ext{$id}->{attachment}) {
			$att = $messages_ext{$id}->{attachment};
			my ($image_name) = ($att =~ m/.*\/(.*)$/);		
			
			check_icon($att);
			
			my $att_image = Gtk2::Image->new_from_pixbuf(set_icon("$icons_dir/$image_name", 16));
			$hbox_t->pack_end($att_image,0,0,0);
			
			# my $title_att = Gtk2::Label->new;
			# $title_att->set_markup("<span foreground=\"#000000\"><small>[$att]</small></span>");
			# $title_att->set_line_wrap(1);
			# $hbox_t->pack_end($title_att,0,0,0);
			
		}
			

		
		# --- options ---
		
		my $hbox_opt = Gtk2::HBox->new(0,0);
		$notify_vbox->pack_start($hbox_opt,0,0,0);
		
		my $command_label = Gtk2::Label->new;
		$command_label->set_markup(text_norm($trans{mail_open}, ""));
		
		my $title_ebox = Gtk2::EventBox->new();
		$title_ebox->modify_bg('normal', Gtk2::Gdk::Color->new (65000, 65000, 65000));
		$title_ebox->signal_connect(button_press_event=>sub{
			run_command($gmail_command, get_login_href($href));
			if ($cookies) {
				# mark as read if we can - otherwise opened messages hang around ...
				### probably need an option for this!
				$request->enqueue(gen_action_url($gmail_act{read},$id));
				@undo_buffer=([$id, $label, 'read']);
				queue_check($label);
			}
		});
		$title_ebox->signal_connect(enter_notify_event=>sub{$command_label->set_markup(text_u($trans{mail_open},""));});
		$title_ebox->signal_connect(leave_notify_event=>sub{$command_label->set_markup(text_norm($trans{mail_open}, ""));});
		
		$title_ebox->add($command_label);
		$hbox_opt->pack_start($title_ebox,0,0,0);
		
		
		if ($cookies) {
			# We can only do these cute things when we've got a Gmail_at string to work with ...
			# thus it's limited to the cookie_login method
			
			# ---- mark as read
			
			my $mark_label = Gtk2::Label->new;
			$mark_label->set_markup(text_norm($trans{mail_mark}));
			
			my $mark_ebox = Gtk2::EventBox->new();
			$mark_ebox->modify_bg('normal', Gtk2::Gdk::Color->new (65000, 65000, 65000));
			my $s1 = $mark_ebox->signal_connect(enter_notify_event=>sub{$mark_label->set_markup(text_u($trans{mail_mark}));});
			my $s2 = $mark_ebox->signal_connect(leave_notify_event=>sub{$mark_label->set_markup(text_norm($trans{mail_mark}));});
			$mark_ebox->signal_connect(button_press_event=>sub{
				$request->enqueue(gen_action_url($gmail_act{read},$id));
				$mark_label->set_markup(text_u($trans{mail_marking}));
				$mark_ebox->signal_handler_disconnect($s1);
				$mark_ebox->signal_handler_disconnect($s2);
				show_notify();
				@undo_buffer=([$id, $label, 'read']);
				queue_check($label);
			});
			$mark_ebox->add($mark_label);
			$hbox_opt->pack_start($mark_ebox,0,0,0);
			
			# ---- archive
			
			my $archive_label = Gtk2::Label->new;
			$archive_label->set_markup(text_norm($trans{mail_archive}));
			
			my $archive_ebox = Gtk2::EventBox->new();
			$archive_ebox->modify_bg('normal', Gtk2::Gdk::Color->new (65000, 65000, 65000));
			my $s1a = $archive_ebox->signal_connect(enter_notify_event=>sub{$archive_label->set_markup(text_u($trans{mail_archive}));});
			my $s2a = $archive_ebox->signal_connect(leave_notify_event=>sub{$archive_label->set_markup(text_norm($trans{mail_archive}));});
			$archive_ebox->signal_connect(button_press_event=>sub{
				$request->enqueue(gen_action_url($gmail_act{archive},$id));
				$request->enqueue(gen_action_url($gmail_act{read},$id)) if $archive_as_read;
				$archive_label->set_markup(text_u($trans{mail_archiving}));
				$archive_ebox->signal_handler_disconnect($s1a);
				$archive_ebox->signal_handler_disconnect($s2a);
				show_notify();
				@undo_buffer=([$id, $label, 'archive']);
				push(@{$undo_buffer[0]}, 'read') if $archive_as_read;
				queue_check($label);
			});
			$archive_ebox->add($archive_label);
			$hbox_opt->pack_start($archive_ebox,0,0,0);
			
			# ---- report spam
			
			my $spam_label = Gtk2::Label->new;
			$spam_label->set_markup(text_norm($trans{mail_report_spam}));
			
			my $spam_ebox = Gtk2::EventBox->new();
			$spam_ebox->modify_bg('normal', Gtk2::Gdk::Color->new (65000, 65000, 65000));
			my $s1s = $spam_ebox->signal_connect(enter_notify_event=>sub{$spam_label->set_markup(text_u($trans{mail_report_spam}));});
			my $s2s = $spam_ebox->signal_connect(leave_notify_event=>sub{$spam_label->set_markup(text_norm($trans{mail_report_spam}));});
			$spam_ebox->signal_connect(button_press_event=>sub{
				$request->enqueue(gen_action_url($gmail_act{read},$id));
				$request->enqueue(gen_action_url($gmail_act{spam},$id));
				$spam_label->set_markup(text_u($trans{mail_reporting_spam}));
				$spam_ebox->signal_handler_disconnect($s1s);
				$spam_ebox->signal_handler_disconnect($s2s);
				show_notify();
				@undo_buffer=([$id, $label, 'spam', 'read']);
				queue_check($label);
			});
			$spam_ebox->add($spam_label);
			$hbox_opt->pack_start($spam_ebox,0,0,0);
			
			# ---- delete
			
			my $delete_label = Gtk2::Label->new;
			$delete_label->set_markup(text_norm($trans{mail_delete}));
			
			my $delete_ebox = Gtk2::EventBox->new();
			$delete_ebox->modify_bg('normal', Gtk2::Gdk::Color->new (65000, 65000, 65000));
			my $s1d = $delete_ebox->signal_connect(enter_notify_event=>sub{$delete_label->set_markup(text_u($trans{mail_delete}));});
			my $s2d = $delete_ebox->signal_connect(leave_notify_event=>sub{$delete_label->set_markup(text_norm($trans{mail_delete}));});
			$delete_ebox->signal_connect(button_press_event=>sub{
				$request->enqueue(gen_action_url($gmail_act{delete},$id));
				$delete_label->set_markup(text_u($trans{mail_deleting}));
				$delete_ebox->signal_handler_disconnect($s1d);
				$delete_ebox->signal_handler_disconnect($s2d);
				show_notify();
				@undo_buffer=([$id, $label, 'delete']);
				queue_check($label);
			});
			$delete_ebox->add($delete_label);
			$hbox_opt->pack_start($delete_ebox,0,0,0);
			
		}
		
		# --- Mail body ---
		
		my $hbox_b = Gtk2::HBox->new(0,0);
		$notify_vbox->pack_start($hbox_b,0,0,0);
		
		my $body_l;
		$body_l = Gtk2::Label->new;
		$body_l->signal_connect(activate_link => sub{

			my ($url_label, $url) = @_;
			run_command($gmail_command, $url);
		});
		$body_l->set_line_wrap(1);
		# my ($w, $h) = $body_l->get_size_request;
		# print "($w, $h)\n";
		$body_l->set_size_request($popup_size) if $popup_size;
		# $body_l->set_width_chars(20);
		# $body_l->set_selectable(1);
		# $body_l->set_max_width_chars(100);

		
		my $term = ($count == $number) ? "" : "\n";
		$body_l->set_markup("<span foreground=\"grey25\">$body</span>$term");
		$hbox_b->pack_start($body_l,0,0,0);
	}
				
	$win_notify_temp->add($notifybox_b);
		
	# If popup was previously displayed, re-show it ...
	if ($redisplay) {
		show_notify($win_notify_temp);
	} else {
		$win_notify->destroy if $win_notify;
		$win_notify="";
		$win_notify = $win_notify_temp;
	}
}


sub check_icon {
	# download the icon if it doesn't exist ...
	my ($image) = @_;
	my ($image_name) = ($image =~ m/.*\/(.*)$/);
	unless (-e "$icons_dir/$image_name") {
		print "Retrieving $image from mail.google.com ...\n" unless $silent;
		$request->enqueue("IMAGE:mail.google.com$image $image_name");
		# return unless $data;
		# print "data is $data\ngoing to >$icons_dir/$image_name";
		# open (DATA, ">$icons_dir/$image_name") || die "Could not open file for writing: $!\n";
		# print DATA $data;
		# close DATA;
		$error_block->down;
	}
}

sub http_get_main {
	my ($address) = @_;
	
	my $ua = LWP::UserAgent->new();		
	my $req = HTTP::Request->new(GET => "$address");

	my $response = $ua->request($req);
	if ($response->is_error) {
		print "error!\n";
		return 0;
	}
	
	my $http = $response->content;
	
	return $http;
	
	
}

sub text_norm {
	my ($body, $pre, $post) = @_;
	$pre = "| " unless defined($pre);
	$post = " " unless defined($post);
	return "$pre<small><span foreground=\"darkred\">$body</span></small>$post";
}

sub text_u {
	my ($body, $pre, $post) = @_;
	$pre = "| " unless defined($pre);
	$post = " " unless defined($post);
	return "$pre<small><span foreground=\"darkred\"><u>$body</u></span></small>$post";
}


sub get_login_href {
	# Login directly to gmail ...
	$_ = shift;
	
	# The following is for people who like to stay permanently logged in ...
	# (enable with -no-login on the command-line for now ...)
	return $_ if $nologin;
	
	my ($options) = m/.*?\?(.*)/;
	my $options_uri = $options ? "?&$options" : "";
	
	s/@/%40/g; # @ needs to be escaped in gmail address
	s/http([^s])/https$1/g; # let's make it secure!
	
	print "login command is: $_\n" unless $silent;

	my $escaped_uri = URI_escape($_);	
	my $URI_user = URI_escape($user);
	my $URI_passwd = URI_escape($passwd_decrypt);
	
	my $target_uri;
	if ($hosted) {
		$target_uri = "http://mail.google.com/a/$hosted/$options_uri";
	} else {
		$target_uri = "https://www.google.com/accounts/ServiceLoginAuth?ltmpl=yj_wsad&ltmplcache=2&continue=$escaped_uri&service=mail&rm=false&ltmpl=yj_wsad&Email=$URI_user&Passwd=$URI_passwd&rmShown=1&null=Sign+in";
	}
	
	return $target_uri;
}
	

sub gen_action_url {
	# I have a feeling that these complicated form post arguments are going to change
	# without warning more than once in the future - collating things here should make
	# updates a bit easier!
	my ($act, $id) = @_;
	my $search;
	
	# Now that we can grab the full text of messages, we'd better clear the cache while we're here ...
	# NB - I realise this won't remove all cached text, in the rare event someone looks at the full message text,
	# and then opens it manually in the webbrowser - but it's the simplest solution for now ...
	unless ($act =~ m/st/) {
		$messages_ext{$id}=undef;
	}
	
	# Undeleting items from trash needs to have the search variable as "trash"
	# - this is a quick hack to get around it!
	($act, $search) = split(":",$act);
	$search ||= 'all';
	
	my $prefix = gen_prefix_url();
	return ("POST:$prefix/?&ik=&search=$search&view=tl&start=0|&act=$act&at=$gmail_at&vp=&msq=&ba=false&t=$id&fs=1&rt=j");
	
	# if ($hosted) {
		# return ("POST:mail.google.com/a/$hosted/?&ik=&search=$search&view=tl&start=0|&act=$act&at=$gmail_at&vp=&msq=&ba=false&t=$id&fs=1");
	# } else {
		# return ("POST:mail.google.com/mail/?&ik=&search=$search&view=tl&start=0|&act=$act&at=$gmail_at&vp=&msq=&ba=false&t=$id&fs=1");
	# }
}

sub gen_prefix_url {
	if ($hosted) {
		return ("mail.google.com/a/$hosted");
	} else {
		return ("mail.google.com/mail");
	}
}


sub undo_last {
	# Undo last Gmail action ...
	print "undo called\n" unless $silent;
	return unless @undo_buffer;
	
	notify($trans{notify_undoing});
	
	my $label;
	foreach my $i (@undo_buffer) {
		my $id = shift(@$i);
		$label = shift(@$i);
		print "undoing $id, @$i\n" unless $silent;
		foreach (@$i) {
			$request->enqueue(gen_action_url($gmail_undo{$_},$id));
		}
	}
	queue_check($label);
}

sub get_screen {
	my ($boxx, $boxy)=@_;
	
	# get screen resolution
	my $monitor = $eventbox->get_screen->get_monitor_at_point($boxx,$boxy);
    	my $rect = $eventbox->get_screen->get_monitor_geometry($monitor);
	my $height = $rect->height;
	
	# support multiple monitors (thanks to Philip Jagielski for this simple solution!)
	my $width;
	unless ($disable_monitors_check) {
		for my $i (0 .. $monitor) {
			$width += $eventbox->get_screen->get_monitor_geometry($i)->width;
		}
	} else {
		$width = $eventbox->get_screen->get_monitor_geometry($monitor)->width;
	}
	
	return ($monitor,$rect,$width,$height);
}

sub show_notify {
	# We can only get the allocated width when the window is shown,
	# so we do all this calculation in a separate subroutine ...
	my ($win_notify_temp) = @_;	
	my $new_win = $win_notify_temp ? $win_notify_temp : $win_notify;
	
	# get eventbox origin and icon height
	my ($boxx, $boxy) = $eventbox->window->get_origin;
	my $icon_height = $eventbox->allocation->height;
	
	# get screen resolution
	my ($monitor,$rect,$width,$height)=get_screen($boxx, $boxy);
	
	# if the tray icon is at the top of the screen, it's safe to move the window
	# to the previous window's position - this makes things look a lot smoother
	# (we can't do it when the tray icon's at the bottom of the screen, because
	# a larger window will cover the icon, and when we move it we'll get another
	# show_notify() event)
	$new_win->move($old_x,$old_y) if (($boxy<($height/2)) && ($old_x || $old_y));
	
	# show the window to get width and height
	$new_win->show_all unless ($new_win->visible);
	my $notify_width=$new_win->allocation->width;
	my $notify_height=$new_win->allocation->height;
		
	if ($notify_height>($height-$icon_height-20)) {
		# print "begin block\n";
		$reshow=1;
		$new_win->hide;

		my $scrolled = Gtk2::ScrolledWindow->new;
		$scrolled->modify_bg('normal', Gtk2::Gdk::Color->new (0, 0, 0));
		$scrolled->set_policy('never','automatic');
		$scrolled->set_shadow_type('GTK_SHADOW_NONE');
		$notify_vbox_b->pack_start($scrolled,1,1,0);
		
		my $scrolled_event = Gtk2::EventBox->new;
		$scrolled_event->modify_bg('normal', Gtk2::Gdk::Color->new (0, 0, 0));
		
		$scrolled->add_with_viewport($scrolled_event);
		
				
		$new_win->resize($notify_width, $height-$icon_height-20);
		$notifybox->reparent($scrolled_event);
		
		$new_win->show_all;
		$new_win->resize($notify_width, $height-$icon_height-20);
		# print "vadj = $vadj\n";
				
		$notify_height=$new_win->allocation->height;
		$notify_width=$new_win->allocation->width;
	}
			
	# calculate best position
	my $x_border = 4;
	my $y_border = 5;
	my $move_x = ($boxx+$notify_width+$x_border > $width) ? ($width-$notify_width-$x_border) : ($boxx);
	my $move_y = ($boxy>($height/2)) ? ($boxy-$notify_height-$y_border) : ($boxy+$icon_height+$y_border);
	
	# move the window
	$new_win->move($move_x,$move_y) if ($move_x || $move_y);
	Gtk2->main_iteration while (Gtk2->events_pending);
	
	# $new_win->show_all unless ($new_win->visible);
	# Gtk2->main_iteration while (Gtk2->events_pending);

	# $scrolled->set_vadjustment($vadj) if $vadj;
	
	# a small sleep to make compiz work better
	# select(undef, undef, undef, 0.150);
	if ($win_notify_temp) {
		$win_notify->destroy;
		$win_notify="";
		$win_notify=$new_win;
	}
	# Gtk2->main_iteration while (Gtk2->events_pending);

	
	($old_x, $old_y) = ($move_x,$move_y);
	
	# Enter/leave notification
	$win_notify->signal_connect('enter_notify_event', sub {
		# print "enter\n";
		$notify_enter = 1;
		my $persistence = Glib::Timeout->add($popup_persistence, sub {
			$reshow=0;
		});
	});
	
	$win_notify->signal_connect('leave_notify_event', sub {
		# print "leave event ...\n";
		return if ($reshow);

		### these four lines fix the XGL/Compiz problem where clicking on the links closes the notifier window
		my ($widget, $event, $data) = @_;
		if ($event->detail eq 'inferior') {
			return;
		}
		
		# print "leave and hide\n";
		$notify_enter = 0;
		$notify_vis = 0;
		$win_notify->hide;
	});
}

sub popup {
	# pops up a little message for new mail - disable by setting popup time to 0
	return unless $popup_delay;
	
	# no point displaying if the user is already looking at the popup ..
	return if (($win_notify) && ($win_notify->visible));
	
	my ($text) = @_;
	
	$popup_win->destroy if $popup_win;
	
	$popup_win = Gtk2::Window->new('popup');
	$popup_win->set('allow-shrink',1);
	$popup_win->set_border_width(2);
	$popup_win->modify_bg('normal', Gtk2::Gdk::Color->new (14756, 20215, 33483));
	
	# the eventbox is needed for the background ...
	my $popupbox = Gtk2::EventBox->new;
	$popupbox->modify_bg('normal', Gtk2::Gdk::Color->new (65000, 65000, 65000));
	
	# the hbox gives an internal border, and allows us to chuck an icon in, too!
	my $popup_hbox = Gtk2::HBox->new (0, 0);
	$popup_hbox->set_border_width(4);
	$popupbox->add($popup_hbox);
	
	# Popup icon
	my $popup_icon = Gtk2::Image->new_from_pixbuf($mail_pixbuf);
	$popup_hbox->pack_start($popup_icon,0,0,3);
	
	my $popuplabel = Gtk2::Label->new;
	$popuplabel->set_line_wrap(1);
	
	$popuplabel->set_markup("$text");
	$popup_hbox->pack_start($popuplabel,0,0,3);
	$popupbox->show_all;
	
	$popup_win->add($popupbox);
	
	# get eventbox origin and icon height
	my ($boxx, $boxy) = $eventbox->window->get_origin;
	my $icon_height = $eventbox->allocation->height;
	
	# get screen resolution
	my ($monitor,$rect,$width,$height)=get_screen($boxx, $boxy);
		
	# show the window to get width and height
	$popup_win->show_all;
	my $popup_width=$popup_win->allocation->width;
	my $popup_height=$popup_win->allocation->height;
	$popup_win->hide;
	$popup_win->resize($popup_width, 1);
	
	# calculate best position
	my $x_border = 4;
	my $y_border = 6;
	my $move_x = ($boxx+$popup_width+$x_border > $width) ? ($width-$popup_width-$x_border) : ($boxx);
	my $move_y = ($boxy>($height/2)) ? ($boxy-$popup_height-$y_border) : ($icon_height+$y_border);
	
	my $shift_y = ($boxy>($height/2)) ? 1 : 0;
	
	$popup_win->move($move_x,$move_y);
	$popup_win->show_all;
			
	# and popup ...
	my $ani_delay = 0.015;
	for (my $i = 1; $i<=$popup_height; $i++) {
		my $move_y = ($shift_y) ? ($boxy-$i-$y_border) : $move_y;
		
		# move the window
		$popup_win->move($move_x,$move_y);
		$popup_win->resize($popup_width, $i);
		Gtk2->main_iteration while (Gtk2->events_pending);
		
		select(undef,undef,undef,$ani_delay);
	}
	
		
	my $close = Glib::Timeout->add($popup_delay, sub { popdown($popup_height, $popup_width, $shift_y, $move_y, $boxy, $y_border, $move_x) });
}

sub popdown {
	# Hides the popup box with animation ...
	my ($popup_height, $popup_width, $shift_y, $move_y, $boxy, $y_border, $move_x) = @_;
	
	for (my $i = $popup_height; $i>0; $i--) {
		my $move_y = ($shift_y) ? ($boxy-$i-$y_border) : $move_y;

		# move the window
		$popup_win->move($move_x,$move_y);
		$popup_win->resize($popup_width, $i);
		Gtk2->main_iteration while (Gtk2->events_pending);
		
		select(undef,undef,undef,0.015);
	}
	
	$popup_win->destroy;
}

	
#######################
# Popup menu handling
#

sub handle_button_press {
	# Modified from yarrsr ...
    	my ($widget, $event) = @_;
    	
    	my $x = $event->x_root - $event->x;
    	my $y = $event->y_root - $event->y;
    	
	if ($event->button == 1) {
		open_gmail();
    	} else {
		$menu->popup(undef,undef, sub{return position_menu($x, $y)},0,$event->button,$event->time);
    	}
}

sub position_menu {
    	# Modified from yarrsr
    	my ($x, $y) = @_;
	
    	my $monitor = $menu->get_screen->get_monitor_at_point($x,$y);
    	my $rect = $menu->get_screen->get_monitor_geometry($monitor);
	
    	my $space_above = $y - $rect->y;
    	my $space_below = $rect->y + $rect->height - $y;
	
    	my $requisition = $menu->size_request();
	
    	if ($requisition->height <= $space_above || $requisition->height <= $space_below) {
		if ($requisition->height <= $space_below) {
    			$y = $y + $eventbox->allocation->height; 
		} else {
    			$y = $y - $requisition->height;
		}
    	} elsif ($requisition->height > $space_below && $requisition->height > $space_above) {
		if ($space_below >= $space_above) {
    			$y = $rect->y + $rect->height - $requisition->height;
		} else {
    			$y = $rect->y;
		}
    	} else {
			$y = $rect->y;
    	}
	
    	return ($x,$y,1);
}


sub pack_menu {
	# This code (and the relevant menu display routine) is based 
	# on code from yarrsr (Yet Another RSS Reader) (http://yarrsr.sf.net)

	$menu = Gtk2::Menu->new;
	
	my $menu_check = Gtk2::ImageMenuItem->new($trans{menu_check});
	$menu_check->set_image(Gtk2::Image->new_from_stock('gtk-refresh','menu'));
	$menu_check->signal_connect('activate',sub {
		queue_check();
		foreach my $label (keys(%label_delay)) {
			queue_check($label);
		}
	});
	
	my $menu_undo;
	if ($cookies) {
		# Undo last POST action
		$menu_undo = Gtk2::ImageMenuItem->new($trans{menu_undo});
		$menu_undo->set_image(Gtk2::Image->new_from_stock('gtk-undo','menu'));
		$menu_undo->signal_connect('activate', \&undo_last);
	}
	
	my $menu_compose = Gtk2::ImageMenuItem->new($trans{menu_compose});
	$menu_compose->set_image(Gtk2::Image->new_from_pixbuf(load_pixbuf($compose_mail_data)));
	$menu_compose->signal_connect('activate',sub {
		run_command($gmail_command, get_login_href("https://mail.google.com/mail/??view=cm&tf=0#compose"));
	});
	
	my $menu_prefs = Gtk2::ImageMenuItem->new($trans{menu_prefs});
	$menu_prefs->set_image(Gtk2::Image->new_from_stock('gtk-preferences','menu'));
	$menu_prefs->signal_connect('activate',sub {
		show_prefs();
	});
	
	my $menu_about = Gtk2::ImageMenuItem->new($trans{menu_about});
	$menu_about->set_image(Gtk2::Image->new_from_stock('gtk-about','menu'));
	$menu_about->signal_connect('activate',sub {
		about();
	});
	
	my $menu_restart = Gtk2::ImageMenuItem->new($trans{menu_restart});
	#$menu_about->set_image(Gtk2::Image->new_from_stock('gtk-about','menu'));
	$menu_restart->signal_connect('activate',sub {
		restart();
	});
	
	my $menu_quit = Gtk2::ImageMenuItem->new_from_stock('gtk-quit');
	$menu_quit->signal_connect('activate',sub {
			Gtk2->main_quit;
	});
	
	# Pack menu ...
	$menu->append($menu_check);
	$menu->append($menu_undo) if $cookies;
	$menu->append($menu_compose);
	$menu->append(Gtk2::SeparatorMenuItem->new);
	$menu->append($menu_prefs);
	$menu->append($menu_about);
	$menu->append(Gtk2::SeparatorMenuItem->new);
	$menu->append($menu_restart);
	$menu->append($menu_quit);
	
	$menu->show_all;
}

sub restart {
	exec "$0 @ARGV";
}


#################
# GUI dialogues
#

sub show_prefs {
	# The preferences dialogue ...
	# Yes, I know, I know - it's getting seriously ugly, isn't it?? :)
	
    	my $dialog = Gtk2::Dialog->new ($trans{prefs}, undef,
                                    	'destroy-with-parent',
                                    	'gtk-ok' => 'ok',
					'gtk-cancel' => 'cancel',
			);
	
	my $hbox = Gtk2::HBox->new (0, 0);
	$hbox->set_border_width (4);
	$dialog->vbox->pack_start ($hbox, 0, 0, 0);
	
	my $vbox = Gtk2::VBox->new (0, 4);
	$hbox->pack_start ($vbox, 0, 0, 4);
	
      	my $frame_login = Gtk2::Frame->new ("$trans{prefs_login}");
	$vbox->pack_start ($frame_login, 0, 0, 4);
      	
		my $table_login = Gtk2::Table->new (2, 3, 0);
      		$table_login->set_row_spacings (4);
      		$table_login->set_col_spacings (4);
		$table_login->set_border_width (5);

		$frame_login->add($table_login);
		
      		my $label_user = Gtk2::Label->new_with_mnemonic ($trans{prefs_login_user});
		$label_user->set_alignment (0, 0.5);
      		$table_login->attach_defaults ($label_user, 0, 1, 0, 1);
		
      		my $entry_user = Gtk2::Entry->new;
		$entry_user->set_width_chars(15);
		$entry_user->append_text($user) if $user;
      		$table_login->attach_defaults ($entry_user, 1, 2, 0, 1);
      		$label_user->set_mnemonic_widget ($entry_user);
		
      		my $label_pwd = Gtk2::Label->new_with_mnemonic ($trans{prefs_login_pass});
		$label_pwd->set_alignment (0, 0.5);
      		$table_login->attach_defaults ($label_pwd, 0, 1, 1, 2);
		
      		my $entry_pwd = Gtk2::Entry->new;
		$entry_pwd->set_width_chars(15);
		$entry_pwd->set_invisible_char('*');
		$entry_pwd->set_visibility(0);
		$entry_pwd->append_text($passwd_decrypt) if $passwd_decrypt;
      		$table_login->attach_defaults ($entry_pwd, 1, 2, 1, 2);
      		$label_pwd->set_mnemonic_widget ($entry_pwd);
		$entry_pwd->signal_connect(activate=>sub {$dialog->response('ok')});
		
		my $button_passwd = Gtk2::CheckButton->new_with_label($trans{prefs_login_save});
		$table_login->attach_defaults($button_passwd, 0, 2, 2, 3 );
		$button_passwd->set_active(1) if ($save_passwd);
		$button_passwd->set_label("$trans{prefs_login_save} ($trans{prefs_login_save_plain})") if ($nocrypt && !$usekwallet);
		$button_passwd->set_label("$trans{prefs_login_save} ($trans{prefs_login_save_kwallet})") if ($usekwallet);
		$button_passwd->signal_connect(toggled=>sub {
				$save_passwd = ($button_passwd->get_active) ? 1 : 0;
			}
		);
	
	my $frame_lang = Gtk2::Frame->new ("$trans{prefs_lang}");
	$vbox->pack_start ($frame_lang, 0, 0, 4);
		
		my $vbox_lang = Gtk2::VBox->new (0, 0);
		$frame_lang->add($vbox_lang);
		$vbox_lang->set_border_width(6);
		
			my $lang_option = Gtk2::OptionMenu->new;
			my $lang_menu = Gtk2::Menu->new;
			
			my $xmlin = XMLin($translations, ForceArray => 1);
			my $count = 0;
			my $index;
			
			my @langs = keys(%{$xmlin->{Language}});
			@langs = sort(@langs);
			# foreach (keys(%{$xmlin->{Language}})) {
			foreach (@langs) {
				my $item = make_menu_item($_);
				$lang_menu->append($item);
				$index = $count if ($_ eq $language); # check which index number is the currently selected langauge
				$count++;
			}
			
			$lang_option->set_menu($lang_menu);
			$lang_option->set_history($index);
			$vbox_lang->pack_start($lang_option,0,0,3);

											
	my $frame_external = Gtk2::Frame->new ("$trans{prefs_external}");
	$vbox->pack_start ($frame_external, 0, 0, 4);
		
		my $vbox_external = Gtk2::VBox->new (0, 0);
		$frame_external->add($vbox_external);
		$vbox_external->set_border_width(6);
		
			# my $hbox_browser = Gtk2::HBox->new (0,0);
			# $vbox_external->pack_start($hbox_browser,1,1,2);
				
			my $exe_label = Gtk2::Label->new_with_mnemonic($trans{prefs_external_browser});
			$exe_label->set_line_wrap(1);
			$exe_label->set_alignment (0, 0.5);
			$vbox_external->pack_start($exe_label,0,0,2);
			
			my $exe_label2 = Gtk2::Label->new();
			$exe_label2->set_markup("<small>$trans{prefs_external_browser2}</small>");
			$exe_label2->set_line_wrap(1);
			$exe_label2->set_alignment (0, 0.5);
			$vbox_external->pack_start($exe_label2,0,0,2);
			
			
			my $hbox_exe = Gtk2::HBox->new (0,0);
			$vbox_external->pack_start($hbox_exe,1,1,3);
			
				my $label_exe_sp = Gtk2::Label->new("   ");
				$label_exe_sp->set_alignment (0, 0.5);
      				$hbox_exe->pack_start($label_exe_sp, 0, 0, 0);
				
				my $exe_entry = Gtk2::Entry->new();
				$exe_entry->set_width_chars(14);
				$exe_entry->set_text($gmail_command);
				$hbox_exe->pack_end($exe_entry,1,1,0);
				
			$vbox_external->pack_start (Gtk2::HSeparator->new, 0, 0, 4);
			
			my $label_notify = Gtk2::Label->new_with_mnemonic ($trans{prefs_external_mail_command});
			$label_notify->set_line_wrap(1);
			$label_notify->set_alignment (0, 0.5);
			$vbox_external->pack_start($label_notify,0,0,3);
			
			my $hbox_notify = Gtk2::HBox->new (0,0);
			$vbox_external->pack_start($hbox_notify,1,1,3);
		
 				my $label_notify_sp = Gtk2::Label->new("   ");
				$label_notify_sp->set_alignment (0, 0.5);
      				$hbox_notify->pack_start($label_notify_sp, 0, 0, 0);
				
     				my $entry_notify = Gtk2::Entry->new;
				$entry_notify->append_text($notify_command) if $notify_command;
				$entry_notify->set_width_chars(15);
      				$hbox_notify->pack_start($entry_notify, 1, 1, 0);
      				$label_notify->set_mnemonic_widget ($entry_notify);
				
			my $label_notify_none = Gtk2::Label->new_with_mnemonic ($trans{prefs_external_nomail_command});
			$label_notify_none->set_alignment (0, 0.5);
			$label_notify_none->set_line_wrap(1);
			$vbox_external->pack_start($label_notify_none,0,0,3);
			
			my $hbox_notify_none = Gtk2::HBox->new (0,0);
			$vbox_external->pack_start($hbox_notify_none,1,1,3);
		
 				my $label_notify_none_sp = Gtk2::Label->new("   ");
				$label_notify_none_sp->set_alignment (0, 0.5);
      				$hbox_notify_none->pack_start($label_notify_none_sp, 0, 0, 0);
				
     				my $entry_notify_none = Gtk2::Entry->new;
				$entry_notify_none->set_width_chars(15);
				$entry_notify_none->append_text($nomail_command) if $nomail_command;
      				$hbox_notify_none->pack_start($entry_notify_none, 1, 1, 0);
      				$label_notify_none->set_mnemonic_widget ($entry_notify_none);
				# $vbox_external->pack_start($entry_notify_none,0,0,3);
				

	my $vbox2 = Gtk2::VBox->new (0, 4);
	$hbox->pack_start ($vbox2, 0, 0, 4);
		
      	my $frame_check = Gtk2::Frame->new ("$trans{prefs_check}");
	$vbox2->pack_start ($frame_check, 0, 0, 4);
		
		my $vbox_check = Gtk2::VBox->new (0, 0);
		$frame_check->add($vbox_check);
		$vbox_check->set_border_width(6);

			my $hbox_delay = Gtk2::HBox->new (0,0);
			$vbox_check->pack_start($hbox_delay,0,0,2);
			
				my $label_delay = Gtk2::Label->new_with_mnemonic ($trans{prefs_check_delay});
				$label_delay->set_alignment (0, 0.5);
      				$hbox_delay->pack_start($label_delay, 0, 0, 0);
				
      				my $entry_delay = Gtk2::Entry->new;
				$entry_delay->set_width_chars(4);
				$entry_delay->append_text($delay/1000) if $delay;
      				$hbox_delay->pack_start($entry_delay, 0, 0, 0);
      				$label_delay->set_mnemonic_widget ($entry_delay);
				
				my $label_secs = Gtk2::Label->new_with_mnemonic ($trans{prefs_check_delay2});
				$label_secs->set_alignment (0, 0.5);
      				$hbox_delay->pack_start($label_secs, 0, 0, 0);
			
			
			##########
			# Labels
			#
			
				my $labels_label = Gtk2::Label->new_with_mnemonic($trans{prefs_check_labels});
				$labels_label->set_line_wrap(1);
				$labels_label->set_alignment (0, 0.5);
				$vbox_check->pack_start($labels_label,0,0,4);
				
				convert_labels_from_hash();
				
				# most of this code is adapted from the treeview.pl example provided with Gtk2-perl ...
				my $sw = Gtk2::ScrolledWindow->new;
      				$sw->set_shadow_type ('etched-in');
      				$sw->set_policy ('automatic', 'automatic');
      				$vbox_check->pack_start ($sw, 1, 1, 0);
				
      				# create model
				my $model = Gtk2::ListStore->new (qw/Glib::String Glib::Int/);
							
  				# add labels to model
  				foreach my $a (@labels) {
      					my $iter = $model->append;
      					$model->set ($iter,
                   					0, $a->{label},
                   					1, $a->{delay});
  				}
	
      				# create tree view
      				my $treeview = Gtk2::TreeView->new_with_model ($model);
      				$treeview->set_rules_hint (1);
      				$treeview->get_selection->set_mode ('single');
				
				# label columns
  				my $renderer = Gtk2::CellRendererText->new;
  				$renderer->signal_connect (edited => \&cell_edited, $model);
  				$renderer->set_data (column => 0);
				
  				$treeview->insert_column_with_attributes (-1, $trans{prefs_check_labels_label}, $renderer,
					    				text => 0,
					    				editable => 1);
				
  				# delay column
  				$renderer = Gtk2::CellRendererText->new;
  				$renderer->signal_connect (edited => \&cell_edited, $model);
  				$renderer->set_data (column => 1);
				
  				$treeview->insert_column_with_attributes (-1, $trans{prefs_check_labels_delay}, $renderer,
					    				text => 1,
					    				editable => 1);
      				$sw->add ($treeview);
				
      				# buttons for adding and removing labels ...
      				my $label_button_hbox = Gtk2::HBox->new (1, 4);
      				$vbox_check->pack_start ($label_button_hbox, 0, 0, 0);
				
      				my $button_addlabel = Gtk2::Button->new ($trans{prefs_check_labels_add});
      				$button_addlabel->signal_connect (clicked => sub {
						push @labels, {
							label => $trans{prefs_check_labels_new},
							delay => 300,
  						};
						
  						my $iter = $model->append;
  						$model->set ($iter,
               						0, $labels[-1]{label},
               						1, $labels[-1]{delay},);
					}, $model);
      				$label_button_hbox->pack_start ($button_addlabel, 1, 1, 0);
				
      				my $button_removelabel = Gtk2::Button->new ($trans{prefs_check_labels_remove});
      				$button_removelabel->signal_connect (clicked => sub {
						my $selection = $treeview->get_selection;
  						my $iter = $selection->get_selected;
  						if ($iter) {
      							my $path = $model->get_path ($iter);
      							my $i = ($path->get_indices)[0];
      							$model->remove ($iter);
      							splice @labels, $i, 1;
  						}
					}, $treeview);
      				$label_button_hbox->pack_start ($button_removelabel, 1, 1, 0);
			
			
			$vbox_check->pack_start (Gtk2::HSeparator->new, 0, 0, 4);
			
			my $hbox_atom = Gtk2::HBox->new (0,0);
			$vbox_check->pack_start($hbox_atom,1,1,2);
			
				my $atom_label = Gtk2::Label->new_with_mnemonic($trans{prefs_check_atom});
				$hbox_atom->pack_start($atom_label,0,0,2);
				
				my $atom_entry = Gtk2::Entry->new();
				$atom_entry->set_width_chars(14);
				$atom_entry->set_text($gmail_address);
				$hbox_atom->pack_end($atom_entry,1,1,2);
			

			
			# Thanks to Rune Maagensen for adding the 24 hour clock button ...				
			my $button_24h = Gtk2::CheckButton->new_with_label($trans{prefs_check_24_hour});
			$vbox_check->pack_start($button_24h, 0, 0, 2);
			$button_24h->set_active(1) if ($time_24);
			$button_24h->signal_connect(toggled=>sub {
       					$time_24 = ($button_24h->get_active) ? 1 : 0;
       				}
			);
			
			my $button_archive = Gtk2::CheckButton->new_with_label($trans{prefs_check_archive});
			$vbox_check->pack_start($button_archive, 0, 0, 2);
			$button_archive->set_active(1) if ($archive_as_read);
			$button_archive->signal_connect(toggled=>sub {
       					$archive_as_read = ($button_archive->get_active) ? 1 : 0;
       				}
			);
			

	
		
	
	my $frame_tray = Gtk2::Frame->new ("$trans{prefs_tray}");
	$vbox2->pack_start ($frame_tray, 0, 0, 4);
		
		my $vbox_tray = Gtk2::VBox->new (0, 0);
		$frame_tray->add($vbox_tray);
		$vbox_tray->set_border_width(6);
		
		# There's a lot of Gtk2-perl modules included in distros with only
		# Gtk-2.4 bindings ... the following code needs 2.6 bindings to funtion
		if (Gtk2->CHECK_VERSION (2, 6, 0)) {
						
			my $hbox_icon_m = Gtk2::HBox->new (0,6);
			$vbox_tray->pack_start($hbox_icon_m, 0, 0, 2);
			
				my $button_m = Gtk2::CheckButton->new_with_label($trans{prefs_tray_mail_icon});
				$hbox_icon_m->pack_start($button_m, 0, 0, 0 );
				$button_m->set_active(1) if ($custom_mail_icon);
				$button_m->signal_connect(toggled=>sub {
						$custom_mail_icon = ($button_m->get_active) ? 1 : 0;
					}
				);
				
				my $button_m_open = Gtk2::Button->new("");
				$button_m_open->set_image(Gtk2::Image->new_from_pixbuf($custom_mail_pixbuf));
				$button_m_open->signal_connect(clicked=>sub {
						get_icon_file(\$mail_icon);
						set_icons();
						$button_m_open->set_image(Gtk2::Image->new_from_pixbuf($custom_mail_pixbuf));
					}
				);
				$hbox_icon_m->pack_end($button_m_open, 0, 0, 0);
			
			my $hbox_icon_nom = Gtk2::HBox->new (0,6);
			$vbox_tray->pack_start($hbox_icon_nom, 1, 1, 2);
			
				my $button_nom = Gtk2::CheckButton->new_with_label($trans{prefs_tray_no_mail_icon});
				$hbox_icon_nom->pack_start($button_nom, 0, 0, 0 );
				$button_nom->set_active(1) if ($custom_no_mail_icon);
				$button_nom->signal_connect(toggled=>sub {
						$custom_no_mail_icon = ($button_nom->get_active) ? 1 : 0;
					}
				);
				
				my $button_nom_open = Gtk2::Button->new("");
				$button_nom_open->set_image(Gtk2::Image->new_from_pixbuf($custom_no_mail_pixbuf));
				$button_nom_open->signal_connect(clicked=>sub {
						get_icon_file(\$no_mail_icon);
						set_icons();
						$button_nom_open->set_image(Gtk2::Image->new_from_pixbuf($custom_no_mail_pixbuf));
					}
				);
				$hbox_icon_nom->pack_end($button_nom_open, 0, 0, 0);
				
			my $hbox_icon_error = Gtk2::HBox->new (0,6);
			$vbox_tray->pack_start($hbox_icon_error, 1, 1, 2);
			
				my $button_error = Gtk2::CheckButton->new_with_label($trans{prefs_tray_error_icon});
				$hbox_icon_error->pack_start($button_error, 0, 0, 0 );
				$button_error->set_active(1) if ($custom_error_icon);
				$button_error->signal_connect(toggled=>sub {
						$custom_error_icon = ($button_error->get_active) ? 1 : 0;
					}
				);
				
				my $button_error_open = Gtk2::Button->new("");
				$button_error_open->set_image(Gtk2::Image->new_from_pixbuf($custom_error_pixbuf));
				$button_error_open->signal_connect(clicked=>sub {
						get_icon_file(\$error_icon);
						set_icons();
						$button_error_open->set_image(Gtk2::Image->new_from_pixbuf($custom_error_pixbuf));
					}
				);
				$hbox_icon_error->pack_end($button_error_open, 0, 0, 0);
				
		} else {
			# Warning message if user doesn't have Gtk2.6 bindings ...
			my $button_gtk_label = Gtk2::Label->new();
			my $error_text = "<i>Button image functions are disabled</i>\n\nPlease upgrade to Gtk v2.6 or later and/or update Gtk2-perl bindings";
			$button_gtk_label->set_line_wrap(1);
			$button_gtk_label->set_markup($error_text);

			$vbox_tray->pack_start($button_gtk_label, 1, 1, 2);
		}	
					
			$vbox_tray->pack_start (Gtk2::HSeparator->new, 0, 0, 4);
			
			my $hbox_pdelay = Gtk2::HBox->new (0,0);
			$vbox_tray->pack_start($hbox_pdelay,0,0,3);
			
				my $label_pdelay = Gtk2::Label->new_with_mnemonic ($trans{prefs_tray_pdelay});
				$label_pdelay->set_alignment (0, 0.5);
      				$hbox_pdelay->pack_start($label_pdelay, 0, 0, 0);
				
      				my $entry_pdelay = Gtk2::Entry->new;
				$entry_pdelay->set_width_chars(3);
				$entry_pdelay->append_text($popup_delay/1000) if $popup_delay;
      				$hbox_pdelay->pack_start($entry_pdelay, 0, 0, 0);
      				$label_pdelay->set_mnemonic_widget ($entry_pdelay);
				
				my $label_psecs = Gtk2::Label->new_with_mnemonic ($trans{prefs_tray_pdelay2});
				$label_psecs->set_alignment (0, 0.5);
      				$hbox_pdelay->pack_start($label_psecs, 0, 0, 0);
				
			$vbox_tray->pack_start (Gtk2::HSeparator->new, 0, 0, 3);
			
			my $button_colour = Gtk2::Button->new($trans{prefs_tray_bg});
			$button_colour->signal_connect(clicked=>\&set_bg_colour);
			$vbox_tray->pack_start($button_colour,0,0,3);
			
				
	$dialog->show_all;
    	my $response = $dialog->run;
	
	if ($response eq 'ok') {
		# remove password from the hash if user requests it ...
		if ($save_passwd && !$usekwallet) {
			$pref_variables{passwd}=\$passwd;
		} else {
			delete $pref_variables{passwd};
		}
		
		# grab all entry variables ...
		$user = $entry_user->get_text;
		$passwd_decrypt = $entry_pwd->get_text;
		$passwd = encrypt_real($passwd_decrypt);
		$delay = ($entry_delay->get_text)*1000;
		$popup_delay = ($entry_pdelay->get_text)*1000;
		$gmail_address = $atom_entry->get_text;
		$gmail_command = $exe_entry->get_text;
		$notify_command	= $entry_notify->get_text;
		$nomail_command	= $entry_notify_none->get_text;
		
		if ($usekwallet && $save_passwd) {
			open KWALLET, "|kwallet -set checkgmail";
			print KWALLET "$passwd\n";
			close KWALLET;
		}

		reinit_checks();
				
		write_prefs();
		set_icons();
		set_language();
		pack_menu();
		queue_check();
	}
	
	$dialog->destroy;	
}


sub reinit_checks {
	Glib::Source->remove($check{inbox}) if $check{inbox};
	$check{inbox} = Glib::Timeout->add($delay, \&queue_check);
	
	foreach my $label (keys(%label_delay)) {
		Glib::Source->remove($check{$label}) if $check{$label};
		$check{$label} = Glib::Timeout->add(($label_delay{$label}*1000), sub{queue_check($label)});
		queue_check($label);
	}		
}


sub cell_edited {
  my ($cell, $path_string, $new_text, $model) = @_;
  my $path = Gtk2::TreePath->new_from_string ($path_string);

  my $column = $cell->get_data ("column");

  my $iter = $model->get_iter ($path);

  if ($column == 0) {
	my $i = ($path->get_indices)[0];
	$labels[$i]{label} = $new_text;

	$model->set ($iter, $column, $labels[$i]{label});

  } elsif ($column == 1) {
	my $i = ($path->get_indices)[0];
	$labels[$i]{delay} = $new_text;

	$model->set ($iter, $column, $labels[$i]{delay});
  }
}


sub make_menu_item
{
	my ($name) = @_;
	my $item = Gtk2::MenuItem->new_with_label($name);
	$item->signal_connect(activate => sub{$language=$name});
	$item->show;

	return $item;
}

sub login {
	# a login dialogue - just ripped from the prefs above ...
	
	# lock shared variables
	lock($user);
	lock($passwd);
	lock($save_passwd);
	lock($gmail_address);

	my ($title) = @_;
    	my $dialog = Gtk2::Dialog->new ($title, undef,
                                    	'destroy-with-parent',
                                    	'gtk-ok' => 'ok',
					'gtk-cancel' => 'cancel',
			);
	# $dialog_login->set_default_response('ok');
	
	my $hbox = Gtk2::HBox->new (0, 0);
	$hbox->set_border_width (4);
	$dialog->vbox->pack_start ($hbox, 0, 0, 0);
	
	my $vbox = Gtk2::VBox->new (0, 4);
	$hbox->pack_start ($vbox, 0, 0, 4);
	      	
	my $table_login = Gtk2::Table->new (2, 3, 0);
      	$table_login->set_row_spacings (4);
      	$table_login->set_col_spacings (4);
	$table_login->set_border_width (5);

	$hbox->add($table_login);
	
      	my $label_user = Gtk2::Label->new_with_mnemonic ($trans{prefs_login_user});
	$label_user->set_alignment (0, 0.5);
      	$table_login->attach_defaults ($label_user, 0, 1, 0, 1);
	
      	my $entry_user = Gtk2::Entry->new;
	$entry_user->set_width_chars(12);
	$entry_user->append_text($user) if $user;
      	$table_login->attach_defaults ($entry_user, 1, 2, 0, 1);
      	$label_user->set_mnemonic_widget ($entry_user);
	
      	my $label_pwd = Gtk2::Label->new_with_mnemonic ($trans{prefs_login_pass});
	$label_pwd->set_alignment (0, 0.5);
      	$table_login->attach_defaults ($label_pwd, 0, 1, 1, 2);
	
      	my $entry_pwd = Gtk2::Entry->new;
	$entry_pwd->set_width_chars(12);
	$entry_pwd->set_invisible_char('*');
	$entry_pwd->set_visibility(0);
	$entry_pwd->append_text($passwd_decrypt) if $passwd_decrypt;
      	$table_login->attach_defaults ($entry_pwd, 1, 2, 1, 2);
      	$label_pwd->set_mnemonic_widget ($entry_pwd);
	$entry_pwd->signal_connect(activate=>sub {$dialog->response('ok')});
	
	my $button_passwd = Gtk2::CheckButton->new_with_label($trans{prefs_login_save});
	$table_login->attach_defaults($button_passwd, 0, 2, 2, 3 );
	$button_passwd->set_active(1) if ($save_passwd);
	$button_passwd->set_label("$trans{prefs_login_save} ($trans{prefs_login_save_plain})") if ($nocrypt && !$usekwallet);
	$button_passwd->set_label("$trans{prefs_login_save} ($trans{prefs_login_save_kwallet})") if ($usekwallet);
	$button_passwd->signal_connect(toggled=>sub {
			$save_passwd = ($button_passwd->get_active) ? 1 : 0;
		}
	);
	
	$dialog->show_all;
    	my $response = $dialog->run;
	if ($response eq 'ok') {
		if (($save_passwd)) {
			$pref_variables{passwd}=\$passwd;
		} else {
			delete $pref_variables{passwd};
		}
		$user = $entry_user->get_text;
		$passwd_decrypt = $entry_pwd->get_text;
		$passwd = encrypt_real($passwd_decrypt);
		write_prefs();
		
		if ($usekwallet && $save_passwd) {
			open KWALLET, "|kwallet -set checkgmail";
			print KWALLET "$passwd\n";
			close KWALLET;
		}

	} else {
		$dialog->destroy;	
		exit 0;
	}
	$dialog->destroy;	
}

sub about {
	my $text = <<EOF;
<b>CheckGmail v$version</b>
Copyright &#169; 2005-7, Owen Marshall
			
<small>This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.</small>

<small>Special thanks to Sandro Tosi, Rune Maagensen, Jean-Baptiste Denis, Jochen Hoenicke, Melita Ivkovic, Poika Pilvimaa, Alvaro Arenas, Marek Drwota, Dennis van der Staal, Jordi Sanfeliu, Fernando Pereira, Matic Ahacic, Johan Gustafsson, Satoshi Tanabe, Marius Mihai, Marek Malysz, Ruszkai &#193;kos, Nageswaran Rajendran, &#23385;&#32487;&#19996;, Martin Kody&#353;, Rune Gangst&#248;, Christian M&#252;ller, Luciano Ziegler, Igor Donev and anonymous contributors for translations ...</small>
		
http://checkgmail.sf.net		
EOF
	chomp($text);
	my $dialog = Gtk2::MessageDialog->new_with_markup(undef,
   			'destroy-with-parent',
   			'info',
   			'ok',
			$text,
		);
  	$dialog->run;
	$dialog->destroy;
}

sub set_bg_colour {
	my $colour;
	my $dialog = Gtk2::ColorSelectionDialog->new ("Set tray background");
	my $colorsel = $dialog->colorsel;
	if ($background) {
		my ($red, $green, $blue) = convert_hex_to_colour($background);
		$colour = Gtk2::Gdk::Color->new($red, $green, $blue);
		$colorsel->set_current_color ($colour);
	}
	
	$colorsel->set_has_palette(1);
	
	my $response = $dialog->run;
	if ($response eq 'ok') {
      		$colour = $colorsel->get_current_color;
      		$eventbox->modify_bg('normal', $colour);
		my $colour_hex = 
			  sprintf("%.2X", ($colour->red  /256))
                  	. sprintf("%.2X", ($colour->green/256))
                  	. sprintf("%.2X", ($colour->blue /256));
		$background = $colour_hex;
	}
	
	$dialog->destroy;
	
}

sub get_icon_file {
	my ($pointer) =  @_;
	
	my $icon_browser = Gtk2::FileChooserDialog->new(
			"Select icon file ...",
			undef,
			'open',
			'gtk-cancel' => 'cancel',
			'gtk-ok' => 'ok',
	);
	
	my $filter = Gtk2::FileFilter->new;
	$filter->add_pixbuf_formats;
	$filter->set_name("Image files");

	$icon_browser->add_filter($filter);

	
	my $response = $icon_browser->run;
	
	my $icon;
	if ($response eq 'ok') {
		$icon = $icon_browser->get_filename;
		$$pointer = $icon;
	}
	
	$icon_browser->destroy;
}

sub set_icons {
	
	# Load custom or default icons for mail status notification ...
	
	# load defaults
	$mail_pixbuf = load_pixbuf($mail_data);
	$no_mail_pixbuf = load_pixbuf($no_mail_data);
	$error_pixbuf = load_pixbuf($error_data);
	$star_pixbuf = load_pixbuf($star_on_data);
	$nostar_pixbuf = load_pixbuf($star_off_data);
	
	# load custom icons if defined
	$custom_mail_pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($mail_icon) if $mail_icon;
	$custom_no_mail_pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($no_mail_icon) if $no_mail_icon;
	$custom_error_pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($error_icon) if $error_icon;
	
	# set custom pixbufs to defaults if undefined
	$custom_mail_pixbuf ||= $mail_pixbuf;
	$custom_no_mail_pixbuf ||= $no_mail_pixbuf;
	$custom_error_pixbuf ||= $error_pixbuf;
	
	# set icon pixbufs to custom pixbufs if user requested
	$mail_pixbuf = $custom_mail_pixbuf if $custom_mail_icon;
	$no_mail_pixbuf = $custom_no_mail_pixbuf if $custom_no_mail_icon;
	$error_pixbuf = $custom_error_pixbuf if $custom_error_icon;
		
}

sub set_icon {
	my ($file, $size) = @_;
	my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($file);
	my $scaled = $pixbuf->scale_simple($size, $size, "hyper");
	return $scaled;
}



#######################
# Encryption routines
#

sub encrypt_real {
	$_ = shift;
	if ($nocrypt) {
		return $_;
	} else {
		return encrypt($_);
	}
}

sub decrypt_real {
	$_ = shift;
	if ($nocrypt) {
		return $_;
	} else {
		return decrypt($_);
	}
}


########
# Misc
#

sub convert_hex_to_colour {
	my ($colour) = @_;
	my ($red, $green, $blue) = $colour =~ /(..)(..)(..)/;

	$red = hex($red)*256;
	$green = hex($green)*256;
	$blue = hex($blue)*256;
	
	return ($red, $green, $blue);
}


#############
# Icon data
#

sub load_pixbuf {
	my $data = shift;
	
	my $loader = Gtk2::Gdk::PixbufLoader->new;
	$loader->write ($data);
	$loader->close;
	
	return $loader->get_pixbuf;
}

sub load_icon_data {
	
	$error_data = unpack("u",
'MB5!.1PT*&@H````-24A$4@```!`````0"`8````?\_]A````!F)+1T0`_P#_
M`/^@O:>3````"7!(67,```QU```,=0$M>)1U````!W1)344\'U047"@0$Y9]#
MH0```85)1$%4.,NUTL%*XU`4QO&_-J3,3$-WTC()(Y\'6G;L+@;CH-AN?0\'P%
MWZ#*>0.?YFZSF(!KEPF#E@2]N"L%P9B*"TTF&<O,@\'AV(?E]^6Y.X(.SE0;!
M67TQBB+ZT^G?GJ\>T[0P6L=`,;V\7%OMNT9K)DI!%&W$:%TL6AA@N_WVH>^3
MB8#6&W$F$@]]O\$`30-G/@<1`#(1)E`W:?#HZ,CP].2E03`#7*#7.4(KI,I$
M\'B;0!^XRD?C[^;GY^OP\SD0:W&G0A"A5`05PE8FXP%4;#WW?_;*_WS-OQ^P&
MY\'E5+I>%HU0,&.#7X.3D\4_LS.?4`=L=G"2%\'8;QZO[>&*W[.\?\'&W%[Z@8-
M9K4R+!;CH>\?9"(%<-!@I=[MU@(JX!4/!J9,DK&CU`P8`7O`MQJ7RR5VGH/G
M=0)N@)_KVUNSOKX>VV$XP_-<)XIZB/2;[0!VGE,F"788_OZ5`=(@L\'Z<GKHU
MKE>T<=Y"%A<7KQ\Q#0(+^#\,X\'F=!A:P"QR62?)O_!GS`K6COO-L,Q_/````
)`$E%3D2N0F""');
	
	$no_mail_data = unpack("u",
'MB5!.1PT*&@H````-24A$4@```!`````0"`0```"U^C?J`````F)+1T0`_X>/
MS+\````)<$A9<P``#\'4```QU`2UXE\'4````\'=$E-10?5!!D#+C1^0]HI````
MB$E$050HS\7/H1&#0!!&X2^9E\'"2X!DD+K7@HE)%*L%1"PY)!;%("HBXRW\'$
M1N1WN^_M[BR_YO1XPLWU"[Q,X!++R5U7X#EASG&^,I@+/*C<=J%7%TK$M;X\
MT1LQP`%G@29!*G6J"F&UY6:ML5F%75@M6D%G1)\[68A8@A"TEOV+#RX3CAO^
6FC<\3AZN>\`BO0````!)14Y$KD)@@@``');
	
	$mail_data = unpack("u",
'MB5!.1PT*&@H````-24A$4@```!`````0"`8````?\_]A````"7!(67,```QU
M```,=0$M>)1U````!W1)344\'U008#C<OWT).ZP```-))1$%4.,OED3$.@S`,
M15^KBHHA8NV2!:EP`B0D3I!+9<BE<@(N`5.5I2MC6=H%(A?2KAWZISCV^[83
M^+4.0]L^U^!B#.>J^@H\AH&[]S$^R>3=>ZY-`\:D:>^Y"1C@*+L79<GH\'&R*
M5GATCJ(LN8@&T4!92U[7:1,!YW6-LC:]@K(6G`-@=([K<O\)WAD`J*:)YW$Q
MB[#(I0U"8)ZF7>$*S]-$%@)HG3`(@;GOR;H.M$89$]=9Q\YDS=9`PF]O(J4U
E6=<Q]_W^%[;P1RTFR0G^5"_P^T_]<U3R]`````!)14Y$KD)@@@``');
	
	$compose_mail_data = unpack("u",
'MB5!.1PT*&@H````-24A$4@```!`````0"`8````?\_]A````!F)+1T0`_P#_
M`/^@O:>3````"7!(67,```L2```+$@\'2W7[\````!W1)344\'U0L#%PT06C)B
M\'P```?A)1$%4.,NMDTUH$U$4A;]))LEDR*1-4],L(H7J2A1+,6E$$"VF8HJ"
M%05_$%V)2,&-".X%<6,1"M*-NJG[4D\'MRK;XLTAB4(QH*5ALJN`B8\J;3)+)
MN!"C0Q)0].[>>><<WKWW//C\'DOZ4:)?=4?#O0Y+[L6T!9D;2*L_D=N0;-Z\/
M`KF?9[>KSOQBGKW);-;G"T2A7`4Q;Y?Y)G<27[UR[1=HY:!61!CQ(5M."XF/
M56IW4U#-R)W$[PMY2KI.I6*"]9*!_@*QS7$L:9?JLD&2-"_HMMQ)G,OGB42B
M=\'>\'\\\'H&<<DKF,8+?\'X08E5UL_\'.YZD___T%N3.GSO+D\1S+RQ\8\'1TCU-.#
MWZ^BJG&H!RE^NH>[](JN4(S91R-#Q\?NOW&T$`[W(H3)N?,74%75,9NOI6UL
M5"<PQ3I=?0E65J>1-,MV&"B*PO!P@H=SL^P?.0"`$`+#,#`,@\+;UQP^<A3%
MKS4U+5O8%(F0W)WDP<P,6[<,`.#UR:RM?6\'\V#BRRQF=MCD(:D\'"H0"I@ZDF
M-G7[%EY9PC1-%`)-W-4:.9N%A:><.\'FZ"36L.A<O3;"XM(1A"`>]Q2";R7`H
MG:9>-;$;#:Q:%0F)AM5@YX[M%-<_=VY!UW42R3T_+F2?@^@!%%6CMR^&KNMM
B#2;O3$]=_HN/.,G_J.\25[KK%,1Y@@````!)14Y$KD)@@@``');

	$star_on_data = unpack("u",
'MB5!.1PT*&@H````-24A$4@```!`````0"`8````?\_]A````!\'-"250("`@(
M?`ADB`````EP2%ES```-UP``#=<!0BB;>````!ET15AT4V]F=\'=A<F4`=W=W
M+FEN:W-C87!E+F]R9YON/!H```)\241!5#B-G5-=2U11%%W[W\'-GQID[V1A^
MI2/-1&9?.D%*,>)3/?10T4-%)4R1^!1!1(\1%/4#`B\'ZH!DMD`KRH;>@\'IIK
M0F$@E*$&HYD.(I0?,Z-S[SV[A]`<\'%_:<&"S66NOM0[G$#.C6)D)JA="O`-1
M3CG.L6B,AXOA1%$V`")Q,]AXN7);Y\'I("\'%G(QR8>=U)QE\'1W^.V\'&N6E3W\'
M\'YX9=C*.ZF+8C1QT5NUH9U(_`?LKMNZZQ``ZBSI-QN$"<`5`2`BMAHBJ&=38
M<BKE$3P,J%]P1#,^OMRY3\'"&F\'E:*6<2P#B`>V1VBQ?EX=,G:O=>TZ6[$IHT
M0)H/1*Y_,FH!2EFP<Q/(YU+(9Z=X:OBA-3\[]$:P4JD2?UB4E!Z`[@E"R$`A
M&0"$%\33D\'(*/K\;@=J3Y/+5"&9.43(./PG15Q$^W[;]8)<D`0`Z``6H!;"3
M!NP)L#T&0$#I;1A)7K5^I]\/L%+\'B9EA)D@2T7VW$;JP[W"W)C$`ML8!7@(X
M\_>R9!UL[2B^O.UP<O-CO<Q\,1IC2P)`-,8V@`XS09[TV/,SM0U\')%2V,(:K
M$3.CK^WLW&A?-,;M*V-9$%73*XPM$0EA@/0&0!@`"%`+@/##*&N20G-5%7!6
M&C-!Q$R\'O(\'](*T6Y&E%+K<)V44/R-,*TH(HV=P$5JK93-"J\%H\'>Z2[S\'!Y
MZV\';B_@Q>,M*CSY>)I!=\'C[KJXO<UG5O$+JWRI7/3$8`?"IP`*!461F5\'GG`
M@Z\:G/3(HUYVED+*R85FOO<\^=RW6TU_ZV)E916`TM67N/8W]O>XGQ*)@\'*6
M[D9C;*[-:B:H16B>&\PJPRI_+AICM6[!_]0?8_PDB6*NF@(`````245.1*Y"
"8((`');

	$star_off_data = unpack("u",
'MB5!.1PT*&@H````-24A$4@```!`````0"`8````?\_]A````!\'-"250("`@(
M?`ADB````?9)1$%4.(VMD\%J$V$4A;_)C&,F36B2,;1-:TA;720N3+.H@R!(
M$0*&K+((:.)3]`&ZRK)TF3?(&R3071]`*18B5!$%H8(FFC).F.DTU\4,4FLB
M")[5SW_//=S_W/.KS(<.;`(F8`.7LTB1OPB8@\\\'@SG`XO`_<FD>:)Z#&X_%D
MH5!82Z?3J5PNEP2T?Q%(=CJ=-/`)^\'!P<)`"DK.("J"&Q1OA60-BCN,4#<-X
M"7B3R>11+!9[#3@$7OC`!?!=`Y;W]_=7&XW&RG0ZO5A<7-0U33,,P_@!?%04
M143$=EUWRW5=9SP>>Y%(1.UVNY]W=W?/-.`RG\\\\;V6QV"7@#O`<FP#=%422<
MM*?K>E+7=2.12*P#]\KELA,^D0BPMK>WM^W[?DM$[L[Q!1\'9%)$7[7;[`7#[
MNH=+]7I]RW7=9R*R/J,YY_O^\V:S60:60__^0+[?[S\6D8<S!+:/CHYV@(VK
M]]?7Z)=*I07@2]BT(B*K8>UKL5A<(-C`+UP/1RR3R9C`1$2>>IZ7\#Q/1,0!
M7J52*1,PYDUPLU:KQ555C0([AX>\'MFF:)Z9IGO1ZO7/@B:JJ>JO52@#160):
M-!J=CD:CD659QY5*Y9UMVZ>>YYU6J]6WEF4=V[9]KBC*)4\'H@-^=5`C<58$1
C0>JNPB#XF5/@#!#^!WX"JHNT6FM(-L<`````245.1*Y"8((`');
	
}


#############
# Languages
#

sub URI_escape {
	# Turn text into HTML escape codes
	($_) = @_;
	s/([^a-zA-Z0-9])/$escapes{$1}/g;
	return $_;
}

sub URI_unescape {
	# Turn HTML escape code into text
	($_) = @_;
	s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	return $_;
}

sub read_translations {
	my $default_translations = <<EOF;
<opt Version="1.12">
  <Language name="Català"
            login_err="Error: Nom d'usuari o contrassenya incorrecte"
            login_title="Entrant a Gmail ..."
            mail_archive="Arxiva"
            mail_archiving="Arxivant ..."
            mail_delete="Suprimeix"
            mail_deleting="Suprimint ..."
            mail_mark="Marca'l com a llegit"
            mail_mark_all="Marca'ls tots com a llegits"
            mail_marking="Marcant com a llegit ..."
            mail_marking_all="Marcant tots com a llegits ..."
            mail_open="Obre"
            mail_report_spam="Marca'l com a correu brossa"
            mail_reporting_spam="Marcant com a correu brossa ..."
            menu_about="_Quant a"
            menu_check="_Comprova correu electrònic"
            menu_compose="Redacta un missatge"
            menu_prefs="_Preferències"
            menu_undo="_Desfés la darrera acció"
            notify_and="i"
            notify_check="S'està comprovant Gmail ..."
            notify_from="De:"
            notify_login="S'està entrant a Gmail ..."
            notify_multiple1="Hi ha"
            notify_multiple2="nous missatges ..."
            notify_new_mail="Nou missatge de"
            notify_no_mail="No hi ha missatges nous"
            notify_no_subject="(sense assumpte)"
            notify_no_text="(sense text)"
            notify_single1="Hi ha"
            notify_single2="un nou missatge ..."
            notify_undoing="Desfent la darrera acció ..."
            prefs="Preferències de CheckGmail"
            prefs_check="Comprovació de missatges"
            prefs_check_24_hour="rellotje de 24 hores"
            prefs_check_archive="Arxiu també marca'l com a llegit"
            prefs_check_atom="Adreça de l'alimentador"
            prefs_check_delay="Verifica nous missatges a la safata d'entrada cada"
            prefs_check_delay2="segs"
            prefs_check_labels="També verifica les següents etiquetes:"
            prefs_check_labels_add="Afegeix una etiqueta"
            prefs_check_labels_delay="Verifica cada (segs)"
            prefs_check_labels_label="Etiqueta"
            prefs_check_labels_new="[nova etiqueta]"
            prefs_check_labels_remove="Suprimeix etiqueta"
            prefs_external="Ordres Externes"
            prefs_external_browser="Ordre a executar quan feu clic a la icona de la safata"
            prefs_external_browser2="(feu servir %u per representar l'adreça web de Gmail)"
            prefs_external_mail_command="Ordre a executar a cada nou missatge:"
            prefs_external_nomail_command="Ordre a executar quan no hi hagi missatges:"
            prefs_lang="Idioma"
            prefs_login="Detalls d'accés"
            prefs_login_pass="_Contrasenya"
            prefs_login_save="Desa contrasenya"
            prefs_login_save_kwallet="a la carpeta de KDE"
            prefs_login_save_plain="com a text"
            prefs_login_user="_Nom d'usuari"
            prefs_tray="Safata del sistema"
            prefs_tray_bg="Configura el color de fons de la safata ..."
            prefs_tray_error_icon="Personalitza la icona d'error"
            prefs_tray_mail_icon="Personalitza la icona de quan hi ha missatges"
            prefs_tray_no_mail_icon="Personalitza la icona de quan no hi ha missatges"
            prefs_tray_pdelay="Mostra finestra emergent de nous missatges durant"
            prefs_tray_pdelay2="segs" />
  <Language name="Dansk"
            login_err="Fejl: forkert brugernavn eller adgangskode"
            login_title="Gmail login"
            mail_archive="Arkivér"
            mail_archiving="Arkiverer ..."
            mail_delete="Slet"
            mail_deleting="Sletter ..."
            mail_mark="Marker læst"
            mail_mark_all="Marker alle som læst"
            mail_marking="Markerer læst ..."
            mail_marking_all="Markerer alle læst ..."
            mail_open="Åbn"
            mail_report_spam="Rapporter spam"
            mail_reporting_spam="Rapporterer spam ..."
            menu_about="_Om Checkgmail"
            menu_check="_Se efter ny post på Gmail"
            menu_compose="Skriv email"
            menu_prefs="_Indstilinger"
            menu_undo="_Fortyd sidste handling ..."
            notify_and="og"
            notify_check="Ser efter ny post på Gmail ..."
            notify_from="Fra:"
            notify_login="Logger ind på Gmail ..."
            notify_multiple1="Der er "
            notify_multiple2=" nye breve ..."
            notify_new_mail="Nyt brev fra "
            notify_no_mail="Ingen nye breve"
            notify_no_subject="(intet emne)"
            notify_no_text="(ingen tekst)"
            notify_single1="Der er "
            notify_single2=" nyt brev ..."
            notify_undoing="Fortryder sidste handling ..."
            prefs="CheckGmail indstillinger"
            prefs_check="Se efter ny post"
            prefs_check_24_hour="24 timers ur"
            prefs_check_archive="Arkivér markerer også læst"
            prefs_check_atom="Feed adresse"
            prefs_check_delay="Se efter ny post i Inbox hver "
            prefs_check_delay2=" sekunder"
            prefs_check_labels="Se også efter følgende mærker:"
            prefs_check_labels_add="Tilføj mærke"
            prefs_check_labels_delay="Se hvert (sekunder)"
            prefs_check_labels_label="Mærke"
            prefs_check_labels_new="[nyt mærke]"
            prefs_check_labels_remove="Fjern Mærke"
            prefs_external="Eksterne programmer"
            prefs_external_browser="Browser"
            prefs_external_browser2="(%u repræsenterer Gmail adressen)"
            prefs_external_mail_command="Kommando ved nyt brev:"
            prefs_external_nomail_command="Kommando ved ingen nye breve:"
            prefs_lang="Sprog"
            prefs_login="Logindetaljer"
            prefs_login_pass="_Adgangskode"
            prefs_login_save="Gem adgagnskode"
            prefs_login_save_kwallet="i KDE tegnebog"
            prefs_login_save_plain="som tekst"
            prefs_login_user="_Brugernavn"
            prefs_tray="Statusfelt"
            prefs_tray_bg="Sæt statusfelt baggrund ..."
            prefs_tray_error_icon="Brug selvvalgt 'fejl' ikon"
            prefs_tray_mail_icon="Brug selvvalgt 'ny post' ikon"
            prefs_tray_no_mail_icon="Brug selvvalgt 'ingen post' ikon"
            prefs_tray_pdelay="Vis nyt brev popup i "
            prefs_tray_pdelay2=" sekunder" />
  <Language name="Deutsch"
            login_err="Fehler: Falsches Login oder Passwort"
            login_title="Google-Mail Login ..."
            mail_archive="Archivieren"
            mail_archiving="Archiviere ..."
            mail_delete="Löschen"
            mail_deleting="Lösche ..."
            mail_mark="Als gelesen markieren"
            mail_mark_all="Alle als gelesen markieren"
            mail_marking="Markiere als gelesen ..."
            mail_marking_all="Markiere alle als gelesen ..."
            mail_open="Öffnen"
            mail_report_spam="Spam melden"
            mail_reporting_spam="Melde Spam ..."
            menu_about="Ü_ber"
            menu_check="_Mail abfragen"
            menu_compose="Neue Nachricht"
            menu_prefs="_Einstellungen"
            menu_undo="_Rückgängig machen"
            notify_and="und"
            notify_check="Frage Google-Mail ab ..."
            notify_from="Von:"
            notify_login="Anmelden bei Google-Mail ..."
            notify_multiple1="Sie haben "
            notify_multiple2=" neue Nachrichten ..."
            notify_new_mail="Neue Nachricht von "
            notify_no_mail="Keine neuen Nachrichten"
            notify_no_subject="(kein Betreff)"
            notify_no_text="(kein Text)"
            notify_single1="Sie haben "
            notify_single2=" neue Nachricht ..."
            notify_undoing="Mache letzte Aktion rückgängig ..."
            prefs="CheckGmail Einstellungen"
            prefs_check="Nachrichtenabfrage"
            prefs_check_24_hour="24 Stunden-Uhr"
            prefs_check_archive="Beim Archivieren als gelesen markieren"
            prefs_check_atom="Feed Adresse:"
            prefs_check_delay="Frage Nachrichten alle "
            prefs_check_delay2=" Sekunden ab"
            prefs_check_labels="Auch die folgenden Labels abfragen:"
            prefs_check_labels_add="Label hinzufügen"
            prefs_check_labels_delay="Frage ab alle (Sekunden)"
            prefs_check_labels_label="Label"
            prefs_check_labels_new="[neues Label]"
            prefs_check_labels_remove="Label entfernen"
            prefs_external="Externe Programme"
            prefs_external_browser="Web-Browser"
            prefs_external_browser2="(Für %u wird die Webadresse (URL) eingesetzt)"
            prefs_external_mail_command="Ausführen wenn neue Nachricht:"
            prefs_external_nomail_command="Ausführen wenn keine neuen Nachrichten:"
            prefs_lang="Sprache"
            prefs_login="Login-Einstellungen"
            prefs_login_pass="_Passwort"
            prefs_login_save="Passwort speichern"
            prefs_login_save_kwallet="in der KDE-Wallet"
            prefs_login_save_plain="unverschlüsselt"
            prefs_login_user="_Login"
            prefs_tray="Systemabschnitt der Kontrollleiste"
            prefs_tray_bg="Hintergrundfarbe ..."
            prefs_tray_error_icon="Benutze eigenes Icon für Fehler"
            prefs_tray_mail_icon="Benutze eigenes Icon für Mail"
            prefs_tray_no_mail_icon="Benutze eigenes Icon für keine Mail"
            prefs_tray_pdelay="Zeige Popupfenster für neue Mail für "
            prefs_tray_pdelay2=" Sekunden" />
  <Language name="English"
            login_err="Error: Incorrect username or password"
            login_title="Login to Gmail ..."
            mail_archive="Archive"
            mail_archiving="Archiving ..."
            mail_delete="Delete"
            mail_deleting="Deleting ..."
            mail_mark="Mark as read"
            mail_mark_all="Mark all as read"
            mail_marking="Marking read ..."
            mail_marking_all="Marking all read ..."
            mail_open="Open"
            mail_report_spam="Report spam"
            mail_reporting_spam="Reporting spam ..."
            menu_about="_About"
            menu_check="_Check mail"
            menu_compose="Compose mail"
            menu_prefs="_Preferences"
            menu_undo="_Undo last action"
			menu_restart="Restart ..."
            notify_and="and"
            notify_check="Checking Gmail ..."
            notify_from="From:"
            notify_login="Logging in to Gmail ..."
            notify_multiple1="There are "
            notify_multiple2=" new messages ..."
            notify_new_mail="New mail from "
            notify_no_mail="No new mail"
            notify_no_subject="(no subject)"
            notify_no_text="(no text)"
            notify_single1="There is "
            notify_single2=" new message ..."
            notify_undoing="Undoing last action ..."
            prefs="CheckGmail preferences"
            prefs_check="Mail checking"
            prefs_check_24_hour="24 hour clock"
            prefs_check_archive="Archive also marks as read"
            prefs_check_atom="Feed address"
            prefs_check_delay="Check Inbox for mail every "
            prefs_check_delay2=" secs"
            prefs_check_labels="Also check the following labels:"
            prefs_check_labels_add="Add label"
            prefs_check_labels_delay="Check every (secs)"
            prefs_check_labels_label="Label"
            prefs_check_labels_new="[new label]"
            prefs_check_labels_remove="Remove label"
            prefs_external="External Commands"
            prefs_external_browser="Command to execute on clicking the tray icon"
            prefs_external_browser2="(use %u to represent the Gmail web address)"
            prefs_external_mail_command="Command to execute on new mail:"
            prefs_external_nomail_command="Command to execute for no mail:"
            prefs_lang="Language"
            prefs_login="Login details"
            prefs_login_pass="_Password"
            prefs_login_save="Save password"
            prefs_login_save_kwallet="in KDE wallet"
            prefs_login_save_plain="as plain text"
            prefs_login_user="_Username"
            prefs_tray="System tray"
            prefs_tray_bg="Set tray background ..."
            prefs_tray_error_icon="Use custom error icon"
            prefs_tray_mail_icon="Use custom mail icon"
            prefs_tray_no_mail_icon="Use custom no mail icon"
            prefs_tray_pdelay="Show new mail popup for "
            prefs_tray_pdelay2=" secs" />
  <Language name="Español"
            login_err="Error: Nombre de usuario o contraseña incorreta"
            login_title="Autentificando en Gmail ..."
            mail_archive="Archivar"
            mail_archiving="Archivando ..."
            mail_delete="Borrar"
            mail_deleting="Borrando ..."
            mail_mark="Marcar como leído"
            mail_mark_all="Marcar todos como leído"
            mail_marking="Marcando como leído ..."
            mail_marking_all="Marcando todos com leído ..."
            mail_open="Abrir"
            mail_report_spam="Marcar como spam"
            mail_reporting_spam="Marcando como spam ..."
            menu_about="_Acerca de Checkgmail"
            menu_check="_Revisar correo"
            menu_compose="Compose mail"
            menu_prefs="_Configurar"
            menu_undo="_Deshacer última acción"
            notify_and="y"
            notify_check="Conectactando Gmail ..."
            notify_from="De:"
            notify_login="Autentificando en Gmail ..."
            notify_multiple1="Hay "
            notify_multiple2=" nuevos mensajes ..."
            notify_new_mail="Nuevo correo de "
            notify_no_mail="No hay nuevos mensajes"
            notify_no_subject="(sin asunto)"
            notify_no_text="(sin texto)"
            notify_single1="Hay "
            notify_single2=" nuevo mensaje ..."
            notify_undoing="Deshacer la última acción ..."
            prefs="Configuración de CheckGmail"
            prefs_check="Verificación de correo"
            prefs_check_24_hour="reloj de 24 horas"
            prefs_check_archive="Archivar también marca como leído"
            prefs_check_atom="Dirección del alimentador (feed)"
            prefs_check_delay="Revisar la bandeja de entrada cada "
            prefs_check_delay2=" segs"
            prefs_check_labels="También verificar las siguientes etiquetas:"
            prefs_check_labels_add="Agregar etiqueta"
            prefs_check_labels_delay="Verificar cada (segs)"
            prefs_check_labels_label="Etiqueta"
            prefs_check_labels_new="[nueva etiqueta]"
            prefs_check_labels_remove="Eliminar etiqueta"
            prefs_external="Comandos Externos"
            prefs_external_browser="Navegador"
            prefs_external_browser2="(%u representa la dirección web de Gmail)"
            prefs_external_mail_command="Comando a ejecutar para nuevos mensajes:"
            prefs_external_nomail_command="Comando a ejecutar si no hay nuevos mensajes:"
            prefs_lang="Lenguaje"
            prefs_login="Detalles de Autentificación"
            prefs_login_pass="_Contraseña"
            prefs_login_save="Guardar contraseña"
            prefs_login_save_kwallet="en KDE wallet"
            prefs_login_save_plain="como texto plano"
            prefs_login_user="_Nombre de usuario"
            prefs_tray="Área de notificaciones"
            prefs_tray_bg="Seleccionar color de fondo ..."
            prefs_tray_error_icon="Personalizar ícono de error"
            prefs_tray_mail_icon="Personalizar ícono de nuevos mensajes"
            prefs_tray_no_mail_icon="Personalizar ícono de no mensajes"
            prefs_tray_pdelay="Mostrar la ventana emergente para nuevos mensajes por "
            prefs_tray_pdelay2=" segs" />
  <Language name="Français"
            login_err="Erreur: Nom d'utilisateur ou mot de passe incorrect"
            login_title="Connexion à Gmail..."
            mail_archive="Archiver"
            mail_archiving="Archivage..."
            mail_delete="Supprimer"
            mail_deleting="Suppression..."
            mail_mark="Marquer comme lu"
            mail_mark_all="Tout marquer comme lu"
            mail_marking="Marquage comme lu..."
            mail_marking_all="Marquage comme lu..."
            mail_open="Ouvrir"
            mail_report_spam="Signaler comme spam"
            mail_reporting_spam="Signalisation comme spam..."
            menu_about="_À propos"
            menu_check="_Vérifier les messages"
            menu_compose="Nouveau message"
            menu_prefs="_Préférences"
            menu_undo="_Annuler la dernière action"
            notify_and="et"
            notify_check="Vérification Gmail..."
            notify_from="De:"
            notify_login="Connexion à Gmail..."
            notify_multiple1="Il y a "
            notify_multiple2=" nouveaux messages..."
            notify_new_mail="Nouveau message de "
            notify_no_mail="Pas de nouveaux messages"
            notify_no_subject="(pas d'objet)"
            notify_no_text="(pas de texte)"
            notify_single1="Il y a "
            notify_single2=" nouveau message..."
            notify_undoing="Annulation de la dernière action..."
            prefs="Préférences de CheckGmail"
            prefs_check="Vérification des messages"
            prefs_check_24_hour="Format horaire 24h "
            prefs_check_archive="Archives marquées comme lues"
            prefs_check_atom="Adresse de flux"
            prefs_check_delay="Vérification toutes les "
            prefs_check_delay2=" secs"
            prefs_check_labels="Also check the following labels:"
            prefs_check_labels_add="Add label"
            prefs_check_labels_delay="Check every (secs)"
            prefs_check_labels_label="Label"
            prefs_check_labels_new="[new label]"
            prefs_check_labels_remove="Remove label"
            prefs_external="Commandes externes"
            prefs_external_browser="Navigateur Web"
            prefs_external_browser2="(utiliser %u pour réprésenter l'adresse web de Gmail)"
            prefs_external_mail_command="Commande à exécuter en cas de nouveaux messages:"
            prefs_external_nomail_command="Commande à exécuter si il n'y a pas de messages:"
            prefs_lang="Langues"
            prefs_login="Informations utilisateur"
            prefs_login_pass="_Mot de passe"
            prefs_login_save="Sauver le mot de passe"
            prefs_login_save_kwallet="dans le portefeuille KDE"
            prefs_login_save_plain="en clair"
            prefs_login_user="_Nom d'utilisateur"
            prefs_tray="Zone de notification"
            prefs_tray_bg="Couleur de fond..."
            prefs_tray_error_icon="Icône d'erreur personnalisée"
            prefs_tray_mail_icon="Icône de mail personnalisée"
            prefs_tray_no_mail_icon="Icône d'absence de mail personnalisée"
            prefs_tray_pdelay="Afficher un popup de notification durant "
            prefs_tray_pdelay2=" secs" />
  <Language name="Hrvatski"
            login_err="Greška: neispravan korisnik ili lozinka"
            login_title="Prijava na Gmail ..."
            mail_archive="Arhiv"
            mail_archiving="Arhiviranje ..."
            mail_delete="Obriši"
            mail_deleting="Brisanje ..."
            mail_mark="Označi kao pročitano"
            mail_mark_all="Označi sve kao pročitano"
            mail_marking="Označavanje pročitanog ..."
            mail_marking_all="Označavanje svega kao pročitanog ..."
            mail_open="Otvori"
            mail_report_spam="Prijavi spam"
            mail_reporting_spam="Prijava spama ..."
            menu_about="_O programu"
            menu_check="_Provjeri mail"
            menu_compose="Napiši poruku"
            menu_prefs="_Postavke"
            menu_undo="_Poništi zadnju akciju"
            notify_and="i"
            notify_check="Provjera Gmaila ..."
            notify_from="Od:"
            notify_login="Prijava na Gmail ..."
            notify_multiple1="Broj novih poruka: "
            notify_multiple2=" ..."
            notify_new_mail="Nova poruka: šalje "
            notify_no_mail="Nema novih poruka"
            notify_no_subject="(nema predmeta)"
            notify_no_text="(nema teksta)"
            notify_single1="Broj novih poruka: "
            notify_single2=" "
            notify_undoing="Poništavanje zadnje akcije ..."
            prefs="Postavke CheckGmaila"
            prefs_check="Provjera maila"
            prefs_check_24_hour="24-satni oblik"
            prefs_check_archive="Označi arhiv pročitanim"
            prefs_check_atom="Adresa feeda"
            prefs_check_delay="Provjeri dolaznu poštu svakih "
            prefs_check_delay2=" sekundi"
            prefs_check_labels="Provjeri i ove etikete:"
            prefs_check_labels_add="Dodaj etiketu"
            prefs_check_labels_delay="Provjeri svake (sekunde)"
            prefs_check_labels_label="Etiketa"
            prefs_check_labels_new="[nova etiketa]"
            prefs_check_labels_remove="Makni etiketu"
            prefs_external="Vanjske naredbe"
            prefs_external_browser="Web preglednik"
            prefs_external_browser2="(upotrijebi %u za prikaz web adrese Gmaila)"
            prefs_external_mail_command="Naredba za izvršenje ako ima novih poruka:"
            prefs_external_nomail_command="Naredba za izvršenje ako nema novih poruka:"
            prefs_lang="Jezik"
            prefs_login="Podaci za prijavu"
            prefs_login_pass="_Lozinka"
            prefs_login_save="Spremi lozinku"
            prefs_login_save_kwallet="u KDE wallet"
            prefs_login_save_plain="kao običan tekst"
            prefs_login_user="_Korisnik"
            prefs_tray="Sistemska traka"
            prefs_tray_bg="Postavi pozadinu sistemske trake ..."
            prefs_tray_error_icon="Odaberi vlastitu ikonu za pogrešku"
            prefs_tray_mail_icon="Odaberi vlastitu ikonu za novu poruku"
            prefs_tray_no_mail_icon="Odaberi vlastitu ikonu kada nema poruka"
            prefs_tray_pdelay="Prikaz prozora za novi mail: "
            prefs_tray_pdelay2=" sekundi" />
  <Language name="Italiano"
            login_err="Errore: Utente o password errato"
            login_title="Login a Gmail ..."
            mail_archive="Archivia"
            mail_archiving="Archiviazione ..."
            mail_delete="Cancella"
            mail_deleting="Cancellazione ..."
            mail_mark="Segna come letta"
            mail_mark_all="Segna tutti come letti"
            mail_marking="Segnalazione come letta ..."
            mail_marking_all="Marcatura tutti come letti ..."
            mail_open="Apri"
            mail_report_spam="Segnala come spam"
            mail_reporting_spam="Segnalazione come spam ..."
            menu_about="_Info"
            menu_check="_Controlla le mail"
            menu_compose="Componi un messaggio"
            menu_prefs="_Preferenze"
            menu_undo="_Annulla l'ultima azione"
            notify_and="e"
            notify_check="Controllo di Gmail ..."
            notify_from="Da:"
            notify_login="Login a Gmail ..."
            notify_multiple1="Ci sono "
            notify_multiple2=" nuovi messaggi ..."
            notify_new_mail="Nuova mail da "
            notify_no_mail="Nessuna nuova mail"
            notify_no_subject="(nessun soggetto)"
            notify_no_text="(nessun testo)"
            notify_single1="Ci sono "
            notify_single2=" nuovi messaggi ..."
            notify_undoing="Undoing last action ..."
            prefs="Preferenze di CheckGmail"
            prefs_check="Controllo delle mail"
            prefs_check_24_hour="Orologio a 24 ore"
            prefs_check_archive="Archivia marca anche come letto"
            prefs_check_atom="Indirizzo dei feed"
            prefs_check_delay="Controlla la Inbox per tutte le mail "
            prefs_check_delay2=" secondi"
            prefs_check_labels="Controlla anche le seguenti etichette:"
            prefs_check_labels_add="Aggiungi etichetta"
            prefs_check_labels_delay="Controlla ogni (sec)"
            prefs_check_labels_label="Etichetta"
            prefs_check_labels_new="[nuova etichetta]"
            prefs_check_labels_remove="Rimuovi etichetta"
            prefs_external="Comandi esterni"
            prefs_external_browser="Comando da eseguire clickando sulla icona tray"
            prefs_external_browser2="(usa %u per rappresentare l'indirizzo web di Gmail)"
            prefs_external_mail_command="Comando da seguire per le nuove mail:"
            prefs_external_nomail_command="Comando da eseguire quando non ci sono mail:"
            prefs_lang="Linguaggio"
            prefs_login="Dettagli di login"
            prefs_login_pass="_Password"
            prefs_login_save="Salva la password"
            prefs_login_save_kwallet="nel wallet KDE"
            prefs_login_save_plain="come testo in chiaro"
            prefs_login_user="_Username"
            prefs_tray="System tray"
            prefs_tray_bg="Imposta lo sfondo della tray ..."
            prefs_tray_error_icon="Utilizza un icona custom per gli errori"
            prefs_tray_mail_icon="Utilizza un icona custom per le mail"
            prefs_tray_no_mail_icon="Utilizza un icona custom per nessuna mail"
            prefs_tray_pdelay="Mostra il popup di nuove mail per "
            prefs_tray_pdelay2=" secondi" />
  <Language name="Magyar"
            login_err="HIBA!: Helytelen felhasználónév, vagy jelszó"
            login_title="Bejelentkezés a Gmail-be ..."
            mail_archive="Archívum"
            mail_archiving="Archiválás ..."
            mail_delete="Törlés"
            mail_deleting="Törlés ..."
            mail_mark="Jelöld olvasottnak"
            mail_mark_all="Jelöld mindet olvasottnak"
            mail_marking="Olvasottnak jelölés ..."
            mail_marking_all="Mindet olvasottnak jelölés ..."
            mail_open="Megnyitás"
            mail_report_spam="Ez spam"
            mail_reporting_spam="Spam bejelentése ..."
            menu_about="_Névjegy"
            menu_check="_Levelek ellenőrzése"
            menu_compose="Levélírás"
            menu_prefs="_Beállítások"
            menu_undo="_Visszavonás"
            notify_and="és"
            notify_check="Gmail ellenőrzése ..."
            notify_from="Küldő:"
            notify_login="Bejelentkezés a Gmail-be ..."
            notify_multiple1="Önnek "
            notify_multiple2=" új levele érkezett ..."
            notify_new_mail="Új levél. Küldő: "
            notify_no_mail="Nincs új levél"
            notify_no_subject="(nincs cím)"
            notify_no_text="(nincs szöveg)"
            notify_single1="Önnek "
            notify_single2=" új levele érkezett ..."
            notify_undoing="Utolsó művelet visszavonása ..."
            prefs="CheckGmail beállításai"
            prefs_check="Levelek ellenőrzése"
            prefs_check_24_hour="24 órás formátum"
            prefs_check_archive="Archiválás olvasottként is jelöl"
            prefs_check_atom="Feed cím"
            prefs_check_delay="Postaláda ellenőrzése minden "
            prefs_check_delay2=" másodpercben"
            prefs_check_labels="Az alábbi címkék ellenőrzése:"
            prefs_check_labels_add="Címke hozzáadása"
            prefs_check_labels_delay="Ellenőrzés gyakorisága (s)"
            prefs_check_labels_label="Címke"
            prefs_check_labels_new="[Új címke]"
            prefs_check_labels_remove="Címke eltávolítása"
            prefs_external="Külső parancsok"
            prefs_external_browser="Parancs végrehajtása a tálcán lévő ikonra való kattintáskor"
            prefs_external_browser2="(%u a Gmail-t jelenti )"
            prefs_external_mail_command="Parancs végrehajtása új levél esetén:"
            prefs_external_nomail_command="Parancs végrehajtása, ha nincs új levél:"
            prefs_lang="Nyelv"
            prefs_login="Bejelentkezési adatok"
            prefs_login_pass="_Jelszó"
            prefs_login_save="Jelszó mentése"
            prefs_login_save_kwallet="KDE wallet-be"
            prefs_login_save_plain="sima szövegként - nincs titkosítás"
            prefs_login_user="_Felhasználónév"
            prefs_tray="Tálca"
            prefs_tray_bg="Tálca háttérszínének beállítása ..."
            prefs_tray_error_icon="Saját hiba ikon"
            prefs_tray_mail_icon="Saját új levél ikon"
            prefs_tray_no_mail_icon="Saját nincs új levél ikon"
            prefs_tray_pdelay="Felugró ablak mutatása új levél esetén "
            prefs_tray_pdelay2=" másodpercig" />
  <Language name="Nederlands"
            login_err="Fout: Onjuiste gebruikersnaam of wachtwoord"
            login_title="inloggen in Gmail ..."
            mail_archive="Archief"
            mail_archiving="Archieveren ..."
            mail_delete="Verwijder"
            mail_deleting="Verwijderen ..."
            mail_mark="Markeren als gelezen"
            mail_mark_all="Markeer alles als gelezen"
            mail_marking="Markeer gelezen ..."
            mail_marking_all="Alles als gelezen markeren ..."
            mail_open="Openen"
            mail_report_spam="Aanmelden spam"
            mail_reporting_spam="Aanmelden als spam ..."
            menu_about="_Info"
            menu_check="_Controleer Post"
            menu_compose="Een nieuw e-mail opstellen"
            menu_prefs="_Voorkeuren"
            menu_undo="_Ongedaan maken laatste bewerking"
            notify_and="en"
            notify_check="Controle Gmail ..."
            notify_from="Van:"
            notify_login="Aanmelden Gmail account"
            notify_multiple1="Er zijn "
            notify_multiple2=" nieuwe berichten ..."
            notify_new_mail="Nieuw bericht van "
            notify_no_mail="Geen nieuwe berichten"
            notify_no_subject="(geen onderwerp)"
            notify_no_text="(geen tekst)"
            notify_single1="Er zijn "
            notify_single2=" nieuwe berichten ..."
            notify_undoing="Ongedaan maken ..."
            prefs="CheckGmail instellingen"
            prefs_check="Controle Post"
            prefs_check_24_hour="24 klok type"
            prefs_check_archive="Archief ook als gelezen markeren"
            prefs_check_atom="Feed adres"
            prefs_check_delay="Controleer postvak elke "
            prefs_check_delay2=" seconden"
            prefs_check_labels="Controleer de volgende accounts:"
            prefs_check_labels_add="Toevoegen account"
            prefs_check_labels_delay="Controleer elke (secs)"
            prefs_check_labels_label="Account"
            prefs_check_labels_new="[nieuw account]"
            prefs_check_labels_remove="Verwijder account"
            prefs_external="Externe Commando's"
            prefs_external_browser="Commando uitvoeren na klikken op tray icoon"
            prefs_external_browser2="gebruik %u om het Gmail web adres te vertegenwoordigen"
            prefs_external_mail_command="Commando uitvoeren bij nieuwe berichten:"
            prefs_external_nomail_command="Commando uitvoeren bij geen berichten:"
            prefs_lang="Taal"
            prefs_login="Account informatie"
            prefs_login_pass="_Wachtwoord"
            prefs_login_save="Wegschrijven wachtwoord"
            prefs_login_save_kwallet="in KDE portefeuille"
            prefs_login_save_plain="als normale tekst"
            prefs_login_user="_Gebruikersnaam"
            prefs_tray="Mededelingengebied"
            prefs_tray_bg="Instelling mededelingengebied achtergrond ..."
            prefs_tray_error_icon="Gebruik voorkeurs fout icoon"
            prefs_tray_mail_icon="Gebruik standaard bericht icoon"
            prefs_tray_no_mail_icon="Gebruik standaard geen bericht icoon"
            prefs_tray_pdelay="Laat nieuwe berichten popup zien voor "
            prefs_tray_pdelay2=" seconden" />
  <Language name="Norsk"
            login_err="Feil:: Feil brukernavn eller passord"
            login_title="Gmail login"
            mail_archive="Arkivér"
            mail_archiving="Arkiverer ..."
            mail_delete="Slett"
            mail_deleting="Sletter ..."
            mail_mark="Marker lest"
            mail_mark_all="Marker alle som lest"
            mail_marking="Markerer lest ..."
            mail_marking_all="Markerer alle lest ..."
            mail_open="Åpne"
            mail_report_spam="Rapporter spam"
            mail_reporting_spam="Rapporterer spam ..."
            menu_about="_Om Checkgmail"
            menu_check="_Se etter ny e-post på Gmail"
            menu_compose="Skriv e-post"
            menu_prefs="_Instillinger"
            menu_undo="_angre sidste handling ..."
            notify_and="og"
            notify_check="Ser etter ny e-post på Gmail ..."
            notify_from="Fra:"
            notify_login="Logger inn på Gmail ..."
            notify_multiple1="Det er "
            notify_multiple2=" ny e-post ..."
            notify_new_mail="Ny e-post fra "
            notify_no_mail="Ingen ny e-post"
            notify_no_subject="(intet emne)"
            notify_no_text="(ingen tekst)"
            notify_single1="Det er "
            notify_single2=" ny e-post ..."
            notify_undoing="Avbryt siste handling ..."
            prefs="CheckGmail innstillinger"
            prefs_check="Se etter ny e-post"
            prefs_check_24_hour="24 timers ur"
            prefs_check_archive="Arkivér markerer også lest"
            prefs_check_atom="Feed adresse"
            prefs_check_delay="Se etter ny e-post hver "
            prefs_check_delay2=" sekunder"
            prefs_check_labels="Sjekk også følgende merker:"
            prefs_check_labels_add="Legg til merke"
            prefs_check_labels_delay="Sjekk hvert (sekn)"
            prefs_check_labels_label="Merke"
            prefs_check_labels_new="[Nytt merke]"
            prefs_check_labels_remove="Fjern merke"
            prefs_external="Eksterne programmer"
            prefs_external_browser="Nettleser"
            prefs_external_browser2="(%u representerer Gmail adressen)"
            prefs_external_mail_command="Kommando ved ny e-post:"
            prefs_external_nomail_command="Kommando ved ingen nye e-poster:"
            prefs_lang="Språk"
            prefs_login="Logindetaljer"
            prefs_login_pass="_passord"
            prefs_login_save="Lagre passord"
            prefs_login_save_kwallet="i KDE tegnebok"
            prefs_login_save_plain="som tekst"
            prefs_login_user="_Brukernavn"
            prefs_tray="Statusfelt"
            prefs_tray_bg="Sett statusfelt bakgrund ..."
            prefs_tray_error_icon="Bruk selvvalgt 'feil' ikon"
            prefs_tray_mail_icon="Bruk selvvalgt 'ny e-post' ikon"
            prefs_tray_no_mail_icon="Brug selvvalgt 'ingen e-post' ikon"
            prefs_tray_pdelay="Vis ny e-post popup i "
            prefs_tray_pdelay2=" sekunder" />
  <Language name="Polski"
            login_err="Błąd: Zły login lub hasło"
            login_title="Logowanie do Gmail ..."
            mail_archive="Archiwizuj"
            mail_archiving="Archiwizuje ..."
            mail_delete="Usuń"
            mail_deleting="Usuwam ..."
            mail_mark="Zaznacz jako przeczytane"
            mail_mark_all="Zaznacz wszystko jako przeczytane"
            mail_marking="Zaznaczam jako przeczytane ..."
            mail_marking_all="Zaznaczam wszystko jako przeczytane ..."
            mail_open="Otwórz"
            mail_report_spam="Raportuj spam"
            mail_reporting_spam="Raportuje spam ..."
            menu_about="_O programie"
            menu_check="_Sprawdź pocztę"
            menu_compose="Napisz list"
            menu_prefs="_Preferencje"
            menu_undo="_Cofnij ostatnią operacje"
            notify_and="i"
            notify_check="Sprawdzam Gmail ..."
            notify_from="Od:"
            notify_login="Logowanie do Gmail ..."
            notify_multiple1="Są "
            notify_multiple2=" nowe wiadomości ..."
            notify_new_mail="Nowa poczta od "
            notify_no_mail="Brak nowych wiadomości"
            notify_no_subject="(brak tematu)"
            notify_no_text="(brak treści)"
            notify_single1="Jest "
            notify_single2=" nowa wiadomość ..."
            notify_undoing="Cofam ostatnią operację ..."
            prefs="CheckGmail - preferencje"
            prefs_check="Sprawdzanie poczty"
            prefs_check_24_hour="zegar 24-o godzinny"
            prefs_check_archive="Archiwizując oznacz również jako przeczytane"
            prefs_check_atom="Adres "
            prefs_check_delay="Sprawdzaj pocztę co "
            prefs_check_delay2=" sekund"
            prefs_check_labels="Sprawdź też etykiety:"
            prefs_check_labels_add="Dodaj etykietę"
            prefs_check_labels_delay="Sprawdź co: (sekund)"
            prefs_check_labels_label="Etykieta"
            prefs_check_labels_new="[nowa etykieta]"
            prefs_check_labels_remove="Usuń etykietę"
            prefs_external="Zewnętrzne polecenia"
            prefs_external_browser="Polecenie do wykonania po kliknięciu w ikonkę"
            prefs_external_browser2="(w miejscu %u zostanie wstawiony adres Gmail)"
            prefs_external_mail_command="Polecenie do wykonania gdy przyjdzie nowa wiadomość:"
            prefs_external_nomail_command="Polecenie do wykonania gdy nie ma nowych wiadomości:"
            prefs_lang="Język"
            prefs_login="Informacje o koncie"
            prefs_login_pass="_Hasło"
            prefs_login_save="Zapisz hasło"
            prefs_login_save_kwallet="w portfelu KDE"
            prefs_login_save_plain="jako zwykły text"
            prefs_login_user="_Użytkownik"
            prefs_tray="Ikonka"
            prefs_tray_bg="Tło pod ikoną ..."
            prefs_tray_error_icon="Własna ikona błędu"
            prefs_tray_mail_icon="Własna ikona informująca o poczcie"
            prefs_tray_no_mail_icon="Własna ikona informująca o braku poczty"
            prefs_tray_pdelay="Pokazuj popup przez "
            prefs_tray_pdelay2=" sekund" />
  <Language name="Português"
            login_err="Erro: Nome de utilizador e palavra passe incorrecta"
            login_title="A autenticar no Gmail..."
            mail_archive="Arquivar"
            mail_archiving="A arquivar..."
            mail_delete="Apagar"
            mail_deleting="A apagar ..."
            mail_mark="Marcar como lido"
            mail_mark_all="Marcar todas como lidas"
            mail_marking="A marcar como lida ..."
            mail_marking_all="A marcar todas como lidas..."
            mail_open="Abrir"
            mail_report_spam="Reportar spam"
            mail_reporting_spam="A reportar spam ..."
            menu_about="_Sobre"
            menu_check="_Verificar mensagens"
            menu_compose="Criar nova mensagem"
            menu_prefs="_Preferências"
            menu_undo="_Desfazer última acção"
            notify_and="e"
            notify_check="A verificar Gmail ..."
            notify_from="De:"
            notify_login="A autenticar no Gmail ..."
            notify_multiple1="Existem "
            notify_multiple2=" mensagens novas..."
            notify_new_mail="Nova mensagem de "
            notify_no_mail="Nenhuma mensagem nova"
            notify_no_subject="(sem assunto)"
            notify_no_text="(sem texto)"
            notify_single1="Existe "
            notify_single2=" mensagem nova ..."
            notify_undoing="A desfazer ultíma acção ..."
            prefs="Preferências do CheckGmail"
            prefs_check="Verificação do Correio"
            prefs_check_24_hour="24"
            prefs_check_archive="Arquivo também marca como lido"
            prefs_check_atom="Endereço feed"
            prefs_check_delay="Verificar Caixa de Entrada por mensagens a cada "
            prefs_check_delay2=" segs"
            prefs_check_labels="Verificar também as seguintes etiquetas:"
            prefs_check_labels_add="Adicionar etiqueta"
            prefs_check_labels_delay="Verificar a cada (segs)"
            prefs_check_labels_label="Etiqueta"
            prefs_check_labels_new="[nova etiqueta]"
            prefs_check_labels_remove="Remover etiqueta"
            prefs_external="Comandos Externos"
            prefs_external_browser="Comando a executar ao clicar no ícone"
            prefs_external_browser2="(use %u para representar o endereço web do Gmail)"
            prefs_external_mail_command="Comando a executar com novas mensagens:"
            prefs_external_nomail_command="Comando a executar quando não houver mensagens:"
            prefs_lang="Ídioma"
            prefs_login="Dados da conta"
            prefs_login_pass="_Senha"
            prefs_login_save="Guardar senha"
            prefs_login_save_kwallet="na carteira do KDE"
            prefs_login_save_plain="como texto"
            prefs_login_user="_Nome do utilizador"
            prefs_tray="Área de notificação"
            prefs_tray_bg="Definir côr de fundo ..."
            prefs_tray_error_icon="Personalizar ícone de erro"
            prefs_tray_mail_icon="Personalizar ícone de mensagem recebida"
            prefs_tray_no_mail_icon="Personalizar ícone de nenhuma mensagem"
            prefs_tray_pdelay="Mostrar popup de nova mensagem durante "
            prefs_tray_pdelay2=" segs" />
  <Language name="Português (Brasil)"
            login_err="Erro: Nome de usuário e senha incorreta"
            login_title="Autenticando no Gmail..."
            mail_archive="Arquivar"
            mail_archiving="Arquivando..."
            mail_delete="Apagar"
            mail_deleting="Apagando ..."
            mail_mark="Marcar como lido"
            mail_mark_all="Marcar todas como lidas"
            mail_marking="Marcando como lida ..."
            mail_marking_all="Marcando todas como lidas..."
            mail_open="Abrir"
            mail_report_spam="Reportar spam"
            mail_reporting_spam="Reportando spam ..."
            menu_about="_Sobre"
            menu_check="_Verificar mensagens"
            menu_compose="Criar nova mensagem"
            menu_prefs="_Preferências"
            menu_undo="_Desfazer última ação"
            notify_and="e"
            notify_check="Verificando Gmail ..."
            notify_from="De:"
            notify_login="Autenticando no Gmail ..."
            notify_multiple1="Existem "
            notify_multiple2=" mensagens novas..."
            notify_new_mail="Nova mensagem de "
            notify_no_mail="Nenhuma mensagem nova"
            notify_no_subject="(sem assunto)"
            notify_no_text="(sem texto)"
            notify_single1="Existe "
            notify_single2=" mensagem nova ..."
            notify_undoing="Desfazendo-se da última ação ..."
            prefs="Preferências do CheckGmail"
            prefs_check="Verificação do Correio"
            prefs_check_24_hour="Utilizar padrão de relógio 24h"
            prefs_check_archive="Quando arquivar, também marcar como lido"
            prefs_check_atom="Endereço feed"
            prefs_check_delay="Verificar por novas mensagens a cada "
            prefs_check_delay2=" segs"
            prefs_check_labels="Selecione também as seguintes etiquetas:"
            prefs_check_labels_add="Nova etiqueta"
            prefs_check_labels_delay="Verificar a cada (segs)"
            prefs_check_labels_label="Etiqueta"
            prefs_check_labels_new="[nova etiqueta]"
            prefs_check_labels_remove="Remover etiqueta"
            prefs_external="Comandos Externos"
            prefs_external_browser="Comando a executar ao clicar no ícone"
            prefs_external_browser2="(use %u para representar o endereço web do Gmail)"
            prefs_external_mail_command="Comando a executar com novas mensagens:"
            prefs_external_nomail_command="Comando a executar quando não houver mensagens:"
            prefs_lang="Idioma"
            prefs_login="Dados da conta"
            prefs_login_pass="_Senha"
            prefs_login_save="Salvar senha"
            prefs_login_save_kwallet="na carteira do KDE"
            prefs_login_save_plain="como texto"
            prefs_login_user="_Nome do usuário"
            prefs_tray="Área de notificação"
            prefs_tray_bg="Definir côr de fundo ..."
            prefs_tray_error_icon="Personalizar ícone de erro"
            prefs_tray_mail_icon="Personalizar ícone de mensagem recebida"
            prefs_tray_no_mail_icon="Personalizar ícone de nenhuma mensagem"
            prefs_tray_pdelay="Mostrar popup de nova mensagem durante "
            prefs_tray_pdelay2=" segs" />
  <Language name="Romană"
            login_err="Eroare: Utilizator sau parolă incorecte"
            login_title="Autentificare la Gmail ..."
            mail_archive="Arhivă"
            mail_archiving="Arhivez ..."
            mail_delete="Şterge"
            mail_deleting="Şterg ..."
            mail_mark="Marcaţi ca citită"
            mail_mark_all="Marcheaza toate ca citite"
            mail_marking="Marchez ca citită ..."
            mail_marking_all="Marchez toate ca citite ..."
            mail_open="Deschide"
            mail_report_spam="Raportează ca spam"
            mail_reporting_spam="Raportez ca spam ..."
            menu_about="_Despre"
            menu_check="_Verificare mail"
            menu_compose="Compune mail nou"
            menu_prefs="_Preferinţe"
            menu_undo="_Anulează ultima acţiune"
            notify_and="şi"
            notify_check="Verific Gmail ..."
            notify_from="De la:"
            notify_login="Autentificare la Gmail ..."
            notify_multiple1="Sunt disponibile "
            notify_multiple2=" mesaje noi ..."
            notify_new_mail="Mail nou de la "
            notify_no_mail="Nici un mail nou"
            notify_no_subject="(fară subiect)"
            notify_no_text="(fară text)"
            notify_single1="Este disponibil "
            notify_single2=" mesaj nou ..."
            notify_undoing="Anulez ultima acţiune ..."
            prefs="Preferinţe CheckGmail"
            prefs_check="Verific mailul"
            prefs_check_24_hour="Afişare ceas în format 24 ore"
            prefs_check_archive="Marchează şi Arhiva ca citită"
            prefs_check_atom="Adresă feed "
            prefs_check_delay="Verifică Căsuţa Poştală la fiecare "
            prefs_check_delay2=" secunde"
            prefs_check_labels="Deasemenea verifică şi următoarele etichete:"
            prefs_check_labels_add="Adaugă etichetă"
            prefs_check_labels_delay="Verifică la fiecare (secunde)"
            prefs_check_labels_label="Etichetă"
            prefs_check_labels_new="[etichetă nouă]"
            prefs_check_labels_remove="Şterge eticheta"
            prefs_external="Comenzi Externe"
            prefs_external_browser="Comandă de executat la apăsarea icon-ului:"
            prefs_external_browser2="(foloseşte %u pentru a reprezenta adresa web Gmail)"
            prefs_external_mail_command="Comandă de executat la mail nou:"
            prefs_external_nomail_command="Comandă de executat când nu este mail:"
            prefs_lang="Limba"
            prefs_login="Detalii autentificare"
            prefs_login_pass="_Parolă"
            prefs_login_save="Salvează parola"
            prefs_login_save_kwallet="în KDE wallet"
            prefs_login_save_plain="ca text simplu"
            prefs_login_user="_Utilizator"
            prefs_tray="Zona de notificare"
            prefs_tray_bg="Selectează fundal zonă de notificare ..."
            prefs_tray_error_icon="Foloseşte iconiţă de eroare diferită"
            prefs_tray_mail_icon="Foloseşte iconiţă de mail diferită"
            prefs_tray_no_mail_icon="Foloseşte iconiţă fară mail diferită"
            prefs_tray_pdelay="Arată fereastra de notificare mail nou pentru "
            prefs_tray_pdelay2=" secunde" />
  <Language name="Slovenčina"
            login_err="Chyba: Nesprávne prihlasovacie meno alebo heslo"
            login_title="Prihlasuje sa na Gmail ..."
            mail_archive="Archivovať"
            mail_archiving="Archivuje sa ..."
            mail_delete="Odstrániť"
            mail_deleting="Odstraňuje sa ..."
            mail_mark="Označiť ako prečítané"
            mail_mark_all="Označiť všetko ako prečítané"
            mail_marking="Označuje sa ako prečítané ..."
            mail_marking_all="Označuje sa všetko ako prečítané ..."
            mail_open="Otvoriť"
            mail_report_spam="Nahlásiť spam"
            mail_reporting_spam="Nahlasuje sa spam ..."
            menu_about="_O programe..."
            menu_check="_Skontrolovať poštu"
            menu_compose="Zostaviť správu"
            menu_prefs="_Nastavenia"
            menu_undo="_Odvolať poslednú operáciu"
            notify_and="a"
            notify_check="Kontroluje sa Gmail ..."
            notify_from="Od:"
            notify_login="Prihlasuje sa na Gmail ..."
            notify_multiple1="Máte nových správ: "
            notify_multiple2=" ..."
            notify_new_mail="Nová správa od: "
            notify_no_mail="Žiadna nová pošta"
            notify_no_subject="(bez predmetu)"
            notify_no_text="(bez textu)"
            notify_single1="Máte "
            notify_single2=" novú správu ..."
            notify_undoing="Odvoláva sa posledná operácia ..."
            prefs="Nastavenia CheckGmail"
            prefs_check="Kontrola pošty"
            prefs_check_24_hour="24-hodinový čas"
            prefs_check_archive="Archivovanie označí ako prečítané"
            prefs_check_atom="Adresa zdroja"
            prefs_check_delay="Kontrola schránky každých "
            prefs_check_delay2=" s"
            prefs_check_labels="Skontrolovať aj tieto zdroje:"
            prefs_check_labels_add="Pridať zdroj"
            prefs_check_labels_delay="Interval (v sekundách)"
            prefs_check_labels_label="Zdroj"
            prefs_check_labels_new="[nový zdroj]"
            prefs_check_labels_remove="Zmazať zdroj"
            prefs_external="Externé príkazy"
            prefs_external_browser="Príkazy pri kliknutí na ikonu v systémovej lište:"
            prefs_external_browser2="(použite %u namiesto web-adresy Gmail-u)"
            prefs_external_mail_command="Príkaz pri zistení novej pošty:"
            prefs_external_nomail_command="Príkaz pri žiadnej novej pošte:"
            prefs_lang="Jazyk"
            prefs_login="Podrobnosti prihlásenia"
            prefs_login_pass="_Heslo"
            prefs_login_save="Uložiť heslo"
            prefs_login_save_kwallet="do KDE wallet"
            prefs_login_save_plain="ako prostý text"
            prefs_login_user="_Meno"
            prefs_tray="Systémová lišta"
            prefs_tray_bg="Nastaviť pozadie lišty ..."
            prefs_tray_error_icon="Vlastnú ikonu - chyba"
            prefs_tray_mail_icon="Vlastnú ikonu - pošta"
            prefs_tray_no_mail_icon="Vlastnú ikonu - žiadna pošta"
            prefs_tray_pdelay="Zobraziť okno novej pošty počas "
            prefs_tray_pdelay2=" s" />
  <Language name="Slovenščina"
            login_err="Napaka: Napačno uporabniško ime ali geslo"
            login_title="Prijavi se v Gmail ..."
            mail_archive="Arhiviraj"
            mail_archiving="Arhiviram ..."
            mail_delete="Izbriši"
            mail_deleting="Brišem ..."
            mail_mark="Označi kot prebrano"
            mail_mark_all="Označi vse kot prebrano"
            mail_marking="Označujem kot prebrano ..."
            mail_marking_all="Označujem vse kot prebrano ..."
            mail_open="Odpri"
            mail_report_spam="Prijavi vslijeno pošto"
            mail_reporting_spam="Poročam vsiljeno pošto ..."
            menu_about="_O CheckGmail"
            menu_check="_Preglej pošto"
            menu_compose="Novo sporočilo"
            menu_prefs="_Nastavitve"
            menu_undo="_Razveljavi zadnjo akcijo"
            notify_and="in"
            notify_check="Pregledujem Gmail ..."
            notify_from="Od:"
            notify_login="Prijavljanje v Gmail ..."
            notify_multiple1="V predalu je "
            notify_multiple2=" sporočil ..."
            notify_new_mail="Nova pošta od "
            notify_no_mail="Ni nove pošte"
            notify_no_subject="(brez zadeve)"
            notify_no_text="(ni besedila)"
            notify_single1="V predalu je "
            notify_single2=" novo sporočilo ..."
            notify_undoing="Razveljavljam zadnjo akcijo ..."
            prefs="CheckGmail nastavitve"
            prefs_check="Preverjanje pošte"
            prefs_check_24_hour="24 urni čas"
            prefs_check_archive="Arhiviraj označi kot prebrano"
            prefs_check_atom="Naslov informacij"
            prefs_check_delay="Preveri pošto vsakih "
            prefs_check_delay2=" sekund"
            prefs_check_labels="Also check the following labels:"
            prefs_check_labels_add="Add label"
            prefs_check_labels_delay="Check every (secs)"
            prefs_check_labels_label="Label"
            prefs_check_labels_new="[new label]"
            prefs_check_labels_remove="Remove label"
            prefs_external="Znanji ukazi"
            prefs_external_browser="Ukaz, ki se bo izvršil ob kliku na ikono na pultu"
            prefs_external_browser2="(uporabi %u da predstaviš Gmail domačo stran)"
            prefs_external_mail_command="Ukaz za izvršitev ob novem sporočilu:"
            prefs_external_nomail_command="Ukaz, ki se izvrši če ni nobene pošte:"
            prefs_lang="Jezik"
            prefs_login="Podrobnosti prijave"
            prefs_login_pass="_Geslo"
            prefs_login_save="Shrani geslo"
            prefs_login_save_kwallet="v KDE denarnico"
            prefs_login_save_plain="kot navaden tekst"
            prefs_login_user="_Uporabniško ime"
            prefs_tray="Sistemski pult"
            prefs_tray_bg="Izberi odzadje pulta ..."
            prefs_tray_error_icon="Uporabi ikono po meri za napako"
            prefs_tray_mail_icon="Uporabi ikono po meri za sporočila"
            prefs_tray_no_mail_icon="Uporabi ikono po meri za brez sporočil"
            prefs_tray_pdelay="Ob novem sporočilu prikaži okno za "
            prefs_tray_pdelay2=" sek." />
  <Language name="Suomi"
            login_err="Virhe: Väärä käyttäjätunnus tai salasana"
            login_title="Kirjaudutaan Gmailiin ..."
            mail_archive="Arkistoi"
            mail_archiving="Arkistoidaan ..."
            mail_delete="Poista"
            mail_deleting="Poistetaan ..."
            mail_mark="Merkitse luetuksi"
            mail_mark_all="Merkitse kaikki luetuiksi"
            mail_marking="Merkitään luetuksi ..."
            mail_marking_all="Merkitään kaikki luetuiksi ..."
            mail_open="Avaa"
            mail_report_spam="Ilmoita roskapostista"
            mail_reporting_spam="Ilmoitetaan roskapostista ..."
            menu_about="_Tietoja"
            menu_check="_Tarkista posti"
            menu_compose="Luo uusi viesti"
            menu_prefs="_Asetukset"
            menu_undo="_Peru viime toiminto"
            notify_and="ja"
            notify_check="Tarkistetaan postia ..."
            notify_from="Lähettäjä:"
            notify_login="Kirjaudutaan Gmailiin ..."
            notify_multiple1="Sinulle on "
            notify_multiple2=" uutta viestiä ..."
            notify_new_mail="Uutta postia, lähettäjä "
            notify_no_mail="Ei uusia viestejä"
            notify_no_subject="(ei aihetta)"
            notify_no_text="(ei tekstiä)"
            notify_single1="Sinulle on "
            notify_single2=" uusi viesti ..."
            notify_undoing="Perutaan viime toimintoa ..."
            prefs="CheckGmail asetukset"
            prefs_check="Postin tarkistus"
            prefs_check_24_hour="24-tuntinen kello"
            prefs_check_archive="Arkistoiminen merkitsee luetuksi"
            prefs_check_atom="Syötteen osoite"
            prefs_check_delay="Tarkista posti "
            prefs_check_delay2=" sekunnin välein"
            prefs_check_labels="Also check the following labels:"
            prefs_check_labels_add="Add label"
            prefs_check_labels_delay="Check every (secs)"
            prefs_check_labels_label="Label"
            prefs_check_labels_new="[new label]"
            prefs_check_labels_remove="Remove label"
            prefs_external="Ulkoiset komennot"
            prefs_external_browser="Kun ilmoitusalueen kuvaketta painetaan, suorita komento:"
            prefs_external_browser2="(%u kuvastaa Gmailin web osoitetta)"
            prefs_external_mail_command="Kun uutta postia saapuu, suorita komento:"
            prefs_external_nomail_command="Kun uutta postia ei ole saapunut, suorita komento:"
            prefs_lang="Kieli"
            prefs_login="Kirjautumisasetukset"
            prefs_login_pass="_Salasana"
            prefs_login_save="Tallenna salasana"
            prefs_login_save_kwallet="KDE lompakkoon"
            prefs_login_save_plain="pelkkäteksti muodossa"
            prefs_login_user="_Käyttäjätunnus"
            prefs_tray="Ilmoitusalue"
            prefs_tray_bg="Aseta ilmoitusalueen tausta ..."
            prefs_tray_error_icon="Käytä omaa virhekuvaketta"
            prefs_tray_mail_icon="Käytä omaa uutta postia -kuvaketta"
            prefs_tray_no_mail_icon="Käytä omaa ei postia -kuvaketta"
            prefs_tray_pdelay="Näytä ilmoitus saapuneesta postista "
            prefs_tray_pdelay2=" sekuntia" />
  <Language name="Svenska"
            login_err="Fel: Felaktigt användarnamn eller lösenord"
            login_title="Gmail Login ..."
            mail_archive="Arkiv"
            mail_archiving="Arkiverar ..."
            mail_delete="Radera"
            mail_deleting="Raderar ..."
            mail_mark="Markera läst"
            mail_mark_all="Markera alla som lästa"
            mail_marking="Markerar läst ..."
            mail_marking_all="Markerar alla lästa ..."
            mail_open="Öppna"
            mail_report_spam="Rapportera skräppost"
            mail_reporting_spam="Rapporterar skräppost ..."
            menu_about="_Om"
            menu_check="_Kolla mail"
            menu_compose="Skriv ett mail"
            menu_prefs="_Inställningar"
            menu_undo="_Ångra senast handling"
            notify_and="och"
            notify_check="Kollar Gmail ..."
            notify_from="Från:"
            notify_login="Loggar in till Gmail ..."
            notify_multiple1="Det finns"
            notify_multiple2="nya meddelanden ..."
            notify_new_mail="Nytt mail från"
            notify_no_mail="Inga nya mail"
            notify_no_subject="(inget ämne)"
            notify_no_text="(ingen text)"
            notify_single1="Det finns"
            notify_single2="nytt meddelande ..."
            notify_undoing="Ångrar senaste handlingen ..."
            prefs="CheckGmail inställningar"
            prefs_check="Se efter nya mail"
            prefs_check_24_hour="24-timmars klocka"
            prefs_check_archive="Arkivering markerar också som läst"
            prefs_check_atom="Feed adress"
            prefs_check_delay="Kolla mail varje"
            prefs_check_delay2="sekund"
            prefs_check_labels="Also check the following labels:"
            prefs_check_labels_add="Add label"
            prefs_check_labels_delay="Check every (secs)"
            prefs_check_labels_label="Label"
            prefs_check_labels_new="[new label]"
            prefs_check_labels_remove="Remove label"
            prefs_external="Externa kommandon"
            prefs_external_browser="Kommando att exekvera vid klick på fältikonen"
            prefs_external_browser2="(använd %u för att representera Gmail webadressen)"
            prefs_external_mail_command="Kommando att exekvera vid nytt mail:"
            prefs_external_nomail_command="Kommando att exekvera vid inget mail:"
            prefs_lang="Språk"
            prefs_login="Logindetaljer"
            prefs_login_pass="_Lösenord"
            prefs_login_save="Spara lösenord"
            prefs_login_save_kwallet="i KDE plånbok"
            prefs_login_save_plain="som klartext"
            prefs_login_user="_Användarnamn"
            prefs_tray="Systemfält"
            prefs_tray_bg="Välj fältbakgrund ..."
            prefs_tray_error_icon="Använd annan fel-ikon"
            prefs_tray_mail_icon="Använd annan mail-ikon"
            prefs_tray_no_mail_icon="Använd annan ingen mail-ikon"
            prefs_tray_pdelay="Visa nytt mail popup i"
            prefs_tray_pdelay2="sekunder" />
  <Language name="hrvatski"
            login_err="Greška: pogrešno korisničko ime ili zaporka"
            login_title="Prijava na Gmail ..."
            mail_archive="Arhiviraj"
            mail_archiving="Arhiviranje ..."
            mail_delete="Obriši"
            mail_deleting="Brisanje ..."
            mail_mark="Označi kao pročitano"
            mail_mark_all="Sve označi kao pročitano"
            mail_marking="Označavanje kao pročitanog ..."
            mail_marking_all="Označavanje svega kao pročitanog ..."
            mail_open="Otvori"
            mail_report_spam="Prijavi neželjenu poruku"
            mail_reporting_spam="Prijava neželjene poruke ..."
            menu_about="_O programu"
            menu_check="_Provjeri poštu"
            menu_compose="Napiši poruku"
            menu_prefs="_Postavke"
            menu_undo="_Poništi zadnji potez"
            notify_and="i"
            notify_check="Provjera Gmaila ..."
            notify_from="Šalje:"
            notify_login="Prijava na Gmail ..."
            notify_multiple1="Broj novih poruka: "
            notify_multiple2=" new messages ..."
            notify_new_mail="Novu poruku šalje "
            notify_no_mail="Nema novih poruka"
            notify_no_subject="(nema predmeta)"
            notify_no_text="(nema teksta)"
            notify_single1="Stigla je "
            notify_single2=" nova poruka ..."
            notify_undoing="Poništavanje zadnjeg postupka ..."
            prefs="Postavke CheckGmaila"
            prefs_check="Provjera pošte"
            prefs_check_24_hour="24-satni oblik"
            prefs_check_archive="Označi i arhiv pročitanim"
            prefs_check_atom="Adresa feeda"
            prefs_check_delay="Provjeri pristiglu poštu svakih "
            prefs_check_delay2=" sek"
            prefs_check_labels="Provjeri i sljedeće oznake:"
            prefs_check_labels_add="Dodaj oznaku"
            prefs_check_labels_delay="Provjeri svakih (sek)"
            prefs_check_labels_label="Oznaka"
            prefs_check_labels_new="[nova oznaka]"
            prefs_check_labels_remove="Ukloni oznaku"
            prefs_external="Vanjske naredbe"
            prefs_external_browser="Naredba za izvršenje prilikom klikanja ikonice na sistemskoj traci"
            prefs_external_browser2="(koristi %u za prikaz web adrese Gmaila)"
            prefs_external_mail_command="Naredba za izvršenje ako ima novih poruka:"
            prefs_external_nomail_command="Naredba za izvršenje ako nema novih poruka:"
            prefs_lang="Jezik"
            prefs_login="Podaci za prijavu"
            prefs_login_pass="_Zaporka"
            prefs_login_save="Spremi zaporku"
            prefs_login_save_kwallet="u KDE wallet"
            prefs_login_save_plain="kao običan text"
            prefs_login_user="_Korisničko ime"
            prefs_tray="Sistemska traka"
            prefs_tray_bg="Postavi pozadinu sistemske trake..."
            prefs_tray_error_icon="Odaberi vlastitu ikonu za pogrešku"
            prefs_tray_mail_icon="Odaberi vlastitu ikonu za novu poruku"
            prefs_tray_no_mail_icon="Odaberi vlastitu ikonu kada nema poruka"
            prefs_tray_pdelay="Prikaži prozorčić s novom porukom na "
            prefs_tray_pdelay2=" sekundi" />
  <Language name="Čeština"
            login_err="Chyba: Špatné jméno nebo heslo"
            login_title="Přihlašuji se na Gmail ..."
            mail_archive="Archivuj"
            mail_archiving="Archivuji ..."
            mail_delete="Odstraň"
            mail_deleting="Odstraňuji ..."
            mail_mark="Označ jako přečtené"
            mail_mark_all="Označ vše jako přečtené"
            mail_marking="Označuji jako přečtené ..."
            mail_marking_all="Označuji vše jako přečtené ..."
            mail_open="Otevřít"
            mail_report_spam="Nahlaš spam"
            mail_reporting_spam="Nahlašuji spam ..."
            menu_about="_O programu"
            menu_check="_Zkontroluj poštu"
            menu_compose="Napiš email"
            menu_prefs="_Nastavení"
            menu_undo="_Vrať poslední akci"
            notify_and="a"
            notify_check="Kontroluji Gmail ..."
            notify_from="Od:"
            notify_login="Přihlašuji se do Gmail ..."
            notify_multiple1="Jsou "
            notify_multiple2=" nové zprávy ..."
            notify_new_mail="Nová zpráva od "
            notify_no_mail="Žádné nové zprávy"
            notify_no_subject="(bez předmětu)"
            notify_no_text="(bez obsahu)"
            notify_single1="Je "
            notify_single2=" nová zpráva ..."
            notify_undoing="Vracím poslední akci ..."
            prefs="CheckGmail - Nastavení"
            prefs_check="Kontrolování pošty"
            prefs_check_24_hour="24-hodinový formát"
            prefs_check_archive="Při archivaci označ jako přečtené"
            prefs_check_atom="Adresa zdroje"
            prefs_check_delay="Kontroluj poštu každých "
            prefs_check_delay2=" vteřin"
            prefs_check_labels="Kontroluj také štítky:"
            prefs_check_labels_add="Přidej štítek"
            prefs_check_labels_delay="Kontroluj každých: (vteřin)"
            prefs_check_labels_label="Štítek"
            prefs_check_labels_new="[nový štítek]"
            prefs_check_labels_remove="Odstraň štítek"
            prefs_external="Příkazy"
            prefs_external_browser="Kliknutím na ikonu se provede"
            prefs_external_browser2="(řetězec %u se nahradí adresou Gmailu)"
            prefs_external_mail_command="Když přijde nová zpráva:"
            prefs_external_nomail_command="Když žádná nová zpráva nepřišla:"
            prefs_lang="Jazyk"
            prefs_login="Informace o účtu"
            prefs_login_pass="_Heslo"
            prefs_login_save="Ulož heslo"
            prefs_login_save_kwallet="w KDE peněžence"
            prefs_login_save_plain="jako běžný text"
            prefs_login_user="_Uživatel"
            prefs_tray="Tray lišta"
            prefs_tray_bg="Pozadí ikony ..."
            prefs_tray_error_icon="Použít vlastní ikonu pro chybu"
            prefs_tray_mail_icon="Použít vlastní ikonu pro novou zprávu"
            prefs_tray_no_mail_icon="Použít vlastní ikonu pro žádnou zprávu"
            prefs_tray_pdelay="Zobraz popup s novou zprávou "
            prefs_tray_pdelay2=" vteřin" />
  <Language name="Русский"
            login_err="Ошибка: Неверный логин или пароль"
            login_title="Логин в Google-Mail ..."
            mail_archive="Архивировать"
            mail_archiving="Архивирую ..."
            mail_delete="Удалить"
            mail_deleting="Удаляю ..."
            mail_mark="Пометить как прочитанное"
            mail_mark_all="Пометить все как прочитанные"
            mail_marking="Помечаю как прочитаное ..."
            mail_marking_all="Помечаю все как прочитанные ..."
            mail_open="Открыть"
            mail_report_spam="Пометить как спам"
            mail_reporting_spam="Помечаю как спам ..."
            menu_about="_О программе"
            menu_check="_Проверить почту"
            menu_compose="Новое сообщение"
            menu_prefs="_Настройки"
            menu_undo="От_менить"
            notify_and="и"
            notify_check="Проверяю Google-Mail ..."
            notify_from="От:"
            notify_login="Соединение с Google-Mail ..."
            notify_multiple1="У вас "
            notify_multiple2=" новых сообщений ..."
            notify_new_mail="Новое сообщение от "
            notify_no_mail="Нет новых сообщений"
            notify_no_subject="(без темы)"
            notify_no_text="(без сообщения)"
            notify_single1="У вас "
            notify_single2=" новое сообщение ..."
            notify_undoing="Отменить последнее изменение ..."
            prefs="Настройки CheckGmail"
            prefs_check="Проверка сообщений"
            prefs_check_24_hour="24-х часовой формат"
            prefs_check_archive="При архивировании пометить как прочитанное"
            prefs_check_atom="Feed адрес:"
            prefs_check_delay="Проверять сообщения каждые "
            prefs_check_delay2=" секунд"
            prefs_check_labels="Также проверять следующие ярлыки:"
            prefs_check_labels_add="Добавить ярлык"
            prefs_check_labels_delay="Проверять каждые (сек)"
            prefs_check_labels_label="Ярлык"
            prefs_check_labels_new="[новый ярлык]"
            prefs_check_labels_remove="Удалить ярлык"
            prefs_external="Внешние программы"
            prefs_external_browser="Web-браузер"
            prefs_external_browser2="(Вместо %u будет установлен адрес)"
            prefs_external_mail_command="Выполнять при новых сообщениях:"
            prefs_external_nomail_command="Выполнять, когда новых сообщений нет:"
            prefs_lang="Язык"
            prefs_login="Login-настройки"
            prefs_login_pass="_Пароль"
            prefs_login_save="Сохранить пароль"
            prefs_login_save_kwallet="в KDE-Wallet"
            prefs_login_save_plain="незашифрованным"
            prefs_login_user="_Логин"
            prefs_tray="Системный трей"
            prefs_tray_bg="Цвет заднего фона ..."
            prefs_tray_error_icon="Использовать свою иконку для ошибок"
            prefs_tray_mail_icon="Использовать свою иконку для новых сообщений"
            prefs_tray_no_mail_icon="Использовать свою иконку для отсутствия новых сообщений"
            prefs_tray_pdelay="Показывать оповещение "
            prefs_tray_pdelay2=" секунд" />
  <Language name="தமிழ்"
            login_err="பிழை: பயனர் பெயரில் அல்லது கடவுச்சொல்லில்"
            login_title="ஜிமெயிலினுள் நுழை ..."
            mail_archive="பேழையிலிடு"
            mail_archiving="பேழையினுள் இடுகிறது..."
            mail_delete="அழி"
            mail_deleting="அழிக்கப்படுகிறது ..."
            mail_mark="படித்ததாகக் குறி"
            mail_mark_all="அனைத்து மடல்களும் படித்ததாகக் குறி"
            mail_marking="படித்ததாகக் குறிக்கப்படுகிறது ..."
            mail_marking_all="அனைத்து மடல்களும் படித்ததாகக் குறிக்கப்படுகிறது ..."
            mail_open="மடலினைத் திற"
            mail_report_spam="ஒவ்வாத/விளம்பர மடல்"
            mail_reporting_spam="ஒவ்வாத/விளம்பர மடலெனத் தெரிவி ..."
            menu_about="_அறிவிப்பான் குறித்து"
            menu_check="_மடல் உள்ளதாவெனப் பார்"
            menu_compose="மடல் எழுத"
            menu_prefs="_அமைவு விருப்பங்கள்"
            menu_undo="_முந்தைய செயலை மாற்று"
            notify_and="மற்றும்"
            notify_check="மடல் வரவைப் பார் ..."
            notify_from="அனுப்புனர்:"
            notify_login="ஜிமெயிலுனுள் நுழைகிறது ..."
            notify_multiple1="அஞ்சல் பெட்டியில் "
            notify_multiple2=" புதிய மடல்கள் வந்துள்ளன ..."
            notify_new_mail="புதிய மடலினை  அனுப்பியவர் "
            notify_no_mail="புதிய மடல் ஏதும் இல்லை"
            notify_no_subject="(பொருள் இல்லை)"
            notify_no_text="(எழுத்து எதுவும் இல்லை)"
            notify_single1="அஞ்சல் பெட்டியில் "
            notify_single2=" புதிய மடல் உள்ளது ..."
            notify_undoing="முந்தைய செயலை  நிராகரிக்கிறது ..."
            prefs="ஜிமெயில் புதுமடல் வரத்தில் உங்களின் விருப்பங்கள்"
            prefs_check="மடலின் வரவு பார்க்கப்படுகிறது"
            prefs_check_24_hour="24 மணிநேரக் கடிகாரம்"
            prefs_check_archive="பேழையிலிட்டுப் படித்ததாகக் குறி"
            prefs_check_atom="ஆட்டோம் அல்லது ஈட்டு முகவரி"
            prefs_check_delay="அஞ்சல் பெட்டியை "
            prefs_check_delay2=" நொடிகளுக்கொருமுறை பார்"
            prefs_check_labels="கீழ்க்கண்டக் குறிகளிடப்பட்ட மடல்கள் உள்ளனவா எனப் பார்:"
            prefs_check_labels_add="புதிதாகக் குறியீட்டை  இணை"
            prefs_check_labels_delay="இவற்றை பார்ப்பதற்கான இடைவெளி (நொடிகளில்)"
            prefs_check_labels_label="குறியீடு"
            prefs_check_labels_new="[புதியக் குறியீடு]"
            prefs_check_labels_remove="குறியீட்டை  நீக்கு"
            prefs_external="வெளி ஆணை"
            prefs_external_browser="குறிப்படத்தை  சொடுக்கும் பொழுது, இயற்றப்படும் ஆணை"
            prefs_external_browser2="(ஜிமெயில் தளத்தைத் திறக்கவேண்டியத் தள உலாவி:)"
            prefs_external_mail_command="புதிய மடல் எழுதுவதற்குத் தேவையான ஆணை:"
            prefs_external_nomail_command="மடல் இல்லை  எனில் இடப்படவேண்டிய ஆணை:"
            prefs_lang="மொழி"
            prefs_login="பயனாளர் விவரங்கள்"
            prefs_login_pass="_கடவுச் சொல்"
            prefs_login_save="கடவுச் சொல்லை சேமிக்க"
            prefs_login_save_kwallet="KDE பையினுள் சேமிக்க"
            prefs_login_save_plain="வெறும் எழுத்துக்களாக சேமிக்க"
            prefs_login_user="_பயனர்"
            prefs_tray="அறிவிப்பானின் பலகை"
            prefs_tray_bg="அறிவிப்பானின் பலகையின் நிறத்தைத் தேர்ந்தெடுக்க ..."
            prefs_tray_error_icon="வழக்கமான பிழை குறிப்படத்தைப் பயன்படுத்த"
            prefs_tray_mail_icon="வழக்கமான மடல் குறிப்படத்தைப் பயன்படுத்த"
            prefs_tray_no_mail_icon="வழக்கமான மடல்-இல்லை குறிப்படத்தைப் பயன்படுத்த"
            prefs_tray_pdelay="புதிய மடலின் வருகை  அறிவிப்பை"
            prefs_tray_pdelay2="நொடிகளுக்குக் காட்டுக" />
  <Language name="Македонски"
            login_err="Грешка: Погрешно корисничко име или лозинка"
            login_title="Се логирам на Gmail ..."
            mail_archive="Архива"
            mail_archiving="Архивирам ..."
            mail_delete="Бриши"
            mail_deleting="Бришам ..."
            mail_mark="Обележи како прочитано"
            mail_mark_all="Обележи сѐ како прочитано"
            mail_marking="Обележувам како прочитано ..."
            mail_marking_all="Обележувам сѐ како прочитано ..."
            mail_open="Отвори"
            mail_report_spam="Пријави спам"
            mail_reporting_spam="Пријавувам спам ..."
            menu_about="_За"
            menu_check="_Провери пошта"
            menu_compose="Пиши пошта"
            menu_prefs="_Поставување"
            menu_undo="_Врати ја претходната акција"
            notify_and="и"
            notify_check="Проверувам на Gmail ..."
            notify_from="Од:"
            notify_login="Се логирам на Gmail ..."
            notify_multiple1="Има "
            notify_multiple2=" нови пораки ..."
            notify_new_mail="Нова пошта од "
            notify_no_mail="Нема нови пораки"
            notify_no_subject="(без наслов)"
            notify_no_text="(без текст)"
            notify_single1="Има "
            notify_single2=" нова порака ..."
            notify_undoing="Ја враќам претходната акција ..."
            prefs="CheckGmail поставувања"
            prefs_check="Проверување пошта"
            prefs_check_24_hour="24 часа"
            prefs_check_archive="Архивирај, исто така обележи како прочитано"
            prefs_check_atom="Адреса на каналот"
            prefs_check_delay="Провери го сандачето за пошта секои "
            prefs_check_delay2=" секунди"
            prefs_check_labels="Исто така провери ги следниве ознаки:"
            prefs_check_labels_add="Додај ознака"
            prefs_check_labels_delay="Провери секои (секунди)"
            prefs_check_labels_label="Ознака"
            prefs_check_labels_new="[нова ознака]"
            prefs_check_labels_remove="Тргни ознака"
            prefs_external="Надворешни команди"
            prefs_external_browser="Команда која ќе се изврши на кликање на иконата "
            prefs_external_browser2="(користи %u да ја преставиш Gmail веб адресата)"
            prefs_external_mail_command="Команда која ќе се изврши кога има нова пошта:"
            prefs_external_nomail_command="Команда која ќе се изврши кога нема нова пошта:"
            prefs_lang="Јазик"
            prefs_login="Детали за логирањето"
            prefs_login_pass="_Лозинка"
            prefs_login_save="Сними лозинка"
            prefs_login_save_kwallet="во KDE паричникот"
            prefs_login_save_plain="како обичен текст"
            prefs_login_user="_Корисничко име"
            prefs_tray="Системско ќоше"
            prefs_tray_bg="Подеси боја на ќошето"
            prefs_tray_error_icon="Користи посебна икона за грешка"
            prefs_tray_mail_icon="Користи посебна икона за нова пошта"
            prefs_tray_no_mail_icon="Користи посебна икона за немање нова пошта"
            prefs_tray_pdelay="Покажи го скокачкото прозорче за нова пошта "
            prefs_tray_pdelay2=" секунди" />
  <Language name="Biełaruskaja łacinka"
            login_err="Pamyłka: Drenny login albo parol"
            login_title="Aŭtaryzacyja ŭ Gmail ..."
            mail_archive="Archivizuj"
            mail_archiving="Archivizuje ..."
            mail_delete="Vydal"
            mail_deleting="Vydalaje ..."
            mail_mark="Paznač jak pračytanaje"
            mail_mark_all="Paznač usio jak pračytanaje"
            mail_marking="Zaznačaje jak pračytanaje ..."
            mail_marking_all="Zaznačaje usio jak pračytanaje ..."
            mail_open="Adčyni"
            mail_report_spam="Rapartuj spam"
            mail_reporting_spam="Rapartuje spam ..."
            menu_about="_Pra prahramu"
            menu_check="_Pravier poštu"
            menu_compose="Napišy list"
            menu_prefs="_Nałady"
            menu_undo="_Anuluj apošniuju aperacyju"
            notify_and="i"
            notify_check="Spraŭdžvaju Gmail ..."
            notify_from="Ad:"
            notify_login="Aŭtaryzacyja ŭ Gmail ..."
            notify_multiple1="Jość "
            notify_multiple2=" novyja listy ..."
            notify_new_mail="Novaja pošta ad "
            notify_no_mail="Niama novych listoŭ"
            notify_no_subject="(biaz temy)"
            notify_no_text="(biaz źmiestu)"
            notify_single1="Jość "
            notify_single2=" novy list ..."
            notify_undoing="Anuloŭvajecca apošniaja aperacyja ..."
            prefs="CheckGmail - nałady"
            prefs_check="Pravierka pošty"
            prefs_check_24_hour="24-hadzinny hadzińnik"
            prefs_check_archive="Aarchivizujučy paznač taksama jak pračytanaje"
            prefs_check_atom="Adras "
            prefs_check_delay="Praviaraj poštu kožnyja "
            prefs_check_delay2=" sekund"
            prefs_check_labels="Pravier taksama etykety:"
            prefs_check_labels_add="Dadaj etykietu"
            prefs_check_labels_delay="Pravier kožnyja: (sekund)"
            prefs_check_labels_label="Etykieta"
            prefs_check_labels_new="[novaja etykieta]"
            prefs_check_labels_remove="Vydal etykietu"
            prefs_external="Unutranyja zahady"
            prefs_external_browser="Zahad kab vykanać paśla kliku ŭ ikonu"
            prefs_external_browser2="(u miescy %u budzie ŭstaŭleny adras Gmail)"
            prefs_external_mail_command="Zahad kab vykanać kali pryjdzie novy list:"
            prefs_external_nomail_command="Zahad kab vykanać kali niama novych listoŭ:"
            prefs_lang="Mova"
            prefs_login="Infarmacyja pra kont"
            prefs_login_pass="_Parol"
            prefs_login_save="Zapišy parol"
            prefs_login_save_kwallet="u hametcy KDE"
            prefs_login_save_plain="jak zvyčajny tekst"
            prefs_login_user="_Karystalnik"
            prefs_tray="Ikona"
            prefs_tray_bg="Fon pad ikonaj ..."
            prefs_tray_error_icon="Ułasnaja ikona pamyłki"
            prefs_tray_mail_icon="Ułasnaja ikona novaj pošty"
            prefs_tray_no_mail_icon="Ułasnaja ikona adsutnaści pošty"
            prefs_tray_pdelay="Pakazvaj vypłyŭnoje vakno ciaham "
            prefs_tray_pdelay2=" sekund" />
  <Language name="日本語"
            login_err="エラー: ユーザーネームまたはパスワードが違います"
            login_title="Gmail にログインしています ..."
            mail_archive="アーカイブ"
            mail_archiving="アーカイブしています ..."
            mail_delete="削除"
            mail_deleting="削除しています ..."
            mail_mark="既読にする"
            mail_mark_all="すべて既読にする"
            mail_marking="既読にしています ..."
            mail_marking_all="すべてを既読にしています ..."
            mail_open="開く"
            mail_report_spam="迷惑メールを報告"
            mail_reporting_spam="迷惑メールを報告しています ..."
            menu_about="CheckGmail について"
            menu_check="メールをチェック"
            menu_compose="メールを作成"
            menu_prefs="設定"
            menu_undo="やり直し"
            notify_and="と"
            notify_check="Gmail をチェックしています ..."
            notify_from="From:"
            notify_login="Gmail にログインしています ..."
            notify_multiple1="新着メール： "
            notify_multiple2=" 通のメッセージ ..."
            notify_new_mail="新着メール from "
            notify_no_mail="新しいメールはありません"
            notify_no_subject="(件名なし)"
            notify_no_text="(テキストなし)"
            notify_single1="新着メール： "
            notify_single2=" 通のメッセージ ..."
            notify_undoing="やり直しを行っています ..."
            prefs="CheckGmail の設定"
            prefs_check="メールのチェック"
            prefs_check_24_hour="24 時間時計"
            prefs_check_archive="既読もアーカイブに入れる"
            prefs_check_atom="フィードのアドレス"
            prefs_check_delay="受信トレイをチェックする周期： "
            prefs_check_delay2=" 秒"
            prefs_check_labels="以下のラベルもチェックします："
            prefs_check_labels_add="ラベルの追加"
            prefs_check_labels_delay="チェックの周期 (秒)"
            prefs_check_labels_label="ラベル"
            prefs_check_labels_new="[新しいラベル]"
            prefs_check_labels_remove="ラベルの削除"
            prefs_external="外部コマンド"
            prefs_external_browser="トレイのアイコンをクリック時に実行するコマンド"
            prefs_external_browser2="(%u は Gmail のウェブアドレスを指します)"
            prefs_external_mail_command="新着メールに対して実行するコマンド:"
            prefs_external_nomail_command="新着メールがない場合に実行するコマンド："
            prefs_lang="言語"
            prefs_login="ログインの詳細"
            prefs_login_pass="パスワード"
            prefs_login_save="パスワードを保存"
            prefs_login_save_kwallet="KDE ウォレットに保存"
            prefs_login_save_plain="プレインテキストとして保存"
            prefs_login_user="ユーザーネーム"
            prefs_tray="システムトレイ"
            prefs_tray_bg="トレイの背景を設定 ..."
            prefs_tray_error_icon="カスタムのエラー・アイコンを使用"
            prefs_tray_mail_icon="カスタムのメール・アイコンを使用"
            prefs_tray_no_mail_icon="カスタムのメールなし・アイコンを使用"
            prefs_tray_pdelay="新着メール時のポップアップ表示時間： "
            prefs_tray_pdelay2=" 秒" />
  <Language name="简体中文"
            login_err="错误: 错误的用户名或密码"
            login_title="登录到Gmail ..."
            mail_archive="归档"
            mail_archiving="正在归档 ..."
            mail_delete="删除"
            mail_deleting="正在删除 ..."
            mail_mark="标记邮件为已读"
            mail_mark_all="标记邮件所有为已读"
            mail_marking="正在标记邮件为已读 ..."
            mail_marking_all="正在标记所有邮件为已读 ..."
            mail_open="打开"
            mail_report_spam="报告垃圾邮件"
            mail_reporting_spam="正在报告垃圾邮件 ..."
            menu_about="关于(_A)"
            menu_check="立即检查邮件(_C)"
            menu_compose="写邮件"
            menu_prefs="首选项(_P)"
            menu_undo="撤消前一操作(_U)"
            notify_and="和"
            notify_check="正在检查Gmail ..."
            notify_from="From:"
            notify_login="正在登录到Gmail ..."
            notify_multiple1="您有 "
            notify_multiple2=" 封新邮件 ..."
            notify_new_mail="新邮件 "
            notify_no_mail="没有新邮件"
            notify_no_subject="(无标题)"
            notify_no_text="(无正文)"
            notify_single1="您有 "
            notify_single2=" 新邮件 ..."
            notify_undoing="正在撤销前一操作 ..."
            prefs="CheckGmail首选项"
            prefs_check="检查设置"
            prefs_check_24_hour="时钟类型为24小时"
            prefs_check_archive="归档并标记为已读"
            prefs_check_atom="Feed地址"
            prefs_check_delay="检查收件箱频率 "
            prefs_check_delay2=" 秒"
            prefs_check_labels="同时检查一下标签:"
            prefs_check_labels_add="添加标签"
            prefs_check_labels_delay="检查频率(秒)"
            prefs_check_labels_label="标签"
            prefs_check_labels_new="[新标签]"
            prefs_check_labels_remove="删除标签"
            prefs_external="扩展设置"
            prefs_external_browser="点击通知栏图标启动程序"
            prefs_external_browser2="(使用 %u 表示Gmail地址)"
            prefs_external_mail_command="写邮件时启动程序:"
            prefs_external_nomail_command="无邮件时启动程序:"
            prefs_lang="界面语言"
            prefs_login="登录设置"
            prefs_login_pass="密码(_P)"
            prefs_login_save="保存密码"
            prefs_login_save_kwallet="到KDE钱包"
            prefs_login_save_plain="不加密"
            prefs_login_user="用户名(_U)"
            prefs_tray="通知栏设置"
            prefs_tray_bg="通知栏背景颜色 ..."
            prefs_tray_error_icon="个性化错误图标"
            prefs_tray_mail_icon="个性化邮件图标"
            prefs_tray_no_mail_icon="个性化无邮件图标"
            prefs_tray_pdelay="通知显示延迟 "
            prefs_tray_pdelay2=" 秒" />
   <Language name="Ελληνικά"
 	    login_err="Σφάλμα: Το όνομα χρήστη και ο κωδικός πρόσβασης δεν ταιριάζουν"
 	    login_title="Σύνδεση στο Gmail ..."
 	    mail_archive="Αρχειοθέτηση"
 	    mail_archiving="Αρχειοθέτηση ..."
 	    mail_delete="Διαγραφή"
 	    mail_deleting="Διαγραφή ..."
 	    mail_mark="Χαρακτηρισμός ως αναγνωσμένο"
 	    mail_mark_all="Χαρακτηρισμός όλων ως αναγνωσμένα"
 	    mail_marking="Χαρακτηρισμός ως αναγνωσμένο ..."
 	    mail_marking_all="Χαρακτηρισμός όλων ως αναγνωσμένα ..."
 	    mail_open="Άνοιγμα"
 	    mail_report_spam="Αναφορά Ανεπιθύμητου"
 	    mail_reporting_spam="Αναφορά Ανεπιθύμητου ..."
 	    menu_about="_Σχετικά"
 	    menu_check="_Έλεγχος mail"
 	    menu_compose="Σύνθεση Μηνύματος"
 	    menu_prefs="_Ρυθμίσεις"
 	    menu_restart="Επανεκκίνηση ..."
 	    menu_undo="_Ακύρωση προηγουμενης πράξης"
 	    notify_and="και"
 	    notify_check="Έλεγχος Gmail ..."
 	    notify_from="Από:"
 	    notify_login="Σύνδεση στο Gmail ..."
 	    notify_multiple1="Υπάρχουν "
 	    notify_multiple2=" νέα μηνύματα ..."
 	    notify_new_mail="Νέο mail από "
 	    notify_no_mail="Κανένα νέο mail"
 	    notify_no_subject="(κανένα θέμα)"
 	    notify_no_text="(κανένα κείμενο)"
 	    notify_single1="Υπάρχει "
 	    notify_single2=" νέο μήνυμα ..."
 	    notify_undoing="Ακύρωση προηγουμενης πράξης ..."
 	    prefs="CheckGmail ρυθμίσεις"
 	    prefs_check="Έλεγχος mail"
 	    prefs_check_24_hour="24 hour clock"
 	    prefs_check_archive="Η Αρχειοθέτηση χαρακτηρίζει το mail και ως αναγνωσμένο"
 	    prefs_check_atom="Feed διεύθυνση"
 	    prefs_check_delay="Έλεγχος στο φάκελο Εισερχόμενα για νέο mail κάθε "
 	    prefs_check_delay2=" δευτερόλεπτα"
 	    prefs_check_labels="Επίσης έλεγχος και τον παρακάτω ετικετών:"
 	    prefs_check_labels_add="Εφαρμογή ετικέτας"
 	    prefs_check_labels_delay="Έλεγχος κάθε (δευτερόλεπτα)"
 	    prefs_check_labels_label="Ετικέτα"
 	    prefs_check_labels_new="[νέα ετικέτα]"
 	    prefs_check_labels_remove="Αφαίρεση ετικέτας"
 	    prefs_external="Εξωτερικές Εντολές"
 	    prefs_external_browser="Εκτέλεση Εντολής όταν κάνετε κλικ στο tray icon"
 	    prefs_external_browser2="(Χρησιμοποιήστε %u για την διεύθυνση του Gmail)"
 	    prefs_external_mail_command="Εκτέλεση Εντολής όταν έχετε νέο mail:"
 	    prefs_external_nomail_command="Εκτέλεση Εντολής όταν δεν έχετε νέο mail:"
 	    prefs_lang="Γλώσσα"
 	    prefs_login="Στοιχεία λογαριασμού"
 	    prefs_login_pass="_Κωδικός Πρόσβασης"
 	    prefs_login_save="Διατήρηση των στοιχείων μου"
 	    prefs_login_save_kwallet="στο KDE wallet"
 	    prefs_login_save_plain="ως απλό κείμενο"
 	    prefs_login_user="_Όνομα Χρήστη"
 	    prefs_tray="System tray"
 	    prefs_tray_bg="Set tray background ..."
 	    prefs_tray_error_icon="Χρησιμοποίησε άλλο εικονίδιο σφάλματος"
 	    prefs_tray_mail_icon="Χρησιμοποίησε άλλο εικονίδιο για νέο mail "
 	    prefs_tray_no_mail_icon="Χρησιμοποίησε άλλο εικονίδιο για κανένα νέο mail"
 	    prefs_tray_pdelay="Υπενθύμιση νέου mail για "
 	    prefs_tray_pdelay2=" δευτερόλεπτα" />
</opt>

EOF
	my $def_xml = XMLin($default_translations, ForceArray => 1);
		
	unless (-e "$prefs_dir/lang.xml") {
		print "Creating translations file at $prefs_dir/lang.xml ...\n";
		# If there isn't a translation file, we create a default one
		$translations = $default_translations;
		open(LANG, ">$prefs_dir/lang.xml") || die("Could not open lang.xml file for writing: $!");
		print LANG $translations;
		close LANG;	
	} else {
		# read translations file if it exists
		open(LANG, "<$prefs_dir/lang.xml") || die("Could not open lang.xml file for reading: $!");
		$translations = join("",<LANG>);
		close LANG;
	}
				
	my $xmlin = XMLin($translations, ForceArray => 1);
	
	my $user_trans_v = $xmlin->{Version};
				
	my $trans_mod;
	foreach my $lang (keys(%{$def_xml->{Language}})) {
		# print "checking $lang\n";
		
		# Check that all translation keys exist, and add in those that don't from defaults ...
		if ($def_xml->{Language}->{$lang}) {
			# user language exists in defaults
			# next if $lang eq 'English';
			foreach (keys(%{$def_xml->{Language}->{English}})) {
				
				if ($lang eq 'English') {
					next if ($xmlin->{Language}->{$lang}->{$_} && ($xmlin->{Language}->{$lang}->{$_} eq $def_xml->{Language}->{$lang}->{$_}));
					$xmlin->{Language}->{$lang}->{$_} = $def_xml->{Language}->{$lang}->{$_};
				} elsif ($def_xml->{Language}->{$lang}->{$_}) {
					# Don't overwrite if the key exists in the user trans file and the version is current
					next if ($xmlin->{Language}->{$lang}->{$_} && $user_trans_v eq $version);
					# Don't overwrite if the key is the same
					next if ($xmlin->{Language}->{$lang}->{$_} && ($xmlin->{Language}->{$lang}->{$_} eq $def_xml->{Language}->{$lang}->{$_}));
					# Don't overwrite if the key exists in the user trans and the key in the default trans is the same as the English one
					next if ($xmlin->{Language}->{$lang}->{$_} && ($def_xml->{Language}->{$lang}->{$_} eq $def_xml->{Language}->{English}->{$_}));
					$xmlin->{Language}->{$lang}->{$_} = $def_xml->{Language}->{$lang}->{$_};
				} else {
					next if $xmlin->{Language}->{$lang}->{$_};
					$xmlin->{Language}->{$lang}->{$_} = $def_xml->{Language}->{English}->{$_};
				}
				print "[$lang] updating key $_ ...\n" unless $silent;
				$trans_mod = 1;
			}
		} else {
			# user language does not exist - use English
			foreach (keys(%{$def_xml->{Language}->{English}})) {
				next if $xmlin->{Language}->{$lang}->{$_};
				$xmlin->{Language}->{$lang}->{$_} = $def_xml->{Language}->{English}->{$_};
				$trans_mod = 1;
			}
		}
	}
	
	foreach (keys(%{$def_xml->{Language}})) {
		# Check that all translation languages are present, and add in those that don't from defaults ...
		my $lang = $_;
		unless ($xmlin->{Language}->{$lang}) {
			$xmlin->{Language}->{$lang} = $def_xml->{Language}->{$lang};
			$trans_mod = 1;
		} 				
	}
	
	
	if ($trans_mod) {
		$xmlin->{Version} = $version;
		$translations = XMLout($xmlin, AttrIndent=>1);
		print "Updating translations file ...\n";
		open(LANG, ">$prefs_dir/lang.xml") || die("Could not open lang.xml file for writing: $!");
		print LANG $translations;
		close LANG;
		print " ... done!\n";
	}

	set_language();
}

sub set_language {
	my $xmlin = XMLin($translations, ForceArray => 1);
	
	## For debugging ...
	# use Data::Dumper;
	# print Dumper $xmlin;
	
	%trans = %{$xmlin->{Language}->{$language}};
}

