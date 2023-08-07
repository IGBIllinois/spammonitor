# Spam Monitor
[![Build Status](https://github.com/IGBIllinois/spammonitor/actions/workflows/main.yml/badge.svg)](https://github.com/IGBIllinois/spammonitor/actions/workflows/main.yml)
- Script checks a person's Junk folder and sends an email digest of spam message.
- Uses Bootstrap 4.1.3 for email template.

# Requirements
* Perl
* Perl Date::Calc
* Perl Email::Simple
* Perl Email::Folder
* Perl Email::Delete
* Perl Net::SMTP

# Installation
* Install Perl cpanm to be able to install perl modules
```
dnf install perl-App-cpanminus
```
* Install the perl modules using cpanm into the lib folder
```
cpanm --installdeps -l $PWD/perl5 .
```

* Create /etc/cron.d/spammonitor and run spammonitor.pl once a day
```
55 23 * * * root /usr/local/spammonitor/spammonitor.pl
```

