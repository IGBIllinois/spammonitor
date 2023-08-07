# Spam Monitor
Script checks a person's Junk folder and sends an email digest of spam message.\
Uses Bootstrap 4.1.3 for email template.\

# Requirements
* Perl
* Perl Date::Calc
* Perl Email::Simple
* Perl Email::Folder
* Perl libnet

# Installation
* Install Perl cpanm to be able to install perl modules
```
dnf install perl-App-cpanminus
```
* Install the perl modules using cpanm into the lib folder
```
cpanm --installdeps -l $PWD/perl5 .
```

