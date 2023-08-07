# Spam Monitor
Script checks a person's Junk folder and sends an email digest of spam message

# Requirements
* Perl
* Perl Date::Calc
* Perl Email::Simple
* Perl Email::Folder
* Perl libnet

# Installation
* On Rocky Linux, install the needed perl RPM Packages
```
dnf install perl-App-cpanminus perl-libnet perl-Email-Simple perl-Date-Calc
```
* Install the remaining modules using cpanm
```
cpanm --installdeps .
```

