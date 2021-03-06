use strict;
use warnings;
use inc::Module::Install;

name        'Parse-FixedRecord';
all_from    'lib/Parse/FixedRecord.pm';

requires 'Moose';
requires 'MooseX::Types';
requires 'MooseX::ClassAttribute';
requires 'DateTime';
requires 'DateTime::Format::Strptime';
requires 'DateTime::Format::Duration';
requires 'List::Util';

license     'perl';
author      'osfameron';

auto_install;
WriteAll;
