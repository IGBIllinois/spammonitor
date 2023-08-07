#!/usr/bin/env perl

# spammonitor.pl
# Author: Daniel Davidson <danield@igb.illinois.edu>, David Slater <dslater@igb.illinois.edu>
# 
# Script checks a person's Junk folder and sends an email digest of spam messages
#

use strict;
use warnings;
use local::lib './perl5';

use Email::Simple;
use Email::Folder;
use Email::Delete qw[delete_message];
use Date::Calc qw(Delta_Days check_date);
use Net::SMTP;
use Getopt::Long;
use Fcntl qw(:flock SEEK_END);
use Cwd qw();

sub help() {
        print "Usage: $0\n";
        print "Script checks a person's Junk folder and sends an email digest of spam messages\n";
        print "\t--dry-run        Does dry run only\n";
        print "\t-h|--help        Prints this help\n";
        exit 0;
}
sub send_mail {
	my $email = $_[0];
	my $message = $_[1];
	my $from_email = $_[2];
	my $email_subject = $_[3];
	my $from_name = $_[4];
	my $smtp = Net::SMTP->new("localhost");
        $smtp->mail($from_email);
	$smtp->to($email);
	$smtp->data();
	$smtp->datasend("To: $email\n");
	$smtp->datasend("Subject: $email_subject\n");
	$smtp->datasend("Content-Type: text/html; charset=\"US-ASCII\"\n");
	$smtp->datasend("From: $from_name <$from_email>\n");
	$smtp->datasend("\n");
	$smtp->datasend("$message");
	$smtp->dataend();
	$smtp->quit;
}

sub get_name {
	my $username = $_[0];
	#my $cmd = "ldapsearch -x 'uid=$username' cn | grep 'cn:' | cut -f 2 -d ':' | xargs";
	my $cmd = "getent passwd $username | cut -f 5 -d ':'";
	my $fullname = `$cmd`;
	return($fullname);

}

my $dryrun = 0;
GetOptions ("dry-run" => \$dryrun,
        "h|help" => sub { help() },
) or die("\n");

my $delta=7;
my $sleep=1;
my $homedirectory1='/home/a-m';
my $homedirectory2='/home/n-z';
my $maildirectory='mail';
my $spamfolder='Junk';
my $mailhost='localhost';
my $fromemail='do-not-reply@igb.illinois.edu';
my $adminemail='help@igb.illinois.edu';
my $fromname='IGB Detect Spam';
my $domain='@igb.illinois.edu';
my %monthtonum = (
	Jan => '1',
	Feb => '2',
	Mar => '3',
	Apr => '4',
	May => '5',
	Jun => '6',
	Jul => '7',
	Aug => '8',
	Sep => '9',
	Oct => '10',
	Nov => '11',
	Dec => '12'
);
my @now=localtime(time);
$now[4]++;
$now[5]+=1900;

my $current_path = Cwd::cwd();
my $css_file = "$current_path/bootstrap.min.css";

open FILE, $css_file or die "Couldn't open file: $!";
my $css = do {local $/; <FILE> };
close FILE;
opendir(HOMEDIR,$homedirectory1);
my @uids=grep ! /^\./, readdir(HOMEDIR);
closedir HOMEDIR;

opendir(HOMEDIR,$homedirectory2);
my @uids2=grep ! /^\./, readdir(HOMEDIR);
closedir HOMEDIR;

#push(@uids,@uids2); 


#me only
@uids=();
@uids[0]='dslater';
while(my $uid=shift(@uids)) {
		#check if user is in a-m or n-z
		my $full_spam_path;
		if($uid=~/^([a-m])/) {       
        		$full_spam_path="/home/a-m/$uid/$maildirectory/$spamfolder";
		}
		elsif($uid=~/^([n-z])/) {
        		$full_spam_path="/home/a-m/$uid/$maildirectory/$spamfolder";
		}
		if(-e "$full_spam_path") {
			my $box=Email::Folder->new("$full_spam_path") or die "Unable to open $full_spam_path";
	
			my @deletemessages=();
			my %todaysspam=();
			while(my $mail=$box->next_message) {
				my $body=$mail->body;
				my $subject=$mail->header("Subject");
				my $from=$mail->header("From");
				my $date=$mail->header("Date");
				my $messageid=$mail->header('Message-ID');
				my @date=split(/\s+/,$date);
				if($date[3]=~/\d{4}/ and $monthtonum{$date[2]} and $date[1]>=1 and $date[1]<=31) {
					if(check_date($date[3],$monthtonum{$date[2]},$date[1])) {
						#print "$date:@date[3],$monthtonum{@date[2]},@date[1]\n";
						my $deltadays=Delta_Days($date[3],$monthtonum{$date[2]},$date[1],
											$now[5],$now[4],$now[3]);
						if($deltadays==0 and $from ne "") {
							$todaysspam{$messageid}{'from'}=$from;
							$todaysspam{$messageid}{'date'}="$date[2]-$date[1]-$date[3]";
							$todaysspam{$messageid}{'subject'}=$subject;
						}
						unless($deltadays < $delta) {
							#print "Deleted message from $from $deltadays day old\n";
							push(@deletemessages,$messageid);
						}
						else {
							#print "keep message from $from\n";
						}
					}
					else {
						push(@deletemessages,$messageid);
					}
				}
				else {
					#print "Invalid date header from $from, deleting message\n";
					push(@deletemessages,$messageid);
				}
			}
			open(MBOX,"$full_spam_path") or die "Cannot open mailbox $full_spam_path\n";
			flock(MBOX, LOCK_EX) or die "Cannot lock mailbox $full_spam_path\n";
			foreach my $deletemessage (@deletemessages) {
				delete_message(
					from => "$full_spam_path",
					matching => sub { my $message=shift; $message->header('Message-ID') eq $deletemessage; }
				);
			}

			sleep($sleep);
			flock(MBOX, LOCK_UN);
			close(MBOX);
			sleep($sleep);
			my $fullname = get_name($uid);	
			my $to = "$uid$domain";
			my $send_subject = "IGB Spam Received $now[4]-$now[3]-$now[5]";
			my $send_message = "<html><head>\n";
			$send_message .= "<style media=\"all\" type=\"text/css\">\n";
			$send_message .= "$css";
			$send_message .= "</style></head>\n";
			$send_message .= "<body>";
			$send_message .= "<div class='container-fluid'><div class='col-sm-8 offset-sm-4'>";
			$send_message .= "<br><p>$fullname, </p>";
			$send_message .= "<p>Today the following messages have been quarantined by the IGB Spam Filter.\n";
			$send_message .= "If you wish to retrieve any of these messages, they are located in your <strong>Junk</strong> folder\n";
			$send_message .= "You can access the Junk folder by accessing the IGB webmail at <a href=\"http://mail.igb.illinois.edu\">http://mail.igb.illinois.edu</a>.\n";
			$send_message .= "or using IMAP to connect to the server.</p>\n";
			$send_message .= "<p>Spam messages over <strong>$delta</strong> days old are automatically deleted.</div></p>"; 
			$send_message .= "<div class='col-sm-8 offset-sm-4'><p><table class='table table-striped table-bordered table-sm'>\n";
			$send_message .= "<tr><th>From</th><th>Date</th><th>Subject</th></tr>\n";
			foreach my $key (keys %todaysspam){
				$send_message .= "<tr><td>$todaysspam{$key}{'from'}</td><td>$todaysspam{$key}{'date'}</td><td>$todaysspam{$key}{'subject'}</td></tr>\n";
			}
			$send_message .= "</table></div>\n";
			$send_message .= "<div class='col-sm-8 offset-sm-4'>\n";
			$send_message .= "<p>IGB Computer Network Resource Group\n";
			$send_message .= "<br><a href='mailto:$adminemail'>$adminemail</a>\n";
			$send_message .= "</div></div></body></html>\n";

			if (keys %todaysspam) {
				send_mail($to,$send_message,$fromemail,$send_subject,$fromname);
				my $num_spam = scalar keys %todaysspam;
				print "$uid email sent. $num_spam spam messages\n";
			}
			else {
				print "$uid has no spam.  Email not sent\n";
			}
		}
}
